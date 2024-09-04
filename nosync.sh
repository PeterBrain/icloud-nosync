#!/usr/bin/env bash

# Default flag values
verbose=0
non_interactive=0

# Display help message
show_help() {
  echo "Usage: nosync [options] <file1> [file2 ... fileN]"
  echo
  echo "Options:"
  echo "  -v, --verbose         Enable verbose output"
  echo "  -n, --non-interactive Skip interactive prompts"
  echo "  -h, --help            Show this help message"
}

# Log messages in verbose mode
log() {
  [ "$verbose" -eq 1 ] && echo "$@"
}

# Add .nosync extension and create a symbolic link to preserve original name
nosync () {
  local original_file="$1"
  local nosync_file="${original_file}.nosync"

  # Check if the file is a symlink, the linked file exists and points to the correct .nosync file
  if [ -L "$original_file" ]; then
    local linked_file
    linked_file=$(readlink "$original_file")

    if [ ! -e "$linked_file" ]; then
      log "Warning: '$original_file' is a symlink to a non-existent file '$linked_file'."
      return
    elif [ "$linked_file" = "$nosync_file" ]; then
      log "Skipping: '$original_file' is already a symlink to '$nosync_file'."
      return
    else
      log "Error: '$original_file' is a symlink to '$linked_file', not '$nosync_file'."
      return
    fi
  fi

  # Check if the file already has a .nosync extension
  if [[ "$original_file" == *.nosync ]]; then
    log "Skipping: '$original_file' already has a .nosync extension."
    return
  fi

  # Check if .nosync file already exists
  if [ -e "$nosync_file" ]; then
    log "Error: '$nosync_file' already exists. Skipping."
    return
  fi

  # Move the original file and create a symbolic link
  if mv "$original_file" "$nosync_file"; then
    ln -s "$nosync_file" "$original_file"

    # Check if inside git repository and handle .gitignore update
    if git rev-parse --is-inside-work-tree &>/dev/null; then
      log "Inside a git repository."

      # Get the root of the git repository
      local git_root
      git_root=$(git rev-parse --show-toplevel)

      # Add *.nosync to .gitignore if non-interactive or prompt user
      if [ "$non_interactive" -eq 1 ]; then
        answer="n"
      else
        # Ask the user if they want to add *.nosync to .gitignore at the root of the repository
        read -rp "Do you want to add '*.nosync' to .gitignore? [y/N] " answer
      fi

      case "$answer" in
        [yY][eE][sS]|[yY])
          # Add *.nosync to .gitignore at the root if not already present
          local gitignore_path="${git_root}/.gitignore"

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

    log "Processed: '$original_file' -> '$nosync_file'"
  else
    log "Error: Failed to move '$original_file'. Skipping."
  fi
}

# Parse flags and arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--verbose)
      verbose=1
      ;;
    -n|--non-interactive)
      non_interactive=1
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    --) # End of all options
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
    *) # No more options, treat remaining arguments as files
      break
      ;;
  esac
  shift
done

# Ensure at least one file argument is provided
if [ $# -eq 0 ]; then
  echo "Error: No file arguments provided."
  show_help
  exit 1
fi

# Process each file argument
for file in "$@"; do
  nosync "$file"
done
