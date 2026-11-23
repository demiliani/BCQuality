"""Score a feature-design report against one experimental fixture.

Usage:
    python tools/score_feature_design.py <case-id> <report.json> [--root <bcquality root>]

Checks, in order: schema validity, reference integrity (every cited path exists
and every path a design element uses is listed in `knowledge`), then the
fixture's expectations. Prints one line per check and exits 1 when any check
fails. Requires jsonschema. Does not repair the report.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

from jsonschema import Draft7Validator


def norm(text: str) -> str:
    return " ".join(text.lower().replace('"', "").split())


def norm_target(text: str) -> str:
    """Object name without annotations: '"Billing Line" (Subscription Billing)' -> 'billing line'."""
    return norm(re.sub(r"\([^)]*\)", "", text))


def design_paths(design: dict) -> set[str]:
    paths: set[str] = set()
    for section in ("objects", "data-flow", "subscriptions", "lifecycle", "tests"):
        for element in design.get(section, []):
            paths.update(element.get("knowledge", []))
    return paths


def score(case: dict, report: dict, root: Path) -> list[tuple[bool, str]]:
    results: list[tuple[bool, str]] = []
    schema = json.loads((root / "schemas/feature-design-report.schema.json").read_text(encoding="utf-8"))
    schema_errors = [e.message for e in Draft7Validator(schema).iter_errors(report)]
    results.append((not schema_errors, "schema valid" + ("" if not schema_errors else f": {schema_errors[:3]}")))
    if schema_errors:
        return results

    design = report["design"]
    cited = {entry["path"] for entry in report["knowledge"]}
    missing_files = sorted(p for p in cited if not (root / p).is_file())
    results.append((not missing_files, "cited articles exist" + ("" if not missing_files else f": {missing_files}")))
    uncited = sorted(design_paths(design) - cited)
    results.append((not uncited, "design paths are listed in knowledge" + ("" if not uncited else f": {uncited}")))

    outcome = report["outcome"]
    results.append((outcome in case["expected-outcomes"], f"outcome {outcome} in {case['expected-outcomes']}"))

    for path in case.get("must-cite", []):
        results.append((path in cited, f"cites {path.rsplit('/', 1)[-1]}"))

    targets = {norm_target(o["target"]) for o in design["objects"]}
    target_texts = " | ".join(norm(o["target"]) for o in design["objects"])
    for target in case.get("must-extend", []):
        results.append((norm_target(target) in targets, f"designs object for {target}"))

    # Compare event names only: a report may append the signature, e.g. "OnAfterX(var Rec; ...)".
    events = {s["event"].split("(")[0].strip(): s for s in design["subscriptions"]}
    for event in case.get("must-subscribe", []):
        results.append((event in events, f"subscribes to {event}"))
    for event in case.get("must-not-subscribe", []):
        results.append((event not in events, f"does not subscribe to {event}"))
    for event, guard in case.get("required-guards", {}).items():
        guards = " ".join(events[event].get("guards", [])) if event in events else ""
        results.append((norm(guard) in norm(guards), f"{event} guarded by {guard}"))

    questions = " ".join(q["question"] for q in report["open-questions"])
    concerns = {l["concern"] for l in design["lifecycle"]}
    design_text = norm(" ".join(
        [o.get("purpose", "") for o in design["objects"]]
        + [f.get("note", "") for f in design["data-flow"]]
        + [s.get("purpose", "") for s in design["subscriptions"]]
        + [l.get("step", "") for l in design["lifecycle"]]
    ))
    for rule in case.get("must-cover-any", []):
        hit = False
        for option in rule["any"]:
            if "object-target" in option and (norm_target(option["object-target"]) in targets or norm(option["object-target"]) in target_texts):
                hit = True
            if "open-question-contains" in option and norm(option["open-question-contains"]) in norm(questions):
                hit = True
            if "lifecycle-concern" in option and option["lifecycle-concern"] in concerns:
                hit = True
            if "subscribes-to" in option and option["subscribes-to"] in events:
                hit = True
            if "design-contains" in option and norm(option["design-contains"]) in design_text:
                hit = True
            if "cites" in option and option["cites"] in cited:
                hit = True
            for object_type, minimum in option.get("object-type-count", {}).items():
                if sum(o["object-type"] == object_type for o in design["objects"]) >= minimum:
                    hit = True
        results.append((hit, f"covers: {rule['why']}"))

    object_types = {o["object-type"] for o in design["objects"]}
    for object_type in case.get("must-include-object-types", []):
        results.append((object_type in object_types, f"designs at least one {object_type}"))
    for concern in case.get("must-cover-lifecycle", []):
        results.append((concern in concerns, f"lifecycle covers {concern}"))

    min_tests = case.get("min-tests", 0)
    results.append((len(design["tests"]) >= min_tests, f"at least {min_tests} test(s), found {len(design['tests'])}"))
    return results


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("case_id")
    parser.add_argument("report")
    parser.add_argument("--root", default=Path(__file__).resolve().parents[1], type=Path)
    args = parser.parse_args()

    fixtures = json.loads((args.root / "evaluation/feature-design-fixtures.json").read_text(encoding="utf-8"))
    cases = {c["id"]: c for c in fixtures["cases"]}
    if args.case_id not in cases:
        print(f"Unknown case '{args.case_id}'. Known: {sorted(cases)}", file=sys.stderr)
        return 2
    report = json.loads(Path(args.report).read_text(encoding="utf-8"))

    results = score(cases[args.case_id], report, args.root.resolve())
    for ok, label in results:
        print(f"{'PASS' if ok else 'FAIL'}  {label}")
    passed = sum(ok for ok, _ in results)
    print(f"\n{passed}/{len(results)} checks passed for {args.case_id}")
    return 0 if passed == len(results) else 1


if __name__ == "__main__":
    sys.exit(main())
