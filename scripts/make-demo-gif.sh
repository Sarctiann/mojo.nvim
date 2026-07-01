#!/usr/bin/env bash
# make-demo-gif.sh
#
# Creates a demo GIF from a screen recording. Each entry in specs.txt
# becomes a short animated clip with an overlay description.
#
# Usage:
#   ./scripts/make-demo-gif.sh <name> [--dir <path>] [--fps <n>] [--res <px>]
#
#   <name>       output name (required) — produces docs/readme-assets/<name>.gif
#                and copies specs.txt → docs/readme-assets/<name>.txt
#   --dir <path> directory containing the video and specs.txt (default: .)
#   --fps <n>    frames per second (default: 4)
#   --res <px>   max width in pixels (default: 800)
#
# Example specs.txt:
#   00:05|00:09|Code completion
#   00:12|00:16|Hover documentation
#
# Requires: ffmpeg, magick (ImageMagick 7+)
# Optional: gifsicle

set -euo pipefail

usage() {
	echo "Usage: $0 <name> [--dir <path>] [--fps <n>] [--res <px>]"
	echo ""
	echo "  <name>       output name (required)"
	echo "  --dir <path> directory with video + specs.txt (default: .)"
	echo "  --fps <n>    frames per second (default: 4)"
	echo "  --res <px>   max width in pixels (default: 800)"
	echo ""
	echo "  Auto-detects a video file in the working directory."
	echo "  Outputs to docs/readme-assets/<name>.gif and copies specs.txt."
	exit 1
}

NAME=""
WORK_DIR="."
FPS=4
MAX_WIDTH=800

while [[ $# -gt 0 ]]; do
	case "$1" in
	--dir)
		WORK_DIR="${2:?--dir requires a path}"
		shift 2
		;;
	--fps)
		FPS="${2:?--fps requires a number}"
		if ! [[ "$FPS" =~ ^[0-9]+$ ]]; then
			echo "Error: --fps must be a positive integer"
			exit 1
		fi
		shift 2
		;;
	--res)
		MAX_WIDTH="${2:?--res requires a number}"
		if ! [[ "$MAX_WIDTH" =~ ^[0-9]+$ ]]; then
			echo "Error: --res must be a positive integer"
			exit 1
		fi
		shift 2
		;;
	--help | -h)
		usage
		;;
	-*)
		echo "Error: unknown flag $1"
		usage
		;;
	*)
		if [ -z "$NAME" ]; then
			NAME="$1"
		else
			echo "Error: unexpected argument '$1'"
			usage
		fi
		shift
		;;
	esac
done

if [ -z "$NAME" ]; then
	usage
fi

WORK_DIR="$(cd "$WORK_DIR" && pwd)"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ASSETS_DIR="$REPO_ROOT/docs/readme-assets"

SPECS="$WORK_DIR/specs.txt"
OUTPUT="$ASSETS_DIR/$NAME.gif"

command -v ffmpeg &>/dev/null || {
	echo "Error: install ffmpeg"
	exit 1
}
command -v magick &>/dev/null || {
	echo "Error: install ImageMagick"
	exit 1
}

