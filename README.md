# Dotfiles

Configuration files for my development environment.

## Setup

To set up your environment with these dotfiles, follow these steps:

1. Clone the repository to your home directory:

    ```sh
    git clone https://github.com/inf1nite-lo0p/dotfiles.git ~/dotfiles
    ```

2. Navigate to the `dotfiles` directory:

    ```sh
    cd ~/dotfiles
    ```

3. Run the setup script to create the necessary symbolic links:

    ```sh
    ./setup.sh
    ```

4. Create `.extra` file

    ```sh
    # Git credentials
    # Not in the repository, to prevent people from accidentally committing under my name
    GIT_AUTHOR_NAME="Your name"
    GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
    GIT_AUTHOR_EMAIL="your@email.here"
    GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
    git config --file "$HOME/.gitconfig.identity" --replace-all user.name "$GIT_AUTHOR_NAME"
    git config --file "$HOME/.gitconfig.identity" --replace-all user.email "$GIT_AUTHOR_EMAIL"
    ```

    Writing to `~/.gitconfig.identity` rather than `--global` keeps the identity in a file that `~/.gitconfig` includes at a known position. That matters for the per-directory overrides below — see the ordering note there.

## Per-directory identities

Optional. Useful when one machine commits under more than one identity — a personal account and a client or employer account, say — and you would rather not remember to switch. Nothing here is configured by default: both hooks are inert until you create the files, so a fresh clone behaves exactly as before.

### Git identity and push credentials

`~/.gitconfig` ends with an `[include]` of `~/.gitconfig.local`, which is not tracked. Put the routing there:

```gitconfig
[include]
    path = ~/.gitconfig.identity          # personal, written by ~/.extra

[includeIf "gitdir:~/acme/"]
    path = ~/.gitconfig.d/acme
```

**Order is load-bearing.** Git resolves duplicate keys last-wins, so the personal identity must be included *first* and each override *after* it. This is also why `.extra` writes to `~/.gitconfig.identity` instead of `--global`: `git config --global` appends a `[user]` block to the *end* of `~/.gitconfig` whenever that section is absent — which is the state right after `setup.sh` rsyncs a fresh copy — and that block would land after the `includeIf` and silently outrank it.

Then `~/.gitconfig.d/acme` carries the override, and optionally an SSH remote rewrite so pushes use a different key:

```gitconfig
[user]
    name = your-work-handle
    email = your@work.email

[url "git@github-acme:"]
    insteadOf = git@github.com:
```

Pair that rewrite with a host alias in `~/.ssh/config`, so only one key is ever offered. With two valid keys and no `IdentitiesOnly`, whichever is presented first wins, which is not something you want decided at random:

```sshconfig
Host github-acme
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_acme
    IdentitiesOnly yes
```

### GitHub CLI account

`gh auth switch` writes to one shared `hosts.yml`, so the active account is global mutable state — with several shells or agents running, one can flip it between your switch and your command. The `gh` wrapper in `.functions` avoids that by selecting a config directory per process. Set the mapping in `~/.extra`:

```sh
export GH_ACCOUNT_ROOTS="$HOME/acme=$HOME/.config/gh-acme"
```

Log each config dir in once, so a stray `gh auth switch` has nothing to switch to:

```sh
GH_CONFIG_DIR="$HOME/.config/gh-acme" gh auth login
```
