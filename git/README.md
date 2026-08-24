# git

```
shared    tracked — tool and display settings, identity-independent
ignore    tracked — global gitignore, symlinked to ~/.config/git/ignore
```

`~/.gitconfig` is **not** tracked. It holds identity and the gh credential helper,
and this repo is public. `bin/setup` writes the identity by asking for a name and
email; `bin/sync` puts the `[include]` on top:

```gitconfig
[include]
	path = ~/dotfiles/git/shared

[user]
	name = ...
	email = ...
```

## `[include]` goes first on purpose

git lets later values win. With the include at the top, repeating any key below it
overrides the shared setting **on that machine only** — which is the escape hatch
that makes a shared file safe to depend on.

Put it at the bottom and the shared file would instead override local intent,
which is backwards. That is why `sync` *prepends* the line instead of appending
it, unlike the zsh reference lines it appends to `~/.zshrc`.

## `sync` owns that one line

Only `sync` writes the include, and it checks for it on every run — asking git for
`include.path` rather than grepping, so `~`, absolute, and relative spellings all
count as present.

This exists because of one silent failure. A machine that had a `~/.gitconfig`
*before* it knew about this repo keeps it: `setup` sees the file, skips it, and the
include never appears. Nothing errors — `git/shared` simply has no effect, so delta
never renders a diff and `git ds` is not a command. It stays invisible until
someone compares two machines by hand.

## What belongs in `shared`

Only settings that are identity-independent and machine-independent:

- `core.pager` / `interactive.diffFilter` — delta
- `delta.*` — navigate, line numbers, OSC 8 hyperlinks, syntax theme
- `merge.conflictstyle = zdiff3` — shows the common ancestor in conflict blocks,
  so you do not have to guess which side changed what (git 2.35+)
- `diff.colorMoved` — colors moved lines as moves rather than delete+add, which
  keeps refactoring diffs readable

`delta.syntax-theme` is tied to the terminal being light. If the theme goes dark,
this changes too — see `ghostty/README.md`.

## Why the credential block stays out

`gh auth setup-git` writes the `[credential "https://github.com"]` block into
`~/.gitconfig` and manages it there. Moving it into `shared` would not stick — gh
rewrites its own copy, leaving two. It also hardcodes an absolute path to the gh
binary, which is machine-specific.

## The global ignore needs no config

`~/.config/git/ignore` is git's XDG default location, so a symlink is enough —
`core.excludesFile` does not need to be set. Verified against a repository with no
`.gitignore` of its own.
