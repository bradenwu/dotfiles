# Repository Guidelines

## Project Structure & Module Organization
This repository is a modular dotfiles workspace, not an application codebase. Source files live in `configs/`, shared shell helpers in `lib/common.sh`, installer entrypoints in `init/`, and validation in `tests/`. The top-level `install.sh` orchestrates full setup, while `check_env.sh` performs environment checks. Claude Code-related helpers live under `claude/`.

## Build, Test, and Development Commands
There is no build step. Use these commands instead:

- `./install.sh` - interactive full install on a personal machine.
- `./install.sh check` - verify required tools and environment assumptions.
- `bash init/init_tmux.sh` - reinstall one module locally.
- `bash tests/test_common.sh` - run the safety tests for `lib/common.sh`.
- `bash claude/install-skills.sh` - restore the Claude skills registry and related assets.

## Coding Style & Naming Conventions
All executable code is POSIX/Bash shell script. Prefer concise functions, quoted variables, and explicit error handling. Keep indentation to 4 spaces in shell scripts, and use `snake_case` for function names and file names. Follow the existing module pattern: `init_<tool>.sh` for installers, `configs/<name>` for source files, and `switch_cc_to_<target>.sh` for Claude backend toggles.

## Testing Guidelines
The main automated coverage is `bash tests/test_common.sh`, which guards the fail-closed backup and install behavior in `lib/common.sh`. Add or update tests there when changing backup, symlink, or remote-install logic. Keep test names descriptive and shell-safe; prefer small, isolated assertions over broad integration checks.

## Commit & Pull Request Guidelines
Recent history uses short, imperative commits, often prefixed with `feat:` or `chore:`. Follow the same style when practical, and keep each commit focused on one change. Pull requests should describe the behavior change, note any install or migration impact, and include screenshots only when a terminal or UI-visible result matters.

## Security & Configuration Tips
Do not commit generated personal files such as `~/.gitconfig`, `~/.ssh/config`, or `.env`. If you add a sensitive template, also update `.gitignore` and provide a matching `.template` source in `configs/`. For remote installs, preserve the repo’s fail-closed behavior: never replace an existing file until backup has succeeded.
