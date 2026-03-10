#!/bin/bash
# Zero Trust Policy Script - Regenerated
# This script demonstrates secure intake, admin search, audit, archiving, and digital signing.

set -e

DATA_DIR="$(dirname "$0")"
USER_DB="$DATA_DIR/user_database.enc"
AUDIT_LOG="$DATA_DIR/security_audit.txt"
CSV_EXPORT="$DATA_DIR/user_database.csv"
ARCHIVE_DIR="$DATA_DIR/archives"
GPG_KEY="jasonnorman66994@gmail.com"

mkdir -p "$ARCHIVE_DIR"

echo "Zero Trust Policy Script"
echo "-------------------------"
echo "1. Secure Intake"
echo "2. Admin Search"
echo "3. Audit Log"
echo "4. Archive & Sign"
echo "5. Exit"
read -p "Select an option: " opt

case $opt in
  1)
    read -p "Enter user name: " uname
    read -p "Enter department: " dept
    echo "$uname,$dept,$(date)" | openssl enc -aes-256-cbc -a -salt -pbkdf2 -pass pass:SuperSecret >> "$USER_DB"
    echo "[INTAKE] $uname from $dept at $(date)" >> "$AUDIT_LOG"
    echo "User intake complete."
    ;;
  2)
    read -p "Admin password: " apw
    if [[ "$apw" != "adminpass" ]]; then echo "Unauthorized."; exit 1; fi
    echo "Decrypted user database:"
    openssl enc -d -aes-256-cbc -a -pbkdf2 -in "$USER_DB" -pass pass:SuperSecret
    echo "[ADMIN SEARCH] Accessed at $(date)" >> "$AUDIT_LOG"
    ;;
  3)
    echo "Audit log:"
    cat "$AUDIT_LOG"
    ;;
  4)
    ARCHIVE_NAME="$ARCHIVE_DIR/audit-$(date +%F).tar.gz"
    SIG_NAME="$ARCHIVE_DIR/audit-$(date +%F).tar.gz.sig"
    echo "[LOG] Creating archive: $ARCHIVE_NAME" >> "$AUDIT_LOG"
    tar czf "$ARCHIVE_NAME" "$AUDIT_LOG" "$USER_DB" && echo "[LOG] Archive created successfully." >> "$AUDIT_LOG" || { echo "[ERROR] Archive creation failed." >> "$AUDIT_LOG"; exit 1; }
    echo "[LOG] Signing archive: $ARCHIVE_NAME" >> "$AUDIT_LOG"
    gpg --yes --batch --local-user "$GPG_KEY" --output "$SIG_NAME" --sign "$ARCHIVE_NAME" && echo "[LOG] Archive signed successfully." >> "$AUDIT_LOG" || { echo "[ERROR] GPG signing failed." >> "$AUDIT_LOG"; exit 1; }
    echo "Archive and digital signature created."
    ;;
  5)
    echo "Exiting."
    exit 0
    ;;
  *)
    echo "Invalid option."
    ;;
esac
