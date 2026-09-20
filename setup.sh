#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Output styling. The level tags are colored only when writing to a terminal,
# so redirected output and log files stay plain. Each stream is checked on its
# own. Disable color with NO_COLOR (https://no-color.org) or TERM=dumb.
SGR_INFO='1;34'   # bold blue
SGR_WARN='1;33'   # bold yellow
SGR_ERROR='1;31'  # bold red
SGR_OK='1;32'     # bold green

color_tag() {
  # Args: <fd> <sgr-code> <tag>. Returns the tag wrapped in color when that fd
  # is a terminal and color is enabled, otherwise the plain tag.
  local fd="$1" sgr="$2" tag="$3"
  if [[ -t "$fd" && -z "${NO_COLOR:-}" && "${TERM:-}" != "dumb" ]]; then
    printf '\033[%sm%s\033[0m' "$sgr" "$tag"
  else
    printf '%s' "$tag"
  fi
}

TAG_INFO="$(color_tag 1 "$SGR_INFO" '[INFO]')"
TAG_WARN="$(color_tag 2 "$SGR_WARN" '[WARN]')"
TAG_ERROR="$(color_tag 2 "$SGR_ERROR" '[ERROR]')"
TAG_OK="$(color_tag 1 "$SGR_OK" '[OK]')"
TAG_MISSING="$(color_tag 2 "$SGR_ERROR" '[MISSING]')"

# Tool registry: name -> one "source|destination|type" line per link target.
# Add new tools here.
#   type=file:    symlink a single file
#   type=dir:     symlink a directory (created in-repo if missing)
#   type=entries: make the destination a real directory and symlink each entry
#                 of the source directory into it, one link per entry
#
# Claude Code ships two settings variants:
#   ollama  claude/settings-ollama.json — the full `env` block, including
#           CLAUDE_CODE_AUTO_COMPACT_WINDOW. This is the default.
#   base    claude/settings.json — the same `env` block without
#           CLAUDE_CODE_AUTO_COMPACT_WINDOW, so the model supplies the window.
# Select with CLAUDE_SETTINGS:
#   CLAUDE_SETTINGS=base bash setup.sh link claude
CLAUDE_SETTINGS="${CLAUDE_SETTINGS:-ollama}"
case "$CLAUDE_SETTINGS" in
  base)   TOOL_CLAUDE_SRC="$SCRIPT_DIR/claude/settings.json" ;;
  ollama) TOOL_CLAUDE_SRC="$SCRIPT_DIR/claude/settings-ollama.json" ;;
  *) echo "$TAG_ERROR Unknown CLAUDE_SETTINGS: $CLAUDE_SETTINGS (base|ollama)" >&2; exit 1 ;;
esac
TOOL_CLAUDE_DST="$HOME/.claude/settings.json"

# Codex ships two config variants:
#   ollama  codex/config-ollama.toml — routes Codex to the local ollama gateway
#           through model_provider and a [model_providers.*] table. This is the
#           default.
#   base    codex/config.toml — no routing keys, so Codex uses its own default
#           provider.
# Select with CODEX_SETTINGS:
#   CODEX_SETTINGS=base bash setup.sh link codex
CODEX_SETTINGS="${CODEX_SETTINGS:-ollama}"
case "$CODEX_SETTINGS" in
  base)   TOOL_CODEX_CONFIG_SRC="$SCRIPT_DIR/codex/config.toml" ;;
  ollama) TOOL_CODEX_CONFIG_SRC="$SCRIPT_DIR/codex/config-ollama.toml" ;;
  *) echo "$TAG_ERROR Unknown CODEX_SETTINGS: $CODEX_SETTINGS (base|ollama)" >&2; exit 1 ;;
