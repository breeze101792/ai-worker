#!/usr/bin/env python3
"""Keep the Claude Code and Codex agent mirrors in sync with opencode.

opencode/agents/*.md is the source of truth. claude/agents/*.md and
codex/agents/*.toml are hand-adapted copies. This script reports where a copy
has drifted and, on request, propagates an opencode agent's body and
description into the mirrors.

What it never touches:

- Frontmatter keys other than `description`. opencode `mode`, `model`, and
  `permission` map to Claude `tools` and Codex TOML `name`, which differ by
  design.
- The file name, and any mirror file that does not exist. The primaries
  `build` and `plan` are opencode-only and stay that way.
- Agents the caller did not name, unless `--all` is given.

Some mirrors diverge on purpose (for example `recruiter` names the target
tool, `ai` names codex/agents). `check` flags those too, so review the diff
before you `apply`.

Assumption: an agent file's frontmatter is flat keys, so the first `---` after
line 1 closes it. A `---` inside frontmatter is not supported. Files are read
and written as UTF-8 with LF line endings.

Requires Python 3.11+ for `tomllib`.

Usage:
    sync-agents.py check [--tool claude|codex|both] [agent ...]
    sync-agents.py apply [--tool claude|codex|both] [--all | agent ...]
    sync-agents.py list [--tool claude|codex|both]

`--tool` goes after the subcommand. `check` exits 1 when any named mirror has
drifted, so it can gate a commit.
"""

from __future__ import annotations

import argparse
import difflib
import os
import sys
import tempfile
import tomllib
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SOURCE_DIR = REPO_ROOT / "opencode" / "agents"
MIRROR_DIRS = {
    "claude": REPO_ROOT / "claude" / "agents",
    "codex": REPO_ROOT / "codex" / "agents",
}
MD_FENCE = "---"
MD_DESC_PREFIX = "description:"
CODEX_DESC_PREFIX = "description = "
CODEX_OPEN = 'developer_instructions = """'
CODEX_CLOSE = '"""'
# A YAML scalar that starts with one of these needs quoting to stay a string.
YAML_INDICATORS = "-?:,[]{}#&*!|>'\"%@`"
EXIT_OK = 0
EXIT_DRIFT = 1
EXIT_USAGE = 2


