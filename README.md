# zsh-indent-control

A tiny Zsh plugin that makes Tab behave nicely at the start of a line.

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
- If there’s any real text before the cursor: falls back to your normal Tab behavior.

It tries hard to preserve your existing setup and play well with completion frameworks.

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
