#!/usr/bin/env bash

# Dotfiles Installation Script
# This script installs and configures dotfiles for a new environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

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

# Function to ask user for confirmation
ask_confirmation() {
    read -p "$1 [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
    fi
    return 0
}

# Function to ask for user input
ask_input() {
    read -p "$1: " response
    echo "$response"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to backup existing file
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup_dir="$HOME/.dotfiles_backup"
        mkdir -p "$backup_dir"
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        cp "$file" "$backup_dir/$(basename "$file")_$timestamp"
        print_success "Backed up $file to $backup_dir/"
    fi
}

# Function to create symbolic link
create_symlink() {
    local source="$1"
    local target="$2"
    
    # Backup existing file if it exists
    backup_file "$target"
    
    # Create symbolic link
    ln -sf "$source" "$target"
    print_success "Created symlink: $target -> $source"
}

# Function to setup git config
setup_git_config() {
    print_status "Setting up git configuration..."
    
    # Ask for user information
    local git_name=$(ask_input "Enter your name for git")
    local git_email=$(ask_input "Enter your email for git")
    
    # Copy template and replace placeholders
    if [ -f "$SCRIPT_DIR/.gitconfig.template" ]; then
        sed "s/Your Name/$git_name/g; s/your.email@example.com/$git_email/g" \
            "$SCRIPT_DIR/.gitconfig.template" > "$HOME/.gitconfig"
        print_success "Git configuration created"
    else
        print_error "Git config template not found"
        return 1
    fi
}

# Function to install oh-my-zsh
install_oh_my_zsh() {
    print_status "Installing oh-my-zsh..."
    
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_warning "oh-my-zsh is already installed"
        return 0
    fi
    
    # Install oh-my-zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    print_success "oh-my-zsh installed successfully"
}

# Function to setup shell
setup_shell() {
    print_status "Setting up shell..."
    
    # Check if zsh is available
    if command_exists zsh; then
        # Change default shell to zsh if it's not already
        if [[ "$SHELL" != *"zsh"* ]]; then
            print_status "Changing default shell to zsh..."
            chsh -s $(which zsh)
            print_success "Default shell changed to zsh"
        else
            print_success "zsh is already the default shell"
        fi
    else
        print_warning "zsh is not available, keeping current shell"
    fi
}

# Function to install dependencies
install_dependencies() {
    print_status "Checking and installing dependencies..."
    
    # Run environment check
    if [ -f "$SCRIPT_DIR/check_env.sh" ]; then
        print_status "Running environment check..."
        "$SCRIPT_DIR/check_env.sh" || {
            print_warning "Environment check found some issues, but continuing with installation..."
            if ask_confirmation "Would you like to see the installation commands for missing dependencies?"; then
                echo ""
                "$SCRIPT_DIR/check_env.sh"
            fi
        }
    else
        print_warning "Environment check script not found, skipping dependency check"
    fi
}

# Function to create symbolic links
create_symbolic_links() {
    print_status "Creating symbolic links..."
    
    # Run the build soft link script
    if [ -f "$SCRIPT_DIR/build_soft_link.sh" ]; then
        "$SCRIPT_DIR/build_soft_link.sh"
        print_success "Symbolic links created"
    else
        print_error "build_soft_link.sh not found"
        return 1
    fi
}

# Function to install additional tools
install_additional_tools() {
    print_status "Installing additional tools..."
    
    # Only install zsh plugins if oh-my-zsh is installed
    if [ -d "$HOME/.oh-my-zsh" ]; then
        # Install zsh-autosuggestions
        if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
            git clone https://github.com/zsh-users/zsh-autosuggestions \
                "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
            print_success "zsh-autosuggestions installed"
        fi
        
        # Install zsh-syntax-highlighting
        if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
            git clone https://github.com/zsh-users/zsh-syntax-highlighting \
                "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
            print_success "zsh-syntax-highlighting installed"
        fi
        
        # Update .zshrc with new plugins
        update_zshrc_plugins
    else
        print_warning "oh-my-zsh not found, skipping zsh plugin installation"
    fi
}

