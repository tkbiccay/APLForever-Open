"""Package exact, independently importable v0.8.2 testing profiles."""

import argparse
import json
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

from build_native_manifest import ROOT, build_manifest, select_revision

PIN = "cce44f491020662045943f638af2b88673d1c60b"


def build_bundle(output: Path) -> None:
    native, checked = build_manifest(ROOT, source_release="v0.8.2")
    tested = {row["apl_file"] for row in native}
    catalogue = json.loads((ROOT / "catalogue/roles.json").read_text(encoding="utf-8-sig"))
    files = {"TESTING_BASELINES.md": (ROOT / "docs/TESTING_BASELINES.md").read_bytes()}
    manifest = {
        "hekili_version": "v0.8.2",
        "hekili_commit": PIN,
        "catalogue_hashes_checked": checked,
        "supported": [],
        "blocked": [],
    }
    for role in catalogue["roles"]:
        name = role["apl_name"]
        if role["support_status"] == "Blocked":
            manifest["blocked"].append(role)
            continue
        if role["support_status"] != "Supported":
            continue
        revisions = role["revisions"]
        by_path = {row["apl_file"]: row for row in revisions}
        selected = select_revision(role, "v0.8.2")
        source = selected["apl_file"]
        if source not in tested:
            raise ValueError(f"Selected file absent from native suite: {source}")
        member = f"testing/{Path(source).name}"
        files[member] = (ROOT / source).read_bytes()
        rollback = role["last_working_apl"]
        rollback_member = None
        if rollback in by_path:
            rollback_member = f"rollbacks/{Path(rollback).name}"
            files[rollback_member] = (ROOT / rollback).read_bytes()
        configuration = {
            "Warlock_Demonology": "Check the assigned_curse specialization setting.",
            "Paladin_Retribution": "Apply the desired Blessing manually.",
        }.get(name)
        manifest["supported"].append({
            **role,
            "import_name": name,
            "selected": selected,
            "bundle_path": member,
            "rollback_bundle_path": rollback_member,
            "rollback_instructions": "Restore your prior profile if no working copy is recorded.",
            "configuration": configuration,
            "readiness": "Cautious testing only",
        })
    if len(manifest["supported"]) != 23 or len(manifest["blocked"]) != 5:
        raise ValueError("Unexpected supported or blocked coverage")
    files["manifest.json"] = (json.dumps(manifest, indent=2, ensure_ascii=False) + "\n").encode()
    output.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(output, "w") as archive:
        for name, data in sorted(files.items()):
            archive.writestr(ZipInfo(name), data, compress_type=ZIP_DEFLATED)
    with ZipFile(output) as archive:
        for row in manifest["supported"]:
            if archive.read(row["bundle_path"]) != (ROOT / row["selected"]["apl_file"]).read_bytes():
                raise ValueError(f"Bundle bytes changed for {row['import_name']}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    build_bundle(parser.parse_args().output)
