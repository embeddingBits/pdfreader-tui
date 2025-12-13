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

      gotoPage() {
            local input

            tput cnorm
            echo
            printf "Go to page (1-%d): " "$TOTAL"

            IFS= read -r input </dev/tty

            tput civis

            if [[ "$input" =~ ^[0-9]+$ ]]; then
                  if (( input >= 1 && input <= TOTAL )); then
                        PAGE=$((input - 1))
                  fi
            fi
      }


while true; do
      clear

      chafa --size="$(tput cols)x$(($(tput lines) - 1))" "${PAGES[$PAGE]}"

      printf "\nPage %d/%d — j/k next/prev, q quit\n" "$((PAGE + 1))" "$TOTAL"

      read -rsn1 key </dev/tty
      [[ "$key" == $'\e' ]] && read -rsn2 key </dev/tty

      case "$key" in
            j | '[B')
                  PAGE=$((PAGE + 1))
                  ;;
            k | '[A')
                  PAGE=$((PAGE - 1))
                  ;;
            g) 
                  gotoPage
                  ;;
            q)
                  exit 0
                  ;;
      esac

      ((PAGE < 0)) && PAGE=$((TOTAL - 1))
      ((PAGE >= TOTAL)) && PAGE=0
done
