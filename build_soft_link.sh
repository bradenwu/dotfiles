#!/bin/bash

# Dotfiles Symbolic Link Creation Script
# This script creates symbolic links for dotfiles with backup functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config_list"
BACKUP_DIR="$HOME/.dotfiles_backup"

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

# Function to backup existing file
backup_file() {
    local file_path="$1"
    local file_name=$(basename "$file_path")
    
    if [ -e "$file_path" ]; then
        # Create backup directory if it doesn't exist
        mkdir -p "$BACKUP_DIR"
        
        # Create timestamped backup
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        local backup_path="$BACKUP_DIR/${file_name}_${timestamp}"
        
        # Copy the file/directory
        cp -r "$file_path" "$backup_path"
        print_success "Backed up $file_path to $backup_path"
        
        return 0
    fi
    return 1
}

# Function to create symbolic link
create_symlink() {
    local source_file="$1"
    local target_file="$2"
    
    # Check if source file exists
    if [ ! -e "$source_file" ]; then
        print_error "Source file does not exist: $source_file"
        return 1
    fi
    
    # Create parent directory if it doesn't exist
    local target_dir=$(dirname "$target_file")
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
        print_status "Created directory: $target_dir"
    fi
    
    # Backup existing file if it exists
    backup_file "$target_file"
    
    # Remove existing target (file or symlink)
    if [ -e "$target_file" ] || [ -L "$target_file" ]; then
        rm -rf "$target_file"
    fi
    
    # Create symbolic link
    ln -s "$source_file" "$target_file"
    print_success "Created symlink: $target_file -> $source_file"
}

# Function to validate config file
validate_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "Config file not found: $CONFIG_FILE"
        return 1
    fi
    
    # Check if config file is readable
    if [ ! -r "$CONFIG_FILE" ]; then
        print_error "Config file is not readable: $CONFIG_FILE"
        return 1
    fi
    
    return 0
}

# Function to create all symbolic links
create_links() {
    print_status "Creating symbolic links..."
    
    local link_count=0
    local skip_count=0
    local error_count=0
    
    # Read config file line by line
    while IFS= read -r file_entry; do
        # Skip empty lines
        if [ -z "$file_entry" ]; then
            continue
        fi
        
        # Skip comments
        if [[ "$file_entry" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Trim whitespace
        file_entry=$(echo "$file_entry" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Skip if empty after trimming
        if [ -z "$file_entry" ]; then
            continue
        fi
        
        # Skip platform-specific files that don't match current platform
        if [[ "$file_entry" == ".functions.macos" && "$OSTYPE" != "darwin"* ]]; then
            print_status "Skipping macOS-specific file: $file_entry"
            ((skip_count++))
            continue
        fi
        
        if [[ "$file_entry" == ".functions.linux" && "$OSTYPE" != "linux-gnu"* ]]; then
            print_status "Skipping Linux-specific file: $file_entry"
            ((skip_count++))
            continue
        fi
        
        # Construct full paths
        local source_path="$SCRIPT_DIR/$file_entry"
        local target_path="$HOME/$file_entry"
        
        print_status "Processing: $file_entry"
        
        # Create symbolic link
        if create_symlink "$source_path" "$target_path"; then
            ((link_count++))
        else
            ((error_count++))
        fi
        
    done < "$CONFIG_FILE"
    
    # Print summary
    echo ""
    print_status "Link creation summary:"
    print_success "Created: $link_count links"
    if [ $skip_count -gt 0 ]; then
        print_warning "Skipped: $skip_count entries"
    fi
    if [ $error_count -gt 0 ]; then
        print_error "Errors: $error_count files"
        return 1
    fi
    
    return 0
}

# Function to list existing symbolic links
list_links() {
    print_status "Existing symbolic links:"
    echo ""
    
    local found_links=0
    
    while IFS= read -r file_entry; do
        # Skip empty lines and comments
        if [ -z "$file_entry" ] || [[ "$file_entry" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Trim whitespace
        file_entry=$(echo "$file_entry" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Skip if empty after trimming
        if [ -z "$file_entry" ]; then
            continue
        fi
        
        local target_path="$HOME/$file_entry"
        
        if [ -L "$target_path" ]; then
            local link_target=$(readlink -f "$target_path")
            print_success "$file_entry -> $link_target"
            ((found_links++))
        elif [ -e "$target_path" ]; then
            print_warning "$file_entry (exists, not a symlink)"
        else
            print_error "$file_entry (missing)"
        fi
        
    done < "$CONFIG_FILE"
    
    if [ $found_links -eq 0 ]; then
        print_warning "No symbolic links found"
    fi
}

# Function to clean up broken links
clean_broken_links() {
    print_status "Checking for broken symbolic links..."
    
    local broken_count=0
    
    while IFS= read -r file_entry; do
        # Skip empty lines and comments
        if [ -z "$file_entry" ] || [[ "$file_entry" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Trim whitespace
        file_entry=$(echo "$file_entry" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Skip if empty after trimming
        if [ -z "$file_entry" ]; then
            continue
        fi
        
        local target_path="$HOME/$file_entry"
        
        # Check if it's a broken symlink
        if [ -L "$target_path" ] && [ ! -e "$target_path" ]; then
            print_warning "Removing broken symlink: $target_path"
            rm -f "$target_path"
            ((broken_count++))
        fi
        
    done < "$CONFIG_FILE"
    
    if [ $broken_count -gt 0 ]; then
        print_success "Removed $broken_count broken links"
    else
        print_success "No broken links found"
    fi
}

# Function to show help
show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  create    Create symbolic links (default)"
    echo "  list      List existing symbolic links"
    echo "  clean     Clean broken symbolic links"
    echo "  help      Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  BACKUP_DIR    Directory for backups (default: ~/.dotfiles_backup)"
    echo "  CONFIG_FILE   Configuration file path (default: ./config_list)"
}

# Main function
main() {
    # Validate config file
    if ! validate_config; then
        exit 1
    fi
    
    # Parse command line arguments
    case "${1:-create}" in
        create)
            print_status "Starting symbolic link creation..."
            echo "Script directory: $SCRIPT_DIR"
            echo "Config file: $CONFIG_FILE"
            echo "Backup directory: $BACKUP_DIR"
            echo ""
            
            if create_links; then
                print_success "Symbolic link creation completed successfully!"
            else
                print_error "Some errors occurred during link creation"
                exit 1
            fi
            ;;
        list)
            list_links
            ;;
        clean)
            clean_broken_links
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi