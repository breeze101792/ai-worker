---
name: webapp-design
description: The web-app design and build playbook — designs, scaffolds, implements, and verifies a new Flask + vanilla JS web app end to end. Use when the user wants a new web app, or when /webapp is invoked.
---

# Web App Design and Build

Build one new web-app project from an empty directory to a running application.
This skill is self-contained. It holds the rules, the procedure, and the fixed
boilerplate. Do not read an external rule file.

## When to use

A new web-app project is needed.

Not for adding a feature to an existing project. Use the project's own
conventions for that.

## The rules

### Core philosophy

Maximum self-containment with minimum tooling. No framework on the frontend,
minimal dependencies on the backend. Prefer explicit code and a simple structure
over abstraction.

### Stack

- **Backend:** Python 3 + Flask, app factory plus blueprints.
- **Frontend:** vanilla HTML, CSS, and JavaScript. No build step, no bundler, no
  transpiler, no CDN dependency.
- **Storage:** the filesystem directly — JSON files or raw `sqlite3`. No ORM, no
  database server.
- **Auth:** custom session auth with hashed passwords. No third-party provider.

### Folder structure

```
project-root/
├── backend/                        # Flask app factory + blueprints
│   ├── app.py                      # create_app(), blueprint registration
│   ├── auth.py                     # session auth, decorators
│   ├── config.py                   # paths, defaults, settings
│   ├── db.py                       # storage layer (file I/O or sqlite)
│   ├── util.py                     # helpers (ok(), err(), etc.)
│   ├── blueprints/                 # route blueprints by resource
│   │   ├── auth.py
│   │   └── resource.py
│   ├── services/                   # business logic (optional)
│   │   └── ...
│   ├── migrations/                 # DB migrations (optional)
│   │   └── ...
│   └── requirements.txt
├── frontend/
│   ├── templates/                  # Jinja2 templates (or static HTML)
│   ├── static/
│   │   ├── css/
│   │   ├── js/
│   │   ├── img/
│   │   ├── vendor/                 # vendored libs (no CDN)
│   │   ├── manifest.json
│   │   └── sw.js
│   └── index.html                  # entry point (or layout.html in templates/)
├── data/                           # mutable runtime data (gitignored)
│   └── .gitkeep
├── docs/                           # design docs, filled in Phase 2
├── tests/
│   ├── test_app.py
│   └── ...
├── start.sh                        # per-host venv launcher
├── .gitignore
├── CLAUDE.md                       # AI assistant instructions
└── README.md                       # overview, setup, usage
```

### Conventions

1. **`start.sh` launcher** — per-host virtualenv (`.venv_$(hostname)`), installs
   dependencies, forwards `PORT`, `HOST`, and `DEBUG`, replaces a running
   instance with `--restart`, and runs the suite with `--test`, both backed by
   a PID file under `data/run/`.
2. **JSON API under `/api/`** — every endpoint returns JSON. Mutations require
   auth; reads may be public.
3. **App factory plus blueprints** — `create_app()` with blueprints organised by
   resource.
4. **Custom auth** — `@login_required` decorators, first-run setup mode,
   `HttpOnly` and `SameSite=Lax` session cookies.
5. **Direct storage** — no ORM. Write atomically through a temporary file and
   `os.replace`. Prevent path traversal with a `safe_path()` helper.
6. **Data separate from code** — config and data live in `config/`, `notebook/`,
   or `data/`, and are gitignored.
7. **Security** — validate input on every endpoint, write atomically, never put
   untrusted data through `innerHTML` (use `textContent`), and handle URLs
   safely.
8. **Frontend fetch wrapper** — one thin `fetch` wrapper with
   `credentials: "same-origin"`, JSON headers, and 401 handling.
9. **Test isolation** — tests point data and config at temporary directories.
   They never touch real data.
10. **Error shape** — every endpoint returns `{ok: true, data: ...}` on success
    or `{ok: false, error: "message"}` on failure. Think through every failure
    case before writing it: missing input, malformed data, auth failure,
    concurrent writes, disk full, network timeout, path traversal, type
    mismatch, and empty state. Catch, log where useful, and return the
    structured error. No endpoint ships without error handling.
11. **Documentation** — `README.md` and `CLAUDE.md` at the root. Design docs go
    under `docs/` as Phase 2 describes. Record why a decision was made, not only
    what it is.

## Phase 1 — Discuss and plan (do not write code)

Ask the user, in one batch:

- purpose — what the app does and why,
- who uses it,
- pages and views,
- data entities,
- auth needed or not,
- anything external it must talk to.

Restate the understanding in a short plan:

- page list,
- entity list,
- endpoint list,
- port.

