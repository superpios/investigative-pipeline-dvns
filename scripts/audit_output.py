#!/usr/bin/env python3
"""Audit post-pipeline: schema, disclaimer, determinism markers, basic invariants.

Exit 0 if all hard checks pass (or no ranked file = zero leads OK).
Exit 1 only on schema/disclaimer violations when ranked output exists.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REQUIRED_LEAD_FIELDS = {
    "id",
    "title",
    "observed_facts",
    "sources",
    "period",
    "rule_id",
    "why_worth_checking",
    "what_cannot_be_claimed",
    "disclaimer",
    "priority_score",
    "priority_reasons",
    "rank_position",
}

DISCLAIMER_MARKERS = (
    "non dimostra alcun illecito",
    "merita verifica",
)

FORBIDDEN_LABELS = (
    "frode",
    "corruzione",
    "illecito penale",
    "colpevole",
    "spreco accertato",
)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--ranked", type=Path, required=True)
    ap.add_argument("--manifest", type=Path)
    ap.add_argument("--history", type=Path)
    args = ap.parse_args()

    errors: list[str] = []
    warnings: list[str] = []

    if args.manifest and args.manifest.exists():
        man = json.loads(args.manifest.read_text(encoding="utf-8"))
        print(f"[manifest] status={man.get('status')} leads_count={man.get('leads_count')}")
        if man.get("status") not in ("ok", "failed"):
            warnings.append(f"unexpected manifest status: {man.get('status')}")

    if not args.ranked.exists():
        print("[audit] No ranked_leads.json — zero leads or fail-closed. Conservative OK.")
        return 0

    ranked = json.loads(args.ranked.read_text(encoding="utf-8"))
    if not isinstance(ranked, list):
        errors.append("ranked_leads.json is not a list")
        print("AUDIT FAIL:", errors)
        return 1

    print(f"[audit] ranked leads: {len(ranked)}")

    seen_ids: set[str] = set()
    prev_score = float("inf")
    for i, lead in enumerate(ranked):
        missing = REQUIRED_LEAD_FIELDS - set(lead.keys())
        if missing:
            errors.append(f"lead[{i}] missing fields: {sorted(missing)}")

        lid = lead.get("id", "")
        if not lid:
            errors.append(f"lead[{i}] empty id")
        elif lid in seen_ids:
            errors.append(f"duplicate id: {lid}")
        seen_ids.add(lid)

        disc = (lead.get("disclaimer") or "").lower()
        if not any(m in disc for m in DISCLAIMER_MARKERS):
            errors.append(f"lead {lid}: disclaimer missing required markers")

        text_blob = " ".join(
            [
                str(lead.get("title", "")),
                " ".join(lead.get("observed_facts") or []),
                str(lead.get("why_worth_checking", "")),
            ]
        ).lower()
        for bad in FORBIDDEN_LABELS:
            if bad in text_blob:
                errors.append(f"lead {lid}: forbidden evaluative label '{bad}'")

        score = lead.get("priority_score")
        if not isinstance(score, (int, float)) or score < 0 or score > 100:
            errors.append(f"lead {lid}: invalid priority_score {score}")

        rank = lead.get("rank_position")
        if rank != i + 1:
            warnings.append(f"lead {lid}: rank_position={rank} expected {i+1}")

        if isinstance(score, (int, float)) and score > prev_score + 1e-9:
            errors.append(f"ordering broken at {lid}: score {score} > previous {prev_score}")
        prev_score = float(score) if isinstance(score, (int, float)) else prev_score

    if args.history and args.history.exists():
        hist_files = sorted(args.history.glob("run_*.json"))
        print(f"[history] snapshots: {len(hist_files)}")
        for hf in hist_files[-3:]:
            print(f"  - {hf.name}")

    for w in warnings:
        print(f"WARN: {w}")
    if errors:
        for e in errors:
            print(f"ERROR: {e}")
        print("AUDIT: FAIL")
        return 1

    print("AUDIT: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
