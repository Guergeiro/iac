{ pkgs, username, ... }:

{
  users.users.${username} = {
    shell = pkgs.bashInteractive;
  };

  programs.bash = {
    completion.enable = true;
    interactiveShellInit = ''
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
  *i*) ;;
  *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "''${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
  xterm-color|*-256color) color_prompt=yes;;
esac

# If this is an xterm set the title to user@host:dir
case "$TERM" in
  xterm*|rxvt*)
    PS1="\[\e]0;''${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
  *)
    ;;
esac

# Removes the need of using cd
shopt -s autocd
# Automatically tries it's best to correct misspell
shopt -s cdspell

# Make sure correct ENV variables are set
export XDG_DATA_HOME=''${XDG_DATA_HOME:="$HOME/.local/share"}
export XDG_CACHE_HOME=''${XDG_CACHE_HOME:="$HOME/.cache"}
export XDG_CONFIG_HOME=''${XDG_CONFIG_HOME:="$HOME/.config"}
export XDG_STATE_HOME=''${XDG_STATE_HOME:="$HOME/.local/state"}

export USERXSESSION="$XDG_CACHE_HOME/X11/xsession"
export USERXSESSIONRC="$XDG_CACHE_HOME/X11/xsessionrc"
export ALTUSERXSESSION="$XDG_CACHE_HOME/X11/Xsession"
export ERRFILE="$XDG_CACHE_HOME/X11/xsession-errors"

export INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"
export SCREENRC="$XDG_CONFIG_HOME/screen/screenrc"
export WGETRC="$XDG_CONFIG_HOME/wgetrc"
export XINITRC="$XDG_CONFIG_HOME/X11/xinitrc"
export XSERVERRC="$XDG_CONFIG_HOME/X11/xserverrc"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"

# Function to automatically update PATH if not exists
function __path_update() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$1:$PATH" ;;
  esac
}

# Gradle
export GRADLE_HOME="$XDG_DATA_HOME/gradle"
__path_update "$GRADLE_HOME/bin"
export GRADLE_USER_HOME="$XDG_CONFIG_HOME/gradle"
__path_update "$GRADLE_USER_HOME"

# npm user global packages
__path_update "$XDG_DATA_HOME/npm/bin"

# pnpm
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
__path_update "$PNPM_HOME"
# pnpm end

# Deno
export DENO_INSTALL="$XDG_DATA_HOME/deno"
__path_update "$DENO_INSTALL/bin"

# Neovim
export NEOVIM_HOME="$XDG_DATA_HOME/neovim"
__path_update "$NEOVIM_HOME/nvim-linux-x86_64/bin"

# Alacritty
export ALACRITTY_HOME="$XDG_DATA_HOME/alacritty"
__path_update "$ALACRITTY_HOME/bin"

# Tmux
export TMUX_HOME="$XDG_DATA_HOME/tmux"
__path_update "$TMUX_HOME/bin"

# Starship
export STARSHIP_HOME="$XDG_DATA_HOME/starship"
__path_update "$STARSHIP_HOME"

# Pip
export PIP_HOME="$XDG_DATA_HOME/pip"
__path_update "$PIP_HOME/bin"

# Go
function __asdf_golang() {
	local go_bin_path="$(asdf which go 2>/dev/null)"
	if [[ -n "''${go_bin_path}" ]]; then
		local abs_go_bin_path="$(readlink -f "''${go_bin_path}")"

		export GOROOT="$(dirname "$(dirname "''${abs_go_bin_path}")")"

		export GOPATH="$(dirname "''${GOROOT}")/packages"

		__path_update "$GOPATH/bin"
fi
}
__asdf_golang

# Rust
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
__path_update "$CARGO_HOME/bin"

export MANPAGER="sh -c 'col -bx | ${pkgs.bat}/bin/bat -l man -p'"

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

# Functions definitions
if [ -f "$XDG_CONFIG_HOME/bash/.bash_functions" ]; then
  . "$XDG_CONFIG_HOME/bash/.bash_functions"
fi

# Tmux definitions
if [ -f "$XDG_CONFIG_HOME/tmux/.bash_functions" ]; then
  . "$XDG_CONFIG_HOME/tmux/.bash_functions"
fi

# Starship definitions
if [ -f "$XDG_CONFIG_HOME/starship/.bash_functions" ]; then
  . "$XDG_CONFIG_HOME/starship/.bash_functions"
fi

# Docker definitions
if [ -f "$XDG_CONFIG_HOME/docker/.bash_functions" ]; then
  . "$XDG_CONFIG_HOME/docker/.bash_functions"
fi

# Private work scripts
if [ -f "$XDG_CONFIG_HOME/dotfiles-work/.bashrc" ]; then
  . "$XDG_CONFIG_HOME/dotfiles-work/.bashrc"
fi

export dotfilesDirectory="$HOME/Documents/guergeiro/dotfiles"
export notesDirectory="$HOME/Brain"
          '';
  };

  programs.tmux = {
    enable = true;
    extraConfig = ''
unbind C-a
unbind C-b
unbind C-w
set-option -g prefix C-a
bind-key C-a send-prefix

# Windows
bind-key l next-window
bind-key h previous-window
bind-key n new-window -c "#{pane_current_path}"
bind-key % split-window -h -c "#{pane_current_path}"
bind-key '"' split-window -c "#{pane_current_path}"

# Panes
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
bind-key -n C-w if-shell "$is_vim" "send-keys C-w" "switch-client -T VIMWINDOWS"
bind-key -T VIMWINDOWS h select-pane -L
bind-key -T VIMWINDOWS j select-pane -D
bind-key -T VIMWINDOWS k select-pane -U
bind-key -T VIMWINDOWS l select-pane -R
bind-key -T VIMWINDOWS s split-window -c "#{pane_current_path}"
bind-key -T VIMWINDOWS v split-window -h -c "#{pane_current_path}"
bind-key -T VIMWINDOWS c kill-pane

# address vim mode switching delay (http://superuser.com/a/252717/65504)
set -s escape-time 0

# increase scrollback buffer size
set -g history-limit 50000

# tmux messages are displayed for 4 seconds
set -g display-time 4000

# upgrade $TERM
set -g default-terminal "tmux-256color"
# set -ag terminal-overrides ",xterm-256color:RGB"

# focus events enabled for terminals that support them
set -g focus-events on

# super useful when using "grouped sessions" and multi-monitor setup
set -g aggressive-resize on

# No bells at all
set -g bell-action none

# No bells at all
set -g bell-action none

# Keep windows around after they exit
set -g remain-on-exit off

# Mouse support
set -g mouse on

# Vi mode
set-window-option -g mode-keys vi
bind-key -T copy-mode-vi v send-keys -X begin-selection

# List of plugins
set -g @resurrect-strategy-vim 'session'

set -g @dracula-show-powerline true
set -g @dracula-show-flags true
set -g @dracula-show-left-icon session
set -g @dracula-plugins "time"
run '${pkgs.tmuxPlugins.dracula}/share/tmux-plugins/dracula/dracula.tmux'
run '${pkgs.tmuxPlugins.dracula}/share/tmux-plugins/yank/yank.tmux'
run '${pkgs.tmuxPlugins.dracula}/share/tmux-plugins/resurrect/resurrect.tmux'
    '';
  };
}

