#!/bin/bash
# Fully automated archive and signing script for Zero Trust logs

set -e

DATA_DIR="$(dirname "$0")"
USER_DB="$DATA_DIR/user_database.enc"
AUDIT_LOG="$DATA_DIR/security_audit.txt"
ARCHIVE_DIR="$DATA_DIR/archives"
GPG_KEY="jasonnorman66994@gmail.com"

mkdir -p "$ARCHIVE_DIR"
ARCHIVE_NAME="$ARCHIVE_DIR/audit-$(date +%F).tar.gz"
SIG_NAME="$ARCHIVE_DIR/audit-$(date +%F).tar.gz.sig"

# Logging
{
  echo "[LOG] Creating archive: $ARCHIVE_NAME"
  tar czf "$ARCHIVE_NAME" "$AUDIT_LOG" "$USER_DB" && echo "[LOG] Archive created successfully." || { echo "[ERROR] Archive creation failed."; exit 1; }
  echo "[LOG] Signing archive: $ARCHIVE_NAME"
  gpg --yes --batch --local-user "$GPG_KEY" --output "$SIG_NAME" --sign "$ARCHIVE_NAME" && echo "[LOG] Archive signed successfully." || { echo "[ERROR] GPG signing failed."; exit 1; }
  echo "[LOG] Archive and digital signature created."
  # Send email notification using Python
  python "$DATA_DIR/test-email.py"
} >> "$AUDIT_LOG"

echo "Archive and signature process complete."
