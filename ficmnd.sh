#!/bin/bash

# File Navigation and Quick Access Setup Script
# Save as ~/.local/scripts/file-setup.sh

# Create common directories if they don't exist
mkdir -p ~/Documents
mkdir -p ~/Downloads
mkdir -p ~/Projects
mkdir -p ~/.local/scripts
mkdir -p ~/.local/bin
mkdir -p ~/sshvlt/

# Add custom functions to .bashrc
cat >> ~/.bashrc << 'EOL'

# Enhanced file navigation and management
# ------------------------------------------

# Quick directory switching with bookmarks
declare -A bookmarks
bookmarks=(
    ["docs"]="$HOME/Documents"
    ["dl"]="$HOME/Downloads"
    ["proj"]="$HOME/Projects"
)

goto() {
    if [ -n "${bookmarks[$1]}" ]; then
        cd "${bookmarks[$1]}"
    else
        echo "Unknown bookmark: $1"
        echo "Available bookmarks:"
        for key in "${!bookmarks[@]}"; do
            echo "  $key -> ${bookmarks[$key]}"
        done
    fi
}

# Add a new bookmark
bookmark() {
    if [ $# -ne 2 ]; then
        echo "Usage: bookmark <name> <path>"
        return 1
    fi
    bookmarks[$1]="$(realpath "$2")"
    echo "Bookmark added: $1 -> ${bookmarks[$1]}"
}

# Enhanced ls commands
alias ll='ls -alFh'
alias la='ls -A'
alias l='ls -CF'
alias lt='ls -ltrh'  # sort by time, newest last
alias lsize='ls -lSrh'  # sort by size
alias tree='tree -C'  # colorized tree

# Quick find functions
# Find files by name
ff() {
    find . -type f -iname "*$1*" 2>/dev/null
}

# Find directories by name
fd() {
    find . -type d -iname "*$1*" 2>/dev/null
}

# Search file contents
search() {
    if [ $# -ne 1 ]; then
        echo "Usage: search <pattern>"
        return 1
    fi
    grep -r "$1" .
}

# Quick directory creation and navigation
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Show directory size
dirsize() {
    du -sh "${1:-.}"
}

# Find largest files/directories
largest() {
    local count="${1:-10}"
    find . -type f -exec du -h {} + | sort -rh | head -n "$count"
}

# Improved file operations with confirmation
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# Quick directory stack navigation
alias d='dirs -v'
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'

# Recent directories
alias recent='ls -lt | head'

# Path management
path() {
    echo $PATH | tr ':' '\n'
}

# Add local bin to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# File type statistics in current directory
filetypes() {
    find . -type f | grep -E ".*\.[a-zA-Z0-9]*$" | sed -e 's/.*\.//' | sort | uniq -c | sort -rn
}

# Quick edit function for config files
conf() {
    case "$1" in
        "bash")
            $EDITOR ~/.bashrc
            ;;
        "vim")
            $EDITOR ~/.vimrc
            ;;
        "git")
            $EDITOR ~/.gitconfig
            ;;
        *)
            echo "Usage: conf [bash|vim|git]"
            ;;
    esac
}

# Initialize common bookmarks
export DOCUMENTS="$HOME/Documents"
export DOWNLOADS="$HOME/Downloads"
export PROJECTS="$HOME/Projects"

EOL

# Create a file indexing script
cat > ~/.local/scripts/index-files.sh << 'EOL'
#!/bin/bash

# Index files in the current directory
index_files() {
    local output_file="file_index.txt"
    echo "Creating file index in $output_file..."
    
    {
        echo "File Index - $(date)"
        echo "----------------------------------------"
        echo
        
        echo "Directory Structure:"
        tree -L 3
        
        echo
        echo "Large Files (>100MB):"
        find . -type f -size +100M -exec ls -lh {} \;
        
        echo
        echo "Recently Modified Files:"
        find . -type f -mtime -7 -ls
        
        echo
        echo "File Types Summary:"
        find . -type f | grep -E ".*\.[a-zA-Z0-9]*$" | sed -e 's/.*\.//' | sort | uniq -c | sort -rn
    } > "$output_file"
    
    echo "Index created in $output_file"
}

index_files
EOL

chmod +x ~/.local/scripts/index-files.sh

# Create a simple script to monitor file changes
cat > ~/.local/scripts/watch-dir.sh << 'EOL'
#!/bin/bash

# Watch directory for changes
if [ $# -eq 0 ]; then
    dir="."
else
    dir="$1"
fi

inotifywait -m -r -e modify,create,delete,move "$dir"
EOL

chmod +x ~/.local/scripts/watch-dir.sh

# Source the new configurations
source ~/.bashrc

echo "File navigation setup complete! New commands available:"
echo "- goto <bookmark>: Quick navigate to bookmarked directories"
echo "- bookmark <name> <path>: Create a new bookmark"
echo "- ff <pattern>: Find files by name"
echo "- fd <pattern>: Find directories by name"
echo "- search <pattern>: Search file contents"
echo "- mkcd <dir>: Create and enter directory"
echo "- dirsize: Show directory size"
echo "- largest [n]: Show n largest files"
echo "- filetypes: Show statistics of file types"
echo "- conf [bash|vim|git]: Quick edit config files"
echo ""
echo "Scripts installed:"
echo "- ~/.local/scripts/index-files.sh: Create file index"
echo "- ~/.local/scripts/watch-dir.sh: Monitor directory changes"
