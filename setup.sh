#!/usr/bin/env bash

PATH=/usr/bin/:/usr/local/bin/:/bin:/usr/sbin/:/sbin
set -euo pipefail
IFS=$'\n\t'

# CONFS :: variables -------------------------------------------------------------------------------------------------------------
LN_TMUX_ORIG_BASE=~/.tmux
LN_TMUX_ORIG_TMUX=~/.tmux.conf
LN_TMUX_ORIG_SCRIPT=~/.local/bin

LN_NVIM_ORIG_BASE=~/.config/nvim

LN_ZSHRC=~/.zshrc
LN_ADDS_01=~/.zshrc-append
LN_ADDS_02=~/.zshrc-sec

LN_VS_CODE=~/.config/Code/User

# ******************************************************************************

main() {
  [[ $RUN_SETUP_BASE -eq 1 ]] && setup_base
  [[ $RUN_INSTALL_DEPENDENCIES_ADDITIONAL -eq 1 ]] && install_dependiencies_additional

  [[ $RUN_INSTALL_DEPENDENCIES_TMUX_NVIM -eq 1 ]] && install_dependiencies_needs
  [[ $RUN_INSTALL_DEPENDENCIES_TMUX_NVIM -eq 1 ]] && install_dependiencies_tmux
  [[ $RUN_INSTALL_DEPENDENCIES_TMUX_NVIM -eq 1 ]] && install_dependiencies_nvim
  [[ $RUN_INSTALL_DEPENDENCIES_TMUX_NVIM -eq 1 ]] && install_dependiencies_needs_rm

  [[ $RUN_SETUP_TMUX -eq 1 ]] && setup_tmux
  [[ $RUN_SETUP_NVIM -eq 1 ]] && setup_nvim
  [[ $RUN_SETUP_CODE -eq 1 ]] && setup_code
  [[ $RUN_SETUP_ADDS -eq 1 ]] && setup_adds
  [[ $RUN_SETUP_FONTS -eq 1 ]] && setup_fonts
}

# ******************************************************************************

# GIT :: init recursives --------------------------------------------------------------------------------------------------------
setup_base() {
  git submodule update --init --recursive --remote
}

# DEPS :: install dependiencies -------------------------------------------------------------------------------------------------
install_dependiencies_additional() {
  echo "DEPS :: install some base services"
  sudo apt install rsync fzf eza bat ripgrep fd-find

  echo "DEPS :: disable rsync systemd service"
  sudo systemctl disable rsync.service
  sudo systemctl mask rsync.service

  # echo "DEPS :: install lazygit with go"
  # go install github.com/jesseduffield/lazygit@latest
}

install_dependiencies_needs() {
  echo "DEPS :: install build dependincies"
  sudo apt install ninja-build gettext cmake unzip curl build-essential \
    automake pkg-config libevent-dev libncurses5-dev bison
}

install_dependiencies_needs_rm() {
  echo "DEPS :: remove some build dependincies"
  sudo apt remove cmake automake
}

install_dependiencies_tmux() {
  echo "DEPS :: install tmux for user only"
  git clone https://github.com/tmux/tmux.git "$HOME/Downloads/tmux" && cd "$HOME/Downloads/tmux"
  sh autogen.sh
  ./configure --prefix="$HOME/.local/" && make
  make install
  cd -
  #rm -rf "$HOME/Downloads/tmux"
}

install_dependiencies_nvim() {
  echo "DEPS :: install nvim for user only"
  git clone https://github.com/neovim/neovim.git "$HOME/Downloads/nvim" && cd "$HOME/Downloads/nvim"
  make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX="$HOME/.local/"
  make install
  cd -
  #rm -rf "$HOME/Downloads/nvim"
}

