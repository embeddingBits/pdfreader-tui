#!/usr/bin/env bash
set -euo pipefail

PDF="$1"

[[ -f "$PDF" ]] || { echo "Usage: pdfchafa <file.pdf>"; exit 1; }

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"; tput cnorm' EXIT
tput civis

pdftoppm -png -r 150 "$PDF" "$TMPDIR/page"

TEXTFILE="$TMPDIR/text.txt"
pdftotext "$PDF" "$TEXTFILE"

mapfile -t PAGES < <(ls "$TMPDIR"/page-*.png | sort -V)

PAGE=0
TOTAL=${#PAGES[@]}

      searchPage() {
            local query matches page

            tput cnorm
            echo
            printf "Search: "
            IFS= read -r query </dev/tty
            tput civis

            [[ -z "$query" ]] && return

            # Find matching pages
            matches=$(grep -ni --color=never "$query" "$TEXTFILE" | cut -d: -f1)

            [[ -z "$matches" ]] && return

            # Convert line numbers to page numbers
            pages=$(awk -v RS=$'\f' -v q="$query" '
            {
                  if (tolower($0) ~ tolower(q))
                        print NR
                  }
            ' "$TEXTFILE")

            mapfile -t pages <<<"$pages"

            if (( ${#pages[@]} == 1 )); then
                  PAGE=$((pages[0] - 1))
                  return
            fi

            # Multiple matches → choose
            selection=$(printf "%s\n" "${pages[@]}" | gum choose --header="Select page")

            [[ -n "$selection" ]] && PAGE=$((selection - 1))
      }

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
            /)
                  searchPage
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
