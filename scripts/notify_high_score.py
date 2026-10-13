#!/usr/bin/env python3
"""Notifica piste ad alto score."""
from __future__ import annotations
import argparse
import json
from pathlib import Path

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("ranked_json", type=Path)
    parser.add_argument("--threshold", type=float, default=15.0)
    parser.add_argument("--output", type=Path, default=Path("high_score_alert.txt"))
    args = parser.parse_args()

    leads = json.loads(args.ranked_json.read_text(encoding="utf-8"))
    high = [L for L in leads if (L.get("priority_score") or 0) >= args.threshold]

    lines = [f"Piste con score >= {args.threshold}: {len(high)}", ""]
    for L in high:
        lines.append(f"#{L.get('rank_position')} score={L.get('priority_score')} {L.get('id')}")
        lines.append(f"  {L.get('title')}")
        lines.append("")

    text = "\n".join(lines)
    args.output.write_text(text, encoding="utf-8")
    print(text)

if __name__ == "__main__":
    main()
