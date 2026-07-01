# make-demo-gif.sh

Create a demo GIF from a screen recording for the README. Works on macOS, Linux, and Windows (MSYS2/WSL).

## Requirements

| OS | Command |
|----|---------|
| macOS | `brew install ffmpeg imagemagick gifsicle` |
| Linux | `sudo apt install ffmpeg imagemagick gifsicle` |
| Windows | `winget install ffmpeg imagemagick gifsicle` or via MSYS2/WSL |

## Usage

```bash
./scripts/make-demo-gif.sh <name> [fps] [width]
```

| Argument | Required | Default | Description                           |
| -------- | -------- | ------- | ------------------------------------- |
| name     | yes      | –       | output filename (without extension)   |
| fps      | no       | 4       | frames per second per clip            |
| width    | no       | 800     | max width in pixels                   |

The script auto-detects the video file (`.mov`, `.mp4`, `.mkv`, `.webm`, `.avi`) and reads `specs.txt`
from the **current working directory**.

## specs.txt format

```
00:05|00:09|Code completion
00:12|00:16|Hover documentation
00:20|00:24|Go to definition
00:28|00:32|Diagnostics
00:36|00:40|Status line
00:44|00:48|Formatter
00:52|00:56|Debugging
01:00|01:04|Outline view
```

Each line creates an animated clip showing that segment with an overlay label.

**Note:** avoid consecutive entries with the same description — the GIF may interpolate frames between them causing visual glitches. If the same feature appears in separate segments, add a brief distinguishing detail to each label.

## Font

The script selects the overlay font based on the detected OS:

| OS      | Font priority                              |
| ------- | ------------------------------------------ |
| macOS   | Helvetica                                  |
| Linux   | DejaVu Sans → Liberation Sans → sans-serif |
| Windows | Arial → sans-serif                         |

## Examples

```bash
# Defaults (4fps, 800px)
./scripts/make-demo-gif.sh features

# Custom
./scripts/make-demo-gif.sh debugging 12 640

# Lower quality for smaller file
./scripts/make-demo-gif.sh completion 8 480
```

## Output

| File                                         | Description                                             |
| -------------------------------------------- | ------------------------------------------------------- |
| `docs/readme-assets/<name>.gif`              | Animated GIF with overlay labels, optimized             |
| `docs/readme-assets/<name>.txt`              | Copy of the `specs.txt` used (feature coverage record)  |

## Workflow

1. Record a screen capture (QuickTime on macOS, OBS/SimpleScreenRecorder on Linux, Xbox Game Bar on Windows)
2. Save the video in a working directory — any common format works (`.mov`, `.mp4`, `.mkv`, `.webm`, `.avi`)
3. Write `specs.txt` in the same directory with timestamps and descriptions
4. Run the script from that directory (pointing at the repo's script path)
5. Adjust timestamps in `specs.txt` and re-run until satisfied — no need to re-record
