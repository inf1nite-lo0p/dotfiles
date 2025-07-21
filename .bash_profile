# Load PATH and environment setup
[ -f ~/.paths ] && source ~/.paths

# Load the shell dotfiles, and then some:
for file in ~/.{aliases,bash_logout,functions,extra,completions}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History behavior
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000

# Terminal tweaks
shopt -s checkwinsize
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Chroot awareness
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# Prompt styling
case "$TERM" in
  xterm-color|*-256color) color_prompt=yes ;;
esac

if [ -n "$force_color_prompt" ]; then
  if [ -x /usr/bin/tput ] && tput setaf 1 &>/dev/null; then
    color_prompt=yes
  else
    color_prompt=
  fi
fi

if [ "$color_prompt" = yes ]; then
  PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
  PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# Terminal window title for xterm
case "$TERM" in
  xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
esac

# Shell behavior
set -o vi

# Starship prompt
eval "$(starship init bash)"

# nvm (after PATH is set)
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Auto-start tmux
if command -v tmux &>/dev/null && [ -z "$TMUX" ]; then
  tmux attach -t main || tmux new -s main
fi