# Auto-detect video file in working directory
VIDEO_EXTS=("mov" "mp4" "mkv" "webm" "avi")
FOUND_VIDEOS=()
for ext in "${VIDEO_EXTS[@]}"; do
	for f in "$WORK_DIR"/*."$ext"; do
		[ -f "$f" ] && FOUND_VIDEOS+=("$f")
	done
done

if [ "${#FOUND_VIDEOS[@]}" -eq 0 ]; then
	echo "Error: no video file found in $WORK_DIR"
	echo "  Supported formats: ${VIDEO_EXTS[*]}"
	exit 1
elif [ "${#FOUND_VIDEOS[@]}" -gt 1 ]; then
	echo "Error: multiple video files found: ${FOUND_VIDEOS[*]}"
	echo "  Keep only one video file in the directory."
	exit 1
fi
INPUT="${FOUND_VIDEOS[0]}"
echo "Video file: $INPUT"

[ -f "$SPECS" ] || {
	echo "Error: $SPECS not found"
	exit 1
}

# Cross-platform font detection
detect_font() {
	local os
	os="$(uname -s)"

	case "$os" in
	Darwin)
		if [ -f "/System/Library/Fonts/Helvetica.ttc" ]; then
			echo "/System/Library/Fonts/Helvetica.ttc"
		else
			echo "Helvetica"
		fi
		;;
	Linux)
		if magick -list font 2>/dev/null | grep -qi "DejaVu-Sans"; then
			echo "DejaVu-Sans"
		elif magick -list font 2>/dev/null | grep -qi "Liberation-Sans"; then
			echo "Liberation-Sans"
		else
			echo "sans-serif"
		fi
		;;
	MINGW* | MSYS* | CYGWIN*)
		if magick -list font 2>/dev/null | grep -qi "Arial"; then
			echo "Arial"
		else
			echo "sans-serif"
		fi
		;;
	*)
		echo "sans-serif"
		;;
	esac
}

FONT=$(detect_font)
echo "Font: $FONT"

mkdir -p "$ASSETS_DIR"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

VIDEO_DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT" 2>/dev/null)
VIDEO_DUR=${VIDEO_DUR%.*}
echo "Video duration: ${VIDEO_DUR}s"

TEXT_COLOR="white"
TEXT_BG="rgba(0,0,0,0.75)"

ALL_FRAMES=()

echo "Processing clips..."

while IFS='|' read -r START END LABEL || [ -n "$START" ]; do
	START=$(echo "$START" | xargs)
	END=$(echo "$END" | xargs)
	[ -z "$START" ] && continue

	SAFE=$(echo "$LABEL" | tr ' ' '_' | tr -cd '[:alnum:]_')
	CLIP_DIR="$TMPDIR/${SAFE}"
	mkdir -p "$CLIP_DIR"

	echo "  $START-$END → $LABEL"

	S_SEC=$(echo "$START" | awk -F: '{ print ($1*60)+$2 }')
	E_SEC=$(echo "$END" | awk -F: '{ print ($1*60)+$2 }')
	NUM_FRAMES=$(((E_SEC - S_SEC) * FPS))
	if [ "$S_SEC" -ge "$VIDEO_DUR" ]; then
		echo "    (past end of video, skipping)"
		continue
	fi
	if [ "$NUM_FRAMES" -le 0 ]; then
		echo "    (invalid times, skipping)"
		continue
	fi

	ffmpeg -nostdin -y -i "$INPUT" -ss "$START" \
		-vf "fps=$FPS,scale=$MAX_WIDTH:-1:flags=lanczos" \
		-frames:v "$NUM_FRAMES" \
		"$CLIP_DIR/f_%04d.png" 2>/dev/null

	FRAMES=$(ls "$CLIP_DIR"/f_*.png 2>/dev/null | sort)
	COUNT=$(echo "$FRAMES" | wc -l | tr -d ' ')
	[ "$COUNT" -eq 0 ] && {
		echo "    (no frames)"
		continue
	}

	FIRST=$(echo "$FRAMES" | head -1)
	H=$(magick identify -format "%h" "$FIRST")

	BAR_H=$((H / 10))
	BAR_Y=$(((H * 3 / 4) - (BAR_H / 2)))
	PT=$((H / 30))
	TEXT_Y=$(((H / 4) - (PT / 4)))

	for f in $FRAMES; do
		labeled="${f%.png}_l.png"
		magick "$f" \
			-fill "$TEXT_BG" \
			-draw "rectangle 0,${BAR_Y} ${MAX_WIDTH},$((BAR_Y + BAR_H))" \
			-fill "$TEXT_COLOR" \
			-font "$FONT" \
			-pointsize "$PT" \
			-gravity center \
			-annotate "+0+${TEXT_Y}" "$LABEL" \
			"$labeled"
		ALL_FRAMES+=("$labeled")
	done
done <"$SPECS"

TOTAL=${#ALL_FRAMES[@]}
if [ "$TOTAL" -eq 0 ]; then
	echo "Error: no frames extracted"
	exit 1
fi

# Remove old GIF if it exists
[ -f "$OUTPUT" ] && rm "$OUTPUT"

echo "Creating GIF ($TOTAL frames) at ${FPS}fps ${MAX_WIDTH}px..."
DELAY=$((100 / FPS))
CMD=(magick)
for f in "${ALL_FRAMES[@]}"; do
	CMD+=(-delay "$DELAY" "$f")
done
CMD+=(-loop 0 "$OUTPUT")
"${CMD[@]}"

if command -v gifsicle &>/dev/null; then
	gifsicle -O1 --colors 192 "$OUTPUT" -o "$OUTPUT"
fi

cp "$SPECS" "$ASSETS_DIR/$NAME.txt"
echo "Copied specs → $ASSETS_DIR/$NAME.txt"
echo "Done! GIF saved to: $OUTPUT"
