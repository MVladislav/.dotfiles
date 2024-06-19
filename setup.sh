#!/usr/bin/env bash

PATH=/usr/bin/:/usr/local/bin/:/bin:/usr/sbin/:/sbin
set -euo pipefail
IFS=$'\n\t'

LN_TMUX_ORIG_BASE=~/.tmux
LN_TMUX_ORIG_TMUX=~/.tmux.conf
LN_TMUX_ORIG_SCRIPT=~/.local/bin

LN_NVIM_ORIG_BASE=~/.config/nvim

LN_ADDS_01=~/.zshrc-append
LN_ADDS_02=~/.zshrc-sec

# DEPS :: install dependiencies -------------------------------------------------------------------------------------------------
echo "DEPS :: install some base services"
sudo apt install rsync eza bat ripgrep fd-find

echo "DEPS :: disable rsync systemd service"
sudo systemctl disable rsync.service
sudo systemctl mask rsync.service

echo "DEPS :: install build dependincies"
#sudo apt install ninja-build gettext cmake unzip curl build-essential \
#automake pkg-config libevent-dev libncurses5-dev bison

echo "DEPS :: install tmux for user only"
#git clone https://github.com/tmux/tmux.git $HOME/Downloads/tmux && cd $HOME/Downloads/tmux
#sh autogen.sh
#./configure --prefix=$HOME/.local/ && make
#make install

echo "DEPS :: install nvim for user only"
#git clone https://github.com/neovim/neovim $HOME/Downloads/nvim && cd $HOME/Downloads/nvim
#make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX=$HOME/.local/
#make install

echo "DEPS :: remove some build dependincies"
sudo apt remove cmake automake

# TMUX :: CREATE LINKS ----------------------------------------------------------------------------------------------------------
echo "TMUX :: Create symlink as from './tmux' '$LN_TMUX_ORIG_BASE'"
rm -f "${LN_TMUX_ORIG_BASE}"
ln -sf "${PWD}/tmux" "${LN_TMUX_ORIG_BASE}"
echo "TMUX :: Create symlink from './tmux.conf' as '$LN_TMUX_ORIG_TMUX'"
rm -f "${LN_TMUX_ORIG_TMUX}"
ln -sf "${PWD}/tmux.conf" "${LN_TMUX_ORIG_TMUX}"

echo "TMUX :: Create symlink from './bin/*' into '$LN_TMUX_ORIG_SCRIPT/'"
for script in "$PWD"/bin/*; do
  ln -sf "$script" "${LN_TMUX_ORIG_SCRIPT}/$(basename "$script")"
done

echo "TMUX :: All symlinks created."

# NVIM :: CREATE LINKS ----------------------------------------------------------------------------------------------------------
echo "NVIM :: Create symlink from './nvim' as '$LN_NVIM_ORIG_BASE'"
rm -f "${LN_NVIM_ORIG_BASE}"
ln -sf "${PWD}/nvim" "${LN_NVIM_ORIG_BASE}"
echo "NVIM :: All symlinks created."

# ADDS :: CREATE LINKS ----------------------------------------------------------------------------------------------------------
echo "ADDS :: Create symlink from './zshrc-append' as '$LN_ADDS_01'"
rm -f "${LN_ADDS_01}"
ln -sf "${PWD}/zshrc-append" "${LN_ADDS_01}"
echo "ADDS :: Create symlink from './zshrc-sec' as '$LN_ADDS_02'"
rm -f "${LN_ADDS_02}"
ln -sf "${PWD}/zshrc-sec" "${LN_ADDS_02}"
echo "ADDS :: All symlinks created."

# FONTS :: ADD FONTS ------------------------------------------------------------------------------------------------------------
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
