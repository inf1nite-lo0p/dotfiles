#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

function doIt() {
	rsync --exclude ".git/" \
		--exclude "setup.sh" \
		--exclude "README.md" \
		--exclude "wsl/" \
		-avh --no-perms . ~;

	ln -sf "$(pwd)/tmux.conf" ~/.tmux.conf

	# WSL-only: shim wl-paste so Claude Code image paste (Ctrl+V) works.
	# WSLg exposes the Windows clipboard image only as image/bmp; Claude reads
	# image/png, so the shim serves a PNG via PowerShell. See wsl/wl-paste.
	if grep -qEi "(microsoft|wsl)" /proc/version 2>/dev/null; then
		mkdir -p ~/.local/bin
		ln -sf "$(pwd)/wsl/wl-paste" ~/.local/bin/wl-paste
	fi

	source ~/.bash_profile;
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	doIt;
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt;
	fi;
fi;
unset doIt;