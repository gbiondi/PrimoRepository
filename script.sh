#!/usr/bin/env bash
set -euo pipefail

# script.sh - copia tutti i file da una cartella A a una cartella B
# - usa rsync se disponibile (consigliato) altrimenti cp -a
# - preserva permessi, timestamp e link simbolici
# - supporta: --dry-run, --update (solo copia file più recenti), --force, --verbose

usage(){
	cat <<EOF
Usage: $(basename "$0") [OPTIONS] <SOURCE_DIR> <DEST_DIR>

Copia tutti i file (inclusi quelli nascosti) dalla cartella SOURCE_DIR alla
cartella DEST_DIR. Se DEST_DIR non esiste viene chiesta conferma (o usa --force).

Options:
	-n, --dry-run     mostra cosa verrebbe copiato ma non copia (se rsync presente)
	-u, --update      copia solo i file più nuovi dal source al dest
	-f, --force       crea DEST_DIR senza chiedere conferma
	-v, --verbose     output dettagliato
	-h, --help        mostra questo aiuto

Examples:
	# copia ricorsivamente e preserva attributi (con rsync se disponibile):
	./script.sh /path/to/A /path/to/B

	# dry-run con rsync (non farà modifiche):
	./script.sh --dry-run /path/to/A /path/to/B

EOF
}

# parse args
DRY_RUN=0
UPDATE=0
FORCE=0
VERBOSE=0
SRC=""
DEST=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		-n|--dry-run) DRY_RUN=1; shift ;;
		-u|--update) UPDATE=1; shift ;;
		-f|--force) FORCE=1; shift ;;
		-v|--verbose) VERBOSE=1; shift ;;
		-h|--help) usage; exit 0 ;;
		--) shift; break ;;
		-*) echo "Unknown option: $1" >&2; usage; exit 2 ;;
		*)
			if [[ -z "$SRC" ]]; then SRC="$1"; else DEST="$1"; fi
			shift
			;;
	esac
done

if [[ -z "$SRC" || -z "$DEST" ]]; then
	echo "Errore: devi fornire SOURCE_DIR e DEST_DIR" >&2
	usage
	exit 2
fi

if [[ ! -e "$SRC" ]]; then
	echo "Errore: source non esiste: $SRC" >&2
	exit 2
fi

if [[ ! -d "$SRC" ]]; then
	echo "Errore: source non è una directory: $SRC" >&2
	exit 2
fi

if [[ -e "$DEST" && ! -d "$DEST" ]]; then
	echo "Errore: dest esiste e non è una directory: $DEST" >&2
	exit 2
fi

if [[ ! -e "$DEST" ]]; then
	if [[ $FORCE -eq 1 ]]; then
		mkdir -p -- "$DEST"
		[[ $VERBOSE -eq 1 ]] && echo "Created dest: $DEST"
	else
		read -r -p "Dest non esiste. Crearlo? [y/N] " ans
		case "$ans" in
			[Yy]*) mkdir -p -- "$DEST" ;;
			*) echo "Operazione annullata."; exit 1 ;;
		esac
	fi
fi

if [[ $(realpath -- "$SRC") == $(realpath -- "$DEST") ]]; then
	echo "Errore: SOURCE e DEST sono lo stesso percorso" >&2
	exit 2
fi

use_rsync=0
if command -v rsync >/dev/null 2>&1; then
	use_rsync=1
fi

if [[ $use_rsync -eq 1 ]]; then
	RSYNC_OPTS=( -a )
	[[ $DRY_RUN -eq 1 ]] && RSYNC_OPTS+=( --dry-run )
	[[ $UPDATE -eq 1 ]] && RSYNC_OPTS+=( --update )
	[[ $VERBOSE -eq 1 ]] && RSYNC_OPTS+=( -v )

	# copy contents of SRC into DEST (including hidden files) using trailing slash
	echo "Using rsync: ${RSYNC_OPTS[*]} $SRC/ -> $DEST/"
	rsync "${RSYNC_OPTS[@]}" -- "$SRC/" "$DEST/"
else
	# fallback to cp -a. Use `cp -a "SRC/." DEST/` to include hidden files.
	CP_OPTS=( -a )
	[[ $UPDATE -eq 1 ]] && CP_OPTS=( -au )
	if [[ $DRY_RUN -eq 1 ]]; then
		echo "rsync non trovato. Dry-run: mostrerei la copia con cp ${CP_OPTS[*]} '$SRC/.' -> '$DEST/'"
		exit 0
	fi

	if [[ $VERBOSE -eq 1 ]]; then
		echo "Using cp: ${CP_OPTS[*]} '$SRC/.' -> '$DEST/'"
	fi

	# cp can fail on some platforms if source ends with /., but it's the standard way to copy hidden files
	cp "${CP_OPTS[@]}" -- "$SRC/." "$DEST/"
fi

echo "Copia completata da '$SRC' a '$DEST'"

