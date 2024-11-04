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
RUN_INSTALL_DEPENDENCIES_TMUX_NVIM=0
RUN_SETUP_BIN=1
RUN_SETUP_TMUX=1
RUN_SETUP_NVIM=1
RUN_SETUP_CODE=1
RUN_SETUP_CODE_EXT=1
RUN_SETUP_ADDS=1
RUN_SETUP_FONTS=1

# CONFS :: variables -------------------------------------------------------------------------------------------------------------
DEPS_INSTALL_PATH=/tmp
DEPS_INSTALL_PKGS=()

USER_LOCAL_PREFIX=~/.local
USER_LOCAL_PREFIX_BIN="$USER_LOCAL_PREFIX/bin"

LN_TMUX_ORIG_BASE=~/.tmux
LN_TMUX_ORIG_TMUX=~/.tmux.conf

LN_NVIM_ORIG_BASE=~/.config/nvim

LN_ZSHRC=~/.zshrc
LN_ADDS_01=~/.zshrc-append
LN_ADDS_02=~/.zshrc-sec

LN_VS_CODE=~/.config/Code/User

# ******************************************************************************

main() {
  setup_base
  [[ $RUN_INSTALL_DEPENDENCIES_ADDITIONAL -eq 1 ]] && install_dependencies_additional

  [[ $RUN_INSTALL_DEPENDENCIES_TMUX_NVIM -eq 1 ]] && install_dependencies_needs
  [[ $RUN_INSTALL_DEPENDENCIES_TMUX_NVIM -eq 1 ]] && install_dependencies_tmux
  [[ $RUN_INSTALL_DEPENDENCIES_TMUX_NVIM -eq 1 ]] && install_dependencies_nvim
  [[ $RUN_INSTALL_DEPENDENCIES_TMUX_NVIM -eq 1 ]] && install_dependencies_needs_rm

  [[ $RUN_SETUP_BIN -eq 1 ]] && setup_bin
  [[ $RUN_SETUP_TMUX -eq 1 ]] && setup_tmux
  [[ $RUN_SETUP_NVIM -eq 1 ]] && setup_nvim
  [[ $RUN_SETUP_CODE -eq 1 ]] && setup_code
  [[ $RUN_SETUP_CODE_EXT -eq 1 ]] && setup_code_ext
  [[ $RUN_SETUP_ADDS -eq 1 ]] && setup_adds
  [[ $RUN_SETUP_FONTS -eq 1 ]] && setup_fonts
}

# ******************************************************************************

# GIT :: init recursive --------------------------------------------------------------------------------------------------------
setup_base() {
  #git submodule update --init --recursive
  git submodule update --init --recursive --remote
}

# DEPS :: install dependencies -------------------------------------------------------------------------------------------------
install_dependencies_additional() {
  echo -e "${BYELLOW}DEPS :: install some base services${NC}"
  sudo apt install rsync fzf eza bat ripgrep fd-find xclip

  echo -e "${BYELLOW}DEPS :: disable rsync systemd service${NC}"
  sudo systemctl disable rsync.service
  sudo systemctl mask rsync.service

  # echo "DEPS :: install npm"
  # sudo snap install node --classic

  # echo "DEPS :: install lazygit with go"
  # sudo snap install go --classic
  # go install github.com/jesseduffield/lazygit@latest
}

