#!/usr/bin/env python3
# json-to-csv: Convierte un archivo JSON (array de objetos) a CSV.
# Uso: ./json-to-csv.py <entrada.json> [salida.csv]
#   Sin salida → escribe a stdout.
# Deps: python3 (stdlib)

import csv
import json
import sys
from pathlib import Path


def flatten_keys(rows: list[dict]) -> list[str]:
    """Recoge todas las keys de todas las filas, preservando orden de aparición."""
    seen: list[str] = []
    seen_set: set[str] = set()
    for row in rows:
        for k in row.keys():
            if k not in seen_set:
                seen.append(k)
                seen_set.add(k)
    return seen


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print("Uso: json-to-csv.py <entrada.json> [salida.csv]", file=sys.stderr)
        return 0 if len(sys.argv) >= 2 else 2

    src = Path(sys.argv[1])
    if not src.is_file():
        print(f"✗ No existe: {src}", file=sys.stderr)
        return 1

    data = json.loads(src.read_text(encoding="utf-8"))

    if not isinstance(data, list):
        print("✗ El JSON debe ser un array de objetos", file=sys.stderr)
        return 1

    if not data:
        print("→ Array vacío, nada que convertir", file=sys.stderr)
        return 0

    if not all(isinstance(r, dict) for r in data):
        print("✗ Todos los elementos deben ser objetos", file=sys.stderr)
        return 1

    headers = flatten_keys(data)

    # Salida: archivo o stdout.
    if len(sys.argv) >= 3:
        out_fh = open(sys.argv[2], "w", encoding="utf-8", newline="")
        close = True
    else:
        out_fh = sys.stdout
        close = False

    try:
        w = csv.DictWriter(out_fh, fieldnames=headers, extrasaction="ignore")
        w.writeheader()
        for row in data:
            w.writerow(row)
    finally:
        if close:
            out_fh.close()

    if close:
        print(f"✓ {len(data)} filas → {sys.argv[2]}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
