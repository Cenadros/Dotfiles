#!/bin/bash

# ===========================================================================
# OS / Platform detection
# ===========================================================================

get_os() {
    local os=""
    local kernelName=""

    kernelName="$(uname -s)"

    if [ "$kernelName" = "Darwin" ]; then
        os="macos"
    elif [ "$kernelName" = "Linux" ]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case "$ID" in
                ubuntu|debian|linuxmint|pop|elementary)
                    os="debian" ;;
                fedora|rhel|centos|rocky|alma)
                    os="fedora" ;;
                arch|manjaro|endeavouros)
                    os="arch" ;;
                opensuse*|sles)
                    os="suse" ;;
                *)
                    os="linux" ;;
            esac
        elif [ -f /etc/lsb-release ]; then
            os="debian"
        elif [ -f /etc/redhat-release ]; then
            os="fedora"
        else
            os="linux"
        fi
    else
        os="$kernelName"
    fi

    printf "%s" "$os"
}

get_os_version() {
    local os=""
    local version=""

    os="$(get_os)"

    if [ "$os" = "macos" ]; then
        version="$(sw_vers -productVersion)"
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        version="$VERSION_ID"
    fi

    printf "%s" "$version"
}

get_os_name() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        printf "%s" "$PRETTY_NAME"
    elif [ "$(get_os)" = "macos" ]; then
        printf "macOS %s" "$(sw_vers -productVersion)"
    else
        printf "%s" "$(uname -s)"
    fi
}

is_wsl() {
    [ -f /proc/version ] && grep -qi "microsoft" /proc/version 2>/dev/null
}

get_arch() {
    local arch=""
    arch="$(uname -m)"

    case "$arch" in
        x86_64|amd64)  printf "amd64" ;;
        aarch64|arm64) printf "arm64" ;;
        armv7l)        printf "armhf" ;;
        *)             printf "%s" "$arch" ;;
    esac
}

get_brew_prefix() {
    if [ "$(get_os)" = "macos" ]; then
        if [ "$(get_arch)" = "arm64" ]; then
            printf "/opt/homebrew"
        else
            printf "/usr/local"
        fi
    else
        printf "/home/linuxbrew/.linuxbrew"
    fi
}

# ===========================================================================
# Package manager helpers
# ===========================================================================

pkg_install() {
    local os=""
    os="$(get_os)"

    case "$os" in
        macos)
            if cmd_exists brew; then
                brew install "$@"
            else
                print_error "Homebrew not found. Install it first."
                return 1
            fi
            ;;
        debian)
            sudo apt-get install -y "$@" > /dev/null
            ;;
        fedora)
            sudo dnf install -y "$@" > /dev/null
            ;;
        arch)
            sudo pacman -S --noconfirm "$@" > /dev/null
            ;;
        suse)
            sudo zypper install -y "$@" > /dev/null
            ;;
        *)
            print_error "Unsupported OS for automatic package install: $os"
            return 1
            ;;
    esac
}

pkg_update() {
    local os=""
    os="$(get_os)"

    case "$os" in
        macos)
            if cmd_exists brew; then
                brew update > /dev/null
            fi
            ;;
        debian)
            sudo apt-get update > /dev/null
            ;;
        fedora)
            sudo dnf check-update > /dev/null 2>&1 || true
            ;;
        arch)
            sudo pacman -Sy > /dev/null
            ;;
        suse)
            sudo zypper refresh > /dev/null
            ;;
    esac
}

# ===========================================================================
# Portable sed -i (works on both GNU and BSD/macOS)
# ===========================================================================

sed_i() {
    if sed --version 2>/dev/null | grep -q "GNU"; then
        sed -i "$@"
    else
        sed -i '' "$@"
    fi
}

# ===========================================================================
# User interaction
# ===========================================================================

answer_is_yes() {
    [[ "$REPLY" =~ ^[Yy]$ ]] \
        && return 0 \
        || return 1
}

ask() {
    print_question "$1"
    read -r
}

ask_for_confirmation() {
    print_question "$1 (y/n) "
    read -r -n 1
    printf "\n"
}

ask_for_sudo() {
    sudo -v &> /dev/null

    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done &> /dev/null &
}

# ===========================================================================
# Command helpers
# ===========================================================================

cmd_exists() {
    command -v "$1" &> /dev/null
}

kill_all_subprocesses() {
    local i=""

    for i in $(jobs -p); do
        kill "$i"
        wait "$i" &> /dev/null
    done
}

execute() {
    local -r CMDS="$1"
    local -r MSG="${2:-$1}"
    local -r TMP_FILE="$(mktemp /tmp/XXXXX)"

    local exitCode=0
    local cmdsPID=""

    set_trap "EXIT" "kill_all_subprocesses"

    eval "$CMDS" \
        &> /dev/null \
        2> "$TMP_FILE" &

    cmdsPID=$!

    show_spinner "$cmdsPID" "$CMDS" "$MSG"

    wait "$cmdsPID" &> /dev/null
    exitCode=$?

    print_result $exitCode "$MSG"

    if [ $exitCode -ne 0 ]; then
        print_error_stream < "$TMP_FILE"
    fi

    rm -rf "$TMP_FILE"

    return $exitCode
}

