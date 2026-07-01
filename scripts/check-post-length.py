#!/usr/bin/env python3
"""Count characters in a community post and check against Discord's 2000-char limit."""

import sys

DISCORD_LIMIT = 2000


def count_chars(path: str) -> int:
    with open(path) as f:
        content = f.read()
    return len(content)


def main() -> None:
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <post.md>")
        sys.exit(1)

    path = sys.argv[1]
    count = count_chars(path)
    over = count - DISCORD_LIMIT

    print(f"{path}: {count} chars")
    if over <= 0:
        print(f"  {abs(over)} chars under Discord limit ({DISCORD_LIMIT})")
        sys.exit(0)
    else:
        print(f"  {over} chars OVER Discord limit ({DISCORD_LIMIT})")
        sys.exit(1)


if __name__ == "__main__":
    main()
