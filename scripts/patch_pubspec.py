#!/usr/bin/env python3
import sys
from pathlib import Path

DEPENDENCIES = [
    ("shared", ["path: ../../packages/shared"]),
    ("data", ["path: ../../packages/data"]),
    ("firebase_core", ["^3.3.0"]),
    ("cloud_firestore", ["^5.2.1"]),
    ("firebase_auth", ["^5.1.2"]),
    ("flutter_map", ["^8.2.2"]),
    ("latlong2", ["^0.9.1"]),
    ("geolocator", ["^13.0.2"]),
    ("flutter_background_service", ["^5.1.0"]),
    ("flutter_background_service_android", ["^6.1.0"]),
    ("shared_preferences", ["^2.3.2"]),
]


def find_block(lines, key):
    key_line = None
    for i, line in enumerate(lines):
        if line.strip() == f"{key}:":
            key_line = i
            break
    if key_line is None:
        return None, None

    end = len(lines)
    for i in range(key_line + 1, len(lines)):
        if lines[i] and not lines[i].startswith(" ") and lines[i].rstrip().endswith(":"):
            end = i
            break
    return key_line, end


def has_dep(lines, name):
    return any(line.startswith(f"  {name}:") or line.startswith(f"  {name} ") for line in lines)


def insert_dep(lines, name, extra_lines, block_end):
    if extra_lines and len(extra_lines) == 1 and extra_lines[0].strip().startswith("^"):
        entry = [f"  {name}: {extra_lines[0].strip()}"]
    else:
        entry = [f"  {name}:"]
        entry += [f"  {line}" for line in extra_lines]
    lines[block_end:block_end] = entry + [""]


def main():
    if len(sys.argv) < 2:
        raise SystemExit("Usage: patch_pubspec.py <pubspec.yaml>")

    path = Path(sys.argv[1])
    lines = path.read_text().splitlines()

    dep_start, dep_end = find_block(lines, "dependencies")
    if dep_start is None:
        lines.append("")
        lines.append("dependencies:")
        dep_start = len(lines) - 1
        dep_end = len(lines)

    for name, extra in DEPENDENCIES:
        if has_dep(lines[dep_start:dep_end], name):
            continue
        insert_dep(lines, name, extra, dep_end)
        dep_end += len(extra) + 2

    path.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