esac
TOOL_CLAUDE_CLAUDE_MD_SRC="$SCRIPT_DIR/claude/CLAUDE.md"
TOOL_CLAUDE_CLAUDE_MD_DST="$HOME/.claude/CLAUDE.md"
TOOL_CLAUDE_AGENTS_DIR_SRC="$SCRIPT_DIR/claude/agents"
TOOL_CLAUDE_AGENTS_DIR_DST="$HOME/.claude/agents"
TOOL_CLAUDE_COMMANDS_DIR_SRC="$SCRIPT_DIR/claude/commands"
TOOL_CLAUDE_COMMANDS_DIR_DST="$HOME/.claude/commands"
TOOL_CLAUDE_SKILLS_DIR_SRC="$SCRIPT_DIR/claude/skills"
TOOL_CLAUDE_SKILLS_DIR_DST="$HOME/.claude/skills"
TOOL_OPENCODE_SRC="$SCRIPT_DIR/opencode/opencode.jsonc"
TOOL_OPENCODE_DST="$HOME/.config/opencode/opencode.jsonc"
TOOL_OPENCODE_AGENTSMD_SRC="$SCRIPT_DIR/opencode/AGENTS.md"
TOOL_OPENCODE_AGENTSMD_DST="$HOME/.config/opencode/AGENTS.md"
TOOL_OPENCODE_AGENTS_SRC="$SCRIPT_DIR/opencode/agents"
TOOL_OPENCODE_AGENTS_DST="$HOME/.config/opencode/agents"
TOOL_OPENCODE_SKILLS_SRC="$SCRIPT_DIR/opencode/skills"
TOOL_OPENCODE_SKILLS_DST="$HOME/.config/opencode/skills"
TOOL_OPENCODE_COMMANDS_SRC="$SCRIPT_DIR/opencode/commands"
TOOL_OPENCODE_COMMANDS_DST="$HOME/.config/opencode/commands"
TOOL_CODEX_AGENTS_DIR_SRC="$SCRIPT_DIR/codex/agents"
TOOL_CODEX_AGENTS_DIR_DST="$HOME/.codex/agents"
TOOL_CODEX_SKILLS_DIR_SRC="$SCRIPT_DIR/codex/skills"
TOOL_CODEX_SKILLS_DIR_DST="$HOME/.agents/skills"
TOOL_CODEX_AGENTSMD_SRC="$SCRIPT_DIR/codex/AGENTS.md"
TOOL_CODEX_AGENTSMD_DST="$HOME/.codex/AGENTS.md"
TOOL_CODEX_CONFIG_DST="$HOME/.codex/config.toml"

MODELS=(
  "deepseek-v4.1-flash:cloud"
  "glm-5.3:cloud"
  "minimax-m3:cloud"
)

usage() {
  cat <<EOF
claude-worker setup — initialize ollama models and tool settings

Usage: $(basename "$0") [options] <command>

Commands:
  pull              Pull all required ollama models (claude)
  link [TOOLS]      Symlink tool settings to the right paths.
                    TOOLS is a comma-separated list to link
                    (default: opencode). Available: claude, opencode, codex
                    Example: link claude
                    Skills are linked per entry: each skill gets its own
                    symlink in a real skills directory, so you can keep a
                    local skill beside the shared ones.
  all [TOOLS]       Run pull + link (default if no command given)
  help              Show this help message

Options:
  --dry-run         Show what would be done without executing

Environment:
  CLAUDE_SETTINGS   Which Claude Code settings variant to link (default: ollama)
                    ollama  the full env block, with the compact-window override
                    base    the same env block without the compact-window override
  CODEX_SETTINGS    Which Codex config variant to link (default: ollama)
                    ollama  route Codex to the local ollama gateway
                    base    Codex uses its own default provider

Examples:
  $(basename "$0") link
  $(basename "$0") link claude
  $(basename "$0") link claude,opencode
  $(basename "$0") all claude,opencode
  $(basename "$0") all claude --dry-run
  CLAUDE_SETTINGS=ollama $(basename "$0") link claude
  CODEX_SETTINGS=ollama $(basename "$0") link codex
  CLAUDE_SETTINGS=ollama CODEX_SETTINGS=ollama $(basename "$0") link claude,codex
  CLAUDE_SETTINGS=base $(basename "$0") link claude
  CODEX_SETTINGS=base $(basename "$0") link codex
EOF
}

