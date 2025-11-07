# 1. Load PATH and environment setup
[ -f ~/.paths ] && source ~/.paths

# 2. Load aliases, functions, and extras
for file in ~/.{aliases,bash_logout,functions,extra}; do
  [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

# 3. If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# 4. History behavior
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000

# 5. Terminal tweaks
shopt -s checkwinsize
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# 6. Chroot awareness
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# 7. Prompt styling
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

# 8. Terminal title for xterm
case "$TERM" in
  xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
esac

# 9. Shell behavior
set -o vi

# 10. Starship prompt
eval "$(starship init bash)"

# 11. Load nvm (must be before completions)
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 12. Load completions (after tools are loaded)
[ -f ~/.completions ] && source ~/.completions

# 13. Enable auto-complete for just tasks
source ~/.just-completion.bash
complete -F _just -o default j