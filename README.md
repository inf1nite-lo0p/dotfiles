# Dotfiles

Configuration files for my development environment.

## Setup

To set up your environment with these dotfiles, follow these steps:

1. Clone the repository to your home directory:

    ```sh
    git clone https://github.com/mohammadxali/dotfiles.git ~/dotfiles
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
    git config --global user.name "$GIT_AUTHOR_NAME"
    GIT_AUTHOR_EMAIL="your@email.here"
    GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
    git config --global user.email "$GIT_AUTHOR_EMAIL"
    ```
