#!/usr/bin/env bash

PATH=/usr/bin/:/usr/local/bin/:/bin:/usr/sbin/:/sbin:/snap/bin/:$HOME/.local/bin
set -euo pipefail
IFS=$'\n\t'

cat <<'EOF'
      .--.
     |o_o |  HI :)
     |:_/ |
    //   \ \
   (|     | )
  /'\_   _/`\
  \___)=(___/

EOF

# ******************************************************************************

RUN_WITH_SUDO=''
IS_SUDO_INSTALL=0
if command -v sudo &>/dev/null; then
  RUN_WITH_SUDO=sudo
  IS_SUDO_INSTALL=1
fi

# ******************************************************************************

# COLOR ------------------------------------------------------------------------
# https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux)
NC='\033[0m'         # No Color
BRED='\033[1;31m'    # Red
BPURPLE='\033[1;35m' # Purple
BYELLOW='\033[1;33m' # Yellow
BCYAN='\033[1;36m'   # Cyan

# CONFS :: variables -----------------------------------------------------------
RUN_INSTALL_DEPENDENCIES_ADDITIONAL=0
RUN_INSTALL_DEPENDENCIES_TMUX=0
RUN_INSTALL_DEPENDENCIES_NVIM=0
RUN_INSTALL_DEPENDENCIES_ZSH=0
RUN_INSTALL_DEPENDENCIES_GHOSTTY=0

RUN_SETUP_BIN=1
RUN_SETUP_TMUX=1
RUN_SETUP_NVIM=1
RUN_SETUP_CODE=1
RUN_SETUP_ZED=1
RUN_SETUP_ADDS=1
RUN_SETUP_LOGSEQ=1

RUN_INSTALL_CODE_EXT=0
RUN_INSTALL_FONTS=0
RUN_INSTALL_BTOP=0
RUN_INSTALL_BTOP_AMD=0
RUN_INSTALL_BTOP_INTEL=0

# CONFS :: variables -----------------------------------------------------------
INSTALL_SOURCE_FROM=release # source | release
VERSION_ZIG_V=0.13.0
VERSION_ZIG="https://ziglang.org/download/${VERSION_ZIG_V}/zig-linux-x86_64-${VERSION_ZIG_V}.tar.xz"
VERSION_GHOSTTY=v1.1.2
VERSION_FONTS_RELEASE='v3.2.1'
VERSION_BTOP='v1.4.0'
VERSION_RSMI='rocm-6.3.3'

DEPS_INSTALL_PATH="${HOME}/.tmp" # /tmp
DEPS_PACKAGES_TO_REMOVE=()

USER_LOCAL_PREFIX="${HOME}/.local"
USER_LOCAL_PREFIX_BIN="$USER_LOCAL_PREFIX/bin"

: "${LN_TMUX_ORIG_BASE=${HOME}/.tmux}"
: "${LN_TMUX_ORIG_TMUX=${HOME}/.tmux.conf}"

: "${LN_NVIM_ORIG_BASE=${HOME}/.config/nvim}"

: "${LN_ZSH_OH_FOLDER=${HOME}/.oh-my-zsh}"
LN_ZSHRC="${HOME}/.zshrc"
LN_ADDS_01="${HOME}/.zshrc-append"
LN_ADDS_02="${HOME}/.zshrc-sec"

: "${LN_GHOSTTY_FOLDER=${HOME}/.config/ghostty}"

: "${LN_VS_CODE=${HOME}/.config/Code/User}"

LN_ZED_FLATPAK="${HOME}/.var/app/dev.zed.Zed/config/zed"
: "${LN_ZED=$LN_ZED_FLATPAK}"
# LN_ZED=${HOME}/.config/zed

LN_LOGSEQ_PATH="${HOME}/.logseq"

# ******************************************************************************

main() {
  if [[ "$INSTALL_SOURCE_FROM" != "source" && "$INSTALL_SOURCE_FROM" != "release" ]]; then
    print_error "❌ Invalid value for INSTALL_SOURCE_FROM: $INSTALL_SOURCE_FROM"
    exit 1
  fi

  [[ $IS_SUDO_INSTALL -eq 1 ]] && sudo -k
  initialize_base
  [[ $RUN_INSTALL_DEPENDENCIES_ADDITIONAL -eq 1 ]] && install_dependencies_additional

  [[ $RUN_INSTALL_DEPENDENCIES_TMUX -eq 1 ]] && install_dependencies_tmux
  [[ $RUN_INSTALL_DEPENDENCIES_NVIM -eq 1 ]] && install_dependencies_nvim
  [[ $RUN_INSTALL_DEPENDENCIES_ZSH -eq 1 ]] && install_dependencies_zsh
  [[ $RUN_INSTALL_DEPENDENCIES_GHOSTTY -eq 1 ]] && install_dependencies_ghostty

  [[ $RUN_SETUP_BIN -eq 1 ]] && setup_bin
  [[ $RUN_SETUP_TMUX -eq 1 ]] && setup_tmux
  [[ $RUN_SETUP_NVIM -eq 1 ]] && setup_nvim
  [[ $RUN_SETUP_CODE -eq 1 ]] && setup_code
  [[ $RUN_SETUP_ZED -eq 1 ]] && setup_zed
  [[ $RUN_SETUP_ADDS -eq 1 ]] && setup_adds
  [[ $RUN_SETUP_LOGSEQ -eq 1 ]] && setup_logseq

  [[ $RUN_INSTALL_CODE_EXT -eq 1 ]] && install_code_ext
  [[ $RUN_INSTALL_FONTS -eq 1 ]] && install_fonts
  [[ $RUN_INSTALL_BTOP -eq 1 ]] && install_btop

  print_info2 "\n✅ All finished!"
}

# ******************************************************************************

install_dependencies_needs() {
  print_notes "   📥 Installing build dependencies..."
  DEPS_PACKAGES_TO_REMOVE=()
  local packages_tools=("${!1}")
  local packages_build=("${!2}")

  local packages_to_install=()

  # Check packages_tools: install if missing, but never mark for removal.
  for pkg in "${packages_tools[@]}"; do
    if ! apt list -qq "$pkg" 2>/dev/null | grep -q 'installed'; then
      packages_to_install+=("$pkg")
    fi
  done

  # Check packages_build: install if missing and add to removal list.
  for pkg in "${packages_build[@]}"; do
    if ! apt list -qq "$pkg" 2>/dev/null | grep -q 'installed'; then
      packages_to_install+=("$pkg")
      DEPS_PACKAGES_TO_REMOVE+=("$pkg")
    fi
  done

  print_notes "   📥 Packages to install: [$(echo "${packages_to_install[*]}" | tr '\n' ' ')]"
  print_notes "   📥 Packages to remove afterward: [$(echo "${DEPS_PACKAGES_TO_REMOVE[*]}" | tr '\n' ' ')]"

  # Only run sudo update and install if any package is missing.
  if [[ ${#packages_to_install[@]} -gt 0 ]]; then
    $RUN_WITH_SUDO apt-get update -qqq || {
      print_error "Failed to update package list"
      exit 1
    }
    $RUN_WITH_SUDO apt-get install -y "${packages_to_install[@]}" 1>/dev/null || {
      print_error "Failed to install packages"
      exit 1
    }
    [[ $IS_SUDO_INSTALL -eq 1 ]] && sudo -k
    print_notes "   📥 Build dependencies installed"
  else
    print_notes "   📥 All dependencies already installed. Skipping dependencies installation."
  fi
}

install_dependencies_needs_rm() {
  if [[ ${#DEPS_PACKAGES_TO_REMOVE[@]} -eq 0 ]]; then
    print_notes "   📥 No packages to remove."
    return 0
  fi

  print_notes "   📥 Removing build dependencies..."
  $RUN_WITH_SUDO apt-get remove -y "${DEPS_PACKAGES_TO_REMOVE[@]}" 1>/dev/null || {
    print_error "Failed to remove packages"
    return 1
  }
  $RUN_WITH_SUDO apt-get -y autoremove -qqq 1>/dev/null
  $RUN_WITH_SUDO apt-get -y autoclean -qqq 1>/dev/null

  [[ $IS_SUDO_INSTALL -eq 1 ]] && sudo -k
  print_notes "   📥 Packages removed: [$(echo "${DEPS_PACKAGES_TO_REMOVE[*]}" | tr '\n' ' ')]"
}

# ******************************************************************************

# BASE :: some general needed prepares -----------------------------------------
initialize_base() {
  mkdir -p "$HOME/.config" 1>/dev/null
}

# DEPS :: install dependencies -------------------------------------------------
install_dependencies_additional() {
  print_info2 "\n📥 DEPS :: install some base services :: [rsync fzf eza bat ripgrep fd-find xclip]"
  $RUN_WITH_SUDO apt-get install -y rsync fzf eza bat ripgrep fd-find xclip 1>/dev/null

  print_info2 "📥 DEPS :: disable rsync systemd service"
  $RUN_WITH_SUDO systemctl disable rsync.service &>/dev/null
  $RUN_WITH_SUDO systemctl mask rsync.service &>/dev/null

  # echo "DEPS :: install npm"
  # $RUN_WITH_SUDO snap install node --classic

  # echo "DEPS :: install lazygit with go"
  # $RUN_WITH_SUDO snap install go --classic
  # go install github.com/jesseduffield/lazygit@latest

  # echo "DEPS :: install zed over flatpak"
  # flatpak install flathub dev.zed.Zed
  [[ $IS_SUDO_INSTALL -eq 1 ]] && sudo -k
}

# SERVICE :: install tmux ------------------------------------------------------
install_dependencies_tmux() {
  print_info2 "\n🚀 TMUX :: install tmux..."
  print_notes "   💡 current installed version :: '$("$USER_LOCAL_PREFIX_BIN/tmux" -V 2>/dev/null)'"
  rm -rf "$DEPS_INSTALL_PATH/tmux" 1>/dev/null

  # Define packages needed for tmux and install
  local packages_tools=(libevent-dev)
  local packages_build=(git unzip curl jq build-essential pkg-config libncurses-dev bison)
  install_dependencies_needs packages_tools[@] packages_build[@]

  if [[ $INSTALL_SOURCE_FROM == 'source' ]]; then
    git clone -q https://github.com/tmux/tmux.git "$DEPS_INSTALL_PATH/tmux"
    cd "$DEPS_INSTALL_PATH/tmux"
    bash ./autogen.sh 1>/dev/null
  elif [[ $INSTALL_SOURCE_FROM == 'release' ]]; then
    mkdir -p "$DEPS_INSTALL_PATH/tmux"
    curl -L -so "$DEPS_INSTALL_PATH/tmux.tar.gz" "$(curl -s 'https://api.github.com/repos/tmux/tmux/releases/latest' | jq -r '.assets[] | select(.name | test(".*tar.gz$")) | .browser_download_url')"
    tar -zxf "$DEPS_INSTALL_PATH/tmux.tar.gz" -C "$DEPS_INSTALL_PATH/tmux" --strip-components=1
    rm "$DEPS_INSTALL_PATH/tmux.tar.gz"
    cd "$DEPS_INSTALL_PATH/tmux"
  fi

  bash ./configure --prefix="$USER_LOCAL_PREFIX/" 1>/dev/null
  make 1>/dev/null
  make install 1>/dev/null
  cd - 1>/dev/null
  rm -rf "$DEPS_INSTALL_PATH/tmux" 1>/dev/null
  print_notes "   💡 new installed version :: '$("$USER_LOCAL_PREFIX_BIN/tmux" -V 2>/dev/null)'"

  # Remove build dependencies if any
  install_dependencies_needs_rm

  print_info2 "🚀 TMUX :: tmux installed!"
}

# SERVICE :: install nvim ------------------------------------------------------
install_dependencies_nvim() {
  print_info2 "\n🚀 NVIM :: install nvim..."
  print_notes "   💡 current installed version :: '$("$USER_LOCAL_PREFIX_BIN/nvim" -v 2>/dev/null | head -n1)'"
  rm -rf "$DEPS_INSTALL_PATH/nvim" 1>/dev/null

  # Define packages needed for nvim and install
  local packages_tools=()
  local packages_build=(git curl ninja-build gettext cmake build-essential)
  install_dependencies_needs packages_tools[@] packages_build[@]

  if [[ $INSTALL_SOURCE_FROM == 'source' ]]; then
    git clone -q https://github.com/neovim/neovim.git "$DEPS_INSTALL_PATH/nvim"
    cd "$DEPS_INSTALL_PATH/nvim"
  elif [[ $INSTALL_SOURCE_FROM == 'release' ]]; then
    git clone -q https://github.com/neovim/neovim.git "$DEPS_INSTALL_PATH/nvim"
    cd "$DEPS_INSTALL_PATH/nvim"
    git checkout -q stable
    # git switch -q release-0.10
  fi

  # CMAKE_BUILD_TYPE: Release | RelWithDebInfo
  make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$USER_LOCAL_PREFIX/" 1>/dev/null
  make install 1>/dev/null
  cd - 1>/dev/null
  rm -rf "$DEPS_INSTALL_PATH/nvim" 1>/dev/null
  print_notes "   💡 new installed version :: '$("$USER_LOCAL_PREFIX_BIN/nvim" -v 2>/dev/null | head -n1)'"

  # Remove build dependencies if any
  install_dependencies_needs_rm

  print_info2 "🚀 NVIM :: nvim installed!"
}

# SERVICE :: install zsh -------------------------------------------------------
install_dependencies_zsh() {
  print_info2 "\n🚀 ZSH :: install zsh ..."
  print_notes "   💡 current installed version :: '$(zsh --version 2>/dev/null | head -n1)'"

  local zsh_install_bin_path
  if [[ $INSTALL_SOURCE_FROM == 'source' ]]; then
    # $RUN_WITH_SUDO apt-get install -y gcc make autoconf yodl texinfo libncurses-dev 1>/dev/null
    # rm -rf "$DEPS_INSTALL_PATH/zsh" 1>/dev/null
    # git clone -q https://github.com/zsh-users/zsh "$DEPS_INSTALL_PATH/zsh"
    # cd "$DEPS_INSTALL_PATH/zsh" 1>/dev/null
    # bash ./Util/preconfig 1>/dev/null
    # bash ./configure --prefix="$USER_LOCAL_PREFIX/" 1>/dev/null
    # make 1>/dev/null
    # # make check 1>/dev/null
    # make install 1>/dev/null
    # # make install.info 1>/dev/null
    # cd - 1>/dev/null
    # zsh_install_bin_path="$USER_LOCAL_PREFIX/bin/zsh"

    $RUN_WITH_SUDO apt-get install -y zsh 1>/dev/null
    zsh_install_bin_path="/usr/bin/zsh"
  elif [[ $INSTALL_SOURCE_FROM == 'release' ]]; then
    $RUN_WITH_SUDO apt-get install -y zsh 1>/dev/null
    zsh_install_bin_path="/usr/bin/zsh"
  fi
  [[ $IS_SUDO_INSTALL -eq 1 ]] && sudo -k

  print_info2 "🚀 ZSH :: Load git submodules"
  git submodule update -q --init --remote \
    zsh/oh-my-zsh \
    zsh/themes/spaceship \
    zsh/themes/headline \
    zsh/plugins/zsh-autosuggestions \
    zsh/plugins/zsh-syntax-highlighting

  rm -f "$LN_ZSH_OH_FOLDER" 1>/dev/null

  print_info2 "🚀 ZSH :: Create symlink from './zsh/oh-my-zsh' as '$LN_ZSH_OH_FOLDER'"
  ln -sf "${PWD}/zsh/oh-my-zsh" "$LN_ZSH_OH_FOLDER"

  print_info2 "🚀 ZSH :: Create symlink from './zsh/themes/*' into '$LN_ZSH_OH_FOLDER/custom/themes/*'"
  ln -sf "${PWD}/zsh/themes/spaceship/spaceship.zsh-theme" "$LN_ZSH_OH_FOLDER/custom/themes/spaceship.zsh-theme" 1>/dev/null
  ln -sf "${PWD}/zsh/themes/headline/headline.zsh-theme" "$LN_ZSH_OH_FOLDER/custom/themes/headline.zsh-theme" 1>/dev/null

  print_info2 "🚀 ZSH :: Create symlink from './zsh/plugins/*' into '$LN_ZSH_OH_FOLDER/custom/plugins/*'"
  ln -sf "${PWD}/zsh/plugins/zsh-autosuggestions" "$LN_ZSH_OH_FOLDER/custom/plugins/zsh-autosuggestions"
  ln -sf "${PWD}/zsh/plugins/zsh-syntax-highlighting" "$LN_ZSH_OH_FOLDER/custom/plugins/zsh-syntax-highlighting"

  print_notes "   💡 new installed version :: '$(zsh --version 2>/dev/null | head -n1)'"

  if [[ "$(basename "$SHELL")" != "zsh" ]]; then
    print_info2 "🚀 ZSH :: Set 'zsh' as new shell für user '$USER'"
    # sudo chsh -s "$(which zsh)" "$USER"
    $RUN_WITH_SUDO chsh -s "$zsh_install_bin_path" "$USER" || {
      print_error "  ❌ Failed to change default shell to ZSH. Please run 'sudo chsh -s \"$(which zsh)\" \"$USER\"' manually."
    }
    [[ $IS_SUDO_INSTALL -eq 1 ]] && sudo -k
  fi

  print_info2 "🚀 ZSH :: zsh installed!"
}

# SERVICE :: install ghostty ---------------------------------------------------
install_dependencies_ghostty() {
  print_info2 "\n🚀 GHOSTTY :: install ghostty ..."
  print_notes "   💡 current installed version :: '$("$USER_LOCAL_PREFIX_BIN/ghostty" --version 2>/dev/null | head -n1)'"
  rm -rf "$DEPS_INSTALL_PATH/ghostty" 1>/dev/null

  # Define packages needed for tmux and install
  local packages_tools=()
  local packages_build=(curl git libgtk-4-dev libadwaita-1-dev)
  install_dependencies_needs packages_tools[@] packages_build[@]

  local ZIG_COMMAND=zig
  if ! command -v zig &>/dev/null; then
    print_notes "   💡 Download binary zig..."
    curl -L -so "$DEPS_INSTALL_PATH/zig.tar.xz" "$VERSION_ZIG"
    mkdir -p "$DEPS_INSTALL_PATH/zig"
    tar xf "$DEPS_INSTALL_PATH/zig.tar.xz" -C "$DEPS_INSTALL_PATH/zig" --strip-components=1
    ZIG_COMMAND="$DEPS_INSTALL_PATH/zig/zig"
  fi

  if [[ $INSTALL_SOURCE_FROM == 'source' ]]; then
    git clone -q https://github.com/ghostty-org/ghostty.git "$DEPS_INSTALL_PATH/ghostty"
    cd "$DEPS_INSTALL_PATH/ghostty"
  elif [[ $INSTALL_SOURCE_FROM == 'release' ]]; then
    git clone -q https://github.com/ghostty-org/ghostty.git "$DEPS_INSTALL_PATH/ghostty"
    cd "$DEPS_INSTALL_PATH/ghostty"
    git checkout -q "$VERSION_GHOSTTY"
  fi

  "$ZIG_COMMAND" build -p "$USER_LOCAL_PREFIX" -Doptimize=ReleaseFast 1>/dev/null
  cd - 1>/dev/null
  rm -rf "$DEPS_INSTALL_PATH/ghostty" 1>/dev/null
  update-desktop-database ~/.local/share/applications/ -q
  print_notes "   💡 new installed version :: '$("$USER_LOCAL_PREFIX_BIN/ghostty" --version 2>/dev/null | head -n1)'"

  # Remove build dependencies if any
  install_dependencies_needs_rm

  print_info2 "🚀 GHOSTTY :: Create symlink from './ghostty/config' into '$LN_GHOSTTY_FOLDER'"
  mkdir -p "${LN_GHOSTTY_FOLDER}"
  ln -sf "${PWD}/ghostty/config" "${LN_GHOSTTY_FOLDER}/config"

  print_info2 "🚀 GHOSTTY :: Switch default keybind to open terminal ('<Ctrl><Alt>T')"
  gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['']"
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name "'Open Custom Terminal'"
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding "'<Ctrl><Alt>T'"
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command "'ghostty'"
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"

  print_info2 "🚀 GHOSTTY :: ghostty installed!"
}

# ******************************************************************************

# BIN :: CREATE LINKS ----------------------------------------------------------
setup_bin() {
  print_info2 "\n🚀 BIN :: Create symlink from './bin/*' into '$USER_LOCAL_PREFIX_BIN/'"
  mkdir -p "$USER_LOCAL_PREFIX_BIN"
  for script in "$PWD"/bin/*; do
    ln -sf "$script" "${USER_LOCAL_PREFIX_BIN}/$(basename "$script")" || print_error "  ❌ Failed to link $script"
  done
  print_info2 "🚀 BIN :: All symlinks created."
}

# TMUX :: CREATE LINKS ---------------------------------------------------------
setup_tmux() {
  print_info2 "\n🚀 TMUX :: Create symlink from './tmux/tmux' as '$LN_TMUX_ORIG_BASE'"
  rm -f "${LN_TMUX_ORIG_BASE}"
  ln -sf "${PWD}/tmux/tmux" "${LN_TMUX_ORIG_BASE}"
  print_info2 "🚀 TMUX :: Create symlink from './tmux/tmux.conf' as '$LN_TMUX_ORIG_TMUX'"
  rm -f "${LN_TMUX_ORIG_TMUX}"
  ln -sf "${PWD}/tmux/tmux.conf" "${LN_TMUX_ORIG_TMUX}"

  print_info2 "🚀 TMUX :: Load git submodules"
  git submodule update -q --init --remote tmux/tmux/plugins/tpm
  if command -v tmux &>/dev/null; then
    print_info2 "🚀 TMUX :: Run tpm to install plugins"
    PATH="$USER_LOCAL_PREFIX_BIN:$PATH" bash "${LN_TMUX_ORIG_BASE}/plugins/tpm/bin/install_plugins" 1>/dev/null
  fi

  print_info2 "🚀 TMUX :: All symlinks created."
}

# NVIM :: CREATE LINKS ---------------------------------------------------------
setup_nvim() {
  print_info2 "\n🚀 NVIM :: Create symlink from './nvim' as '$LN_NVIM_ORIG_BASE'"
  rm -f "${LN_NVIM_ORIG_BASE}"
  ln -sf "${PWD}/nvim" "${LN_NVIM_ORIG_BASE}"
  print_info2 "🚀 NVIM :: All symlinks created."
}

# CODE :: CREATE LINKS ---------------------------------------------------------
setup_code() {
  mkdir -p "$LN_VS_CODE"
  print_info2 "\n🚀 CODE :: Create symlink from './code/keybindings.json' into '$LN_VS_CODE'"
  rm -f "${LN_VS_CODE}/keybindings.json"
  ln -sf "${PWD}/code/keybindings.json" "${LN_VS_CODE}/keybindings.json"
  print_info2 "🚀 CODE :: Create symlink from './code/settings.json' into '$LN_VS_CODE'"
  rm -f "${LN_VS_CODE}/settings.json"
  ln -sf "${PWD}/code/settings.json" "${LN_VS_CODE}/settings.json"
  print_info2 "🚀 CODE :: Create symlink from './code/snippets' into '$LN_VS_CODE'"
  rm -f "${LN_VS_CODE}/snippets"
  ln -sf "${PWD}/code/snippets" "${LN_VS_CODE}/snippets"
  print_info2 "🚀 CODE :: All symlinks created."
}

# ZED :: CREATE LINKS ----------------------------------------------------------
setup_zed() {
  mkdir -p "$LN_ZED"
  print_info2 "\n🚀 ZED :: Create symlink from './zed/keymap.json' into '$LN_ZED'"
  rm -f "${LN_ZED}/keymap.json"
  ln -sf "${PWD}/zed/keymap.json" "${LN_ZED}/keymap.json"
  print_info2 "🚀 ZED :: Create symlink from './zed/settings.json' into '$LN_ZED'"
  rm -f "${LN_ZED}/settings.json"
  ln -sf "${PWD}/zed/settings.json" "${LN_ZED}/settings.json"
  print_info2 "🚀 ZED :: Create symlink from './zed/snippets' into '$LN_ZED'"
  rm -f "${LN_ZED}/snippets"
  ln -sf "${PWD}/zed/snippets" "${LN_ZED}/snippets"
  print_info2 "🚀 ZED :: All symlinks created."
}

# ADDS :: CREATE LINKS ---------------------------------------------------------
setup_adds() {
  print_info2 "\n🚀 ADDS :: Create symlink from './zsh/zshrc' as '$LN_ZSHRC'"
  rm -f "${LN_ZSHRC}"
  ln -sf "${PWD}/zsh/zshrc" "${LN_ZSHRC}"

  print_info2 "🚀 ADDS :: Create symlink from './zsh/zshrc-append' as '$LN_ADDS_01'"
  rm -f "${LN_ADDS_01}"
  ln -sf "${PWD}/zsh/zshrc-append" "${LN_ADDS_01}"
  print_info2 "🚀 ADDS :: Create symlink from './zsh/zshrc-sec' as '$LN_ADDS_02'"
  rm -f "${LN_ADDS_02}"
  ln -sf "${PWD}/zsh/zshrc-sec" "${LN_ADDS_02}"

  local lines_to_add=(
    'source ~/.zshrc-append'
    'source ~/.zshrc-sec'
    'touch ~/.zshrc-secrets'
    'source ~/.zshrc-secrets'
  )
  for line in "${lines_to_add[@]}"; do
    if ! grep -Fxq "$line" "${HOME}/.bashrc"; then
      echo "$line" >>"${HOME}/.bashrc"
    fi
  done

  print_info2 "🚀 ADDS :: All symlinks created."
}

# LOGSEQ :: CREATE LINKS -------------------------------------------------------
setup_logseq() {
  mkdir -p "${LN_LOGSEQ_PATH}/config/"

  print_info2 "\n🚀 LOGSEQ :: Create symlink from './logseq/preferences.json' as '$LN_LOGSEQ_PATH/preferences.json'"
  rm -f "${LN_LOGSEQ_PATH}/preferences.json"
  ln -sf "${PWD}/logseq/preferences.json" "${LN_LOGSEQ_PATH}/preferences.json"
  print_info2 "🚀 LOGSEQ :: Create symlink from './logseq/config.edn' as '$LN_LOGSEQ_PATH/config/config.edn'"
  rm -f "${LN_LOGSEQ_PATH}/config/config.edn"
  ln -sf "${PWD}/logseq/config.edn" "${LN_LOGSEQ_PATH}/config/config.edn"
  print_info2 "🚀 LOGSEQ :: Create symlink from './logseq/plugins.edn' as '$LN_LOGSEQ_PATH/config/plugins.edn'"
  rm -f "${LN_LOGSEQ_PATH}/config/plugins.edn"
  ln -sf "${PWD}/logseq/plugins.edn" "${LN_LOGSEQ_PATH}/config/plugins.edn"

  print_info2 "🚀 LOGSEQ :: All symlinks created."
}

# ******************************************************************************

# CODE :: install ext ----------------------------------------------------------
install_code_ext() {
  if command -v code &>/dev/null; then
    print_info2 "\n🚀 CODE :: installing code extensions"

    VS_CODE_EXTS=(
      "aaron-bond.better-comments" "adpyke.vscode-sql-formatter" "analytic-signal.preview-pdf" "bibhasdn.unique-lines"
      "bierner.markdown-preview-github-styles" "charliermarsh.ruff" "donjayamanne.githistory" "eamodio.gitlens"
      "esbenp.prettier-vscode" "foxundermoon.shell-format" "ms-python.python" "mushan.vscode-paste-image"
      "pkief.material-icon-theme" "redhat.ansible" "redhat.vscode-xml" "redhat.vscode-yaml"
      "samuelcolvin.jinjahtml" "silofy.hackthebox" "streetsidesoftware.code-spell-checker"
      "streetsidesoftware.code-spell-checker-german" "tamasfe.even-better-toml" "timonwong.shellcheck"
      "wayou.vscode-todo-highlight" "yzane.markdown-pdf" "yzhang.markdown-all-in-one"
    )

    for vs_code_ext in "${VS_CODE_EXTS[@]}"; do
      print_info2 "  📌 CODE:: install extionsion '$vs_code_ext'"
      code --force --install-extension "$vs_code_ext" 1>/dev/null
    done
  else
    print_error "👎CODE :: code is not installed, extension install will skipped!"
  fi
}

# FONTS :: add fonts -----------------------------------------------------------
install_fonts() {
  print_info2 "\n🚀 FONTS :: Download some nerd fonts"

  local packages_tools=()
  local packages_build=(curl)
  install_dependencies_needs packages_tools[@] packages_build[@]

  FONTS_URLS=(
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION_FONTS_RELEASE}/NerdFontsSymbolsOnly.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION_FONTS_RELEASE}/FiraCode.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION_FONTS_RELEASE}/Hack.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION_FONTS_RELEASE}/UbuntuMono.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION_FONTS_RELEASE}/FiraMono.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION_FONTS_RELEASE}/RobotoMono.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION_FONTS_RELEASE}/ProggyClean.tar.xz"
  )
  FONTS_DIR="${HOME}/.local/share/fonts/nerd-fonts"
  mkdir -p "$FONTS_DIR"

  for url in "${FONTS_URLS[@]}"; do
    file_name=$(basename "$url")

    print_info2 "  - ⬇️ Downloading $file_name..."
    curl -sL -o "/tmp/$file_name" "$url" || {
      print_error "Failed to download $file_name"
      return 1
    }

    print_info2 "  - ⬇️ Extracting $file_name..."
    tar -xf "/tmp/$file_name" -C "$FONTS_DIR" || {
      print_error "Failed to extract $file_name"
      return 1
    }

    rm "/tmp/$file_name"
  done

  install_dependencies_needs_rm

  print_info2 "🚀 FONTS :: All fonts are downloaded and extracted"
}

install_btop() {
  print_info2 "\n🚀 BTOP :: install btop..."
  print_notes "   💡 current installed version :: '$("$USER_LOCAL_PREFIX_BIN/btop" -v 2>/dev/null | head -n1)'"
  rm -rf "$DEPS_INSTALL_PATH/btop" 1>/dev/null

  # Define packages needed for btop and install
  local packages_tools=()
  local packages_build=(git build-essential cmake libdrm-dev)
  install_dependencies_needs packages_tools[@] packages_build[@]

  if [[ $INSTALL_SOURCE_FROM == 'source' ]]; then
    git clone -q https://github.com/aristocratos/btop.git "$DEPS_INSTALL_PATH/btop"
    pushd "$DEPS_INSTALL_PATH/btop" 1>/dev/null
  elif [[ $INSTALL_SOURCE_FROM == 'release' ]]; then
    git clone -q https://github.com/aristocratos/btop.git "$DEPS_INSTALL_PATH/btop"
    pushd "$DEPS_INSTALL_PATH/btop" 1>/dev/null
    git checkout -q "${VERSION_BTOP}"
  fi

  # Handle ROCm SMI if needed
  local RSMI_STATIC='false'
  if [[ $RUN_INSTALL_BTOP_AMD -eq 1 ]]; then
    git clone -q --depth 1 -b "$VERSION_RSMI" https://github.com/RadeonOpenCompute/rocm_smi_lib.git lib/rocm_smi_lib
    pushd lib/rocm_smi_lib 1>/dev/null
    mkdir -p build 1>/dev/null
    cd build 1>/dev/null
    cmake .. 1>/dev/null
    make -j "$(nproc)" 1>/dev/null
    popd 1>/dev/null
    RSMI_STATIC='true'
  fi

  # Build and install btop
  make -j "$(nproc)" GPU_SUPPORT="true" RSMI_STATIC="$RSMI_STATIC" ADDFLAGS="-Wno-dangling-reference -march=native" 1>/dev/null
  make install PREFIX="$USER_LOCAL_PREFIX" 1>/dev/null

  popd 1>/dev/null
  rm -rf "$DEPS_INSTALL_PATH/btop" 1>/dev/null
  print_notes "   💡 new installed version :: '$("$USER_LOCAL_PREFIX_BIN/btop" -v 2>/dev/null | head -n1)'"

  if [[ $RUN_INSTALL_BTOP_INTEL -eq 1 ]]; then
    print_notes "   💡 configure btop with 'setcap' for 'GPU' access without 'sudo'"
    $RUN_WITH_SUDO setcap cap_dac_read_search,cap_sys_admin+ep "$USER_LOCAL_PREFIX_BIN/btop" 1>/dev/null
    [[ $IS_SUDO_INSTALL -eq 1 ]] && sudo -k
  fi

  # Remove build dependencies if any
  install_dependencies_needs_rm

  print_info2 "🚀 BTOP :: btop installed!"
}

# ******************************************************************************

print_info() { echo -e "${BPURPLE}$1${NC}"; }
print_info2() { echo -e "${BYELLOW}$1${NC}"; }
print_notes() { echo -e "${BCYAN}$1${NC}"; }
print_error() { echo -e "${BRED}$1${NC}" >&2; }

# ******************************************************************************

# Function to show usage information
usage() {
  print_info "📑 Usage: $0 [options]"
  print_info "   Examples:"
  print_info "     $0                                             Run only config setups without installations"
  print_info "     $0 -if                                         Run config setups with fonts install"
  print_info "     $0 -ds -it                                     Install only additional tools"
  print_info "     $0 -ds -itmux -invim                           Install only tmux and nvim"
  print_info "     $0 -ds -izsh                                   Install only zsh"
  print_info "     $0 -ds -ighost                                 Install only ghostty"
  print_info "     $0 -ds -ibtop                                  Install only btop"
  print_info "     $0 -it -invim -izsh -itmux                     Install nvim, zsh and tmux with additional tools + config setup"
  print_info "     $0 -it -invim -ighost                          Install nvim and ghostty with additional tools + config setup"
  print_info "   Options:"
  print_info "     -h,            --help                          Show this help message and exit"
  print_info "     -it,           --install-additional-tools      Install additional tools [rsync fzf eza bat ripgrep fd-find]"
  print_info "     -itmux,        --install-dependencies-tmux     Install/update service tmux"
  print_info "     -invim,        --install-dependencies-nvim     Install/update service nvim"
  print_info "     -izsh,         --install-dependencies-zsh      Install/update service zsh"
  print_info "     -ighost,       --install-dependencies-ghostty  Install/update service ghostty"
  print_info "     -nsb,          --not-setup-bin                 Skip setup_bin"
  print_info "     -nst,          --not-setup-tmux                Skip setup_tmux"
  print_info "     -nsv,          --not-setup-nvim                Skip setup_nvim"
  print_info "     -nsc,          --not-setup-code                Skip setup_code"
  print_info "     -nsz,          --not-setup-zed                 Skip setup_zed"
  print_info "     -nsa,          --not-setup-adds                Skip setup_adds"
  print_info "     -nsl,          --not-setup-logseq              Skip setup_logseq"
  print_info "     -ds,           --disable-setups                Skip all setup"
  print_info "     -ice,          --install-code-ext              Run install install_code_ext"
  print_info "     -ifont,        --install-fonts                 Run install install_fonts"
  print_info "     -ibtop,        --install-btop                  Run install install_btop"
  print_info "     -ibtop-amd,    --install-btop-amd              Run install install_btop with AMD GPU support"
  print_info "     -ibtop-intel,  --install-btop-intel            Run install install_btop with intel GPU support"
  print_info "     -s                                             Use 'source' instead 'release' for install services"
}

# Function to parse command-line arguments
parse_args() {
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    -h | --help)
      usage
      exit 0
      ;;
    -it | --install-additional-tools)
      RUN_INSTALL_DEPENDENCIES_ADDITIONAL=1
      ;;
    -itmux | --install-dependencies-tmux)
      RUN_INSTALL_DEPENDENCIES_TMUX=1
      ;;
    -invim | --install-dependencies-nvim)
      RUN_INSTALL_DEPENDENCIES_NVIM=1
      ;;
    -izsh | --install-dependencies-zsh)
      RUN_INSTALL_DEPENDENCIES_ZSH=1
      ;;
    -ighost | --install-dependencies-ghostty)
      RUN_INSTALL_DEPENDENCIES_GHOSTTY=1
      ;;
    -ioall | --install-dependencies-old-all)
      RUN_INSTALL_DEPENDENCIES_ADDITIONAL=1
      RUN_INSTALL_DEPENDENCIES_TMUX=1
      RUN_INSTALL_DEPENDENCIES_NVIM=1
      RUN_INSTALL_DEPENDENCIES_ZSH=1
      ;;
    -inall | --install-dependencies-new-all)
      RUN_INSTALL_DEPENDENCIES_ADDITIONAL=1
      RUN_INSTALL_DEPENDENCIES_NVIM=1
      RUN_INSTALL_DEPENDENCIES_GHOSTTY=1
      RUN_SETUP_TMUX=0
      ;;
    -nsb | --not-setup-bin)
      RUN_SETUP_BIN=0
      ;;
    -nst | --not-setup-tmux)
      RUN_SETUP_TMUX=0
      ;;
    -nsv | --not-setup-nvim)
      RUN_SETUP_NVIM=0
      ;;
    -nsc | --not-setup-code)
      RUN_SETUP_CODE=0
      ;;
    -nsz | --not-setup-zed)
      RUN_SETUP_ZED=0
      ;;
    -nsa | --not-setup-adds)
      RUN_SETUP_ADDS=0
      ;;
    -nsl | --not-setup-logseq)
      RUN_SETUP_LOGSEQ=0
      ;;
    -ds | --disable-setups)
      RUN_SETUP_BIN=0
      RUN_SETUP_TMUX=0
      RUN_SETUP_NVIM=0
      RUN_SETUP_CODE=0
      RUN_SETUP_ZED=0
      RUN_SETUP_ADDS=0
      RUN_SETUP_LOGSEQ=0
      ;;
    -ice | --install-code-ext)
      RUN_INSTALL_CODE_EXT=1
      ;;
    -ifont | --install-fonts)
      RUN_INSTALL_FONTS=1
      ;;
    -ibtop | --install-btop)
      RUN_INSTALL_BTOP=1
      ;;
    -ibtop-amd | --install-btop-amd)
      RUN_INSTALL_BTOP=1
      RUN_INSTALL_BTOP_AMD=1
      ;;
    -ibtop-intel | --install-btop-intel)
      RUN_INSTALL_BTOP=1
      RUN_INSTALL_BTOP_INTEL=1
      ;;
    -s)
      INSTALL_SOURCE_FROM=source
      ;;
    -d | --debug)
      set -x # Enable debug mode
      ;;
    *)
      print_error "❌ Unknown option: $key"
      usage
      exit 1
      ;;
    esac
    shift
  done
}

# ******************************************************************************

print_info2 "✅ Starting script $0 ..."

# Parse command-line arguments
parse_args "$@"

main
exit 0
