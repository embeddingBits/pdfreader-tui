#!/usr/bin/env bash
set -euo pipefail

PDF="$1"

[[ -f "$PDF" ]] || { echo "Usage: pdfchafa <file.pdf>"; exit 1; }

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"; tput cnorm' EXIT
tput civis

pdftoppm -png -r 150 "$PDF" "$TMPDIR/page"

mapfile -t PAGES < <(ls "$TMPDIR"/page-*.png | sort -V)

PAGE=0
TOTAL=${#PAGES[@]}

while true; do
    clear

    TERM_W=$(tput cols)
    TERM_H=$(tput lines)

    # Leave space for footer
    TERM_H=$((TERM_H - 2))

    # Render size (adjust if needed)
    IMG_W=$((TERM_W * 70 / 100))
    IMG_H=$((TERM_H * 80 / 100))

    # Center offsets
    OFFSET_X=$(( (TERM_W - IMG_W) / 2 ))
    OFFSET_Y=$(( (TERM_H - IMG_H) / 2 ))

    # Move cursor to center
    tput cup "$OFFSET_Y" "$OFFSET_X"

    chafa --size="${IMG_W}x${IMG_H}" "${PAGES[$PAGE]}"

    # Footer (centered)
    tput cup "$((TERM_H + 1))" "$(( (TERM_W - 35) / 2 ))"
    printf "Page %d/%d — j/k next/prev, q quit" "$((PAGE + 1))" "$TOTAL"

    read -rsn1 key </dev/tty
    [[ "$key" == $'\e' ]] && read -rsn2 key </dev/tty

    case "$key" in
        j | '[B')
            PAGE=$((PAGE + 1))
            ;;
        k | '[A')
            PAGE=$((PAGE - 1))
            ;;
        q)
            exit 0
            ;;
    esac

    ((PAGE < 0)) && PAGE=$((TOTAL - 1))
    ((PAGE >= TOTAL)) && PAGE=0
done

