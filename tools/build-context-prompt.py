#!/usr/bin/env python3
"""Build a deterministic, non-repeating Nix source context-stress prompt."""

from __future__ import annotations

import argparse
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--target-bytes", required=True, type=int)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--nixpkgs-modules", required=True, type=Path)
    args = parser.parse_args()

    repository = Path(__file__).resolve().parents[1]
    repository_files = sorted(repository.glob("system/*.nix")) + sorted(repository.glob("users/yejashi/*.nix"))
    module_files = sorted(
        path
        for path in args.nixpkgs_modules.rglob("*.nix")
        if 500 <= path.stat().st_size <= 12_000
    )

    header = """Repository and NixOS module context follows. Each source file appears only once.

Task: review how this workstation configuration composes NixOS and Home Manager
modules. Identify three concrete maintainability or correctness risks, explain
the relevant module/option patterns using specific supplied files, and propose
one small local-AI-related configuration improvement. Do not invent files or
options. End with a prioritized verification checklist.
"""
    footer = "\nEnd of supplied source. Now perform the requested analysis.\n"
    sections = [header]
    current_bytes = len((header + footer).encode())

    for path in repository_files + module_files:
        if current_bytes >= args.target_bytes:
            break
        text = path.read_text(errors="replace")
        try:
            label = path.relative_to(repository)
        except ValueError:
            label = Path("nixpkgs") / path.relative_to(args.nixpkgs_modules)
        section = f"\n--- FILE: {label} ---\n{text}\n"
        section_bytes = len(section.encode())
        remaining = args.target_bytes - current_bytes
        if section_bytes <= remaining + 1024:
            sections.append(section)
            current_bytes += section_bytes

    sections.append(footer)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("".join(sections))
    print(f"wrote {args.output}: {args.output.stat().st_size} bytes, {len(sections) - 2} unique source files")


if __name__ == "__main__":
    main()
