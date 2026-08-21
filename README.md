# dotfiles

Personal configuration shared across machines (macOS).

```
bin/setup      First-time setup on a new machine — run once, right after clone
bin/sync       Bring an already-configured machine up to date
nvim/          Markdown workbench (Neovim 0.12)
ghostty/       Terminal
zsh/           Shell
git/           Shared git config + global ignore
Brewfile       Every external tool the above depends on
```

Two mechanisms, chosen by whether anything else writes to the file:

- **Symlinked** — `~/.config/nvim`, `~/.config/ghostty`, `~/.config/git/ignore`. Nothing but this repo touches those, so the repo owns
  them outright.
- **Referenced** — `~/.zshenv`, `~/.zprofile`, `~/.zshrc`, `~/.gitconfig` stay real
  local files that `source` (or `[include]`) the shared version. Installers append
  to these constantly — OrbStack, nvm, conda, rustup — and OrbStack's own comment
  says *"This won't be added again if you remove it."* A repo that owned those
  files would silently destroy such lines. Appending a reference destroys nothing,
  which is why `sync` can fix them without asking.

**The scripts are the source of truth.** These documents explain *why*; when a
document and a script disagree, the script is right. Do not hand-execute a
procedure that `bin/setup` or `bin/sync` already performs.

Both are Python and run on **Homebrew's** Python, never the system one — the
CLT's 3.9 is an Apple byproduct that is already end-of-life, and pinning to brew
keeps both machines on the same interpreter. `bin/setup` installs Homebrew and
that Python if missing, creates `.venv`, and re-executes itself there; `bin/sync`
uses that environment and tells you to run `setup` first if it is absent.
Dependencies are pinned in `bin/requirements.txt` (just `rich`, for the output).

Every answer `setup` would ask for can be given as a flag instead, so it can run
unattended — see `bin/setup --help`. Add `-v` to either script to see the full
output of anything that failed.

## New machine

```bash
git clone https://github.com/hoemoon/dotfiles.git ~/dotfiles
~/dotfiles/bin/setup
```

That is the whole procedure. **`setup` asks everything up front, then runs to
completion without stopping.** The questions are numbered so you know how many are
left, and anything already configured is not asked about at all — a second run on
a finished machine asks nothing.

What it may ask: git name and email, whether this machine does App Store Connect
releases, whether to install `macism` (which requires trusting a third-party brew
tap), whether to move an existing Ghostty config aside, and whether to log in to
GitHub.

Two things sit outside that block by necessity. Installing Homebrew needs an admin
password, so it happens *before* the questions; `gh auth login` needs a browser, so
it happens *last*. `brew bundle` may also prompt for a password when installing
casks.

```bash
# unattended, for a second machine or a rebuild
~/dotfiles/bin/setup --name "..." --email "..." --no-asc --macism --no-gh
```

Two things `setup` cannot do, reported at the end only when they apply: copying
the ASC private key (`.p8`) from another machine, and registering the Issuer ID in
the Keychain, which only works from a GUI terminal session.

## Updating an existing machine

```bash
~/dotfiles/bin/sync
```

Pulls, creates any missing symlinks, and reconciles the Brewfile. Safe to re-run.
**It never overwrites anything it did not create** — if a real file occupies a
target path, or a symlink points elsewhere, it warns and moves on, because that is
a decision for a human. Exits 1 when something needs attention.

This is exactly the gap `git pull` leaves. Because the symlinks point into the
repository, **edits to existing files take effect from the pull alone.** What a
pull cannot do is (1) create links for files newly added to the repo and
(2) install newly declared Brewfile entries. `sync` does those two things.

## Where to look

| If you are… | Read |
|---|---|
| debugging Ghostty theme, font, or a config that seems ignored | [ghostty/README.md](ghostty/README.md) |
| touching the shell — plugins, PATH, env vars, startup time, completion | [zsh/README.md](zsh/README.md) |
| dealing with git identity, the diff pager, or credential helpers | [git/README.md](git/README.md) |
| editing in nvim — LSP, formatters, notes, keymaps | [nvim/README.md](nvim/README.md) |
| switching the color theme (it lives in three files) | [ghostty/README.md](ghostty/README.md) |
| wondering why a value is empty in a script but fine in the terminal | [zsh/README.md](zsh/README.md) |

## Why not track `~/.config` itself

`~/.config` holds more than fifteen directories belonging to other tools — `gh/`,
`github-copilot/`, `configstore/` and friends. Even when no credentials are
visible today, **there is no control over which tool drops a token there
tomorrow.** A whitelist `.gitignore` does not help: one `git add -f` leaks it.
Keeping the repository outside `~/.config` removes that risk structurally.

The same reasoning keeps `~/.zshenv` and `~/.gitconfig` untracked — they carry
identity and machine-bound values, and this repository is public. `bin/setup`
writes them locally.
