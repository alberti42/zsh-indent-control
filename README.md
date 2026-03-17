# zsh-indent-control

A tiny Zsh plugin that makes Tab behave nicely at the start of a line — loads in ~2 ms.

Turn leading Tab into spaces.

When your cursor is still in the “leading” (indentation) area at the beginning of the line (meaning there are only spaces/tabs before it on the current line), pressing Tab inserts a fixed number of spaces. Everywhere else, Tab keeps doing whatever it already did in your shell (completion, suggestions, etc.).

## Why you might want this

If you often write multi-line commands, paste snippets, or format blocks by hand in the terminal, you’ve probably hit this annoyance:

- You want Tab to indent
- But Zsh/your terminal may instead insert a literal tab character (\t), often displayed as a big jump (commonly 8 columns).

It’s not obvious how to make ZLE insert a fixed number of spaces instead of a literal tab. This is where this plugin steps in: it makes Tab context-aware:

- Indent with spaces when you’re clearly indenting
- Otherwise, don’t get in the way

## What it does (in plain terms)

- If there’s only whitespace before the cursor on the current line: inserts spaces (you choose how many).
- If there’s any real text before the cursor: hands control back to whatever widget was bound to Tab before this plugin loaded.

At load time the plugin snapshots the existing Tab binding (e.g. `expand-or-complete`, `fzf-tab`, or any other completion widget) and stores it. When Tab is pressed outside the indentation area, the plugin simply calls that stored widget — so completion keeps working exactly as before.

## Install

### Oh My Zsh (as a custom plugin)

1. Clone into your custom plugins folder:

   ```sh
   git clone https://github.com/alberti42/zsh-indent-control.git \
     ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-indent-control
   ```

2. Add it to your plugins list in `~/.zshrc`:

   ```sh
   plugins=(... zsh-indent-control)
   ```

3. Reload your shell:

   ```sh
   source ~/.zshrc
   ```

### Zinit

```zsh
# Import zsh-indent-control
zinit lucid wait'0c' from'gh-r' extract'!' light-mode \
  atinit:"export ZLE_INDENT_WIDTH=2" compile \
  for @alberti42/zsh-indent-control
```

The `wait'0c'` delay is intentional. This plugin works by snapshotting whatever is bound to Tab at load time, then calling that widget when Tab is pressed outside the indentation area. It must therefore load *after* any plugin that binds to Tab — in particular `fzf-tab` (if installed), which always installs its own Tab widget and never passes control to a previously bound widget. Loading last ensures the snapshot captures the final Tab binding and completion keeps working correctly.

### Manual install (source the file)

Clone anywhere and source the plugin file from your `~/.zshrc`:

```sh
source /path/to/zsh-indent-control/zsh-indent-control.plugin.zsh
```

## Configuration

### Indentation width

Set how many spaces to insert when indenting:

```sh
export ZLE_INDENT_WIDTH=2
```

Put it in `~/.zshrc` before the plugin is loaded.

### Keymaps

Most users do not need to touch this setting. ZLE uses the `main` keymap during normal line editing. `bindkey -e` (Emacs) and `bindkey -v` (vi) work by making `main` an alias for `emacs` or `viins` respectively, so binding to `main` is sufficient for normal editing in either mode.

Other keymaps (`isearch`, `menuselect`, `vicmd`, etc.) are independent — they are only active in special transient contexts (incremental search, completion menus, vi command mode) where Tab-indent is typically not useful.

The only reason to customize is if you want Tab-indent in one of those additional keymaps:

- `vicmd` — vi command mode (entered by pressing Escape in vi insert mode).
- Custom keymaps created by you or other plugins.

```sh
export ZIC_KEYMAPS='main,vicmd'
```

`main` is always included even if omitted from the list.

## Notes

- This plugin only changes what Tab does at the very start of a line (the indentation area).
- When you’re not indenting, it preserves your original Tab behavior for the active key mode.
- Works with common Zsh key modes (Emacs and Vi).
- This is not an auto-indent plugin: it does not analyze code or reformat lines; it only inserts a fixed number of spaces.

## Author
- **Author:** Andrea Alberti
- **GitHub Profile:** [alberti42](https://github.com/alberti42)
- **Donations:** [![Buy Me a Coffee](https://img.shields.io/badge/Donate-Buy%20Me%20a%20Coffee-orange)](https://buymeacoffee.com/alberti)

Feel free to contribute to the development of this plugin or report any issues in the [GitHub repository](https://github.com/alberti42/Zsh-Opencode-Tab/issues).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