# TMUX :: CREATE LINKS ----------------------------------------------------------------------------------------------------------
setup_tmux() {
  echo "TMUX :: Create symlink from './tmux/tmux' as '$LN_TMUX_ORIG_BASE'"
  rm -f "${LN_TMUX_ORIG_BASE}"
  ln -sf "${PWD}/tmux/tmux" "${LN_TMUX_ORIG_BASE}"
  echo "TMUX :: Create symlink from './tmux/tmux.conf' as '$LN_TMUX_ORIG_TMUX'"
  rm -f "${LN_TMUX_ORIG_TMUX}"
  ln -sf "${PWD}/tmux/tmux.conf" "${LN_TMUX_ORIG_TMUX}"

  echo "TMUX :: Create symlink from './bin/*' into '$LN_TMUX_ORIG_SCRIPT/'"
  for script in "$PWD"/bin/*; do
    ln -sf "$script" "${LN_TMUX_ORIG_SCRIPT}/$(basename "$script")"
  done

  echo "TMUX :: Run tpm to install plugins"
  PATH="$HOME/.local/bin:$PATH" bash "${LN_TMUX_ORIG_BASE}/plugins/tpm/scripts/install_plugins.sh"

  echo "TMUX :: All symlinks created."
}

# NVIM :: CREATE LINKS ----------------------------------------------------------------------------------------------------------
setup_nvim() {
  echo "NVIM :: Create symlink from './nvim' as '$LN_NVIM_ORIG_BASE'"
  rm -f "${LN_NVIM_ORIG_BASE}"
  ln -sf "${PWD}/nvim" "${LN_NVIM_ORIG_BASE}"
  echo "NVIM :: All symlinks created."
}

# CODE :: CREATE LINKS -----------------------------------------------------------------------------------------------------------
setup_code() {
  mkdir -p "$LN_VS_CODE"
  echo "CODE :: Create symlink from './code/keybindings.json' into '$LN_VS_CODE'"
  rm -f "${LN_VS_CODE}/keybindings.json"
  ln -sf "${PWD}/code/keybindings.json" "${LN_VS_CODE}/keybindings.json"
  echo "CODE :: Create symlink from './code/settings.json' into '$LN_VS_CODE'"
  rm -f "${LN_VS_CODE}/settings.json"
  ln -sf "${PWD}/code/settings.json" "${LN_VS_CODE}/settings.json"
  echo "CODE :: Create symlink from './code/snippets' into '$LN_VS_CODE'"
  rm -f "${LN_VS_CODE}/snippets"
  ln -sf "${PWD}/code/snippets" "${LN_VS_CODE}/snippets"
}

# ADDS :: CREATE LINKS ----------------------------------------------------------------------------------------------------------
setup_adds() {
  echo "ADDS :: Create symlink from './zshrc' as '$LN_ZSHRC'"
  rm -f "${LN_ZSHRC}"
  ln -sf "${PWD}/zshrc" "${LN_ZSHRC}"

  echo "ADDS :: Create symlink from './zshrc-append' as '$LN_ADDS_01'"
  rm -f "${LN_ADDS_01}"
  ln -sf "${PWD}/zshrc-append" "${LN_ADDS_01}"
  echo "ADDS :: Create symlink from './zshrc-sec' as '$LN_ADDS_02'"
  rm -f "${LN_ADDS_02}"
  ln -sf "${PWD}/zshrc-sec" "${LN_ADDS_02}"
  echo "ADDS :: All symlinks created."
}

# FONTS :: ADD FONTS ------------------------------------------------------------------------------------------------------------
setup_fonts() {
  echo "FONTS :: Download some nerd fonts"
  FONTS_URLS=(
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/NerdFontsSymbolsOnly.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Hack.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/UbuntuMono.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraMono.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/RobotoMono.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/ProggyClean.tar.xz"
  )
  FONTS_DIR=~/.local/share/fonts/nerd-fonts
  mkdir -p "$FONTS_DIR"

  for url in "${FONTS_URLS[@]}"; do
    file_name=$(basename "$url")
    echo "FONTS :: Downloading $file_name..."
    curl -sL -o "/tmp/$file_name" "$url"
    echo "FONTS :: Extracting $file_name..."
    tar -xf "/tmp/$file_name" -C "$FONTS_DIR"
    rm "/tmp/$file_name"
  done

  echo "FONTS :: All fonts are downloaded and extracted"
}

# ******************************************************************************

# Function to show usage information
usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -h, --help                                  Show this help message and exit"
  echo "  -nsb, --no-setup-base                       Skip setup_base"
  echo "  -nia, --no-install-dependencies-additional  Skip setup_dependiencies"
  echo "  -nitn, --no-install-dependencies-tmux-nvim  Skip setup_dependiencies"
  echo "  -nst, --no-setup-tmux                       Skip setup_tmux"
  echo "  -nsn, --no-setup-nvim                       Skip setup_nvim"
  echo "  -nsc, --no-setup-code                       Skip setup_code"
  echo "  -nsa, --no-setup-adds                       Skip setup_adds"
  echo "  -nsf, --no-setup-fonts                      Skip setup_fonts"
}

# Function to parse command-line arguments
parse_args() {
  RUN_SETUP_BASE=1
  RUN_INSTALL_DEPENDENCIES_ADDITIONAL=1
  RUN_INSTALL_DEPENDENCIES_TMUX_NVIM=0
  RUN_SETUP_TMUX=1
  RUN_SETUP_NVIM=1
  RUN_SETUP_CODE=1
  RUN_SETUP_ADDS=1
  RUN_SETUP_FONTS=1

  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    -h | --help)
      usage
      exit 0
      ;;
    -nsb | --no-setup-base)
      RUN_SETUP_BASE=0
      ;;
    -nia | --no-install-dependencies-additional)
      RUN_INSTALL_DEPENDENCIES_ADDITIONAL=0
      ;;
    -nitn | --no-install-dependencies-tmux-nvim)
      RUN_INSTALL_DEPENDENCIES_TMUX_NVIM=0
      ;;
    -itn | --install-dependencies-tmux-nvim)
      RUN_INSTALL_DEPENDENCIES_TMUX_NVIM=0
      ;;
    -nst | --no-setup-tmux)
      RUN_SETUP_TMUX=0
      ;;
    -nsn | --no-setup-nvim)
      RUN_SETUP_NVIM=0
      ;;
    -nsc | --no-setup-code)
      RUN_SETUP_CODE=0
      ;;
    -nsa | --no-setup-adds)
      RUN_SETUP_ADDS=0
      ;;
    -nsf | --no-setup-fonts)
      RUN_SETUP_FONTS=0
      ;;
    *)
      echo "Unknown option: $key" >&2
      usage
      exit 1
      ;;
    esac
    shift
  done
}

# ******************************************************************************

echo "Starting script $0 ..."

# Parse command-line arguments
parse_args "$@"

main
exit 0