info()  { echo "$TAG_INFO  $*"; }
warn()  { echo "$TAG_WARN  $*" >&2; }
err()   { echo "$TAG_ERROR $*" >&2; }

# Resolve a tool name to "src|dst|type" lines (one per link target).
# Returns 1 if unknown.
resolve_tool() {
  local name="$1"
  case "$name" in
    claude)
      echo "$TOOL_CLAUDE_SRC|$TOOL_CLAUDE_DST|file"
      echo "$TOOL_CLAUDE_CLAUDE_MD_SRC|$TOOL_CLAUDE_CLAUDE_MD_DST|file"
      echo "$TOOL_CLAUDE_AGENTS_DIR_SRC|$TOOL_CLAUDE_AGENTS_DIR_DST|dir"
      echo "$TOOL_CLAUDE_COMMANDS_DIR_SRC|$TOOL_CLAUDE_COMMANDS_DIR_DST|dir"
      echo "$TOOL_CLAUDE_SKILLS_DIR_SRC|$TOOL_CLAUDE_SKILLS_DIR_DST|entries"
      ;;
    opencode)
      echo "$TOOL_OPENCODE_SRC|$TOOL_OPENCODE_DST|file"
      echo "$TOOL_OPENCODE_AGENTSMD_SRC|$TOOL_OPENCODE_AGENTSMD_DST|file"
      echo "$TOOL_OPENCODE_AGENTS_SRC|$TOOL_OPENCODE_AGENTS_DST|dir"
      echo "$TOOL_OPENCODE_SKILLS_SRC|$TOOL_OPENCODE_SKILLS_DST|entries"
      echo "$TOOL_OPENCODE_COMMANDS_SRC|$TOOL_OPENCODE_COMMANDS_DST|dir"
      ;;
    codex)
      echo "$TOOL_CODEX_AGENTS_DIR_SRC|$TOOL_CODEX_AGENTS_DIR_DST|dir"
      echo "$TOOL_CODEX_SKILLS_DIR_SRC|$TOOL_CODEX_SKILLS_DIR_DST|entries"
      echo "$TOOL_CODEX_AGENTSMD_SRC|$TOOL_CODEX_AGENTSMD_DST|file"
      echo "$TOOL_CODEX_CONFIG_SRC|$TOOL_CODEX_CONFIG_DST|file"
      ;;
    *) err "Unknown tool: $name (available: claude, opencode, codex)"; return 1 ;;
  esac
}

# LSP tools that must be installed manually on the host.
# (opencode auto-installs: clangd, bash-language-server, lua-ls.
#  Project-scoped npm deps: typescript, pyright — not checked here.)
# Format: "binary|opencode_server_label|install_hint"
LSP_DEPS=(
  "go|gopls|Install Go: brew install go  (or apt: golang-go)"
  "rust-analyzer|rust|Install rust-analyzer: brew install rust-analyzer  (or: rustup component add rust-analyzer)"
)

# Print a report of missing LSP toolchains for opencode.
check_lsp_deps() {
  local missing=0
  info "Checking LSP toolchains for opencode..."
  for entry in "${LSP_DEPS[@]}"; do
    IFS='|' read -r bin label hint <<< "$entry"
    if command -v "$bin" >/dev/null 2>&1; then
      info "  $TAG_OK      $bin (opencode server: $label)"
    else
      warn "  $TAG_MISSING $bin (opencode server: $label)"
      warn "            -> $hint"
      missing=$((missing+1))
    fi
  done
  if [[ $missing -gt 0 ]]; then
    echo "" >&2
    warn "$missing LSP toolchain(s) missing. opencode will not start those servers until installed."
    warn "Auto-installing servers (clangd, bash, lua-ls) is enabled by default."
    warn "Disable with: export OPENCODE_DISABLE_LSP_DOWNLOAD=true"
  else
    info "All host-required LSP toolchains present."
  fi
}

cmd_pull() {
  local dry_run=false
  [[ "${1:-}" == "--dry-run" ]] && dry_run=true

  info "Pulling Ollama models from settings-ollama.json..."
  for model in "${MODELS[@]}"; do
    if $dry_run; then
      info "Would pull: $model"
    else
      info "Pulling: $model"
      ollama pull "$model"
    fi
  done
  $dry_run || info "All models pulled."
}

