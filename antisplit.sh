#!/usr/bin/env bash

# AntiSplit - Merge split APK files and sign them
# Script by: @a1002a

set -e  # Exit on error

# --- Version ---
ANTISPLIT_VERSION="1.1.0"

# --- Colors (ANSI) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# --- Helper functions using gum for spinners and colored messages ---
info() {
    gum style --foreground 39 "● $1"
}

success() {
    gum style --foreground 82 "✓ $1"
}

error() {
    gum style --foreground 196 "✗ $1" >&2
    exit 1
}

# --- Header with ANSI colors ---
show_header() {
    figlet -f slant "AntiSplit"
    echo -e "${GREEN}       APK Split Merger auto Signer${NC}"
    echo -e "${GREEN}                        @a1002a${NC}"
    echo
}

# --- Help with ANSI colors ---
show_help() {
    echo -e "${MAGENTA}AntiSplit v$ANTISPLIT_VERSION - Merge split APK files and sign them${NC}"
    echo
    echo -e "${GRAY}Usage:${NC}"
    echo "  antisplit [FILE]"
    echo "  antisplit -h | --help | h | help"
    echo "  antisplit -v | --version | v | version"
    echo
    echo -e "${GRAY}If no FILE is provided, an interactive input (using gum) will be used.${NC}"
    echo
    echo -e "${GRAY}FILE can be a split APK (.apks, .apkm, .xapk). The signed APK will be created${NC}"
    echo -e "${GRAY}in the same directory with '_signed.apk' suffix.${NC}"
    echo
    echo -e "${GRAY}Options:${NC}"
    echo -e "  ${CYAN}-h, --help, h, help${NC}   Show this help message."
    echo -e "  ${CYAN}-v, --version, v, version${NC}   Show version information."
    exit 0
}

# --- Version function ---
show_version() {
    echo -e "${MAGENTA}AntiSplit v$ANTISPLIT_VERSION${NC}"
    exit 0
}

# --- Validate input file extension ---
validate_input() {
    local file="$1"
    local ext="${file##*.}"
    if [[ "$ext" != "apks" && "$ext" != "apkm" && "$ext" != "xapk" ]]; then
        error "Invalid file type. Please provide a .apks, .apkm, or .xapk file."
    fi
}

# --- Main ---
show_header

# --- Argument parsing ---
if [ $# -eq 0 ]; then
    # Interactive mode: prompt for file path
    INPUT_FILE=$(gum input --placeholder "/path/to/file.apks" --prompt ">>> ")
    if [ -z "$INPUT_FILE" ]; then
        gum style --foreground 196 "No input provided. Exiting."
        exit 0
    fi
    # Check for "exit" command
    if [[ "$INPUT_FILE" == "exit" ]]; then
        echo "Exiting."
        exit 0
    fi
    validate_input "$INPUT_FILE"
elif [ $# -eq 1 ]; then
    case "$1" in
        -h|--help|h|help)
            show_help
            ;;
        -v|--version|v|version)
            show_version
            ;;
        *)
            INPUT_FILE="$1"
            # Check if input is "exit" (useful for scripting, though unlikely)
            if [[ "$INPUT_FILE" == "exit" ]]; then
                echo "Exiting."
                exit 0
            fi
            validate_input "$INPUT_FILE"
            ;;
    esac
else
    show_help
fi

# --- Process the file ---
INPUT="$(realpath "$INPUT_FILE")"
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
gum spin --spinner dot --title "Merging APK splits" -- apkeditor m -i "$INPUT" -o "$OUTPUT" || error "Merge failed"

# --- Signing step ---
info "Signing APK..."
gum spin --spinner dot --title "Signing APK" -- apksigner sign --ks "$KEYSTORE" --ks-pass 'pass:password' --ks-key-alias 'antisplit' --key-pass 'pass:password' --out "$SIGNED" "$OUTPUT" || error "Signing failed"

# --- Cleanup ---
rm -f "$OUTPUT"
[ -f "${SIGNED}.idsig" ] && rm -f "${SIGNED}.idsig"

success "All done! Signed APK: $SIGNED"
