"""
Oslo City Bike → Snowflake loader

update
----------------------------------
Dwa tryby:
  python load_oslo_bikes.py --backfill   # ładuje dane historyczne (2023-01 → poprzedni miesiąc)
  python load_oslo_bikes.py              # ładuje tylko kolejny brakujący miesiąc (tryb automatyczny)
"""

import snowflake.connector
import requests
import csv
import io
import argparse
from datetime import datetime, date
from dateutil.relativedelta import relativedelta
import os

# ── Konfiguracja Snowflake ──────────────────────────────────────────────────
SNOWFLAKE_CONFIG = {
    "account":   os.getenv("SNOWFLAKE_ACCOUNT",   "BZYEXBI-OQ97203"),
    "user":      os.getenv("SNOWFLAKE_USER",       "TWOJ_USER"),       # ← zmień lub ustaw env
    "password":  os.getenv("SNOWFLAKE_PASSWORD",   ""),                 # ← nigdy nie wpisuj tu hasła!
    "database":  "OSLO_CITY_BIKES",
    "schema":    "STAGE",
    "warehouse": os.getenv("SNOWFLAKE_WAREHOUSE",  "COMPUTE_WH"),       # ← sprawdź nazwę w Snowflake
}

TABLE  = "BIKES_STATIONS"
STAGE  = "OSLO_BIKES_STAGE"

# Backfill od kiedy (możesz zmienić na 2019-04 jeśli chcesz pełną historię)
BACKFILL_START = date(2023, 1, 1)

# ── Helpers ─────────────────────────────────────────────────────────────────

def csv_url(year: int, month: int) -> str:
    return f"https://data.urbansharing.com/oslobysykkel.no/trips/v1/{year}/{month:02d}.csv"


def file_exists_on_server(year: int, month: int) -> bool:
    """Sprawdza czy plik CSV dla danego miesiąca już istnieje na serwerze."""
    url = csv_url(year, month)
    try:
        r = requests.head(url, timeout=10)
        return r.status_code == 200
    except requests.RequestException:
        return False


def get_max_date(conn) -> date | None:
    """Zwraca maksymalną datę started_at z tabeli w Snowflake."""
    cur = conn.cursor()
    cur.execute(f"SELECT MAX(started_at) FROM {TABLE}")
    result = cur.fetchone()[0]
    cur.close()
    return result.date() if result else None


def load_month(conn, year: int, month: int) -> int:
    """
    Pobiera CSV z Oslo Bike, uploaduje do stage i robi COPY INTO.
    Zwraca liczbę załadowanych wierszy.
    """
    url = csv_url(year, month)
    print(f"  → Pobieranie: {url}")

    response = requests.get(url, timeout=60)
    response.raise_for_status()

    # Wrzuć plik do Snowflake internal stage
    filename = f"oslo_bikes_{year}_{month:02d}.csv"
    file_obj = io.BytesIO(response.content)

    cur = conn.cursor()

    # Upload do stage
    cur.execute(f"PUT file://{filename} @{STAGE} AUTO_COMPRESS=TRUE OVERWRITE=TRUE",
                file_stream=file_obj)

    # Usuń stare dane z tego miesiąca żeby uniknąć duplikatów
    # (ważne dla bieżącego miesiąca który jest aktualizowany codziennie)
    cur.execute(f"""
        DELETE FROM {TABLE}
        WHERE YEAR(started_at) = {year}
          AND MONTH(started_at) = {month}
    """)
    deleted = cur.rowcount
    if deleted > 0:
        print(f"  🗑 Usunięto {deleted} starych wierszy za {year}-{month:02d}")

    # COPY INTO tabela
    cur.execute(f"""
        COPY INTO {TABLE}
        FROM @{STAGE}/{filename}.gz
        FILE_FORMAT = (
            TYPE = 'CSV'
            FIELD_OPTIONALLY_ENCLOSED_BY = '"'
            SKIP_HEADER = 1
            TIMESTAMP_FORMAT = 'AUTO'
        )
        ON_ERROR = 'CONTINUE'
    """)

    rows = cur.fetchone()[0]
    cur.close()
    print(f"  ✓ Załadowano {rows} wierszy za {year}-{month:02d}")
    return rows


def months_between(start: date, end: date):
    """Generator miesięcy od start do end (włącznie)."""
    current = start.replace(day=1)
    end = end.replace(day=1)
    while current <= end:
        yield current.year, current.month
        current += relativedelta(months=1)


# ── Tryb backfill ────────────────────────────────────────────────────────────

def run_backfill(conn):
    """Ładuje wszystkie miesiące od BACKFILL_START do poprzedniego miesiąca."""
    today = date.today()
    end = (today.replace(day=1) - relativedelta(months=1))  # poprzedni miesiąc

    print(f"\n📦 BACKFILL: {BACKFILL_START.strftime('%Y-%m')} → {end.strftime('%Y-%m')}")

    total = 0
    for year, month in months_between(BACKFILL_START, end):
        if not file_exists_on_server(year, month):
            print(f"  ⚠ Brak pliku dla {year}-{month:02d}, pomijam")
            continue
        try:
            total += load_month(conn, year, month)
        except Exception as e:
            print(f"  ✗ Błąd dla {year}-{month:02d}: {e}")

    print(f"\n✅ Backfill zakończony. Łącznie załadowano: {total} wierszy")


# ── Tryb automatyczny (monthly append) ───────────────────────────────────────

def run_monthly(conn):
    """
    Sprawdza jaki jest MAX(started_at) w tabeli
    i ładuje kolejny miesiąc jeśli plik już istnieje.
    """
    print("\n🔄 TRYB AUTOMATYCZNY")

    max_date = get_max_date(conn)
    if max_date is None:
        print("  ⚠ Tabela jest pusta! Uruchom najpierw --backfill")
        return

    print(f"  Ostatnia data w tabeli: {max_date}")

    today = date.today()
    current_month = today.replace(day=1)
    max_month = max_date.replace(day=1)

    # Jesli MAX jest w biezacym miesiacu → odswież biezacy (daily update)
    # Jesli MAX jest w poprzednim miesiacu → zaladuj nastepny
    if max_month >= current_month:
        year, month = today.year, today.month
        print(f"  Biezacy miesiac — odswiezam: {year}-{month:02d}")
    else:
        next_month = (max_month + relativedelta(months=1))
        year, month = next_month.year, next_month.month
        print(f"  Sprawdzam czy istnieje: {year}-{month:02d}")

    if not file_exists_on_server(year, month):
        print(f"  Plik {year}-{month:02d} jeszcze niedostepny. Sprobuj pozniej.")
        return

    try:
        load_month(conn, year, month)
        print(f"\n✅ Zaladowano {year}-{month:02d}")
    except Exception as e:
        print(f"\n✗ Blad: {e}")


# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Oslo City Bike → Snowflake loader")
    parser.add_argument("--backfill", action="store_true",
                        help="Załaduj dane historyczne od BACKFILL_START")
    args = parser.parse_args()

    print("🔌 Łączenie z Snowflake...")
    conn = snowflake.connector.connect(**SNOWFLAKE_CONFIG)
    print("✓ Połączono\n")

    try:
        if args.backfill:
            run_backfill(conn)
        else:
            run_monthly(conn)
    finally:
        conn.close()
        print("\n🔌 Rozłączono z Snowflake")


if __name__ == "__main__":
    main()