# Link every entry of a source directory into a real destination directory,
# one symlink per entry. Args: <tool_name> <src> <dst> [--dry-run]
link_entries() {
  local tool="$1"
  local src="$2"
  local dst="$3"
  local dry_run="${4:-}"
  local entry name target replace_symlink=false

  if [[ -L "$dst" ]]; then
    replace_symlink=true
    warn "Replacing whole-directory symlink with a real directory: $dst"
    if [[ "$dry_run" != "--dry-run" ]]; then
      rm "$dst"
    fi
  elif [[ -e "$dst" && ! -d "$dst" ]]; then
    warn "Existing file at $dst (not a directory). Backing up to ${dst}.bak"
    if [[ "$dry_run" == "--dry-run" ]]; then
      info "Would back up: $dst -> ${dst}.bak"
    else
      mv "$dst" "${dst}.bak"
    fi
  fi

  if [[ ! -d "$dst" ]]; then
    if [[ "$dry_run" == "--dry-run" ]]; then
      info "Would create directory: $dst"
    else
      mkdir -p "$dst"
    fi
  fi

  for entry in "$src"/*; do
    [[ -e "$entry" || -L "$entry" ]] || continue
    name="$(basename "$entry")"
    target="$dst/$name"

    if [[ -L "$target" && "$(readlink "$target")" == "$entry" ]]; then
      info "Already linked ($tool): $target -> $entry"
      continue
    fi

    # In a dry-run migration the old symlink is still in place, so entries seen
    # through it are not real destination entries to back up.
    if ! $replace_symlink && [[ -e "$target" || -L "$target" ]]; then
      warn "Existing entry at $target (not our symlink). Backing up to ${target}.bak"
      if [[ "$dry_run" == "--dry-run" ]]; then
        info "Would back up: $target -> ${target}.bak"
      else
        mv "$target" "${target}.bak"
      fi
    fi

    if [[ "$dry_run" == "--dry-run" ]]; then
      info "Would link ($tool): $target -> $entry"
    else
      ln -sfn "$entry" "$target"
      info "Linked ($tool): $target -> $entry"
    fi
  done

  if $replace_symlink && [[ "$dry_run" == "--dry-run" ]]; then
    return 0
  fi

  # A link into this source whose skill was deleted or renamed upstream.
  for target in "$dst"/*; do
    [[ -L "$target" ]] || continue
    case "$(readlink "$target")" in
      "$src"/*) ;;
      *) continue ;;
    esac
    [[ -e "$target" ]] && continue
    warn "Removing stale link (target gone): $target"
    if [[ "$dry_run" == "--dry-run" ]]; then
      info "Would remove: $target"
    else
      rm "$target"
    fi
  done
}

# Link one src|dst|type entry. Args: <tool_name> <src> <dst> <type> [--dry-run]
link_one() {
  local tool="$1"
  local src="$2"
  local dst="$3"
  local type="$4"
  local dry_run="${5:-}"

  if [[ "$type" == "entries" ]]; then
    if [[ ! -e "$src" && ! -L "$src" ]]; then
      if [[ "$dry_run" == "--dry-run" ]]; then
        info "Would create source dir: $src"
        return 0
      fi
      mkdir -p "$src"
    fi
    link_entries "$tool" "$src" "$dst" "$dry_run"
    return 0
  fi

  local is_dir=false
  [[ "$type" == "dir" ]] && is_dir=true

  # A dir source is created in-repo if missing so the symlink always resolves.
  if $is_dir && [[ ! -e "$src" && ! -L "$src" ]]; then
    if [[ "$dry_run" == "--dry-run" ]]; then
      info "Would create source dir: $src"
    else
      mkdir -p "$src"
    fi
  elif [[ ! -e "$src" && ! -L "$src" ]]; then
    err "Source not found for $tool: $src"
    return 1
  fi

  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    info "Already linked ($tool): $dst -> $src"
    return 0
  fi

  if [[ -e "$dst" || -L "$dst" ]]; then
    if [[ -L "$dst" ]]; then
      warn "Existing symlink at $dst (not pointing to $src). Replacing."
      if [[ "$dry_run" == "--dry-run" ]]; then
        info "Would remove symlink: $dst"
      else
        rm "$dst"
      fi
    else
      warn "Existing file/directory at $dst (not a symlink). Backing up to ${dst}.bak"
      if [[ "$dry_run" == "--dry-run" ]]; then
        info "Would back up: $dst -> ${dst}.bak"
        return 0
      fi
      mv "$dst" "${dst}.bak"
    fi
  fi

  if [[ "$dry_run" == "--dry-run" ]]; then
    info "Would link ($tool): $dst -> $src"
  else
    mkdir -p "$(dirname "$dst")"
    ln -sfn "$src" "$dst"
    info "Linked ($tool): $dst -> $src"
  fi
}

# Link one tool. Args: <tool_name> [--dry-run]
link_tool() {
  local tool="$1"
  local dry_run="${2:-}"

  local pairs failed=0
  if ! pairs="$(resolve_tool "$tool")"; then
    return 1
  fi

  while IFS= read -r pair; do
    [[ -z "$pair" ]] && continue
    local src dst type
    IFS='|' read -r src dst type <<< "$pair"
    if ! link_one "$tool" "$src" "$dst" "$type" "$dry_run"; then
      failed=$((failed+1))
    fi
  done <<< "$pairs"

  return $failed
}

# Parse a comma-separated tool list into an array.
parse_tools() {
  local spec="$1"
  TOOLS=()
  IFS=',' read -r -a parts <<< "$spec"
  for t in "${parts[@]}"; do
    t="${t// /}"  # trim spaces
    [[ -z "$t" ]] && continue
    TOOLS+=("$t")
  done
  if [[ ${#TOOLS[@]} -eq 0 ]]; then
    err "No tools specified."
    return 1
  fi
}

cmd_link() {
  local dry_run="${1:-}"
  local tool_spec="${LINK_TOOLS:-opencode}"

  parse_tools "$tool_spec" || return 1

  local failed=0
  local opencode_linked=false
  for tool in "${TOOLS[@]}"; do
    if ! link_tool "$tool" "$dry_run"; then
      failed=$((failed+1))
    elif [[ "$tool" == "opencode" && "$dry_run" != "--dry-run" ]]; then
      opencode_linked=true
    fi
  done

  # Only run the LSP check on a real (non-dry-run) opencode link
  if [[ "$opencode_linked" == "true" ]]; then
    check_lsp_deps
  fi

  return $failed
}

cmd_all() {
  local dry_run="${1:-}"

  cmd_pull "$dry_run"
  cmd_link "$dry_run"
}

# --- arg parsing ---
DRY_RUN=false
COMMAND=""
LINK_TOOLS=""

ARGS=("$@")
i=0
while [[ $i -lt ${#ARGS[@]} ]]; do
  arg="${ARGS[$i]}"
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    help|pull|link|all) COMMAND="$arg" ;;
    *)
      # First non-command, non-flag arg is the optional tool list for link/all
      if [[ -z "$COMMAND" ]]; then
        err "Unknown argument: $arg"
        usage; exit 1
      fi
      if [[ "$COMMAND" == "link" || "$COMMAND" == "all" ]]; then
        if [[ -n "$LINK_TOOLS" ]]; then
          err "Unexpected extra argument: $arg"
          usage; exit 1
        fi
        LINK_TOOLS="$arg"
      else
        err "Unknown argument: $arg"
        usage; exit 1
      fi
      ;;
  esac
  i=$((i+1))
done

: "${COMMAND:=all}"

DRY_FLAG=""
$DRY_RUN && DRY_FLAG="--dry-run"

case "$COMMAND" in
  help)  usage ;;
  pull)  cmd_pull "$DRY_FLAG" ;;
  link)  cmd_link "$DRY_FLAG" ;;
  all)   cmd_all "$DRY_FLAG" ;;
esac
