#!/usr/bin/env zsh

##############################################
#  zsh-indent-control (c) 2026 Andrea Alberti
##############################################

# Create a keymap to organize the variables of this zsh plugin
typeset -gA _zsh_indent_control
_zsh_indent_control[bindkey.key]='^I'
_zsh_indent_control[indent.width]=${ZLE_INDENT_WIDTH:-2}

# Define widget early
_zsh_indent_control_or_fallback() {
  emulate -L zsh

  local left_of_line=${LBUFFER##*$'\n'}
  local -i indent_width
  indent_width=${_zsh_indent_control[indent_width]:-2}
  (( indent_width < 0 )) && indent_width=0
   
  # Remove ALL whitespace; if nothing remains, we're in "indentation only"
  if [[ -z ${left_of_line//[[:space:]]/} ]]; then
    LBUFFER+="${(l:${indent_width}:: :)""}"
    return
  fi

  # Fallback to whatever was originally bound to the trigger key in the current keymap.
  # Note: $KEYMAP is often "main" (not "emacs"/"viins").
  local km="${KEYMAP:-main}"
  local orig_widget="${_zsh_indent_control[orig_widget_$km]}"
  if [[ -z "$orig_widget" && "$km" != "main" ]]; then
    # If orig was empty, but $KEYMAP was not main,
    # then try again with main
    orig_widget="${_zsh_indent_control[orig_widget_main]}"
  fi

  if [[ -n "$orig_widget" && "$orig_widget" != "_zsh_indent_control_or_fallback" ]]; then
    # Call the original widget bound to the trigger key
    zle "$orig_widget"
  else
    zle expand-or-complete
  fi
}

# Register the widget
zle -N _zsh_indent_control_or_fallback

# Saves original binding per keymap; binds trigger key to _zsh_indent_control_or_fallback.
# We don't assume any specific completion plugin; we preserve whatever was bound.
(){
  local keymap binding orig_widget bindkey_key
  bindkey_key="${_zsh_indent_control[bindkey.key]}"
  if [[ -z "$bindkey_key" ]]; then
    bindkey_key='^I'
    _zsh_indent_control[bindkey.key]="$bindkey_key"
  fi
  
  local -a keymaps=(main emacs viins vicmd visual)

  # First pass: snapshot what is currently bound.
  # This must happen before we bind anything, because some keymaps can share
  # underlying bindings (so changing one can affect others).
  for keymap in $keymaps; do
    binding=$(bindkey -M "$keymap" "$bindkey_key" 2>/dev/null) || binding=""
    orig_widget="${binding##* }"
    if [[ -n "$binding" && -n "$orig_widget" && "$orig_widget" != "$bindkey_key" && "$orig_widget" != "_zsh_indent_control_or_fallback" ]]; then
      _zsh_indent_control[orig_widget_$keymap]="$orig_widget"
    fi
  done

  # Second pass: bind the trigger key in all common keymaps.
  for keymap in $keymaps; do
    bindkey -M "$keymap" "$bindkey_key" _zsh_indent_control_or_fallback 2>/dev/null
  done
}
