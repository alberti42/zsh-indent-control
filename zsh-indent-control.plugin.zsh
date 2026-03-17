#!/usr/bin/env zsh

##############################################
#  zsh-indent-control (c) 2026 Andrea Alberti
##############################################

# ── Bootstrap ────────────────────────────────────────────────────────
# This plugin is a ZLE widget; it has no use outside interactive shells.
[[ -o interactive ]] || return 0

# ── State container ──────────────────────────────────────────────────
# All plugin state lives in one associative array.
# Key scoping convention:
#   cfg.*    user-configurable options (read once at init)
#   state.*  runtime state (original widget snapshots)
#   guard.*  idempotence flags
#   meta.*   paths and metadata
typeset -gA _zsh_indent_control

# Idempotency guard: safe to re-source.
(( ${+_zsh_indent_control[guard.inited]} )) && return 0
_zsh_indent_control[guard.inited]=1

# ── Metadata ─────────────────────────────────────────────────────────
_zsh_indent_control[meta.plugin_dir]=${${(%):-%x}:a:h}

# ── User config (read once; env vars must be set before sourcing) ─────

# cfg.trigger_key: the key to intercept (default: ^I = Tab)
_zsh_indent_control[cfg.trigger_key]='^I'

# cfg.indent_width: number of spaces per indent (default: 2)
_zsh_indent_control[cfg.indent_width]=${ZLE_INDENT_WIDTH:-2}

# cfg.keymaps: Zsh keymaps to bind; "main" is always included.
# ZLE uses "main" during normal line editing; bindkey -e/-v make
# main an alias for emacs/viins.  Other keymaps (isearch, menuselect, vicmd, …)
# are independent and only active in transient contexts.
# Customize only to add extra keymaps (e.g. vicmd).
(){
  local -aU _zic_raw=(${(s:,:)${ZIC_KEYMAPS:-main}} main)
  _zsh_indent_control[cfg.keymaps]="${(j:,:)_zic_raw}"
}

# ── Lazy stub widget ──────────────────────────────────────────────────
# On first Tab: sources the core (which redefines this to the real widget),
# then calls the real widget.  All subsequent Tab presses skip this stub.
function _zsh_indent_control.widget() {
  local _zic_core="${_zsh_indent_control[meta.plugin_dir]}/src/zsh-indent-control.zsh"
  if [[ -r $_zic_core ]] && builtin source "$_zic_core"; then
    _zsh_indent_control.widget
  else
    zle expand-or-complete
  fi
}

zle -N _zsh_indent_control.widget

# ── Keybinding snapshot + bind ────────────────────────────────────────
# Two-pass approach: snapshot first, then rebind.
# Why two passes: some keymaps share underlying bindings, so changing
# one can silently affect others before we snapshot them.
(){
  local keymap binding orig_widget
  local trigger_key="${_zsh_indent_control[cfg.trigger_key]}"
  local -a keymaps=(${(s:,:)${_zsh_indent_control[cfg.keymaps]}})

  # Pass 1: snapshot the widget currently bound to the trigger key.
  for keymap in $keymaps; do
    binding=$(bindkey -M "$keymap" "$trigger_key" 2>/dev/null) || binding=""
    orig_widget="${binding##* }"
    if [[ -n "$binding" && -n "$orig_widget" \
        && "$orig_widget" != "$trigger_key" \
        && "$orig_widget" != "_zsh_indent_control.widget" ]]; then
      _zsh_indent_control[state.orig_widget.${keymap}]="$orig_widget"
    fi
  done

  # Pass 2: bind the trigger key to our widget in all requested keymaps.
  for keymap in $keymaps; do
    bindkey -M "$keymap" "$trigger_key" _zsh_indent_control.widget 2>/dev/null
  done
}
