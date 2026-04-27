#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

function doIt() {
	rsync --exclude ".git/" \
		--exclude "setup.sh" \
		--exclude "README.md" \
		-avh --no-perms . ~;

	ln -sf "$(pwd)/tmux.conf" ~/.tmux.conf
    ln -sf "$(pwd)/.inputrc" ~/.inputrc

	mkdir -p ~/.claude/hooks
	ln -sf "$(pwd)/.claude/settings.json" ~/.claude/settings.json
	ln -sf "$(pwd)/.claude/statusline-shadcn.sh" ~/.claude/statusline-shadcn.sh
	ln -sf "$(pwd)/.claude/hooks/dotfiles-context.sh" ~/.claude/hooks/dotfiles-context.sh

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