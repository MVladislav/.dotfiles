# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="spaceship"

# when tmux user installed local bin will needed for plugins
if [ -d "$HOME/.local/bin" ]; then
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
  fi
fi

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Add wisely, as too many plugins slow down shell startup.
plugins=(colored-man-pages command-not-found docker git gitignore golang helm history kubectl lxd nmap npm oc pip httpie pylint rust sudo terraform tmux ubuntu ufw zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration
source ~/.zshrc-append
source ~/.zshrc-sec

touch ~/.zshrc-secrets
source ~/.zshrc-secrets
