#!/usr/bin/env python3
"""Check release-policy structure and tag-specific Stata package metadata."""

from __future__ import annotations

import argparse
import datetime as dt
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def error(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)


def require_file(path: Path, errors: list[str]) -> str:
    if not path.is_file():
        errors.append(f"missing required file: {path.relative_to(ROOT)}")
        return ""
    return path.read_text(encoding="utf-8", errors="strict")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--tag",
        help="release tag to validate, such as v0.2.0 or v0.2.0-rc1",
    )
    args = parser.parse_args()
    errors: list[str] = []

    changelog = require_file(ROOT / "CHANGELOG.md", errors)
    releasing = require_file(ROOT / "RELEASING.md", errors)
    readme = require_file(ROOT / "README.md", errors)

    pkg_files = sorted(ROOT.glob("*.pkg"))
    if len(pkg_files) != 1:
        errors.append(f"expected exactly one root .pkg file; found {len(pkg_files)}")
        pkg_path = None
        pkg_text = ""
        package = ""
    else:
        pkg_path = pkg_files[0]
        package = pkg_path.stem
        pkg_text = require_file(pkg_path, errors)
        require_file(ROOT / f"{package}.ado", errors)

    manifest_files: list[str] = []
    package_stata_version = ""

    if "## Unreleased" not in changelog:
        errors.append("CHANGELOG.md must contain an Unreleased section")
    if "immutable" not in releasing.lower() or "ssc" not in releasing.lower():
        errors.append("RELEASING.md must document immutable tags and SSC")
    readme_lower = readme.lower()
    if "development version" not in readme_lower or "/main/" not in readme:
        errors.append("README.md must label the main install as development")
    if package and f"ssc install {package}" not in readme_lower:
        errors.append(f"README.md must document the SSC command for {package}")
    if "/vX.Y.Z/" not in readme:
        errors.append("README.md must show installation from an immutable vX.Y.Z tag")

    if pkg_path is not None:
        for line in pkg_text.splitlines():
            match = re.match(r"^f\s+(.+?)\s*$", line)
            if match:
                manifest_file = match.group(1)
                manifest_files.append(manifest_file)
                if not (ROOT / manifest_file).is_file():
                    errors.append(
                        f"package manifest lists missing file: {manifest_file}"
                    )

        requirement_match = re.search(
            r"^d\s+Requires:\s+Stata version\s+(\d+(?:\.\d+)?)\s*$",
            pkg_text,
            flags=re.IGNORECASE | re.MULTILINE,
        )
        if not requirement_match:
            errors.append("package metadata needs 'd Requires: Stata version N'")
        else:
            package_stata_version = requirement_match.group(1)
            if f"Stata {package_stata_version}" not in readme:
                errors.append(
                    "README.md minimum Stata version must match package metadata"
                )

        for manifest_file in manifest_files:
            if not manifest_file.lower().endswith(".ado"):
                continue
            ado_path = ROOT / manifest_file
            if not ado_path.is_file():
                continue
            ado_text = require_file(ado_path, errors)
            version_match = re.search(
                r"^\s*version\s+(\d+(?:\.\d+)?)\s*$",
                ado_text,
                flags=re.IGNORECASE | re.MULTILINE,
            )
            if not version_match:
                errors.append(f"{manifest_file} needs a Stata version command")
            elif (
                package_stata_version
                and float(version_match.group(1)) != float(package_stata_version)
            ):
                errors.append(
                    f"{manifest_file} version {version_match.group(1)} does not "
                    f"match package requirement {package_stata_version}"
                )

    if args.tag:
        tag_match = re.fullmatch(
            r"v(?P<version>\d+\.\d+\.\d+)(?:-(?P<pre>(?:rc|alpha|beta)\d+))?",
            args.tag,
        )
        if not tag_match:
            errors.append(f"invalid release tag: {args.tag}")
        elif pkg_path is not None:
            version = tag_match.group("version")
            ado_text = require_file(ROOT / f"{package}.ado", errors)
            ado_match = re.search(
                rf"^\*!\s+{re.escape(package)}\s+"
                rf"(?P<version>\d+\.\d+\.\d+)\s+"
                rf"(?P<date>\d{{1,2}}[a-z]{{3}}\d{{4}})\s*$",
                ado_text,
                flags=re.IGNORECASE | re.MULTILINE,
            )
            pkg_match = re.search(
                r"^d\s+Distribution-Date:\s*(\d{8})\s*$",
                pkg_text,
                flags=re.MULTILINE,
            )
            changelog_match = re.search(
                rf"^##\s+{re.escape(version)}\s+-\s+"
                rf"(?P<date>\d{{4}}-\d{{2}}-\d{{2}})\s*$",
                changelog,
                flags=re.MULTILINE,
            )

            if not ado_match:
                errors.append(
                    f"{package}.ado needs '*! {package} {version} DDmonYYYY'"
                )
            elif ado_match.group("version") != version:
                errors.append(
                    f"ado version {ado_match.group('version')} does not match {version}"
                )
            if not pkg_match:
                errors.append(f"{package}.pkg needs d Distribution-Date: YYYYMMDD")
            if not changelog_match:
                errors.append(f"CHANGELOG.md needs a dated {version} section")

            if ado_match and pkg_match and changelog_match:
                try:
                    ado_date = dt.datetime.strptime(
                        ado_match.group("date").lower(), "%d%b%Y"
                    ).date()
                    pkg_date = dt.datetime.strptime(pkg_match.group(1), "%Y%m%d").date()
                    log_date = dt.date.fromisoformat(changelog_match.group("date"))
                    if not ado_date == pkg_date == log_date:
                        errors.append(
                            "ado header, package Distribution-Date, and changelog "
                            "release date do not agree"
                        )
                except ValueError as exc:
                    errors.append(f"invalid release date: {exc}")

    for message in errors:
        error(message)
    if errors:
        return 1

    if args.tag:
        print(f"Release metadata is consistent for {args.tag}.")
    else:
        print("Release-policy structure and package manifest are valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
