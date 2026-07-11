# wd — warp directory for fish

`wd` (warp directory) lets you jump to custom directories in [fish](https://fishshell.com),
without using `cd`. Because `cd` seems inefficient when the folder is frequently
visited or has a long path.

This is a [fish](https://fishshell.com) port of the zsh plugin
[`mfaerevaag/wd`](https://github.com/mfaerevaag/wd), installable via
[fisher](https://github.com/jorgebucaran/fisher).

## Install

With [fisher](https://github.com/jorgebucaran/fisher):

```fish
fisher install ehlxr/fish-wd
```

Or install from a local clone:

```fish
fisher install /path/to/fish-wd
```

## Usage

- Add a warp point to the current working directory:

  ```fish
  wd add foo
  ```

  If a warp point with the same name exists, use `wd add foo --force` to overwrite it.

  Note: a warp point cannot contain colons or slashes, cannot consist of only
  dots, and cannot be a reserved command name.

- Add a warp point with the current directory's name:

  ```fish
  wd add
  ```

- Add a warp point to any directory with a custom name:

  ```fish
  wd addcd /path/to/dir bar
  ```

  Omit the name to use the directory's own name:

  ```fish
  wd addcd /path/to/dir
  ```

- Warp to `foo` from anywhere:

  ```fish
  wd foo
  ```

- Warp to a directory within `foo` (with autocompletion):

  ```fish
  wd foo some/inner/path
  ```

- Warp to a parent directory using dot syntax:

  ```fish
  wd ..     # up one level
  wd ...    # up two levels
  ```

- Remove a warp point (omit the name to use the current directory's name):

  ```fish
  wd rm foo
  ```

- List all warp points (stored in `~/.warprc` by default):

  ```fish
  wd list
  ```

- List files in a given warp point:

  ```fish
  wd ls foo
  ```

- Show the path of a given warp point:

  ```fish
  wd path foo
  ```

- Open a warp point in the file explorer (`open` / `xdg-open`):

  ```fish
  wd open foo
  ```

- Show warp points that point to the current directory, or the path for a
  given point:

  ```fish
  wd show
  wd show foo
  ```

- Remove warp points to nonexistent directories (use `--force` to skip the
  confirmation prompt):

  ```fish
  wd clean
  wd clean --force
  ```

- Print usage info (also shown when calling `wd` with no command):

  ```fish
  wd help
  ```

- Print the version:

  ```fish
  wd --version
  ```

- Use a specific config file (useful for testing):

  ```fish
  wd --config ./file <command>
  ```

- Silence all output:

  ```fish
  wd --quiet <command>
  ```

## Configuration

Set the `WD_CONFIG` environment variable to change where warp points are
stored. Defaults to `$HOME/.warprc`.

```fish
set -gx WD_CONFIG $HOME/.config/warprc
```

## Credits

Based on the original zsh plugin by [@mfaerevaag](https://github.com/mfaerevaag/wd).

## License

[MIT](LICENSE)
