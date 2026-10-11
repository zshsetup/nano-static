# nano-static

Portable builds of [GNU nano](https://www.nano-editor.org/) with ncurses linked in statically,
built with [zig](https://ziglang.org) as the C toolchain.

- Linux glibc: only glibc is linked dynamically, and only symbols up to glibc 2.17, so the
  binaries run on anything from CentOS 7 onwards
- Linux musl (`--static`): fully static, no runtime dependencies at all (e.g. Alpine)
- macOS: only libSystem is dynamic (it ships with macOS, which has no fully static binaries)

Common terminal descriptions (xterm, xterm-256color, screen, screen-256color, tmux, tmux-256color,
linux, vt100, vt220, rxvt, alacritty, kitty, foot, wezterm, ...) are compiled into ncurses, so
nano works even on systems without a terminfo database. The system database is still used
first, from `/etc/terminfo`, `/lib/terminfo`, `/usr/share/terminfo`, and `/usr/lib/terminfo`, or
from `$TERMINFO`, `$TERMINFO_DIRS`, and `~/.terminfo`.

Translations (`--disable-nls`) and file type detection with libmagic are disabled, as they would
need more libraries.

## Prerequisites

- `zig`, GNU make (the `make` 3.81 of macOS is enough), `perl`, `git`
- `autoconf`, `automake`, `autopoint` (gettext), `libtool`, and `pkg-config` (the git tree of nano
  ships no `configure` script, and its `autogen.sh` imports gnulib)
- On macOS: Xcode Command Line Tools (SDK)

## Installation

Clone the repo with submodules (shallow, the history of the vendored projects is not needed):

```shell
git clone --recurse-submodules --shallow-submodules https://github.com/zshsetup/nano-static
cd nano-static
```

## Usage

```shell
./build.sh
```

This builds ncurses from `vendor/` as static libraries, then builds nano against them. Output is
installed under `dist/`:

- `dist/bin/nano`: the binary; copy it anywhere on your `PATH`
- `dist/share/man`: the man pages of nano, rnano, and nanorc
- `dist/share/nano`: the syntax definitions; nano looks for them in `/usr/local/share/nano`, so
  when installing elsewhere, add `include "<prefix>/share/nano/*.nanorc"` to `~/.nanorc`

Pass `--static` for the fully static musl build on Linux (output in `dist-static/`), `--clean` to
remove previous build output first, and `--jobs N` to control parallelism.

To run the smoke tests against the build:

```shell
./tests/run_smoke_tests.sh            # dist/
./tests/run_smoke_tests.sh --static   # dist-static/
```

## Releases

Publishing a GitHub release tagged with the nano version (e.g. `v9.2`, matching the tag checked out
in `vendor/nano`) builds and attaches `nano-static-<platform>.tar.gz` for `macos-arm64`,
`linux-amd64`, `linux-arm64`, `linux-musl-amd64`, and `linux-musl-arm64`, together with the sources
they were built from (`nano-static-sources.tar.gz`).

To update a vendored project, check out a new release tag in its submodule and commit it, e.g.
`git -C vendor/nano fetch --depth 1 origin tag v9.3 && git -C vendor/nano checkout v9.3`; the commit
of gnulib is the one in `autogen.sh` of nano.

## Acknowledgments

This repository builds and vendors the following upstream projects, unmodified, as git
submodules under `vendor/`. Credit goes to their respective authors:

- [GNU nano](https://www.nano-editor.org/) by the Free Software Foundation and contributors
- [GNU gnulib](https://www.gnu.org/software/gnulib/) by the Free Software Foundation
- [ncurses](https://invisible-island.net/ncurses/) by Thomas E. Dickey and the Free Software
  Foundation

## License

MIT for the code in this repository. See `NOTICE` for the licenses of the upstream projects and the
resulting binaries, which are GPL-3.0-or-later (nano).
