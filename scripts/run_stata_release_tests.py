#!/usr/bin/env python3
"""Run cellgraph's release tests without trusting Stata's shell exit status."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEPENDENCIES = ("moremata", "require", "ftools", "reghdfe", "gtools")


class GateError(RuntimeError):
    pass


def find_stata(explicit: str | None) -> Path:
    configured = [explicit, os.environ.get("STATA_BIN")]
    for candidate in configured:
        if candidate and Path(candidate).is_file():
            return Path(candidate).resolve()

    mac_candidates = [
        Path("/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp")
    ]
    versioned = list(
        Path("/Applications").glob("Stata */StataMP.app/Contents/MacOS/stata-mp")
    )
    versioned.sort(
        key=lambda path: int(
            re.search(r"Stata (\d+)", str(path)).group(1)  # type: ignore[union-attr]
        ),
        reverse=True,
    )
    mac_candidates.extend(versioned)
    for candidate in mac_candidates:
        if not candidate.is_file():
            continue
        installation_root = candidate.parents[3]
        if (installation_root / "stata.lic").is_file():
            return candidate.resolve()
    for command in ("stata-mp", "stata-se", "stata"):
        resolved = shutil.which(command)
        if resolved:
            return Path(resolved).resolve()
    raise GateError("Stata executable not found; pass --stata or set STATA_BIN")


def stata_path(path: Path) -> str:
    return str(path.resolve()).replace('"', '""')


def write_do(path: Path, lines: list[str]) -> None:
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def run_stata(stata: Path, do_file: Path) -> str:
    log_path = do_file.with_suffix(".log")
    log_path.unlink(missing_ok=True)
    env = os.environ.copy()
    if "Contents/MacOS" in str(stata.parent):
        installation_root = stata.parents[3]
        env["PATH"] = f"{installation_root}:{env.get('PATH', '')}"
    completed = subprocess.run(
        [str(stata), "-b", "do", do_file.name],
        cwd=do_file.parent,
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )
    if not log_path.is_file():
        detail = (completed.stdout + "\n" + completed.stderr).strip()
        raise GateError(f"Stata did not create {log_path.name}: {detail}")
    log = log_path.read_text(encoding="utf-8", errors="replace")
    if not log.strip():
        detail = (completed.stdout + "\n" + completed.stderr).strip()
        raise GateError(f"Stata created an empty {log_path.name}: {detail}")
    if "Cannot find license file" in log:
        raise GateError(f"Stata could not access its license; see {log_path}")
    return log


def require_marker(log: str, marker: str, label: str, log_path: Path) -> None:
    if marker not in log:
        raise GateError(f"{label} did not finish successfully; see {log_path}")


def validate_suite(log: str, label: str, log_path: Path, require_deps: bool) -> None:
    totals = re.findall(r"^Total tests:\s+(\d+)\s*$", log, flags=re.MULTILINE)
    passes = re.findall(r"^Passed:\s+(\d+)\s*$", log, flags=re.MULTILINE)
    failures = re.findall(r"^Failed:\s+(\d+)\s*$", log, flags=re.MULTILINE)
    if not totals or not passes or not failures:
        raise GateError(f"{label} has no complete test summary; see {log_path}")
    total, passed, failed = map(int, (totals[-1], passes[-1], failures[-1]))
    if failed != 0 or passed != total or "ALL TESTS PASSED" not in log:
        raise GateError(
            f"{label} failed ({passed}/{total} passed, {failed} failed); "
            f"see {log_path}"
        )
    skips = re.findall(r"^SKIP: .+$", log, flags=re.MULTILINE)
    if require_deps and skips:
        raise GateError(
            f"{label} skipped required dependency coverage: {', '.join(skips)}; "
            f"see {log_path}"
        )
    print(f"PASS: {label} ({passed}/{total})")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--stata", help="path to the Stata batch executable")
    parser.add_argument(
        "--install-dependencies",
        action="store_true",
        help="install release-test dependencies into the isolated ado tree",
    )
    parser.add_argument(
        "--require-dependencies",
        action="store_true",
        help="fail if any dependency-backed test group is skipped",
    )
    args = parser.parse_args()

    if args.require_dependencies and not args.install_dependencies:
        raise GateError(
            "--require-dependencies requires --install-dependencies because "
            "the release gate uses an isolated ado tree"
        )

    stata = find_stata(args.stata)
    work = Path(tempfile.mkdtemp(prefix="cellgraph-release-tests-"))
    source = work / "source"
    run_dir = work / "installed-package"
    plus = work / "ado" / "plus"
    personal = work / "ado" / "personal"
    plus.mkdir(parents=True)
    personal.mkdir(parents=True)
    run_dir.mkdir()
    shutil.copytree(
        ROOT,
        source,
        ignore=shutil.ignore_patterns(
            ".git", "*.log", "AGENTS.md", "plans", ".claude"
        ),
    )
    print(f"Release-test workspace: {work}")

    sysdirs = [
        f'sysdir set PLUS "{stata_path(plus)}"',
        f'sysdir set PERSONAL "{stata_path(personal)}"',
    ]

    if args.install_dependencies:
        setup = work / "install_dependencies.do"
        setup_lines = ["clear all", "set more off", *sysdirs]
        for dependency in DEPENDENCIES:
            setup_lines.extend(
                [
                    f"capture noisily ssc install {dependency}, replace",
                    "if _rc exit _rc",
                ]
            )
        setup_lines.extend(
            ['di as result "DEPENDENCY INSTALLATION PASSED"', "exit, clear"]
        )
        write_do(setup, setup_lines)
        setup_log = run_stata(stata, setup)
        require_marker(
            setup_log,
            "DEPENDENCY INSTALLATION PASSED",
            "dependency installation",
            setup.with_suffix(".log"),
        )
        print("PASS: isolated dependency installation")

    for suffix, setting, label in (
        ("default", "on", "full suite with varabbrev on"),
        ("varabbrev_off", "off", "full suite with varabbrev off"),
    ):
        wrapper = source / f"release_full_{suffix}.do"
        write_do(
            wrapper,
            [
                "set more off",
                *sysdirs,
                f"set varabbrev {setting}",
                "do test_cellgraph.do",
            ],
        )
        log = run_stata(stata, wrapper)
        validate_suite(
            log,
            label,
            wrapper.with_suffix(".log"),
            args.require_dependencies,
        )

    package_test = run_dir / "release_package_and_help.do"
    write_do(
        package_test,
        [
            "clear all",
            "set more off",
            *sysdirs,
            "set varabbrev off",
            f'net install cellgraph, replace from("{stata_path(source)}")',
            "which cellgraph",
            "findfile cellgraph.sthlp",
            "forvalues i = 1/10 {",
            '    di as text "RUNNING HELP EXAMPLE ex`i\'"',
            "    cellgraph_run ex`i' using cellgraph.sthlp, preserve",
            "}",
            'di as result "PACKAGE INSTALL AND HELP EXAMPLES PASSED"',
            "exit, clear",
        ],
    )
    package_log = run_stata(stata, package_test)
    require_marker(
        package_log,
        "PACKAGE INSTALL AND HELP EXAMPLES PASSED",
        "package install and help examples",
        package_test.with_suffix(".log"),
    )
    print("PASS: isolated net install and all 10 help examples")
    print("All Stata release gates passed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except GateError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