Stop and wait for the user to confirm the plan. Do not scaffold before
confirmation.

## Phase 2 — Design docs

Load the `project-design` skill and give its rules to each design agent. That
skill defines the folder tree, the module contract template, and the quality
bar. Every agent writes into the same tree.

Dispatch the design agents in this order:

1. `product-designer` — `docs/requirements/`: requirements, scope, functional
   flows, and testable acceptance criteria.
2. `ui-designer` — `docs/ui/`: every page and view with its empty, loading,
   error, and edge states, the design tokens, and a reference HTML/CSS mockup
   under `docs/ui/mockup/`.
3. `architect` — `docs/architecture/` (overview, `data-model.md`, `modules/`)
   and `docs/contracts/api.md`. The API doc carries the `{ok, data/error}` shape
   on every endpoint. The architect also fixes module reuse: one fetch wrapper,
   one auth decorator, one storage layer, one set of error helpers.

Create `docs/security/` when the app has auth or takes untrusted input. Write
`docs/testing/` with the test plan. Keep `docs/README.md` as the single index of
every doc.

Then run one cross-check round. Each agent reviews the other two sets against
its own:

- `product-designer` — every flow and edge case appears in the UI docs and the
  API doc.
- `architect` — every UI state can be produced by the planned endpoints and
  modules, and every endpoint can be implemented from the data model.
- `ui-designer` — every page and state named in the flows has a design.

Report every disagreement to the user. Do not resolve it silently.

Present `docs/README.md` and the tree for review and wait for go-ahead before
implementation.

## Phase 3 — Scaffold

Create the project directory at the path the user gave. A bare name means
`./<name>` in the current working directory. Never assume a fixed parent
directory. The project name is lowercase kebab-case.

Then apply these fixed boilerplate rules.

### `start.sh`

Per-host venv `.venv_$(hostname)`. Installs `backend/requirements.txt`. Runs
`backend/app.py` in the foreground, so the server is whatever that file starts.

`backend/app.py` reads `HOST`, `PORT`, and `DEBUG` from the environment and
starts the server under an `if __name__ == "__main__":` guard. Do not put the
runner in `start.sh`; it must stay server-neutral.

Every option is a flag. `--restart` replaces a running instance, `--test` runs
the suite and exits, `--host` and `--port` override the bind address, and
`--debug` sets `DEBUG=1` and leaves the behaviour to the app. A PID file under
`data/run/` is how `--restart` finds the old instance. Use this exact block,
replacing `<PORT>` with the chosen port:

```bash
#!/usr/bin/env bash
#   ./start.sh                     # defaults: 0.0.0.0:<PORT>, debug off
#   ./start.sh --debug             # run with DEBUG=1
#   ./start.sh --host 127.0.0.1    # bind loopback only
#   ./start.sh --port 8080 --debug
#   ./start.sh --restart           # replace the running instance
#   ./start.sh --test              # run the test suite and exit
#   ./start.sh --help

set -euo pipefail

HOSTNAME="$(hostname)"
VENV=".venv_${HOSTNAME}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$ROOT/data/run/server.pid"
STOP_TIMEOUT=10

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-<PORT>}"
DEBUG="${DEBUG:-0}"
RESTART=false
TEST=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  --host <addr>   bind address (default 0.0.0.0)
  --port <port>   listen port (default <PORT>)
  --debug         enable debug mode (DEBUG=1)
  --restart       stop the running instance, then start a new one
  --test          run the test suite and exit
  -h, --help      show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      [[ $# -ge 2 ]] || { echo "--host needs a value" >&2; exit 2; }
      HOST="$2"; shift 2 ;;
    --port)
      [[ $# -ge 2 ]] || { echo "--port needs a value" >&2; exit 2; }
      PORT="$2"; shift 2 ;;
    --debug) DEBUG=1; shift ;;
    --restart) RESTART=true; shift ;;
    --test) TEST=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

setup_env() {
  if [ ! -d "$VENV" ]; then
    python3 -m venv "$VENV"
  fi

  # shellcheck disable=SC1091
  source "$VENV/bin/activate"

  pip install -q -r backend/requirements.txt
}

run_tests() {
  setup_env
  echo "Running tests"
  exec python -m pytest tests/
}

running_pid() {
  local pid
  [[ -f "$PID_FILE" ]] || return 1
  pid="$(cat "$PID_FILE")"
  [[ -n "$pid" ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  case "$(ps -p "$pid" -o comm= 2>/dev/null || true)" in
    *python*) printf '%s\n' "$pid" ;;
    *) return 1 ;;
  esac
}

stop_server() {
  local pid children child waited=0
  if ! pid="$(running_pid)"; then
    rm -f "$PID_FILE"
    echo "No server running."
    return 0
  fi
  echo "Stopping server (PID $pid)"
  children="$(pgrep -P "$pid" 2>/dev/null || true)"
  kill "$pid" 2>/dev/null || true
  for child in $children; do
    kill "$child" 2>/dev/null || true
  done
  while [[ "$waited" -lt "$STOP_TIMEOUT" ]]; do
    if ! kill -0 "$pid" 2>/dev/null; then
      rm -f "$PID_FILE"
      echo "Stopped."
      return 0
    fi
    sleep 1
    waited=$((waited + 1))
  done
  echo "Server did not stop after ${STOP_TIMEOUT}s, killing."
  kill -9 "$pid" 2>/dev/null || true
  for child in $children; do
    kill -9 "$child" 2>/dev/null || true
  done
  rm -f "$PID_FILE"
}

start_server() {
  local pid
  if pid="$(running_pid)"; then
    if ! $RESTART; then
      echo "Already running (PID $pid). Use --restart to replace it."
      return 1
    fi
    stop_server
  fi

  setup_env
  export HOST PORT DEBUG

  mkdir -p "$(dirname "$PID_FILE")"
  printf '%s\n' "$$" > "$PID_FILE"
  echo "Serving on http://$HOST:$PORT (debug $DEBUG, PID $$)"
  exec python "$ROOT/backend/app.py"
}

cd "$ROOT"
if $TEST; then
  run_tests
fi
start_server
```

