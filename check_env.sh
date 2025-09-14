#!/usr/bin/env bash

# Environment Check Script for Dotfiles Installation
# This script checks for required tools and system dependencies

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if file exists
file_exists() {
    [ -f "$1" ]
}

# Function to check if directory exists
dir_exists() {
    [ -d "$1" ]
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            echo "debian"
        elif [ -f /etc/redhat-release ]; then
            echo "redhat"
        elif [ -f /etc/arch-release ]; then
            echo "arch"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "cygwin" ]]; then
        echo "cygwin"
    elif [[ "$OSTYPE" == "msys" ]]; then
        echo "msys"
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        echo "freebsd"
    else
        echo "unknown"
    fi
}

# Function to check shell
check_shell() {
    current_shell=$(basename "$SHELL")
    case "$current_shell" in
        bash|zsh|fish)
            print_success "Shell: $current_shell"
            return 0
            ;;
        *)
            print_warning "Shell: $current_shell (not fully supported)"
            return 1
            ;;
    esac
}

# Function to check essential tools
check_essential_tools() {
    print_status "Checking essential tools..."
    
    # Core tools - git and basic utilities
    local core_tools=("git" "curl" "vim")
    # Optional tools - nice to have but not required
    local optional_tools=("wget" "tmux" "zsh")
    local missing_core=()
    local missing_optional=()
    
    # Check core tools
    for tool in "${core_tools[@]}"; do
        if command_exists "$tool"; then
            print_success "✓ $tool (core)"
        else
            print_error "✗ $tool (core)"
            missing_core+=("$tool")
        fi
    done
    
    # Check optional tools
    for tool in "${optional_tools[@]}"; do
        if command_exists "$tool"; then
            print_success "✓ $tool (optional)"
        else
            print_warning "✗ $tool (optional)"
            missing_optional+=("$tool")
        fi
    done
    
    if [ ${#missing_core[@]} -eq 0 ]; then
        print_success "All core tools are installed"
        if [ ${#missing_optional[@]} -gt 0 ]; then
            print_warning "Missing optional tools: ${missing_optional[*]}"
        fi
        return 0
    else
        print_error "Missing core tools: ${missing_core[*]}"
        return 1
    fi
}

# Function to check optional tools
check_optional_tools() {
    print_status "Checking optional tools..."
    
    local tools=("node" "python" "python3" "ruby" "go" "docker" "kubectl")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            print_success "✓ $tool"
        else
            print_warning "✗ $tool (optional)"
        fi
    done
}

# Function to check package manager
check_package_manager() {
    print_status "Checking package manager..."
    
    local os=$(detect_os)
    local pkg_manager=""
    
    case "$os" in
        debian)
            if command_exists apt; then
                pkg_manager="apt"
            elif command_exists apt-get; then
                pkg_manager="apt-get"
            fi
            ;;
        redhat)
            if command_exists yum; then
                pkg_manager="yum"
            elif command_exists dnf; then
                pkg_manager="dnf"
            fi
            ;;
        arch)
            if command_exists pacman; then
                pkg_manager="pacman"
            fi
            ;;
        macos)
            if command_exists brew; then
                pkg_manager="brew"
            fi
            ;;
    esac
    
    if [ -n "$pkg_manager" ]; then
        print_success "Package manager: $pkg_manager"
        return 0
    else
        print_warning "No recognized package manager found"
        return 1
    fi
}

# Function to check oh-my-zsh
check_oh_my_zsh() {
    print_status "Checking oh-my-zsh..."
    
    if dir_exists "$HOME/.oh-my-zsh"; then
        print_success "oh-my-zsh is installed"
        return 0
    else
        print_warning "oh-my-zsh is not installed"
        return 0  # oh-my-zsh is optional, so don't fail the check
    fi
}

# Function to check tmux configuration
check_tmux_config() {
    print_status "Checking tmux configuration..."
    
    if command_exists tmux; then
        local tmux_version=$(tmux -V | cut -d' ' -f2)
        print_success "tmux version: $tmux_version"
        return 0
    else
        print_error "tmux is not installed"
        return 1
    fi
}

# Function to generate install recommendations
generate_recommendations() {
    local os=$(detect_os)
    print_status "Generating installation recommendations for $os..."
    
    echo ""
    echo "=== Installation Commands ==="
    
    case "$os" in
        debian)
            echo "# Install essential tools on Debian/Ubuntu:"
            echo "sudo apt update"
            echo "sudo apt install -y git curl wget vim tmux zsh"
            echo ""
            echo "# Install oh-my-zsh:"
            echo "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
            ;;
        redhat)
            echo "# Install essential tools on RedHat/CentOS:"
            echo "sudo yum update"
            echo "sudo yum install -y git curl wget vim tmux zsh"
            echo ""
            echo "# Install oh-my-zsh:"
            echo "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
            ;;
        arch)
            echo "# Install essential tools on Arch Linux:"
            echo "sudo pacman -Syu git curl wget vim tmux zsh"
            echo ""
            echo "# Install oh-my-zsh:"
            echo "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
            ;;
        macos)
            echo "# Install Homebrew (if not installed):"
            echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
            echo ""
            echo "# Install essential tools:"
            echo "brew install git curl wget vim tmux zsh"
            echo ""
            echo "# Install oh-my-zsh:"
            echo "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
            ;;
        *)
            echo "Please install the following tools manually:"
            echo "- git"
            echo "- curl"
            echo "- wget"
            echo "- vim"
            echo "- tmux"
            echo "- zsh"
            echo "- oh-my-zsh"
            ;;
    esac
}

# Main check function
main() {
    echo "=== Dotfiles Environment Check ==="
    echo ""
    
    # Detect OS
    local os=$(detect_os)
    print_status "Detected OS: $os"
    echo ""
    
    # Check shell
    check_shell
    echo ""
    
    # Check essential tools
    if ! check_essential_tools; then
        echo ""
        generate_recommendations
        echo ""
        print_error "Essential tools are missing. Please install them before continuing."
        exit 1
    fi
    echo ""
    
    # Check optional tools
    check_optional_tools
    echo ""
    
    # Check package manager
    check_package_manager
    echo ""
    
    # Check oh-my-zsh
    check_oh_my_zsh
    echo ""
    
    # Check tmux configuration
    check_tmux_config
    echo ""
    
    print_success "Environment check completed!"
    
    # Summary
    echo ""
    echo "=== Summary ==="
    echo "OS: $os"
    echo "Shell: $SHELL"
    echo "Ready for dotfiles installation!"
}

# Always run main function, but control output based on execution context
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Run directly, show full output
    main "$@"
    exit 0
else
    # Run from another script, capture output and return status
    main "$@" >/dev/null 2>&1
    exit $?
fi