#!/usr/bin/env bash

set -Eeuo pipefail

readonly DEFAULT_SOURCE="/media/music"
readonly DEFAULT_DESTINATION="music_crypt:"

usage() {
  cat <<'EOF'
Synchronise une bibliothèque musicale vers un remote rclone chiffré.

Usage:
  sync_music_rclone_crypt.sh [options] [source] [remote:chemin]

Options:
  --dry-run  Simule la synchronisation sans modifier la destination.
  --yes      Confirme le miroir sans demander de validation interactive.
  -h, --help Affiche cette aide.

Valeurs par défaut :
  source       MUSIC_SOURCE_PATH ou /media/music
  destination  RCLONE_DESTINATION ou music_crypt:

Attention : rclone sync crée un miroir. Hors simulation, les fichiers absents
de la source peuvent être supprimés de la destination.
EOF
}

fail() {
  printf 'Erreur : %s\n' "$1" >&2
  exit 1
}

dry_run=false
assume_yes=false

while (($# > 0)); do
  case "$1" in
    --dry-run)
      dry_run=true
      shift
      ;;
    --yes)
      assume_yes=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      fail "option inconnue : $1"
      ;;
    *)
      break
      ;;
  esac
done

(($# <= 2)) || fail "trop d'arguments (consultez --help)"

source_path=${1:-${MUSIC_SOURCE_PATH:-$DEFAULT_SOURCE}}
destination=${2:-${RCLONE_DESTINATION:-$DEFAULT_DESTINATION}}

command -v rclone >/dev/null 2>&1 ||
  fail "rclone est requis. Installez-le depuis https://rclone.org/install/."

[[ $destination == *:* ]] ||
  fail "la destination doit suivre la forme remote:chemin"
remote_name=${destination%%:*}
[[ -n $remote_name ]] || fail "le nom du remote rclone est vide"

[[ -d $source_path ]] ||
  fail "le dossier source '$source_path' est absent ou inaccessible"
clean_source=$(cd -P -- "$source_path" 2>/dev/null && pwd) ||
  fail "impossible de résoudre le dossier source '$source_path'"

case "$clean_source" in
  / | /Applications | /Library | /System | /Users | /Volumes | /bin | /boot | /dev | /etc | /home | /lib | /lib64 | /media | /mnt | /mnt/c | /mnt/wsl | /mnt/wslg | /opt | /proc | /root | /run | /sbin | /srv | /sys | /tmp | /usr | /var)
    fail "le chemin système '$clean_source' ne peut pas être synchronisé"
    ;;
esac

if ! find "$clean_source" -type f -print -quit 2>/dev/null | grep -q .; then
  fail "le dossier source '$clean_source' est vide ; miroir annulé"
fi

if ! find "$clean_source" -type f \( \
  -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.aac' -o \
  -iname '*.flac' -o -iname '*.ogg' -o -iname '*.opus' -o \
  -iname '*.wav' \
\) -print -quit 2>/dev/null | grep -q .; then
  fail "aucun fichier audio pris en charge n'a été trouvé ; miroir annulé"
fi

if ! rclone listremotes | grep -Fxq "${remote_name}:"; then
  fail "le remote '${remote_name}:' n'existe pas. Configurez d'abord un remote crypt avec 'rclone config'."
fi

remote_type=$(
  rclone config redacted "$remote_name" 2>/dev/null |
    sed -n 's/^[[:space:]]*type[[:space:]]*=[[:space:]]*//p' |
    head -n 1
)
[[ $remote_type == crypt ]] ||
  fail "le remote '${remote_name}:' doit être de type crypt"

printf 'Source      : %s\n' "$clean_source"
printf 'Destination : %s\n' "$destination"

if [[ $dry_run == false && $assume_yes == false ]]; then
  [[ -t 0 ]] ||
    fail "une exécution non interactive exige --yes (utilisez d'abord --dry-run)"
  printf '\nCette opération mettra la destination en miroir et pourra y supprimer des fichiers.\n'
  read -r -p "Saisissez SYNCHRONISER pour continuer : " confirmation
  [[ $confirmation == SYNCHRONISER ]] || fail "synchronisation annulée"
fi

rclone_options=(
  --progress
  --stats 3s
  --transfers 2
  --checkers 4
  --tpslimit 5
  --retries 5
  --low-level-retries 10
  --retries-sleep 3s
  --timeout 30m
  --buffer-size 64M
  --fast-list
)

if [[ $dry_run == true ]]; then
  rclone_options+=(--dry-run)
  printf 'Mode        : simulation\n'
fi

rclone sync "$clean_source" "$destination" "${rclone_options[@]}"

if [[ $dry_run == true ]]; then
  printf '\nSimulation terminée : aucune donnée distante n’a été modifiée.\n'
else
  printf '\nSynchronisation terminée avec succès.\n'
fi