### `.gitignore`

Write exactly these lines, one per line:

```
.venv_*/
__pycache__/
*.pyc
data/
.pytest_cache/
```

### `backend/requirements.txt`

Starts as `flask` and `pytest`. Add a package only when a feature needs it.

### `tests/conftest.py`

Must isolate data with `tempfile.mkdtemp()` and env vars set before
`create_app()`. Provide three fixtures:

- `app`,
- `client`,
- `authed` — a client fixture that calls the project's setup and login
  endpoints.

Tests never touch the project's real `data/` directory.

### Placeholders and docs

- `docs/` and `data/` contain `.gitkeep`.
- `README.md` — overview, setup, usage.
- `CLAUDE.md` — stack, folder map, conventions, commands for AI agents.

### `backend/util.py`

Provides `ok(data)` and `err(message, status)`. They return the
`{ok: true, data: ...}` and `{ok: false, error: ...}` JSON shapes.

### `backend/config.py`

Reads the data directory from an env var named `<NAME_UPPER>_DATA_DIR`, where
`<NAME_UPPER>` is the project name uppercased with `-` replaced by `_`. Default
to the project's `data/` directory.

## Port

Pick a port nothing else uses:

1. Read the `PORT` default in sibling `start.sh` files in the project's parent
   directory, when any exist. Do not reuse a port claimed there.
2. Skip a port that is already bound on this host.
3. Otherwise take a free port and write it into `start.sh`.

## Phase 4 — Build

Implement the design with `web-engineer`, in this order:

1. shared modules — fetch wrapper, auth decorator, error helpers,
2. blueprints,
3. pages.

Follow the conventions above. Convention 10 applies to every endpoint.

## Phase 5 — Verify and hand over

1. Run `./start.sh --test`. It must pass.
2. Start `start.sh`. Use `./start.sh --restart` when an older instance is still
   running.
3. Smoke-test the health of each page and endpoint with curl.
4. Confirm no endpoint returns HTML on an API error.
5. Stop the server.
6. Run `code-reviewer` on the new project. Run `security-reviewer` too when the
   app has auth or takes untrusted input. Fix every blocking finding, then run
   the tests again.
7. Report which files were created, the port, and how to run it.

Do not declare done if any test fails, the server does not start, or a blocking
review finding is open.

## Code review checklist

Before declaring the project done, verify:

- **Design match** — the code matches the approved design. Every deviation was
  discussed.
- **Error handling** — every endpoint returns `{ok, error}` on failure. Empty,
  malformed, unauthorised, and not-found cases are handled.
- **Security** — auth gates on every mutation, input validation on every
  endpoint, no `innerHTML` with untrusted data, safe URL handling, path
  traversal prevented.
- **Data integrity** — atomic writes, no partial write on crash, safe
  migrations.
- **No regressions** — the suite passes and new behaviour has tests. Tests use
  isolated temp data.
- **Clean diff** — no unrelated changes, no debug code, no commented-out code.

## What not to do

- Do not write application code before the design docs exist and the user
  approves them.
- Do not add a framework, bundler, CDN, ORM, or database server.
- Do not read an external rule file. Everything needed is in this skill.
- Do not touch sibling projects.
- Do not git commit without user approval.
