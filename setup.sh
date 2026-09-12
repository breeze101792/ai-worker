#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Tool registry: name -> one "source|destination|type" line per link target.
# Add new tools here.
#   type=file: symlink a single file
#   type=dir:  symlink a directory (created in-repo if missing)
TOOL_CLAUDE_SRC="$SCRIPT_DIR/claude/settings-ollama.json"
TOOL_CLAUDE_DST="$HOME/.claude/settings.json"
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

MODELS=(
  "deepseek-v4-flash:cloud"
  "deepseek-v4-pro:cloud"
  "glm-5.1:cloud"
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
  all [TOOLS]       Run pull + link (default if no command given)
  help              Show this help message

Options:
  --dry-run         Show what would be done without executing

Examples:
  $(basename "$0") link
  $(basename "$0") link claude
  $(basename "$0") link claude,opencode
  $(basename "$0") all claude,opencode
  $(basename "$0") all claude --dry-run
EOF
}

info()  { echo "[INFO]  $*"; }
warn()  { echo "[WARN]  $*" >&2; }
err()   { echo "[ERROR] $*" >&2; }

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
      echo "$TOOL_CLAUDE_SKILLS_DIR_SRC|$TOOL_CLAUDE_SKILLS_DIR_DST|dir"
      ;;
    opencode)
      echo "$TOOL_OPENCODE_SRC|$TOOL_OPENCODE_DST|file"
      echo "$TOOL_OPENCODE_AGENTSMD_SRC|$TOOL_OPENCODE_AGENTSMD_DST|file"
      echo "$TOOL_OPENCODE_AGENTS_SRC|$TOOL_OPENCODE_AGENTS_DST|dir"
      echo "$TOOL_OPENCODE_SKILLS_SRC|$TOOL_OPENCODE_SKILLS_DST|dir"
      echo "$TOOL_OPENCODE_COMMANDS_SRC|$TOOL_OPENCODE_COMMANDS_DST|dir"
      ;;
    codex)
      echo "$TOOL_CODEX_AGENTS_DIR_SRC|$TOOL_CODEX_AGENTS_DIR_DST|dir"
      echo "$TOOL_CODEX_SKILLS_DIR_SRC|$TOOL_CODEX_SKILLS_DIR_DST|dir"
      echo "$TOOL_CODEX_AGENTSMD_SRC|$TOOL_CODEX_AGENTSMD_DST|file"
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
      info "  [OK]      $bin (opencode server: $label)"
    else
      warn "  [MISSING] $bin (opencode server: $label)"
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

# Link one src|dst|type entry. Args: <tool_name> <src> <dst> <type> [--dry-run]
link_one() {
  local tool="$1"
  local src="$2"
  local dst="$3"
  local type="$4"
  local dry_run="${5:-}"

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
