#!/usr/bin/env bash
#
# Runs the coverage-instrumented banking binary through a sequence of
# small, targeted input fixtures (tests/coverage_fixtures/*.txt) plus
# two filesystem "tamper" steps, instead of a single monolithic input
# file. This is necessary because EOF permanently ends stdin for a
# process: distinct EOF-handling branches (closed input at the main
# menu vs. mid-login vs. mid-transfer, etc.) can only be exercised one
# at a time, each in its own process invocation. gcov accumulates
# .gcda coverage counts additively across multiple runs of the same
# instrumented binary, so running many short passes back-to-back
# against one binary yields a single merged coverage report.
#
# Usage: run_coverage_passes.sh <path-to-coverage-binary>

set -euo pipefail

BIN="$1"
FIXTURES_DIR="tests/coverage_fixtures"
LOG_DIR="build/coverage/pass_logs"

mkdir -p "$LOG_DIR"
rm -rf database
mkdir -p database

run_pass() {
    local name="$1"
    "$BIN" < "$FIXTURES_DIR/$name" > "$LOG_DIR/$name.out" 2>&1 || true
}

# 1. Comprehensive walkthrough: registration edge cases, login,
#    transfers, history, integrity, credential changes, deposits,
#    admin panel, lockouts, frozen accounts.
run_pass 01_main.txt

# 2-8. EOF ("input stream closed") branches at the main menu, and at
#      each prompt of login/registration. Each must be its own
#      process since EOF is permanent for the life of the process.
run_pass 02_eof_main.txt
run_pass 03_eof_login_user.txt
run_pass 04_eof_login_pass.txt
run_pass 05_eof_login_pin.txt
run_pass 06_eof_reg_user.txt
run_pass 07_eof_reg_pass.txt
run_pass 08_eof_reg_pin.txt

# 9-10. A fresh user with no transaction history yet (covers the
#       "No transactions found" branches), then one transaction
#       written for later tampering.
run_pass 09_freshuser_zero_history.txt
run_pass 10_freshuser_write_tx.txt

# 11-18. EOF branches inside the dashboard: change-credentials (each
#        of its 4 prompts), deposit, transfer (both prompts), and the
#        dashboard menu itself.
run_pass 11_eof_chpw_curpass.txt
run_pass 12_eof_chpw_curpin.txt
run_pass 13_eof_chpw_newpass.txt
run_pass 14_eof_chpw_newpin.txt
run_pass 15_eof_deposit_amt.txt
run_pass 16_eof_transfer_recv.txt
run_pass 17_eof_transfer_amt.txt
run_pass 18_eof_dashboard.txt

# 19-21. Remaining validation edge cases: overlong input lines (drain
#        loop), non-digit PIN, invalid-character username, and
#        malformed/too-short UPI IDs.
run_pass 19_account_edgecases.txt
run_pass 20_reg_edgecases.txt
run_pass 21_tx_badformats.txt

# 22-24. EOF branches inside the admin panel.
run_pass 22_eof_admin_menu.txt
run_pass 23_eof_admin_freeze.txt
run_pass 24_eof_admin_clearlock.txt

# 25. Tamper the transaction written in pass 10 so its stored hash no
#     longer matches its recomputed hash, then verify -> exercises
#     integrity.c's "[TAMPERED]" branch.
python3 "$FIXTURES_DIR/tamper_last_transaction.py" amount
run_pass 25_verify_tampered.txt

# 26. Corrupt the same record's encrypted payload so it can no longer
#     be AES-decrypted, then view history -> exercises history.c's
#     "[DECRYPTION ERROR]" branch.
python3 "$FIXTURES_DIR/tamper_last_transaction.py" hex
run_pass 26_history_decrypt_error.txt

echo "All coverage passes complete. Per-pass output in $LOG_DIR/."
