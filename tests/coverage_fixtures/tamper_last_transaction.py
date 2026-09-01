#!/usr/bin/env python3
"""
Corrupts the most recently written transaction record in
database/transactions.dat so that the next coverage pass can
exercise the integrity "[TAMPERED]" branch and the history
"[DECRYPTION ERROR]" branch.

Usage: tamper_last_transaction.py <amount|hex>
  amount - rewrite the amount field so the recomputed hash no
           longer matches the stored hash (integrity.c TAMPERED path)
  hex    - corrupt the encryptedData field so AES decryption fails
           (history.c DECRYPTION ERROR path)
"""
import sys

PATH = "database/transactions.dat"
mode = sys.argv[1] if len(sys.argv) > 1 else "amount"

with open(PATH) as f:
    lines = f.readlines()

parts = lines[-1].rstrip("\n").split("|")
if mode == "amount":
    parts[2] = "999.00"
elif mode == "hex":
    parts[4] = "zz"
else:
    raise SystemExit(f"unknown mode: {mode}")

lines[-1] = "|".join(parts) + "\n"

with open(PATH, "w") as f:
    f.writelines(lines)
