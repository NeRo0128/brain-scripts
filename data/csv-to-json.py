#!/usr/bin/env python3
# csv-to-json: Convierte un archivo CSV a JSON.
# Uso: ./csv-to-json.py <entrada.csv> [salida.json]
#   Sin salida → escribe a stdout.
# Deps: python3 (stdlib)

import csv
import json
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print("Uso: csv-to-json.py <entrada.csv> [salida.json]", file=sys.stderr)
        print("  Sin argumento de salida, escribe a stdout.", file=sys.stderr)
        return 0 if len(sys.argv) >= 2 else 2

    src = Path(sys.argv[1])
    if not src.is_file():
        print(f"✗ No existe: {src}", file=sys.stderr)
        return 1

    # utf-8-sig maneja BOM (Excel, etc.)
    with src.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        rows = [dict(r) for r in reader]

    out_json = json.dumps(rows, indent=2, ensure_ascii=False)

    if len(sys.argv) >= 3:
        Path(sys.argv[2]).write_text(out_json + "\n", encoding="utf-8")
        print(f"✓ {len(rows)} filas → {sys.argv[2]}", file=sys.stderr)
    else:
        print(out_json)

    return 0


if __name__ == "__main__":
    sys.exit(main())
