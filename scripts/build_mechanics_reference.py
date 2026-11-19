#!/usr/bin/env python3
"""Validate pinned Forever class mechanics and generate GitHub reference pages.

Source registration facts and reviewed gameplay annotations are separate.
No network calls, packages, imported APLs or runtime dependencies.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
PIN = "8f95f2ea0a45428554c1e938ed7357b870030514"
CLASSES = ("Druid", "Hunter")
LANES = {"General", "MajorCooldowns", "MinorCooldowns", "Defensives", "Interrupts", "Potions", "Utility"}
TAGS = set(("offensive defensive utility control interrupt stun slow taunt threat movement "
            "pet_management summoning healing resource aoe dot buff debuff ranged melee "
            "maintenance execute mitigation crowd_control form major_cooldown minor_cooldown").split())
TOGGLES = {None, "cooldowns", "defensives", "interrupts", "potions", "movement"}
GCDS = {None, "off", "spell", "totem"}
BT = chr(96)


def require(ok, message):
    if not ok:
        raise ValueError(message)


def documents(root=ROOT):
    return [json.loads((root / "knowledge" / "classes" / (cl + ".json")).read_text(encoding="utf-8"))
            for cl in CLASSES]


def validate_structure(doc, supported):
    cl = doc.get("class")
    require(doc.get("schema_version") == 1 and cl in CLASSES, "class/schema invalid")
    pin = doc.get("pin", {})
    require(pin.get("product") == "Hekili Forever" and pin.get("tag") == "v0.9.0"
            and pin.get("commit") == PIN, f"{cl}: unknown or silently changed source pin")
    require(pin.get("class_file") == f"src/Hekili_{cl}/{cl}.lua"
            and re.fullmatch("[0-9a-f]{40}", pin.get("class_file_blob_sha", "")),
            f"{cl}: missing Git source blob pin")
    require(doc.get("pilot_role") in supported and doc["pilot_role"].startswith(cl + "_")
            and len(doc.get("tree_names", [])) == 3, f"{cl}: bad pilot role or trees")
    require(doc.get("abilities") and doc.get("talents"), f"{cl}: no data")
    ability_keys = set()
    for ab in doc["abilities"]:
        k = ab.get("key")
        require(isinstance(k, str) and re.fullmatch("[a-z][a-z0-9_]*", k) and k not in ability_keys,
                f"{cl}: bad or duplicate ability {k}")
        ability_keys.add(k)
        require(type(ab.get("id")) is int and ab["id"] > 0
                and type(ab.get("source_line")) is int and ab["source_line"] > 0,
                f"{cl}/{k}: source identity")
        tags = ab.get("tags")
        require(isinstance(tags, list) and tags and len(tags) == len(set(tags)) and set(tags) <= TAGS,
                f"{cl}/{k}: missing/unsupported classifications")
        require(ab.get("native_toggle") in TOGGLES and ab.get("gcd") in GCDS
                and ab.get("suggested_apl_lane") in LANES
                and ab.get("classification_grade") == "Supported",
                f"{cl}/{k}: native vs interpreted toggle or GCD")
        require(ab.get("resource_type") in (None, "mana", "rage", "energy"), f"{cl}/{k}: resource")
        for field in ("cooldown_seconds", "spend_literal"):
            v = ab.get(field)
            require(v is None or type(v) in (int, float) and v >= 0,
                    f"{cl}/{k}: numeric {field}")
        require(isinstance(ab.get("note"), str) and ab["note"].strip(), f"{cl}/{k}: note")
        rg = ab.get("range")
        if rg:
            require(rg.get("evidence") == "source_world"
                    and rg.get("source", "").startswith("tests/Forever/helpers/")
                    and isinstance(rg.get("source_anchor"), str)
                    and type(rg.get("minimum_yards")) is int
                    and type(rg.get("maximum_yards")) is int
                    and 0 <= rg["minimum_yards"] <= rg["maximum_yards"] <= 100,
                    f"{cl}/{k}: unsupported range claim")
    talents = set()
    for tal in doc["talents"]:
        k = tal.get("key")
        require(isinstance(k, str) and re.fullmatch("[a-z][a-z0-9_]*", k)
                and k not in talents, f"{cl}: duplicate talent {k}")
        talents.add(k)
        require(type(tal.get("tree")) is int and 1 <= tal["tree"] <= 3
                and type(tal.get("spell_id")) is int and tal["spell_id"] > 0
                and type(tal.get("max_rank")) is int and 1 <= tal["max_rank"] <= 10
                and type(tal.get("source_line")) is int and tal["source_line"] > 0,
                f"{cl}/{k}: talent source identity")
        require(type(tal.get("mechanics_reviewed")) is bool
                and tal["mechanics_reviewed"] == ("reviewed_note" in tal),
                f"{cl}/{k}: review must be explicit")


def literal(block, field, quoted):
    pat = (rf'^        {re.escape(field)} = "([^"]+)"'
           if quoted else rf"^        {re.escape(field)} = (\d+(?:\.\d+)?)\s*(?:,|$)")
    m = re.search(pat, block, re.M)
    return m.group(1) if m else None


def validate_source(doc, upstream):
    pin = doc["pin"]
    path = upstream / pin["class_file"]
    raw = path.read_bytes()
    blob = hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()
    require(blob == pin["class_file_blob_sha"], f"{path}: source blob changed")
    rows = raw.decode("utf-8-sig").splitlines()
    for ab in doc["abilities"]:
        k, n = ab["key"], ab["source_line"]
        require(rows[n-1] == f"    {k} = {{", f"{k}: changed registration line {n}")
        remainder = rows[n:]
        stop = next((i for i, row in enumerate(remainder) if row == "    },"), None)
        require(stop is not None, f"{k}: unterminated ability")
        block = "\n".join(remainder[:stop])
        require(literal(block, "id", False) == str(ab["id"]), f"{k}: ability ID changed")
        for target, field in (("gcd", "gcd"), ("native_toggle", "toggle"),
                              ("resource_type", "spendType")):
            require(literal(block, field, True) == ab[target],
                    f"{k}: source {field} changed")
        for target, field in (("cooldown_seconds", "cooldown"), ("spend_literal", "spend")):
            val = literal(block, field, False)
            require((float(val) if val is not None else None) == ab[target],
                    f"{k}: source numeric {field} changed")
        rg = ab["range"]
        if rg:
            world = (upstream / rg["source"]).read_text(encoding="utf-8")
            require(rg["source_anchor"] in world, f"{k}: world range changed")
    start = next(i for i, row in enumerate(rows) if "spec:RegisterTalents({" in row) + 1
    end = next(i for i in range(start, len(rows)) if rows[i] == "})")
    pat = re.compile(r"^    ([a-z][a-z0-9_]*) = \{ ([123]), (\d+), (\d+) \},?")
    actual = {}
    for i in range(start, end):
        match = pat.match(rows[i])
        if match:
            actual[match.group(1)] = (int(match.group(2)), int(match.group(3)),
                                      int(match.group(4)), i+1)
    expected = {t["key"]: (t["tree"], t["spell_id"], t["max_rank"], t["source_line"])
                for t in doc["talents"]}
    require(actual == expected, f"{doc['class']}: incomplete/changed talent tree")


def upstream_link(doc, line):
    pin = doc["pin"]
    return f"https://github.com/zmsl/hekili/blob/{PIN}/{pin['class_file']}#L{line}"


def render(doc):
    cl = doc["class"]
    pin = doc["pin"]
    lines = [
        f"# {cl} — {doc['pilot_spec']} pilot mechanics reference", "",
        f"**Forever source:** {pin['tag']} · exact commit {BT}{PIN}{BT} · "
        f"client data build {BT}{pin['client_data_build']}{BT}.", "",
        "**Development knowledge only.** Engine registration fields are source-pinned; "
        "classifications and proposed APL lanes are reviewed interpretations, "
        "not automatically supported toggles or in-game validation.", "",
        f"**Scope:** {len(doc['abilities'])} reviewed abilities; "
        f"all {len(doc['talents'])} registered class talents from three trees. "
        f"Pilot role: {BT}{doc['pilot_role']}{BT}. Missing ability entries mean "
        "**not yet reviewed**, never an assertion of absence.", "",
        "## Reviewed abilities", "",
        "| Ability/source | Classifications | Native toggle / suggested lane | GCD · CD · resource | Range evidence | Notes and limitations |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for ab in doc["abilities"]:
        k = ab["key"]
        link = upstream_link(doc, ab["source_line"])
        native = ab["native_toggle"] or "not declared"
        gcd = ab["gcd"] or "not checked"
        cd = f"{ab['cooldown_seconds']:g}s" if ab["cooldown_seconds"] is not None else "dynamic/unknown"
        res = ab["resource_type"] or "none declared"
        if ab["spend_literal"] is not None:
            res += f" (source spend {ab['spend_literal']:g})"
        rg = ab["range"]
        rng = ("not checked" if rg is None else
               f"{rg['minimum_yards']}–{rg['maximum_yards']}yd *source world only*")
        lines.append(f"| [{BT}{k}{BT}]({link}) | {', '.join(ab['tags'])} | "
                     f"{BT}{native}{BT} / **{ab['suggested_apl_lane']}** | "
                     f"{gcd} · {cd} · {res} | {rng} | {ab['note']} |")
    lines.extend([
        "", "Native toggle = actual registered class pack field. Suggested APL lane "
        "= intended design classification **only**. "
        "No native toggle does not imply that a user-facing mode is automatically obeyed. "
        "Source-world range does not prove the live client's range or Auto Shot fidelity.", "",
        "## All registered class talents", "",
        "| Talent/source | Tree | Rank 1 spell ID | Max ranks | Mechanical review |",
        "| --- | --- | ---: | ---: | --- |",
    ])
    for t in doc["talents"]:
        link = upstream_link(doc, t["source_line"])
        status = (t["reviewed_note"] if t["mechanics_reviewed"]
                  else "Registered only — effects not yet reviewed")
        lines.append(f"| [{BT}{t['key']}{BT}]({link}) | {doc['tree_names'][t['tree']-1]} | "
                     f"{t['spell_id']} | {t['max_rank']} | {status} |")
    lines.extend([
        "", "## Safe reuse", "",
        "- Canonical data: class JSON; this Markdown is generated. Do not edit manually.",
        "- Check native source, engine observations, level/rank and latest release "
        "before transferring mechanics to another spec.",
        "- On upstream release changes: diff, review and explicitly re-pin; never "
        "overwrite v0.9.0 facts or copy Retail/Classic/SoD assumptions.",
        "- Regenerate: python scripts/build_mechanics_reference.py --write. "
        "Validate: --check; optional pinned checkout: --source-root ../upstream/hekili.",
        "- Research once → Preserve evidence (including failed tests) → "
        "Reuse after role-specific verification. No APL approval from this page.", "",
    ])
    return "\n".join(lines)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    mode = p.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--write", action="store_true")
    p.add_argument("--source-root", type=Path)
    args = p.parse_args()
    cat = json.loads((ROOT / "catalogue" / "roles.json").read_text(encoding="utf-8-sig"))
    supported = {r["apl_name"] for r in cat["roles"] if r["support_status"] == "Supported"}
    source = args.source_root.resolve() if args.source_root else None
    if source:
        head = subprocess.check_output(["git", "-C", str(source), "rev-parse", "HEAD"],
                                       text=True).strip()
        require(head == PIN, "upstream source checkout must be exact v0.9.0 commit")
    for doc in documents():
        validate_structure(doc, supported)
        if source:
            validate_source(doc, source)
        path = ROOT / "docs" / "reference" / (doc["pilot_role"] + ".md")
        page = render(doc)
        if args.check:
            require(path.exists() and path.read_text(encoding="utf-8") == page,
                    f"{path}: missing or stale generated page; use --write")
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(page, encoding="utf-8")
        print(f"{doc['class']}: {len(doc['abilities'])} reviewed abilities / "
              f"{len(doc['talents'])} talent registrations — "
              f"{'checked' if args.check else 'written'}")


if __name__ == "__main__":
    main()
