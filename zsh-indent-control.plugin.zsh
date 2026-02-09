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

# ── Widget ───────────────────────────────────────────────────────────
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
    _zsh_indent_control.debug.log "indent: inserted ${indent_width} spaces"
    return
  fi

  # Fallback: call whatever was originally bound to the trigger key
  # in the active keymap.  $KEYMAP is often "main" (not "emacs"/"viins").
  local km="${KEYMAP:-main}"
  local orig_widget="${_zsh_indent_control[state.orig_widget.${km}]}"
  if [[ -z "$orig_widget" && "$km" != "main" ]]; then
    orig_widget="${_zsh_indent_control[state.orig_widget.main]}"
  fi

  if [[ -n "$orig_widget" && "$orig_widget" != "_zsh_indent_control.widget" ]]; then
    _zsh_indent_control.debug.log "fallback: $orig_widget (keymap=$km)"
    zle "$orig_widget"
  else
    _zsh_indent_control.debug.log "fallback: expand-or-complete (keymap=$km)"
    zle expand-or-complete
  fi
}

# ── Init ─────────────────────────────────────────────────────────────
# Reads user config, registers the widget, and bootstraps keybindings.
# Idempotent: guarded so re-sourcing is safe (§11).
#
# Why emulate -LR: this is a one-shot function (not hot-path), so a full
# option reset gives us a predictable environment (§18).
function _zsh_indent_control.init() {
  (( ${+_zsh_indent_control[guard.inited]} )) && return 0

  builtin emulate -LR zsh
  builtin setopt warn_create_global no_short_loops

  _zsh_indent_control[guard.inited]=1

  # ── metadata ──
  _zsh_indent_control[meta.plugin_dir]=${${(%):-%x}:a:h}

  # ── user config (read once; env vars must be set before sourcing) ──

  # cfg.trigger_key: the key to intercept (default: ^I = Tab)
  _zsh_indent_control[cfg.trigger_key]='^I'

  # cfg.indent_width: number of spaces per indent (default: 2)
  _zsh_indent_control[cfg.indent_width]=${ZLE_INDENT_WIDTH:-2}

  # cfg.debug_mode: enable trace output to stderr (default: off)
  _zsh_indent_control[cfg.debug_mode]=${ZIC_DEBUG:-0}

  # cfg.keymaps: Zsh keymaps to bind; "main" is always included
  local -a _zic_raw=(${(s:,:)${ZIC_KEYMAPS:-main}})
  _zic_raw+=(main)
  _zsh_indent_control[cfg.keymaps]="${(j:,:)${(u)_zic_raw}}"

  # ── debug logger ──
  # No-op by default; replaced with a real logger when cfg.debug_mode=1.
  if (( _zsh_indent_control[cfg.debug_mode] )); then
    function _zsh_indent_control.debug.log() {
      builtin print -u2 "[zsh-indent-control] $*"
    }
  else
    function _zsh_indent_control.debug.log() { return 0 }
  fi

  # ── register widget ──
  zle -N _zsh_indent_control.widget

  # ── bootstrap keybindings ──
  # Two-pass approach: snapshot first, then rebind.
  # Why two passes: some keymaps share underlying bindings, so changing
  # one can silently affect others before we snapshot them.
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

  _zsh_indent_control.debug.log "init: keymaps=${_zsh_indent_control[cfg.keymaps]}" \
    "indent_width=${_zsh_indent_control[cfg.indent_width]}"
}

# ── Self-init (§11: module calls its own init at EOF) ────────────────
_zsh_indent_control.init
