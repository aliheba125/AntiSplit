#!/usr/bin/env bash

# AntiSplit - Merge split APK files and sign them
# Script by: @termuxvoid

set -e  # Exit on error

# --- Colors (ANSI) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Helper functions ---
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }

# --- Spinner function using gum if available, otherwise fallback ---
spinner() {
    local cmd="$1"
    local msg="$2"

    if command -v gum &>/dev/null; then
        gum spin --spinner dot --title "$msg" -- bash -c "$cmd"
    else
        echo -n "$msg ... "
        if eval "$cmd" >/dev/null 2>&1; then
            echo "done."
        else
            echo "failed."
            return 1
        fi
    fi
}

# --- Check dependencies ---
command -v apkeditor >/dev/null 2>&1 || error "apkeditor not found in PATH."
command -v apksigner >/dev/null 2>&1 || error "apksigner not found in PATH."

# --- Header with figlet (if installed) ---
if command -v figlet &>/dev/null; then
    figlet -f slant "AntiSplit"
else
    echo "AntiSplit"
fi

echo -e "${CYAN}\tAPK Split Merger auto Signer${NC}"
echo -e "${CYAN}\t\t\t\t@termuxvoid${NC}"
echo

# --- Input handling ---
if [ $# -eq 0 ]; then
    echo "Usage: $0 <input.apks|apkm|xapk>"
    exit 1
fi

INPUT="$(realpath "$1")"
INPUT_DIR="$(dirname "$INPUT")"
BASE_NAME="$(basename "$INPUT" .${INPUT##*.})"

OUTPUT="$INPUT_DIR/$BASE_NAME.apk"
SIGNED="$INPUT_DIR/${BASE_NAME}_signed.apk"

info "Input: $INPUT"
info "Output: $SIGNED"

if [ ! -f "$INPUT" ]; then
    error "File not found: $INPUT"
fi

# --- Keystore location (relative to script) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYSTORE="$SCRIPT_DIR/key/antisplit.keystore"

if [ ! -f "$KEYSTORE" ]; then
    error "Keystore not found: $KEYSTORE"
fi

# --- Merge step ---
info "Merging split files..."
spinner "apkeditor m -i \"$INPUT\" -o \"$OUTPUT\"" "Merging APK splits" || error "Merge failed"

# --- Signing step ---
info "Signing APK..."
spinner "apksigner sign --ks \"$KEYSTORE\" --ks-pass 'pass:password' --ks-key-alias 'antisplit' --key-pass 'pass:password' --out \"$SIGNED\" \"$OUTPUT\"" "Signing APK" || error "Signing failed"

# --- Cleanup ---
rm -f "$OUTPUT"
if [ -f "${SIGNED}.idsig" ]; then
    rm -f "${SIGNED}.idsig"
fi

success "All done! Signed APK: $SIGNED"