# Function to update .zshrc with new plugins
update_zshrc_plugins() {
    print_status "Updating .zshrc plugins..."
    
    if [ -f "$HOME/.zshrc" ]; then
        # Backup existing .zshrc
        backup_file "$HOME/.zshrc"
        
        # Check if plugins already include the additional plugins
        if grep -q "zsh-autosuggestions" "$HOME/.zshrc"; then
            print_success "zsh plugins already updated"
        else
            # Update plugins section - replace the git-only plugins array
            sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
            print_success "zsh plugins updated"
        fi
    else
        print_warning ".zshrc not found, skipping plugin update"
    fi
}

# Function to show post-installation instructions
show_post_install_instructions() {
    echo ""
    echo "=== Installation Complete! ==="
    echo ""
    echo "Next steps:"
    echo "1. Restart your shell or run: source ~/.zshrc"
    echo "2. Check that all dotfiles are properly linked"
    echo "3. Customize your configuration as needed"
    echo ""
    echo "Useful commands:"
    echo "- View backup files: ls -la ~/.dotfiles_backup/"
    echo "- Check environment: $SCRIPT_DIR/check_env.sh"
    echo "- Update dotfiles: cd $SCRIPT_DIR && git pull"
    echo ""
    echo "Enjoy your new environment!"
}

# Function to uninstall dotfiles
uninstall_dotfiles() {
    print_status "Uninstalling dotfiles..."
    
    if ! ask_confirmation "Are you sure you want to uninstall dotfiles?"; then
        return 0
    fi
    
    # Remove symbolic links
    while IFS= read -r file; do
        if [[ $file =~ ^# ]]; then
            continue
        fi
        if [ -L "$HOME/$file" ]; then
            rm "$HOME/$file"
            print_status "Removed symlink: $HOME/$file"
        fi
    done < "$SCRIPT_DIR/config_list"
    
    # Restore from backup if exists
    local backup_dir="$HOME/.dotfiles_backup"
    if [ -d "$backup_dir" ]; then
        print_status "Backup files are available in: $backup_dir"
        print_status "You can manually restore files if needed"
    fi
    
    print_success "Dotfiles uninstalled"
}

# Main installation function
main() {
    echo "=== Dotfiles Installation Script ==="
    echo ""
    
    # Check if script is run from the correct directory
    if [ ! -f "$SCRIPT_DIR/config_list" ]; then
        print_error "This script must be run from the dotfiles directory"
        exit 1
    fi
    
    # Parse command line arguments
    case "${1:-install}" in
        install)
            print_status "Starting dotfiles installation..."
            
            # Install dependencies
            if ! install_dependencies; then
                print_error "Dependency installation failed"
                exit 1
            fi
            
            # Setup git config
            if ask_confirmation "Would you like to setup git configuration?"; then
                setup_git_config
            fi
            
            # Install oh-my-zsh
            if ask_confirmation "Would you like to install oh-my-zsh?"; then
                install_oh_my_zsh
            fi
            
            # Setup shell
            if ask_confirmation "Would you like to set zsh as default shell?"; then
                setup_shell
            fi
            
            # Create symbolic links
            create_symbolic_links
            
            # Install additional tools
            if ask_confirmation "Would you like to install additional zsh plugins?"; then
                install_additional_tools
                update_zshrc_plugins
            fi
            
            show_post_install_instructions
            ;;
        check)
            print_status "Checking environment..."
            if [ -f "$SCRIPT_DIR/check_env.sh" ]; then
                "$SCRIPT_DIR/check_env.sh"
            else
                print_error "Environment check script not found"
            fi
            ;;
        uninstall)
            uninstall_dotfiles
            ;;
        help|--help|-h)
            echo "Usage: $0 {install|check|uninstall|help}"
            echo ""
            echo "Commands:"
            echo "  install   Install dotfiles (default)"
            echo "  check     Check environment dependencies"
            echo "  uninstall Uninstall dotfiles"
            echo "  help      Show this help message"
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi