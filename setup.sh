#!/usr/bin/env bash

PATH=/usr/bin/:/usr/local/bin/:/bin:/usr/sbin/:/sbin:/snap/bin/
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

### COLOR ### (https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux)
NC='\033[0m' # No Color
# Bold
BRED='\033[1;31m'    # Red
BPURPLE='\033[1;35m' # Purple
BYELLOW='\033[1;33m' # Yellow
BCYAN='\033[1;36m'   # Cyan

# CONFS :: variables -------------------------------------------------------------------------------------------------------------
RUN_INSTALL_DEPENDENCIES_ADDITIONAL=0
RUN_INSTALL_DEPENDENCIES_TMUX=0
RUN_INSTALL_DEPENDENCIES_NVIM=0
RUN_INSTALL_DEPENDENCIES_ZSH=0
RUN_SETUP_BIN=1
RUN_SETUP_TMUX=1
RUN_SETUP_NVIM=1
RUN_SETUP_CODE=1
RUN_SETUP_CODE_EXT=1
RUN_SETUP_ZED=1
RUN_SETUP_ADDS=1
RUN_SETUP_FONTS=1
RUN_SETUP_LOGSEQ=1

# CONFS :: variables -------------------------------------------------------------------------------------------------------------
INSTALL_SOURCE_FROM=release # source | release
FONTS_RELEASE_VERSION='v3.2.1'

DEPS_INSTALL_PATH="${HOME}/.tmp" # /tmp
DEPS_INSTALL_PKGS=()

USER_LOCAL_PREFIX="${HOME}/.local"
USER_LOCAL_PREFIX_BIN="$USER_LOCAL_PREFIX/bin"

: "${LN_TMUX_ORIG_BASE=${HOME}/.tmux}"
: "${LN_TMUX_ORIG_TMUX=${HOME}/.tmux.conf}"

: "${LN_NVIM_ORIG_BASE=${HOME}/.config/nvim}"

: "${LN_ZSH_OH_FOLDER=${HOME}/.oh-my-zsh}"
LN_ZSHRC="${HOME}/.zshrc"
LN_ADDS_01="${HOME}/.zshrc-append"
LN_ADDS_02="${HOME}/.zshrc-sec"

: "${LN_VS_CODE=${HOME}/.config/Code/User}"

LN_ZED_FLATPAK="${HOME}/.var/app/dev.zed.Zed/config/zed"
: "${LN_ZED=$LN_ZED_FLATPAK}"
# LN_ZED=${HOME}/.config/zed

LN_LOGSEQ_PATH="${HOME}/.logseq"

# ******************************************************************************

main() {
  initialize_base
  [[ $RUN_INSTALL_DEPENDENCIES_ADDITIONAL -eq 1 ]] && install_dependencies_additional

  if [[ $RUN_INSTALL_DEPENDENCIES_TMUX -eq 1 || $RUN_INSTALL_DEPENDENCIES_NVIM -eq 1 ]]; then
    install_dependencies_needs
    [[ $RUN_INSTALL_DEPENDENCIES_TMUX -eq 1 ]] && install_dependencies_tmux
    [[ $RUN_INSTALL_DEPENDENCIES_NVIM -eq 1 ]] && install_dependencies_nvim
    install_dependencies_needs_rm
  fi

  [[ $RUN_INSTALL_DEPENDENCIES_ZSH -eq 1 ]] && install_dependencies_zsh

  [[ $RUN_SETUP_BIN -eq 1 ]] && setup_bin
  [[ $RUN_SETUP_TMUX -eq 1 ]] && setup_tmux
  [[ $RUN_SETUP_NVIM -eq 1 ]] && setup_nvim
  [[ $RUN_SETUP_CODE -eq 1 ]] && setup_code
  [[ $RUN_SETUP_CODE_EXT -eq 1 ]] && setup_code_ext
  [[ $RUN_SETUP_ZED -eq 1 ]] && setup_zed
  [[ $RUN_SETUP_ADDS -eq 1 ]] && setup_adds
  [[ $RUN_SETUP_FONTS -eq 1 ]] && setup_fonts
  [[ $RUN_SETUP_LOGSEQ -eq 1 ]] && setup_logseq
}

# ******************************************************************************

# GIT :: init recursive --------------------------------------------------------------------------------------------------------
initialize_base() {
  mkdir -p "$HOME/.config" 1>/dev/null
}

# DEPS :: install dependencies -------------------------------------------------------------------------------------------------
install_dependencies_additional() {
  print_info2 "\n📥 DEPS :: install some base services :: [rsync,fzf,eza,bat,ripgrep,fd-find,xclip]"
  "${PKG_CMD_INSTALL[@]}" rsync fzf eza bat ripgrep fd-find xclip 1>/dev/null

  print_info2 "📥 DEPS :: disable rsync systemd service"
  sudo systemctl disable rsync.service &>/dev/null
  sudo systemctl mask rsync.service &>/dev/null

  # echo "DEPS :: install npm"
  # sudo snap install node --classic

  # echo "DEPS :: install lazygit with go"
  # sudo snap install go --classic
  # go install github.com/jesseduffield/lazygit@latest

  # echo "DEPS :: install zed over flatpak"
  # flatpak install flathub dev.zed.Zed
}

install_dependencies_needs() {
  print_info2 "\n📥 DEPS :: install build dependincies"
  local packages_tools=(git curl unzip libevent-dev)
  local packages_build=(ninja-build gettext cmake build-essential
    automake pkg-config libevent-dev libncurses-dev bison)

  for pkg in "${packages_build[@]}"; do
    if ! "${PKG_CMD_LIST[@]}" "$pkg" 2>/dev/null | "${INSTALLED_CHECK_CMD[@]}"; then
      DEPS_INSTALL_PKGS+=("$pkg")
    fi
  done

  print_info2 "📥 DEPS :: following pkg's will be installed: '[$(echo "${packages_tools[*]}" | tr '\n' ',')$(echo "${DEPS_INSTALL_PKGS[*]}" | tr '\n' ',')]'"
  print_info2 "📥 DEPS :: following pkg's will be afterwards uninstalled: '[$(echo "${DEPS_INSTALL_PKGS[*]}" | tr '\n' ',')]'"
  print_info2 "📥 DEPS :: installing..."
  if [[ ${#DEPS_INSTALL_PKGS[@]} -gt 0 || ${#packages_tools[@]} -gt 0 ]]; then
    "${PKG_CMD_UPDATE[@]}" 1>/dev/null
    "${PKG_CMD_INSTALL[@]}" "${packages_tools[@]}" "${DEPS_INSTALL_PKGS[@]}" 1>/dev/null
  fi
  print_info2 "📥 DEPS :: installed!"
}

install_dependencies_needs_rm() {
  print_info2 "\n📥 DEPS :: removing not needed build dependincies '[$(echo "${DEPS_INSTALL_PKGS[*]}" | tr '\n' ',')]'..."
  "${PKG_CMD_REMOVE[@]}" "${DEPS_INSTALL_PKGS[@]}" 1>/dev/null
  # sudo apt-get -y autoremove 1>/dev/null
  # sudo apt-get -y autoclean 1>/dev/null
  print_info2 "📥 DEPS :: removed!"
}

install_dependencies_tmux() {
  print_info2 "\n🚀 TMUX :: install tmux for user only..."
  print_notes "   💡 current installed version :: '$("$USER_LOCAL_PREFIX_BIN/tmux" -V 2>/dev/null)'"
  rm -rf "$DEPS_INSTALL_PATH/tmux" 1>/dev/null

  if [[ $INSTALL_SOURCE_FROM == 'source' ]]; then
    git clone -q https://github.com/tmux/tmux.git "$DEPS_INSTALL_PATH/tmux"
    cd "$DEPS_INSTALL_PATH/tmux"
    bash ./autogen.sh 1>/dev/null
  else
    curl -L -so "$DEPS_INSTALL_PATH/tmux.tar.gz" "$(curl -s 'https://api.github.com/repos/tmux/tmux/releases/latest' | jq -r '.assets[] | select(.name | test(".*tar.gz$")) | .browser_download_url')"
    mkdir -p "$DEPS_INSTALL_PATH/tmux"
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
  print_info2 "🚀 TMUX :: tmux for user only installed!"
}

install_dependencies_nvim() {
  print_info2 "\n🚀 NVIM :: install nvim for user only..."
  print_notes "   💡 current installed version :: '$("$USER_LOCAL_PREFIX_BIN/nvim" -v 2>/dev/null | head -n1)'"
  rm -rf "$DEPS_INSTALL_PATH/nvim" 1>/dev/null

  if [[ $INSTALL_SOURCE_FROM == 'source' ]]; then
    git clone -q https://github.com/neovim/neovim.git "$DEPS_INSTALL_PATH/nvim"
    cd "$DEPS_INSTALL_PATH/nvim"
  else
    git clone -q https://github.com/neovim/neovim.git "$DEPS_INSTALL_PATH/nvim"
    cd "$DEPS_INSTALL_PATH/nvim"
    git switch -q stable
  fi

  # Release | RelWithDebInfo
  make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$USER_LOCAL_PREFIX/" 1>/dev/null
  make install 1>/dev/null
  cd - 1>/dev/null
  rm -rf "$DEPS_INSTALL_PATH/nvim" 1>/dev/null
  print_notes "   💡 new installed version :: '$("$USER_LOCAL_PREFIX_BIN/nvim" -v 2>/dev/null | head -n1)'"
  print_info2 "🚀 NVIM :: nvim for user only installed!"
}

install_dependencies_zsh() {
  print_info2 "\n🚀 ZSH :: install zsh ..."
  print_notes "   💡 current installed version :: '$(zsh --version 2>/dev/null | head -n1)'"

  local ZSH_INSTALL_BIN_PATH
  if [[ $INSTALL_SOURCE_FROM == 'source' ]]; then
    git clone -q https://github.com/zsh-users/zsh "$DEPS_INSTALL_PATH/zsh"
    cd "$DEPS_INSTALL_PATH/zsh"
    bash ./Util/preconfig 1>/dev/null
    bash ./configure --prefix="$USER_LOCAL_PREFIX/" 1>/dev/null
    make 1>/dev/null
    make install 1>/dev/null
    ZSH_INSTALL_BIN_PATH="$USER_LOCAL_PREFIX/bin/zsh"

    # "${PKG_CMD_INSTALL[@]}" zsh 1>/dev/null
  else
    "${PKG_CMD_INSTALL[@]}" zsh 1>/dev/null
    ZSH_INSTALL_BIN_PATH="/usr/bin/zsh"
  fi

  print_info2 "🚀 ZSH :: Load git submodules"
  git submodule -q update --init --remote \
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
    sudo chsh -s "$ZSH_INSTALL_BIN_PATH" "$USER" || {
      print_error "  ❌ Failed to change default shell to ZSH. Please run 'sudo chsh -s \"$(which zsh)\" \"$USER\"' manually."
    }
  fi

  print_info2 "🚀 ZSH :: zsh installed!"
}

# BIN :: CREATE LINKS ----------------------------------------------------------------------------------------------------------
setup_bin() {
  print_info2 "\n🚀 BIN :: Create symlink from './bin/*' into '$USER_LOCAL_PREFIX_BIN/'"
  mkdir -p "$USER_LOCAL_PREFIX_BIN"
  for script in "$PWD"/bin/*; do
    ln -sf "$script" "${USER_LOCAL_PREFIX_BIN}/$(basename "$script")" || print_error "  ❌ Failed to link $script"
  done
  print_info2 "🚀 BIN :: All symlinks created."
}

# TMUX :: CREATE LINKS ----------------------------------------------------------------------------------------------------------
setup_tmux() {
  print_info2 "\n🚀 TMUX :: Load git submodules"
  git submodule -q update --init --remote tmux/tmux/plugins/tpm

  print_info2 "\n🚀 TMUX :: Create symlink from './tmux/tmux' as '$LN_TMUX_ORIG_BASE'"
  rm -f "${LN_TMUX_ORIG_BASE}"
  ln -sf "${PWD}/tmux/tmux" "${LN_TMUX_ORIG_BASE}"
  print_info2 "🚀 TMUX :: Create symlink from './tmux/tmux.conf' as '$LN_TMUX_ORIG_TMUX'"
  rm -f "${LN_TMUX_ORIG_TMUX}"
  ln -sf "${PWD}/tmux/tmux.conf" "${LN_TMUX_ORIG_TMUX}"

  print_info2 "🚀 TMUX :: Run tpm to install plugins"
  PATH="$USER_LOCAL_PREFIX_BIN:$PATH" bash "${LN_TMUX_ORIG_BASE}/plugins/tpm/bin/install_plugins" 1>/dev/null

  print_info2 "🚀 TMUX :: All symlinks created."
}

# NVIM :: CREATE LINKS ----------------------------------------------------------------------------------------------------------
setup_nvim() {
  print_info2 "\n🚀 NVIM :: Create symlink from './nvim' as '$LN_NVIM_ORIG_BASE'"
  rm -f "${LN_NVIM_ORIG_BASE}"
  ln -sf "${PWD}/nvim" "${LN_NVIM_ORIG_BASE}"
  print_info2 "🚀 NVIM :: All symlinks created."
}

# CODE :: CREATE LINKS -----------------------------------------------------------------------------------------------------------
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

setup_code_ext() {
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

# ZED :: CREATE LINKS -----------------------------------------------------------------------------------------------------------
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

# ADDS :: CREATE LINKS ----------------------------------------------------------------------------------------------------------
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

  print_info2 "🚀 ADDS :: All symlinks created."
}

# LOGSEQ :: CREATE LINKS ----------------------------------------------------------------------------------------------------------
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

# FONTS :: ADD FONTS ------------------------------------------------------------------------------------------------------------
setup_fonts() {
  print_info2 "\n🚀 FONTS :: Download some nerd fonts"
  FONTS_URLS=(
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${FONTS_RELEASE_VERSION}/NerdFontsSymbolsOnly.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${FONTS_RELEASE_VERSION}/FiraCode.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${FONTS_RELEASE_VERSION}/Hack.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${FONTS_RELEASE_VERSION}/UbuntuMono.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${FONTS_RELEASE_VERSION}/FiraMono.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${FONTS_RELEASE_VERSION}/RobotoMono.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${FONTS_RELEASE_VERSION}/ProggyClean.tar.xz"
  )
  FONTS_DIR="${HOME}/.local/share/fonts/nerd-fonts"
  mkdir -p "$FONTS_DIR"

  for url in "${FONTS_URLS[@]}"; do
    file_name=$(basename "$url")
    print_info2 "🚀 FONTS :: Downloading $file_name..."
    curl -sL -o "/tmp/$file_name" "$url"
    print_info2 "🚀 FONTS :: Extracting $file_name..."
    tar -xf "/tmp/$file_name" -C "$FONTS_DIR"
    rm "/tmp/$file_name"
  done

  print_info2 "🚀 FONTS :: All fonts are downloaded and extracted"
}

# ******************************************************************************

print_info() { echo -e "${BPURPLE}$1${NC}"; }
print_info2() { echo -e "${BYELLOW}$1${NC}"; }
print_notes() { echo -e "${BCYAN}$1${NC}"; }
print_error() { echo -e "${BRED}$1${NC}" >&2; }

# ******************************************************************************

# Detect OS and set variables
set_os_variables() {
  if [[ -f "/etc/os-release" ]]; then
    # shellcheck source=/dev/null
    . "/etc/os-release"
    case $ID in
    ubuntu | debian)
      print_info "🤖 Detect '$ID' as running OS will use 'sudo' for further installations"
      PKG_MANAGER=("sudo" "apt-get")
      INSTALL_CMD=("install" "-y")
      REMOVE_CMD=("remove" "-y")
      UPDATE_CMD=("update" "-qq")
      LIST_CMD=("list" "-qq")
      INSTALLED_CHECK_CMD=("grep" "-q" "'installed'")
      ;;
    fedora)
      print_info "🤖 Detect '$ID' as running OS will use 'dnf' for further installations"
      PKG_MANAGER=("sudo" "dnf")
      INSTALL_CMD=("install" "-y")
      REMOVE_CMD=("remove" "-y")
      UPDATE_CMD=("update" "-qq")
      LIST_CMD=("info")
      INSTALLED_CHECK_CMD=("grep" "-q" "'Installed Packages'")
      ;;
    *)
      print_error "Unsupported OS: $ID"
      exit 1
      ;;
    esac

    PKG_CMD_INSTALL=("${PKG_MANAGER[@]}" "${INSTALL_CMD[@]}")
    PKG_CMD_REMOVE=("${PKG_MANAGER[@]}" "${REMOVE_CMD[@]}")
    PKG_CMD_UPDATE=("${PKG_MANAGER[@]}" "${UPDATE_CMD[@]}")
    PKG_CMD_LIST=("${PKG_MANAGER[@]}" "${LIST_CMD[@]}")
  else
    print_error "/etc/os-release not found!"
    exit 1
  fi
}

# Function to show usage information
usage() {
  print_info "📑 Usage: $0 [options]"
  print_info "   Examples:"
  print_info "     $0                                         Run all setups"
  print_info "     $0 -nsce -nsf                              Run all setups without vscode ext and fonts"
  print_info "     $0 -ds -ida                                Install only additional tools"
  print_info "     $0 -ds -idt -idn                           Install only tmux and nvim"
  print_info "     $0 -ds -idz                                Install only zsh"
  print_info "     $0 -nsce -nsf -ida -idt -idn -idz          Full setup and install"
  print_info "   Options:"
  print_info "     -h,    --help                               Show this help message and exit"
  print_info "     -ida,  --install-dependencies-additional    Not Skip install additional tools [rsync fzf eza bat ripgrep fd-find]"
  print_info "     -idt,  --install-dependencies-tmux          Not Skip install/update services tmux (user based)"
  print_info "     -idn,  --install-dependencies-nvim          Not Skip install/update services nvim (user based)"
  print_info "     -idz,  --install-dependencies-zsh           Not Skip install/update service zsh"
  print_info "     -nsb,  --not-setup-bin                      Skip setup_bin"
  print_info "     -nst,  --not-setup-tmux                     Skip setup_tmux"
  print_info "     -nsn,  --not-setup-nvim                     Skip setup_nvim"
  print_info "     -nsc,  --not-setup-code                     Skip setup_code"
  print_info "     -nsce, --not-setup-code-ext                 Skip setup_code_ext"
  print_info "     -nsz,  --not-setup-zed                      Skip setup_zed"
  print_info "     -nsa,  --not-setup-adds                     Skip setup_adds"
  print_info "     -nsf,  --not-setup-fonts                    Skip setup_fonts"
  print_info "     -nsl,  --not-setup-logseq                   Skip setup_logseq"
  print_info "     -vpn,  --setup-vpn                          setup_vpn"
  print_info "     -ds,   --disable-setups                     Skip all setup"
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
    -ida | --install-dependencies-additional)
      RUN_INSTALL_DEPENDENCIES_ADDITIONAL=1
      ;;
    -idt | --install-dependencies-tmux)
      RUN_INSTALL_DEPENDENCIES_TMUX=1
      ;;
    -idn | --install-dependencies-nvim)
      RUN_INSTALL_DEPENDENCIES_NVIM=1
      ;;
    -idz | --install-dependencies-zsh)
      RUN_INSTALL_DEPENDENCIES_ZSH=1
      ;;
    -nsb | --not-setup-bin)
      RUN_SETUP_BIN=0
      ;;
    -nst | --not-setup-tmux)
      RUN_SETUP_TMUX=0
      ;;
    -nsn | --not-setup-nvim)
      RUN_SETUP_NVIM=0
      ;;
    -nsc | --not-setup-code)
      RUN_SETUP_CODE=0
      ;;
    -nsce | --not-setup-code-ext)
      RUN_SETUP_CODE_EXT=0
      ;;
    -nsz | --not-setup-zed)
      RUN_SETUP_ZED=0
      ;;
    -nsa | --not-setup-adds)
      RUN_SETUP_ADDS=0
      ;;
    -nsf | --not-setup-fonts)
      RUN_SETUP_FONTS=0
      ;;
    -nsl | --not-setup-logseq)
      RUN_SETUP_LOGSEQ=0
      ;;
    -ds | --disable-setups)
      RUN_SETUP_BIN=0
      RUN_SETUP_TMUX=0
      RUN_SETUP_NVIM=0
      RUN_SETUP_CODE=0
      RUN_SETUP_CODE_EXT=0
      RUN_SETUP_ZED=0
      RUN_SETUP_ADDS=0
      RUN_SETUP_FONTS=0
      RUN_SETUP_LOGSEQ=0
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

set_os_variables
main
exit 0
