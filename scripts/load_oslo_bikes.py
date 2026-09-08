def run_monthly(conn):
    """
    Sprawdza jaki jest MAX(started_at) w tabeli i ładuje WSZYSTKIE
    zaległe miesiące aż do bieżącego (jeśli pliki już istnieją).
    Dzięki pętli, jedno uruchomienie dogania cały backlog zamiast
    ładować tylko jeden miesiąc na tydzień.
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

    # Ustal od którego miesiąca zaczynamy nadganiać
    if max_month >= current_month:
        # Ostatni załadowany miesiąc to już bieżący → tylko odśwież go
        start_month = current_month
    else:
        start_month = max_month + relativedelta(months=1)

    loaded_any = False
    year, month = start_month.year, start_month.month

    while True:
        target = date(year, month, 1)

        if not file_exists_on_server(year, month):
            print(f"  Plik {year}-{month:02d} jeszcze niedostepny. Koniec pętli.")
            break

        print(f"  Ladowanie: {year}-{month:02d}")
        try:
            load_month(conn, year, month)
            loaded_any = True
        except Exception as e:
            print(f"\n✗ Blad przy {year}-{month:02d}: {e}")
            sys.exit(1)  # FIX: bez tego GitHub Actions pokazuje "sukces" mimo błędu

        # Jeśli właśnie załadowany miesiąc to bieżący miesiąc → koniec
        # (bieżący miesiąc będzie odświeżany co tydzień, nie idziemy dalej w przyszłość)
        if target >= current_month:
            break

        next_month = target + relativedelta(months=1)
        year, month = next_month.year, next_month.month

    if loaded_any:
        print(f"\n✅ Zakonczono ladowanie zaleglych miesiecy")
    else:
        print(f"\nℹ Brak nowych danych do zaladowania")
