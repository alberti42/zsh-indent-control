# zsh-indent-control — core module
#
# Sourced lazily on first Tab press (via widget stub).
# Never loaded at shell startup.

# ── Real widget ───────────────────────────────────────────────────────
# ZLE widget bound to the trigger key (default: Tab / ^I).
#
# Decision logic:
#   - Extract text left of the cursor on the current line.
#   - If only whitespace precedes the cursor → insert cfg.indent_width spaces.
#   - Otherwise → call the original widget that was bound to the trigger key.
#
# Why emulate -L (not -LR): this is a hot-path function (runs on every
# Tab press); we localize options without a full reset (§18).
#
# Inputs:  LBUFFER, KEYMAP (ZLE specials)
# Touches: LBUFFER (mutated on indent) or delegates via zle
function _zsh_indent_control.widget() {
  emulate -L zsh

  local left_of_line=${LBUFFER##*$'\n'}
  local -i indent_width
  indent_width=${_zsh_indent_control[cfg.indent_width]:-2}
  (( indent_width < 0 )) && indent_width=0

  # If only whitespace precedes the cursor, insert spaces (indent).
  if [[ -z ${left_of_line//[[:space:]]/} ]]; then
    LBUFFER+="${(l:${indent_width}:: :)""}"
    return
  fi

  # Fallback: call whatever was originally bound to the trigger key.
  local km="${KEYMAP:-main}"
  local orig_widget="${_zsh_indent_control[state.orig_widget.${km}]:-${_zsh_indent_control[state.orig_widget.main]:-expand-or-complete}}"
  zle "$orig_widget"
}

# ── Compile (best-effort) ─────────────────────────────────────────────
# Compiles both the bootstrap and core to .zwc on first load.
# Subsequent shell starts will source the compiled bytecode directly,
# skipping the text-parsing overhead.
function _zsh_indent_control._compile() {
  emulate -L zsh

  local script compiled
  local -a scripts=(
    "${_zsh_indent_control[meta.plugin_dir]}/zsh-indent-control.plugin.zsh"
    "${_zsh_indent_control[meta.plugin_dir]}/src/zsh-indent-control.zsh"
  )

  for script in "${scripts[@]}"; do
    [[ -r $script ]] || continue
    compiled="${script}.zwc"
    # Compile only when missing or stale.
    if [[ ! -r $compiled || $script -nt $compiled ]]; then
      zcompile -Uz -- "$script" 2>/dev/null || true
    fi
  done
}

_zsh_indent_control._compile
