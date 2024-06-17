#!/usr/bin/env bash

PATH=/usr/bin/:/usr/local/bin/:/bin:/usr/sbin/:/sbin
set -euo pipefail
IFS=$'\n\t'

LN_TMUX_ORIG_BASE=~/.tmux
LN_TMUX_ORIG_TMUX=~/.tmux.conf
LN_TMUX_ORIG_SCRIPT=~/.local/bin

LN_NVIM_ORIG_BASE=~/.config/nvim

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