get_answer() {
    printf "%s" "$REPLY"
}

is_git_repository() {
    git rev-parse &> /dev/null
}

is_supported_version() {
    declare -a v1=(${1//./ })
    declare -a v2=(${2//./ })
    local i=""

    for (( i=${#v1[@]}; i<${#v2[@]}; i++ )); do
        v1[i]=0
    done

    for (( i=0; i<${#v1[@]}; i++ )); do
        if [[ -z ${v2[i]} ]]; then
            v2[i]=0
        fi

        if (( 10#${v1[i]} < 10#${v2[i]} )); then
            return 1
        elif (( 10#${v1[i]} > 10#${v2[i]} )); then
            return 0
        fi
    done
}

mkd() {
    if [ -n "$1" ]; then
        if [ -e "$1" ]; then
            if [ ! -d "$1" ]; then
                print_error "$1 - a file with the same name already exists!"
            else
                print_success "$1"
            fi
        else
            execute "mkdir -p '$1'" "$1"
        fi
    fi
}

# ===========================================================================
# Printing helpers
# ===========================================================================

print_error() {
    print_in_red "   [✖] $1 $2\n"
}

print_error_stream() {
    while read -r line; do
        print_error "↳ ERROR: $line"
    done
}

print_in_color() {
    printf "%b" \
        "$(tput setaf "$2" 2> /dev/null)" \
        "$1" \
        "$(tput sgr0 2> /dev/null)"
}

print_in_green() {
    print_in_color "$1" 2
}

print_in_purple() {
    print_in_color "$1" 5
}

print_in_red() {
    print_in_color "$1" 1
}

print_in_yellow() {
    print_in_color "$1" 3
}

print_question() {
    print_in_yellow "   [?] $1"
}

print_result() {
    if [ "$1" -eq 0 ]; then
        print_success "$2"
    else
        print_error "$2"
    fi

    return "$1"
}

print_success() {
    print_in_green "   [✔] $1\n"
}

print_warning() {
    print_in_yellow "   [!] $1\n"
}

# ===========================================================================
# Misc helpers
# ===========================================================================

set_trap() {
    trap -p "$1" | grep "$2" &> /dev/null \
        || trap "$2" "$1"
}

skip_questions() {
     while :; do
        case $1 in
            -y|--yes) return 0;;
                   *) break;;
        esac
        shift 1
    done

    return 1
}

# ===========================================================================
# Application install helpers
# ===========================================================================

install_brew_cask() {
    local app_name="$1"
    local cask_name="$2"
    local app_path="${3:-/Applications/${app_name}.app}"

    if [ ! -d "$app_path" ]; then
        echo "    Installing ${app_name}..."
        brew install --cask "$cask_name"
    else
        echo "    ${app_name} already installed."
    fi
}

install_mas_app() {
    local app_name="$1"
    local mas_id="$2"
    local app_path="${3:-/Applications/${app_name}.app}"

    if [ ! -d "$app_path" ]; then
        if mas_signed_in; then
            mas install "$mas_id"
        else
            print_warning "Skipping ${app_name} — not signed into the Mac App Store."
        fi
    else
        echo "    ${app_name} already installed."
    fi
}

git_clone_or_pull() {
    local repo_url="$1"
    local target_dir="$2"
    local extra_flags="${3:-}"

    if [ -d "$target_dir/.git" ]; then
        git -C "$target_dir" pull
    else
        # shellcheck disable=SC2086
        git clone $extra_flags "$repo_url" "$target_dir"
    fi
}

init_brew() {
    local prefix
    prefix="$(get_brew_prefix)"
    if [ -f "${prefix}/bin/brew" ]; then
        eval "$(${prefix}/bin/brew shellenv)"
    fi
}

show_spinner() {
    local -r FRAMES='/-\|'

    # shellcheck disable=SC2034
    local -r NUMBER_OR_FRAMES=${#FRAMES}

    local -r CMDS="$2"
    local -r MSG="$3"
    local -r PID="$1"

    local i=0
    local frameText=""

    if [ "${CI:-}" != "true" ]; then
        printf "\n\n\n"
        tput cuu 3

        tput sc
    fi

    while kill -0 "$PID" &>/dev/null; do

        frameText="   [${FRAMES:i++%NUMBER_OR_FRAMES:1}] $MSG"

        if [ "${CI:-}" != "true" ]; then
            printf "%s\n" "$frameText"
        else
            printf "%s" "$frameText"
        fi

        sleep 0.2

        if [ "${CI:-}" != "true" ]; then
            tput rc
        else
            printf "\r"
        fi

    done
}
