#!/usr/bin/env bash

# Default flag values
verbose=0
non_interactive=0 # 0 - interactive; 1 - automatic no; 2 - automatic yes
hide_file=0 # hide .nosync

# Display help message
show_help() {
  echo "nosync - Add a .nosync extension to files and create a symlink."
  echo
  echo "Usage: nosync [options] <file1> [file2 ... fileN]"
  echo
  echo "Options:"
  echo "  -v, --verbose                Enable verbose output"
  echo "  -n, --no, --non-interactive  Automatically respond no to all prompts"
  echo "  -y, --yes                    Automatically respond yes to all prompts"
  echo "  -x, --hidden                 Hide the .nosync file with chflags"
  echo "  -h, --help                   Show this help message"
}

# Error log function for non-verbose but critical errors
error_log() {
  echo "Error:" "$@" >&2
}

# Log messages in verbose mode
log() {
  [ "$verbose" -eq 1 ] && echo "$@"
}

# Add .nosync extension and create a symbolic link
nosync () {
  original_file="$1"
  nosync_file="${original_file}.nosync"
  linked_file=""
  git_root=""
  gitignore_path=""
  answer=""

  # Check if the file is a symlink
  if [ -L "$original_file" ]; then
    linked_file=$(readlink "$original_file")

    if [ ! -e "$linked_file" ]; then
      log "Warning: '$original_file' is a symlink to a non-existent file '$linked_file'."
      return 1
    elif [ "$linked_file" = "$nosync_file" ]; then
      log "Skipping: '$original_file' is already a symlink to '$nosync_file'."
      return 0
    else
      error_log "'$original_file' is a symlink to '$linked_file', not '$nosync_file'."
      return 1
    fi
  fi

  # Check if the file already has a .nosync extension
  if [ "${original_file%.nosync}" != "$original_file" ]; then
    log "Skipping: '$original_file' already has a .nosync extension."
    return 0
  fi

  # Move the original file and create a symbolic link
  if mv "$original_file" "$nosync_file"; then
    if ! ln -s "$nosync_file" "$original_file"; then
      error_log "Failed to create symlink for '$nosync_file'."
      return 1
    fi

    # Check if inside git repository and handle .gitignore update
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      log "Inside a git repository."

      # Get the root of the git repository
      git_root=$(git rev-parse --show-toplevel)

      # Add *.nosync to .gitignore if non-interactive or prompt user
      case "$non_interactive" in
        1) answer="n" ;;
        2) answer="y" ;;
        *) read -rp "Do you want to add '*.nosync' to .gitignore? [y/N] " answer ;;
      esac

      case "$answer" in
        [yY][eE][sS]|[yY])
          # Add *.nosync to .gitignore at the root if not already present
          gitignore_path="${git_root}/.gitignore"

          if [ -e "$gitignore_path" ]; then
            if ! grep -qx '\*.nosync' "$gitignore_path"; then
              echo "*.nosync" >> "$gitignore_path"
              log "Added '*.nosync' to $gitignore_path."
            else
              log "'*.nosync' is already in $gitignore_path."
            fi
          else
            echo "*.nosync" > "$gitignore_path"
            log "Created $gitignore_path and added '*.nosync'."
          fi
          ;;
        *)
          log "Skipped adding '*.nosync' to .gitignore."
          ;;
      esac
    fi

    # Hide nosync file if requested
    if [ "$hide_file" -eq 1 ]; then
      chflags hidden "$nosync_file"
      log "$nosync_file has been hidden using the hidden attribute."
    fi

    log "Processed: '$original_file' -> '$nosync_file'"
  else
    error_log "Failed to move '$original_file'. Skipping."
    return 1
  fi
}

# Parse flags and arguments using getopts
while getopts ":vnyhx-:" opt; do
  case $opt in
    v) verbose=1 ;;
    n) non_interactive=1 ;;
    y) non_interactive=2 ;;
    x) hide_file=1 ;;
    h) show_help; exit 0 ;;
    -)
      case "${OPTARG}" in
        verbose) verbose=1 ;;
        no|non-interactive) non_interactive=1 ;;
        yes) non_interactive=2 ;;
        hidden) hide_file=1 ;;
        help) show_help; exit 0 ;;
        *)
          error_log "Unknown option --${OPTARG}"
          show_help
          exit 1
          ;;
      esac ;;
    \?)
      error_log "Unknown option: -$OPTARG"
      show_help
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

# Ensure at least one file argument is provided
if [ $# -eq 0 ]; then
  error_log "No file arguments provided."
  show_help
  exit 1
fi

# Process each file argument
for file in "$@"; do
  nosync "$file"
done