install_dependencies_needs() {
  echo -e "${BYELLOW}DEPS :: install build dependincies${NC}"
  local packages_tools=(git curl unzip libevent-dev)
  local packages_build=(ninja-build gettext cmake build-essential
    automake pkg-config libevent-dev libncurses-dev bison)

  for pkg in "${packages_build[@]}"; do
    if ! apt -qq list "$pkg" 2>/dev/null | grep -q "installed"; then
      DEPS_INSTALL_PKGS+=("$pkg")
    fi
  done

  echo -e "${BYELLOW}DEPS :: following pkg's will be installed: '[$(echo "${packages_tools[*]}" | tr '\n' ',')$(echo "${DEPS_INSTALL_PKGS[*]}" | tr '\n' ',')]'${NC}"
  echo -e "${BYELLOW}DEPS :: following pkg's will be afterwards uninstalled: '[$(echo "${DEPS_INSTALL_PKGS[*]}" | tr '\n' ',')]'${NC}"
  if [[ ${#DEPS_INSTALL_PKGS[@]} -gt 0 || ${#packages_tools[@]} -gt 0 ]]; then
    sudo apt update
    sudo apt install "${packages_tools[@]}" "${DEPS_INSTALL_PKGS[@]}"
  fi
}

install_dependencies_needs_rm() {
  echo -e "${BYELLOW}DEPS :: remove some build dependincies${NC}"
  sudo apt remove "${DEPS_INSTALL_PKGS[@]}"
  sudo apt autoremove && sudo apt autoclean
}

install_dependencies_tmux() {
  echo -e "${BYELLOW}DEPS :: install tmux for user only${NC}"
  echo -e "${BCYAN}  - current installed version :: '$("$USER_LOCAL_PREFIX_BIN/tmux" -V 2>/dev/null)'${NC}"
  git clone https://github.com/tmux/tmux.git "$DEPS_INSTALL_PATH/tmux" && cd "$DEPS_INSTALL_PATH/tmux"
  bash autogen.sh
  ./configure --prefix="$USER_LOCAL_PREFIX/" && make
  make install
  cd -
  rm -rf "$DEPS_INSTALL_PATH/tmux"
  echo -e "${BCYAN}  - current installed version :: '$("$USER_LOCAL_PREFIX_BIN/tmux" -V 2>/dev/null)'${NC}"
}

install_dependencies_nvim() {
  echo -e "${BYELLOW}DEPS :: install nvim for user only${NC}"
  echo -e "${BCYAN}  - current installed version :: '$("$USER_LOCAL_PREFIX_BIN/nvim" -v 2>/dev/null)'${NC}"
  git clone https://github.com/neovim/neovim.git "$DEPS_INSTALL_PATH/nvim" && cd "$DEPS_INSTALL_PATH/nvim"
  make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX="$USER_LOCAL_PREFIX/"
  make install
  cd -
  rm -rf "$DEPS_INSTALL_PATH/nvim"
  echo -e "${BCYAN}  - current installed version :: '$("$USER_LOCAL_PREFIX_BIN/nvim" -v 2>/dev/null)'${NC}"
}

# BIN :: CREATE LINKS ----------------------------------------------------------------------------------------------------------
setup_bin() {
  echo -e "${BYELLOW}BIN :: Create symlink from './bin/*' into '$USER_LOCAL_PREFIX_BIN/'${NC}"
  mkdir -p "$USER_LOCAL_PREFIX_BIN"
  for script in "$PWD"/bin/*; do
    ln -sf "$script" "${USER_LOCAL_PREFIX_BIN}/$(basename "$script")"
  done
  echo -e "${BYELLOW}BIN :: All symlinks created.${NC}"
}
# TMUX :: CREATE LINKS ----------------------------------------------------------------------------------------------------------
setup_tmux() {
  echo -e "${BYELLOW}TMUX :: Create symlink from './tmux/tmux' as '$LN_TMUX_ORIG_BASE'${NC}"
  rm -f "${LN_TMUX_ORIG_BASE}"
  ln -sf "${PWD}/tmux/tmux" "${LN_TMUX_ORIG_BASE}"
  echo -e "${BYELLOW}TMUX :: Create symlink from './tmux/tmux.conf' as '$LN_TMUX_ORIG_TMUX'${NC}"
  rm -f "${LN_TMUX_ORIG_TMUX}"
  ln -sf "${PWD}/tmux/tmux.conf" "${LN_TMUX_ORIG_TMUX}"

  echo -e "${BYELLOW}TMUX :: Run tpm to install plugins${NC}"
  #PATH="$USER_LOCAL_PREFIX_BIN:$PATH" bash "${LN_TMUX_ORIG_BASE}/plugins/tpm/bin/clean_plugins"
  PATH="$USER_LOCAL_PREFIX_BIN:$PATH" bash "${LN_TMUX_ORIG_BASE}/plugins/tpm/bin/install_plugins"

  echo -e "${BYELLOW}TMUX :: All symlinks created.${NC}"
}

# NVIM :: CREATE LINKS ----------------------------------------------------------------------------------------------------------
setup_nvim() {
  echo -e "${BYELLOW}NVIM :: Create symlink from './nvim' as '$LN_NVIM_ORIG_BASE'${NC}"
  rm -f "${LN_NVIM_ORIG_BASE}"
  ln -sf "${PWD}/nvim" "${LN_NVIM_ORIG_BASE}"
  echo -e "${BYELLOW}NVIM :: All symlinks created.${NC}"
}

# CODE :: CREATE LINKS -----------------------------------------------------------------------------------------------------------
setup_code() {
  mkdir -p "$LN_VS_CODE"
  echo -e "${BYELLOW}CODE :: Create symlink from './code/keybindings.json' into '$LN_VS_CODE'${NC}"
  rm -f "${LN_VS_CODE}/keybindings.json"
  ln -sf "${PWD}/code/keybindings.json" "${LN_VS_CODE}/keybindings.json"
  echo -e "${BYELLOW}CODE :: Create symlink from './code/settings.json' into '$LN_VS_CODE'${NC}"
  rm -f "${LN_VS_CODE}/settings.json"
  ln -sf "${PWD}/code/settings.json" "${LN_VS_CODE}/settings.json"
  echo -e "${BYELLOW}CODE :: Create symlink from './code/snippets' into '$LN_VS_CODE'${NC}"
  rm -f "${LN_VS_CODE}/snippets"
  ln -sf "${PWD}/code/snippets" "${LN_VS_CODE}/snippets"
}

setup_code_ext() {

  if command -v code &>/dev/null; then
    echo -e "${BYELLOW}CODE :: installing code extensions${NC}"

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
      echo -e "${BYELLOW}  - CODE:: install extionsion '$vs_code_ext'${NC}"
      code --install-extension "$vs_code_ext"
    done
  else
    echo -e "${BRED}CODE :: code is not installed, extension install will skipped!${NC}"
  fi

}

# ADDS :: CREATE LINKS ----------------------------------------------------------------------------------------------------------
setup_adds() {
  echo -e "${BYELLOW}ADDS :: Create symlink from './zshrc' as '$LN_ZSHRC'${NC}"
  rm -f "${LN_ZSHRC}"
  ln -sf "${PWD}/zshrc" "${LN_ZSHRC}"

  echo -e "${BYELLOW}ADDS :: Create symlink from './zshrc-append' as '$LN_ADDS_01'${NC}"
  rm -f "${LN_ADDS_01}"
  ln -sf "${PWD}/zshrc-append" "${LN_ADDS_01}"
  echo -e "${BYELLOW}ADDS :: Create symlink from './zshrc-sec' as '$LN_ADDS_02'${NC}"
  rm -f "${LN_ADDS_02}"
  ln -sf "${PWD}/zshrc-sec" "${LN_ADDS_02}"
  echo -e "${BYELLOW}ADDS :: All symlinks created.${NC}"
}

# FONTS :: ADD FONTS ------------------------------------------------------------------------------------------------------------
setup_fonts() {
  echo -e "${BYELLOW}FONTS :: Download some nerd fonts${NC}"
  FONTS_RELEASE_VERSION='v3.2.1'
  FONTS_URLS=(
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${FONTS_RELEASE_VERSION}/NerdFontsSymbolsOnly.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${FONTS_RELEASE_VERSION}/FiraCode.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${FONTS_RELEASE_VERSION}/Hack.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${FONTS_RELEASE_VERSION}/UbuntuMono.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${FONTS_RELEASE_VERSION}/FiraMono.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${FONTS_RELEASE_VERSION}/RobotoMono.tar.xz"
    "https://github.com/ryanoasis/nerd-fonts/releases/download/${FONTS_RELEASE_VERSION}/ProggyClean.tar.xz"
  )
  FONTS_DIR=~/.local/share/fonts/nerd-fonts
  mkdir -p "$FONTS_DIR"

  for url in "${FONTS_URLS[@]}"; do
    file_name=$(basename "$url")
    echo -e "${BYELLOW}FONTS :: Downloading $file_name...${NC}"
    curl -sL -o "/tmp/$file_name" "$url"
    echo -e "${BYELLOW}FONTS :: Extracting $file_name...${NC}"
    tar -xf "/tmp/$file_name" -C "$FONTS_DIR"
    rm "/tmp/$file_name"
  done

  echo -e "${BYELLOW}FONTS :: All fonts are downloaded and extracted${NC}"
}

# ******************************************************************************

# Function to show usage information
usage() {
  echo -e "${BPURPLE}Usage: $0 [options]${NC}"
  echo -e "${BPURPLE}Options:${NC}"
  echo -e "${BPURPLE}  -h,    --help                               Show this help message and exit${NC}"
  echo -e "${BPURPLE}  -ida,  --install-dependencies-additional    Not Skip install additional tools [rsync fzf eza bat ripgrep fd-find]${NC}"
  echo -e "${BPURPLE}  -idtn, --install-dependencies-tmux-nvim     Not Skip install services [tmux nvim] (user based)${NC}"
  echo -e "${BPURPLE}  -nsb,  --no-setup-bin                       Skip setup_bin${NC}"
  echo -e "${BPURPLE}  -nst,  --no-setup-tmux                      Skip setup_tmux${NC}"
  echo -e "${BPURPLE}  -nsn,  --no-setup-nvim                      Skip setup_nvim${NC}"
  echo -e "${BPURPLE}  -nsc,  --no-setup-code                      Skip setup_code${NC}"
  echo -e "${BPURPLE}  -nsce, --no-setup-code-ext                  Skip setup_code_ext${NC}"
  echo -e "${BPURPLE}  -nsa,  --no-setup-adds                      Skip setup_adds${NC}"
  echo -e "${BPURPLE}  -nsf,  --no-setup-fonts                     Skip setup_fonts${NC}"
  echo -e "${BPURPLE}  -ds,   --disable-setups                     Skip all setup${NC}"
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
    -idtn | --install-dependencies-tmux-nvim)
      RUN_INSTALL_DEPENDENCIES_TMUX_NVIM=1
      ;;
    -nsb | --no-setup-bin)
      RUN_SETUP_BIN=0
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
    -nsce | --no-setup-code-ext)
      RUN_SETUP_CODE_EXT=0
      ;;
    -nsa | --no-setup-adds)
      RUN_SETUP_ADDS=0
      ;;
    -nsf | --no-setup-fonts)
      RUN_SETUP_FONTS=0
      ;;
    -ds | --disable-setups)
      RUN_SETUP_BIN=0
      RUN_SETUP_TMUX=0
      RUN_SETUP_NVIM=0
      RUN_SETUP_CODE=0
      RUN_SETUP_CODE_EXT=0
      RUN_SETUP_ADDS=0
      RUN_SETUP_FONTS=0
      ;;
    *)
      echo -e "${BRED}Unknown option: $key${NC}" >&2
      usage
      exit 1
      ;;
    esac
    shift
  done
}

# ******************************************************************************

echo -e "${BYELLOW}Starting script $0 ...${NC}"

# Parse command-line arguments
parse_args "$@"

main
exit 0
