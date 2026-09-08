"""
Oslo City Bike — Realtime station status loader (GBFS)

Pobiera aktualną dostępność rowerów/miejsc dla wszystkich stacji
(station_status.json z GBFS) i dopisuje snapshot do Snowflake.

Uruchamiane codziennie (np. przez GitHub Actions cron) — każdy run
dopisuje nowy wiersz per stacja, budując historię dostępności w czasie.

Użycie:
  python load_realtime_status.py
"""
import snowflake.connector
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend
from datetime import datetime, timezone
import os
import sys
import io
import csv
import requests

CLIENT_IDENTIFIER = "ania-oslobikes-portfolio"
STATUS_URL = "https://gbfs.urbansharing.com/oslobysykkel.no/station_status.json"

private_key_str = os.getenv("SNOWFLAKE_PRIVATE_KEY")
private_key = serialization.load_pem_private_key(
    private_key_str.encode(),
    password=None,
    backend=default_backend()
)
private_key_bytes = private_key.private_bytes(
    encoding=serialization.Encoding.DER,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption()
)

SNOWFLAKE_CONFIG = {
    "account":   os.getenv("SNOWFLAKE_ACCOUNT", "BZYEXBI-OQ97203"),
    "user":      os.getenv("SNOWFLAKE_USER",    "dbt_automation"),
    "private_key": private_key_bytes,
    "database":  "OSLO_CITY_BIKES",
    "schema":    "STAGE",
    "warehouse": os.getenv("SNOWFLAKE_WAREHOUSE", "COMPUTE_WH"),
}

STAGE = "OSLO_REALTIME_STAGE"
TABLE = "STATION_STATUS_SNAPSHOTS"

# ── Helpers ─────────────────────────────────────────────────────────────────

def fetch_station_status() -> list[dict]:
    """Pobiera aktualny stan wszystkich stacji z GBFS."""
    headers = {"Client-Identifier": CLIENT_IDENTIFIER}
    response = requests.get(STATUS_URL, headers=headers, timeout=30)
    response.raise_for_status()
    payload = response.json()
    return payload["data"]["stations"]


def stations_to_csv_bytes(stations: list[dict], snapshot_at: datetime) -> io.BytesIO:
    """Konwertuje listę stacji (JSON) do CSV w pamięci, gotowego do PUT."""
    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow([
        "station_id", "num_bikes_available", "num_docks_available",
        "is_installed", "is_renting", "is_returning",
        "last_reported", "snapshot_at",
    ])
    for s in stations:
        last_reported = datetime.fromtimestamp(s["last_reported"], tz=timezone.utc)
        writer.writerow([
            s["station_id"],
            s["num_bikes_available"],
            s["num_docks_available"],
            bool(s["is_installed"]),
            bool(s["is_renting"]),
            bool(s["is_returning"]),
            last_reported.strftime("%Y-%m-%d %H:%M:%S"),
            snapshot_at.strftime("%Y-%m-%d %H:%M:%S"),
        ])
    return io.BytesIO(buffer.getvalue().encode("utf-8"))


def load_snapshot(conn) -> int:
    """Pobiera aktualny stan stacji i dopisuje go do Snowflake. Zwraca liczbę wierszy."""
    snapshot_at = datetime.now(timezone.utc)
    print(f"  → Pobieranie danych z: {STATUS_URL}")

    stations = fetch_station_status()
    print(f"  → Pobrano dane dla {len(stations)} stacji")

    file_obj = stations_to_csv_bytes(stations, snapshot_at)
    filename = f"station_status_{snapshot_at.strftime('%Y%m%dT%H%M%S')}.csv"

    cur = conn.cursor()

    cur.execute(f"PUT file://{filename} @{STAGE} AUTO_COMPRESS=TRUE OVERWRITE=TRUE",
                file_stream=file_obj)

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
    print(f"  ✓ Zapisano snapshot: {rows} wierszy ({snapshot_at.isoformat()})")
    return rows


# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    print("🔌 Łączenie z Snowflake...")
    conn = snowflake.connector.connect(**SNOWFLAKE_CONFIG)
    print("✓ Połączono\n")

    print("🔄 REALTIME SNAPSHOT")
    try:
        load_snapshot(conn)
        print("\n✅ Zakonczono")
    except Exception as e:
        print(f"\n✗ Blad: {e}")
        conn.close()
        sys.exit(1)
    finally:
        conn.close()
        print("\n🔌 Rozłączono z Snowflake")


if __name__ == "__main__":
    main()
