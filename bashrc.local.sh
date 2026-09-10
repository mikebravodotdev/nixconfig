# Managed by nix-darwin via configuration.nix — edit bashrc.local.sh in the
# nixconfig repo, not this generated file directly.
#
# Ported from Omarchy (https://omarchy.org) default/bash/* configuration,
# adapted for macOS/Homebrew+Nix instead of Arch/pacman. Skipped: anything
# Linux-only (drive formatting, the xdg-open wrapper — macOS already has a
# native `open`) or tied to Omarchy's own `omarchy` CLI dispatcher.

# --- Environment ---
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export BAT_THEME=ansi
export MANROFFOPT="-c"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export STARSHIP_CONFIG=/etc/starship.toml

# --- History ---
shopt -s histappend
HISTCONTROL=ignoreboth
HISTSIZE=32768
HISTFILESIZE="${HISTSIZE}"

# --- File system ---
if command -v eza &> /dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias ll='eza -l --icons'
  alias la='eza -la --icons'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

if command -v fzf &> /dev/null && command -v bat &> /dev/null; then
  alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
  alias eff='$EDITOR "$(ff)"'
fi

# Send the most recently modified file under the current dir via scp,
# picked interactively with fzf. Usage: sff host:/tmp/
sff() {
  if [ $# -eq 0 ]; then echo "Usage: sff <destination> (e.g. sff host:/tmp/)"; return 1; fi
  local file
  file=$(find . -type f -exec stat -f '%m%t%N' {} \; | sort -rn | cut -f2- | ff) && [ -n "$file" ] && scp "$file" "$1"
}

if command -v zoxide &> /dev/null; then
  alias cd="zd"
  zd() {
    if (( $# == 0 )); then
      builtin cd ~ || return
    elif [[ -d $1 ]]; then
      builtin cd "$1" || return
    else
      if ! z "$@"; then
        echo "Error: Directory not found"
        return 1
      fi
      printf "\U000F17A9 "
      pwd
    fi
  }
fi

# --- Directories ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# --- Compression ---
compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }
alias decompress="tar -xzf"

# --- Git ---
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

# Create a new worktree and branch from within the current git directory.
ga() {
  if [[ -z "$1" ]]; then
    echo "Usage: ga [branch name]"
    return 1
  fi

  local branch="$1"
  local base="$(basename "$PWD")"
  local wt_path="../${base}--${branch}"

  git worktree add -b "$branch" "$wt_path"
  command -v mise &> /dev/null && mise trust "$wt_path"
  cd "$wt_path"
}

# Remove the worktree and branch from within an active worktree directory
# created by `ga` (expects a "<root>--<branch>" directory name).
gd() {
  if command -v gum &> /dev/null && gum confirm "Remove worktree and branch?"; then
    local cwd base branch root worktree

    cwd="$(pwd)"
    worktree="$(basename "$cwd")"
    root="${worktree%%--*}"
    branch="${worktree#*--}"

    if [[ "$root" != "$worktree" ]]; then
      cd "../$root"
      git worktree remove "$cwd" --force || return 1
      git branch -D "$branch"
    fi
  fi
}

# --- SSH port forwarding ---
fip() {
  (( $# < 2 )) && echo "Usage: fip <host> <port1> [port2] ..." && return 1
  local host="$1"
  shift
  for port in "$@"; do
    ssh -f -N -L "$port:localhost:$port" "$host" && echo "Forwarding localhost:$port -> $host:$port"
  done
}

dip() {
  (( $# == 0 )) && echo "Usage: dip <port1> [port2] ..." && return 1
  for port in "$@"; do
    pkill -f "ssh.*-L $port:localhost:$port" && echo "Stopped forwarding port $port" || echo "No forwarding on port $port"
  done
}

# Note: macOS's BSD pgrep has no -a flag (Linux procps-only); -fl is the
# closest equivalent (match full command line, print pid + command name).
lip() {
  pgrep -fl "ssh.*-L [0-9]+:localhost:[0-9]+" || echo "No active forwards"
}

# --- Tmux dev layouts ---
t() { tmux attach || tmux new -s Work; }

# Create a Tmux dev layout with editor, ai, and terminal.
# Usage: tdl <c|cx|codex|other_ai> [<second_ai>]
tdl() {
  [[ -z $1 ]] && { echo "Usage: tdl <c|cx|codex|other_ai> [<second_ai>]"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tdl."; return 1; }

  local current_dir="${PWD}"
  local editor_pane ai_pane ai2_pane
  local ai="$1"
  local ai2="$2"

  editor_pane="$TMUX_PANE"
  tmux rename-window -t "$editor_pane" "$(basename "$current_dir")"
  tmux split-window -v -p 15 -t "$editor_pane" -c "$current_dir"
  ai_pane=$(tmux split-window -h -p 30 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')

  if [[ -n $ai2 ]]; then
    ai2_pane=$(tmux split-window -v -t "$ai_pane" -c "$current_dir" -P -F '#{pane_id}')
    tmux send-keys -t "$ai2_pane" "$ai2" C-m
  fi

  tmux send-keys -t "$ai_pane" "$ai" C-m
  tmux send-keys -t "$editor_pane" "$EDITOR ." C-m
  tmux select-pane -t "$editor_pane"
}

# Create multiple tdl windows, one per subdirectory of the current directory.
# Usage: tdlm <c|cx|codex|other_ai> [<second_ai>]
tdlm() {
  [[ -z $1 ]] && { echo "Usage: tdlm <c|cx|codex|other_ai> [<second_ai>]"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tdlm."; return 1; }

  local ai="$1"
  local ai2="$2"
  local base_dir="$PWD"
  local first=true

  tmux rename-session "$(basename "$base_dir" | tr '.:' '--')"

  for dir in "$base_dir"/*/; do
    [[ -d $dir ]] || continue
    local dirpath="${dir%/}"

    if $first; then
      tmux send-keys -t "$TMUX_PANE" "cd '$dirpath' && tdl $ai $ai2" C-m
      first=false
    else
      local pane_id=$(tmux new-window -c "$dirpath" -P -F '#{pane_id}')
      tmux send-keys -t "$pane_id" "tdl $ai $ai2" C-m
    fi
  done
}

# Create a multi-pane swarm layout with the same command started in each pane.
# Usage: tsl <pane_count> <command>
tsl() {
  [[ -z $1 || -z $2 ]] && { echo "Usage: tsl <pane_count> <command>"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tsl."; return 1; }

  local count="$1"
  local cmd="$2"
  local current_dir="${PWD}"
  local -a panes

  tmux rename-window -t "$TMUX_PANE" "$(basename "$current_dir")"
  panes+=("$TMUX_PANE")

  while (( ${#panes[@]} < count )); do
    local new_pane
    local split_target="${panes[-1]}"
    new_pane=$(tmux split-window -h -t "$split_target" -c "$current_dir" -P -F '#{pane_id}')
    panes+=("$new_pane")
    tmux select-layout -t "${panes[0]}" tiled
  done

  for pane in "${panes[@]}"; do
    tmux send-keys -t "$pane" "$cmd" C-m
  done

  tmux select-pane -t "${panes[0]}"
}

alias ic='tdl c'
alias ix='tdl cx'
alias icx='tdl c cx'

# --- AI / dev tool shortcuts ---
n() { if [ "$#" -eq 0 ]; then command nvim . ; else command nvim "$@"; fi; }
alias cx='printf "\033[2J\033[3J\033[H" && claude --permission-mode bypassPermissions'
alias cy='codex -s danger-full-access -a never'
alias c='opencode'
alias d='docker'
alias r='rails'
alias mup='MISE_MINIMUM_RELEASE_AGE=0 mise up'

# --- Init: version managers, prompt, directory jumping, fuzzy find ---
if command -v mise &> /dev/null; then
  eval "$(mise activate bash)"
fi

if [[ $- == *i* ]] && [[ ${TERM:-} != "dumb" ]] && command -v starship &> /dev/null; then
  eval "$(starship init bash)"
fi

if command -v zoxide &> /dev/null; then
  eval "$(zoxide init bash)"
fi

if command -v fzf &> /dev/null; then
  eval "$(fzf --bash)"
fi

# --- Readline tweaks ---
if [[ $- == *i* ]] && [[ -f /etc/inputrc.omarchy ]]; then
  bind -f /etc/inputrc.omarchy
fi

# Add your own exports, aliases, and functions in a separate ~/.bashrc.local2
# (or just extend this file in the nixconfig repo) — don't edit /etc/bashrc.local
# directly, it gets regenerated on every darwin-rebuild switch.