class AgentFormatError(Exception):
    """A source or mirror file does not match the expected format."""


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write_atomic(path: Path, text: str) -> None:
    """Replace `path` with `text`, LF endings, never leaving it truncated."""
    handle, tmp = tempfile.mkstemp(dir=path.parent, prefix=".sync-", suffix=".tmp")
    try:
        with os.fdopen(handle, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(text)
        # mkstemp creates 0600; restore the target's mode so a shared checkout
        # does not silently lose group/other read.
        os.chmod(tmp, path.stat().st_mode & 0o7777)
        os.replace(tmp, path)
    except BaseException:
        Path(tmp).unlink(missing_ok=True)
        raise


def read_markdown(path: Path) -> tuple[str, str, str]:
    """Return (prefix, body, description) for an opencode or Claude agent file.

    `prefix` is the frontmatter block including both fences and a trailing
    newline. `body` is the text after the closing fence with surrounding
    newlines stripped. Rebuild the file as prefix + "\n" + body + "\n".
    """
    lines = read_text(path).split("\n")
    if not lines or lines[0] != MD_FENCE:
        raise AgentFormatError(f"{path}: missing opening {MD_FENCE}")
    try:
        close = lines.index(MD_FENCE, 1)
    except ValueError:
        raise AgentFormatError(f"{path}: missing closing {MD_FENCE}") from None
    prefix = "\n".join(lines[: close + 1]) + "\n"
    body = "\n".join(lines[close + 1 :]).strip("\n")
    return prefix, body, markdown_description(prefix, path)


def markdown_description(prefix: str, path: Path) -> str:
    for line in prefix.split("\n"):
        if line.startswith(MD_DESC_PREFIX):
            return yaml_scalar(line[len(MD_DESC_PREFIX) :].strip())
    raise AgentFormatError(f"{path}: no {MD_DESC_PREFIX} in frontmatter")


def markdown_with_description(prefix: str, description: str, path: Path) -> str:
    """Swap the `description:` line, or keep the prefix verbatim if unchanged.

    Preserving the line when the value already matches keeps `apply`
    idempotent: a mirror whose body changed but whose description did not is
    not re-quoted on every run.
    """
    if markdown_description(prefix, path) == description:
        return prefix
    out = []
    for line in prefix.split("\n"):
        if line.startswith(MD_DESC_PREFIX):
            out.append(f"{MD_DESC_PREFIX} {yaml_quote(description)}")
        else:
            out.append(line)
    return "\n".join(out)


def yaml_quote(value: str) -> str:
    """Quote a value only when it would not survive as a plain YAML scalar."""
    needs = (
        value == ""
        or value != value.strip()
        or ": " in value
        or value.endswith(":")
        or " #" in value
        or any(ch in value for ch in "\n\t\"\\")
        or value[0] in YAML_INDICATORS
    )
    if not needs:
        return value
    escaped = (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
        .replace("\t", "\\t")
    )
    return f'"{escaped}"'


def yaml_scalar(text: str) -> str:
    """Inverse of yaml_quote for the subset this script writes."""
    if len(text) >= 2 and text[0] == '"' and text[-1] == '"':
        return yaml_unescape(text[1:-1])
    if len(text) >= 2 and text[0] == "'" and text[-1] == "'":
        return text[1:-1].replace("''", "'")
    return text


def yaml_unescape(text: str) -> str:
    simple = {"\\": "\\", '"': '"', "n": "\n", "t": "\t"}
    out = []
    i = 0
    while i < len(text):
        char = text[i]
        if char == "\\" and i + 1 < len(text):
            out.append(simple.get(text[i + 1], text[i + 1]))
            i += 2
        else:
            out.append(char)
            i += 1
    return "".join(out)


def read_codex(path: Path) -> tuple[str, str, str, str]:
    """Return (head, body, tail, description) for a Codex agent TOML file.

    `head` ends with the opening triple-quote and a newline; `tail` begins with
    the closing triple-quote. The body and description come from `tomllib`, so
    the values are authoritative rather than re-parsed from escaped text — this
    is what lets `check` see an escape that was silently rewritten. Rebuild the
    file as head + toml_escape_body(body) + "\n" + tail.
    """
    text = read_text(path)
    lines = text.split("\n")
    try:
        open_i = next(i for i, l in enumerate(lines) if l.startswith(CODEX_OPEN))
    except StopIteration:
        raise AgentFormatError(f"{path}: no {CODEX_OPEN}") from None
    try:
        close_i = max(i for i, l in enumerate(lines) if l.rstrip() == CODEX_CLOSE)
    except ValueError:
        raise AgentFormatError(f"{path}: no closing {CODEX_CLOSE}") from None
    if close_i <= open_i:
        raise AgentFormatError(f"{path}: closing {CODEX_CLOSE} before opening")
    try:
        parsed = tomllib.loads(text)
    except tomllib.TOMLDecodeError as exc:
        raise AgentFormatError(f"{path}: cannot parse ({exc})") from None
    try:
        description = parsed["description"]
        body = parsed["developer_instructions"]
    except KeyError as exc:
        raise AgentFormatError(f"{path}: missing key {exc}") from None
    head = "\n".join(lines[: open_i + 1]) + "\n"
    tail = "\n".join(lines[close_i:])
    return head, body.strip("\n"), tail, description


def toml_escape_body(body: str) -> str:
    """Escape a body for a TOML multi-line basic string.

    Backslash is the only escape TOML applies inside `\"\"\"` that appears in
    prose. `\"\"\"` itself cannot be escaped this way, so `render` refuses it.
    """
    return body.replace("\\", "\\\\")


def codex_with_description(head: str, description: str, current: str) -> str:
    """Swap the `description = ` line, or keep it verbatim if unchanged.

    Keeping the existing line when the value already matches keeps `apply`
    idempotent for the same reason as the Markdown path.
    """
    if current == description:
        return head
    out = []
    for line in head.split("\n"):
        if line.startswith(CODEX_DESC_PREFIX):
            out.append(f'{CODEX_DESC_PREFIX}"{toml_escape(description)}"')
        else:
            out.append(line)
    return "\n".join(out)


def toml_escape(text: str) -> str:
    return text.replace("\\", "\\\\").replace('"', '\\"')


def source_agent_names() -> list[str]:
    return sorted(p.stem for p in SOURCE_DIR.glob("*.md"))


def mirror_path(tool: str, agent: str) -> Path:
    suffix = ".md" if tool == "claude" else ".toml"
    return MIRROR_DIRS[tool] / f"{agent}{suffix}"


def mirror_state(tool: str, agent: str, src_body: str, src_desc: str):
    """Return (exists, body_matches, desc_matches) for one mirror."""
    path = mirror_path(tool, agent)
    if not path.exists():
        return False, None, None
    if tool == "claude":
        _, body, desc = read_markdown(path)
    else:
        _, body, _, desc = read_codex(path)
    return True, body == src_body, desc == src_desc


def drift_fields(tool: str, agent: str, src_body: str, src_desc: str) -> list[str]:
    exists, body_ok, desc_ok = mirror_state(tool, agent, src_body, src_desc)
    if not exists:
        return []
    fields = []
    if not body_ok:
        fields.append("body")
    if not desc_ok:
        fields.append("description")
    return fields


def render(tool: str, agent: str, src_body: str, src_desc: str) -> str:
    """Build the full mirror text, validating it before anyone writes it."""
    path = mirror_path(tool, agent)
    if tool == "claude":
        prefix, _, _ = read_markdown(path)
        text = f"{markdown_with_description(prefix, src_desc, path)}\n{src_body}\n"
        check = read_markdown_text(text, path)
        if check[1] != src_body or check[2] != src_desc:
            raise AgentFormatError(f"{path}: rebuild would not round-trip")
        return text

    if CODEX_CLOSE in src_body:
        raise AgentFormatError(
            f"{path}: body contains {CODEX_CLOSE}, which cannot go inside a "
            f'TOML """ block; reword the source body'
        )
    head, _, tail, desc = read_codex(path)
    text = f"{codex_with_description(head, src_desc, desc)}" \
           f"{toml_escape_body(src_body)}\n{tail}"
    try:
        parsed = tomllib.loads(text)
    except tomllib.TOMLDecodeError as exc:
        raise AgentFormatError(f"{path}: rebuild produces invalid TOML ({exc})") from None
    if parsed.get("description") != src_desc:
        raise AgentFormatError(f"{path}: description would not round-trip")
    if parsed.get("developer_instructions", "").strip("\n") != src_body:
        raise AgentFormatError(
            f"{path}: body would not round-trip through TOML; a backslash in "
            f"the body is being read as an escape"
        )
    return text


def read_markdown_text(text: str, path: Path) -> tuple[str, str, str]:
    """read_markdown over an in-memory string, for validating a rebuild."""
    lines = text.split("\n")
    try:
        close = lines.index(MD_FENCE, 1)
    except ValueError:
        raise AgentFormatError(f"{path}: rebuild lost the closing {MD_FENCE}") from None
    prefix = "\n".join(lines[: close + 1]) + "\n"
    body = "\n".join(lines[close + 1 :]).strip("\n")
    return prefix, body, markdown_description(prefix, path)


def show_diff(tool: str, agent: str, src_body: str, src_desc: str) -> None:
    path = mirror_path(tool, agent)
    if not path.exists():
        return
    try:
        new_text = render(tool, agent, src_body, src_desc)
    except AgentFormatError as exc:
        print(f"    cannot render: {exc}")
        return
    diff = difflib.unified_diff(
        read_text(path).splitlines(),
        new_text.splitlines(),
        fromfile=f"a/{path.relative_to(REPO_ROOT)}",
        tofile=f"b/{path.relative_to(REPO_ROOT)}",
        lineterm="",
    )
    for line in diff:
        print(f"    {line}")


def load_source(agent: str) -> tuple[str, str, Path]:
    path = SOURCE_DIR / f"{agent}.md"
    if not path.exists():
        raise AgentFormatError(f"{path}: not an opencode agent")
    _, body, desc = read_markdown(path)
    return body, desc, path


def selected_agents(names: list[str], use_all: bool) -> list[str]:
    available = source_agent_names()
    if use_all:
        return available
    unknown = [n for n in names if n not in available]
    if unknown:
        raise AgentFormatError(f"unknown agent(s): {', '.join(unknown)}")
    return names


def cmd_check(agents: list[str], tools: list[str], use_all: bool) -> int:
    checked = selected_agents(agents, use_all)
    source_cache = {a: load_source(a)[:2] for a in checked}
    drifted = 0
    for agent in checked:
        body, desc = source_cache[agent]
        for tool in tools:
            path = mirror_path(tool, agent)
            if not path.exists():
                print(f"no mirror  {agent:<22} {tool}")
                continue
            fields = drift_fields(tool, agent, body, desc)
            if fields:
                drifted += 1
                print(f"drift      {agent:<22} {tool}: {', '.join(fields)}")
            else:
                print(f"ok         {agent:<22} {tool}")
    if drifted:
        print(f"\n{drifted} mirror(s) drifted. Review, then run: "
              f"sync-agents.py apply <agent> [--tool claude|codex|both]")
    return EXIT_DRIFT if drifted else EXIT_OK


def cmd_apply(agents: list[str], tools: list[str], use_all: bool, dry_run: bool) -> int:
    if not use_all and not agents:
        raise AgentFormatError("name at least one agent, or pass --all")
    if use_all:
        print("warning: --all rewrites every mirror, including agents that "
              "diverge on purpose (recruiter, ai, ui-designer).")
    changed = 0
    for agent in selected_agents(agents, use_all):
        body, desc, _ = load_source(agent)
        for tool in tools:
            path = mirror_path(tool, agent)
            if not path.exists():
                print(f"skip       {agent:<22} {tool}: no mirror file")
                continue
            fields = drift_fields(tool, agent, body, desc)
            if not fields:
                print(f"ok         {agent:<22} {tool}")
                continue
            if dry_run:
                print(f"update     {agent:<22} {tool}: {', '.join(fields)}")
                show_diff(tool, agent, body, desc)
                changed += 1
                continue
            # Render (and validate) before counting or writing.
            text = render(tool, agent, body, desc)
            write_atomic(path, text)
            print(f"update     {agent:<22} {tool}: {', '.join(fields)}")
            changed += 1
    suffix = " (dry run, nothing written)" if dry_run else ""
    print(f"\n{changed} mirror(s) updated{suffix}.")
    return EXIT_OK


def cmd_list(tools: list[str]) -> int:
    print(f"{'agent':<22} " + "  ".join(f"{t:<8}" for t in tools))
    for agent in source_agent_names():
        cells = []
        try:
            body, desc, _ = load_source(agent)
        except AgentFormatError:
            body = desc = ""
        for tool in tools:
            path = mirror_path(tool, agent)
            if not path.exists():
                cells.append("missing ")
            else:
                fields = drift_fields(tool, agent, body, desc)
                cells.append("drift   " if fields else "ok      ")
        print(f"{agent:<22} " + "  ".join(cells))
    return EXIT_OK


def parse_tools(spec: str) -> list[str]:
    if spec == "both":
        return list(MIRROR_DIRS)
    if spec not in MIRROR_DIRS:
        raise AgentFormatError(f"unknown tool: {spec} (claude|codex|both)")
    return [spec]


def build_parser() -> argparse.ArgumentParser:
    summary = (__doc__ or "").strip().split("\n", 1)[0]
    parser = argparse.ArgumentParser(description=summary)
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--tool", default="both",
                        help="claude, codex, or both (default: both)")
    sub = parser.add_subparsers(dest="command", required=True)

    check = sub.add_parser("check", parents=[common],
                           help="report drift, exit 1 if any")
    check.add_argument("--all", action="store_true", help="check every agent")
    check.add_argument("agents", nargs="*", help="agent names (default: all)")

    apply_cmd = sub.add_parser("apply", parents=[common],
                               help="copy body and description")
    apply_cmd.add_argument("--all", action="store_true", help="apply every agent")
    apply_cmd.add_argument("--dry-run", action="store_true",
                           help="print the diff without writing")
    apply_cmd.add_argument("agents", nargs="*", help="agent names")

    sub.add_parser("list", parents=[common],
                   help="show the mirror state of every agent")
    return parser


def main(argv: list[str]) -> int:
    args = build_parser().parse_args(argv)
    try:
        tools = parse_tools(args.tool)
        if args.command == "check":
            return cmd_check(args.agents, tools, args.all or not args.agents)
        if args.command == "apply":
            return cmd_apply(args.agents, tools, args.all, args.dry_run)
        return cmd_list(tools)
    except AgentFormatError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return EXIT_USAGE


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
