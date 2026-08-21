# zsh

Three files, split by *when zsh reads them*. Getting this wrong is the most
common way for configuration to look present but be invisible.

| Local file | Sources | Read by | Holds |
|---|---|---|---|
| `~/.zshenv` | `zsh/env.zsh` | **every** zsh — scripts, `zsh -c`, non-interactive | PATH, environment variables |
| `~/.zprofile` | `zsh/profile.zsh` | login shells, once | `brew shellenv`, PATH precedence |
| `~/.zshrc` | `zsh/rc.zsh` | interactive shells | plugins, completion, history, aliases, keybindings |

**The local files are not symlinks, and that is deliberate.** They are the files
every installer appends to — OrbStack, nvm, conda, rustup, gcloud. OrbStack even
states *"This won't be added again if you remove it."* If the repo owned
`~/.zprofile`, adopting these dotfiles on a machine would silently delete that
line and break the OrbStack CLI with no way to notice.

So each local file is real, machine-specific, and carries one `source` line
pointing at the shared version. Installer lines and this repo's config coexist.
`bin/sync` only checks that the `source` line is present and appends it if not —
appending destroys nothing, so it never has to stop and ask.

Anything edited in `~/.zshrc` stays on that machine. To change both machines,
edit `zsh/rc.zsh`.

`~/.zsh_plugins.txt` does not exist: `antidote load` takes the bundle path
directly, so `rc.zsh` points it at `zsh/zsh_plugins.txt` in the repo. The
generated static bundle lands in `~/.zsh_plugins.zsh`, which is machine-local by
nature — it contains absolute paths.

## Machine-bound values live in `~/.zshenv`, below the source line

The shared half (`zsh/env.zsh`) carries PATH and `ARCHIVE_DIR` — same on every
machine, no secrets. Anything bound to one machine goes in the local file under
the `source` line, because this repo is public. `bin/setup` writes it:

```zsh
# ~/.zshenv — read by every zsh. No output, no slow work.
source ~/dotfiles/zsh/env.zsh

export ASC_KEY_ID=... ASC_KEY_PATH=...
[[ -n $ASC_ISSUER_ID ]] || export ASC_ISSUER_ID="$(security find-generic-password -s ASC_ISSUER_ID -w 2>/dev/null)"
```

**It has to be `.zshenv`, not `.zshrc`.** `.zshrc` is read *only by interactive
shells*, so a non-interactive call such as `zsh -c "ship ..."`, a script, or a
launchd job would see none of these values. That failure is silent: the variable
is simply empty.

The `ASC_ISSUER_ID` line guards on the variable already being set so nested shells
skip the Keychain lookup — the parent exports it, children inherit it.

> The Keychain read only works in a GUI (Aqua) session. Over SSH, in a launchd
> job, or inside an agent shell, `security` cannot unlock the login keychain and
> returns empty with rc=36. That is not a broken Keychain item.

## PATH is set in two places on purpose

`.zshenv` puts `~/.local/bin` first so non-interactive shells can find `ship`,
`uia`, and friends. Then `.zprofile` runs `brew shellenv`, which prepends
Homebrew — so `.zprofile` re-asserts `~/.local/bin` afterwards.

`typeset -U path PATH` makes that a move rather than an append, so the entry never
appears twice. Without it, PATH grew a duplicate on every nested shell.

This ordering matters: `ship`, `uia`, and `tiny-press` exist both in
`~/.local/bin` and as brew formulae. The wrong precedence runs the wrong binary.

## Everything external is guarded

antidote, fzf, and eza are each called only when present. On a machine where
`brew bundle` has not run yet, the shell still starts cleanly — you lose plugins
and the `ls` aliases, but nothing errors. The prompt is not in that list: it is
plain zsh with no external process, so it works on a bare machine.

The antidote path follows `HOMEBREW_PREFIX` (exported by `brew shellenv` in
`.zprofile`, which runs first), so it resolves on Intel Macs at `/usr/local` too.
Hardcoding `/opt/homebrew` made this fail *silently* there — the guard swallowed
it and plugins just never loaded.

fzf is guarded on `[[ -t 0 ]]`, not on the `zle` option. A tty-less interactive
shell (`zsh -i -c ...`) still has `zle` on, so that guard never fired and fzf
printed `can't change option: zle` twice on every such invocation.

## Plugins

`zsh_plugins.txt` is tracked; the plugins themselves are not. antidote clones them
into `~/.zsh/plugins` on first shell start and regenerates the static bundle
whenever the list is newer.

**`ANTIDOTE_HOME` is deliberately moved off its default of `~/Library/Caches`.**
An OS cache purge deletes the plugins but leaves the generated
`~/.zsh_plugins.zsh` behind — every shell then sources missing paths and errors,
and antidote does not repair itself because the `.txt` is not newer than the
bundle. This was reproduced accidentally while moving the directory.

Three plugins, chosen by measurement:

- `zsh-autosuggestions` — no built-in equivalent
- `zsh-completions` — adds to `fpath` only, effectively free
- `zsh-syntax-highlighting` — kept over `fast-syntax-highlighting`, which costs
  2.2× to load (+10.5 ms). "Fast" refers to redraw speed while typing, not startup.

History prefix search uses the built-in `up-line-or-beginning-search` widget
rather than a plugin; substring search anywhere in the line is fzf's `Ctrl-R`.

## compinit is cached for 24 hours

A full `compinit` security scan costs ~27 ms, the single largest startup item. The
dump is rebuilt only when it is more than a day old; otherwise `compinit -C` skips
the check, saving ~18 ms.

The cost: **a newly installed completion may not appear for up to a day.** To pick
it up immediately:

```zsh
rm ~/.zcompdump && exec zsh
```

## Terminal integration

Ghostty injects its shell integration only into shells it spawns *directly* —
not into zellij or tmux panes, not into `exec zsh`. Since zellij is in daily use,
`rc.zsh` sources the integration explicitly when `GHOSTTY_RESOURCES_DIR` is set.
Re-sourcing in a directly-spawned shell is harmless; the script guards itself with
`_ghostty_state`.

Without this, panes lose prompt marking and new splits do not inherit the working
directory.
