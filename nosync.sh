#!/usr/bin/env bash

# Add .nosync extension and create a symbolic link to preserve original name

nosync () {
  original_file="$1"
  nosync_file="${original_file}.nosync"

  # Check if the file is a symlink
  if [ -L "$original_file" ]; then
    linked_file=$(readlink "$original_file")

    # Check if the linked file exists
    if [ ! -e "$linked_file" ]; then
      echo "Warning: '$original_file' is a symlink to '$linked_file', but the target no longer exists."
      return
    fi

    # If it's already a symlink pointing to the correct .nosync file, skip
    if [ "$linked_file" = "$nosync_file" ]; then
      echo "Skipping: '$original_file' is already a symlink to '$nosync_file'."
      return
    else
      echo "Error: '$original_file' is a symlink to '$linked_file', not '$nosync_file'."
      return
    fi
  fi

  # Check if the file already has a .nosync extension
  if [ "${original_file##*.}" = "nosync" ]; then
    echo "Skipping: '$original_file' already has a .nosync extension."
    return
  fi

  # Check if .nosync file already exists
  if [ -e "$nosync_file" ]; then
    echo "Error: '$nosync_file' already exists. Skipping."
    return
  fi

  # Move the original file and create a symbolic link
  if mv "$original_file" "$nosync_file"; then
    ln -s "$nosync_file" "$original_file"

    # Check if inside git repository
    inside_git_repo=$(git rev-parse --is-inside-work-tree 2>/dev/null)

    if [ "$inside_git_repo" ]; then
      echo "Inside a git repository."

      # Get the root of the git repository
      git_root=$(git rev-parse --show-toplevel)

      # Ask the user if they want to add *.nosync to .gitignore
      read -rp "Do you want to add '*.nosync' to .gitignore at the root of the repository? [y/N] " answer
      case "$answer" in
        [yY][eE][sS]|[yY])
          # Add *.nosync to .gitignore at the root if not already present
          gitignore_path="${git_root}/.gitignore"

          if [ -e "$gitignore_path" ]; then
            if ! grep -qx '\*.nosync' "$gitignore_path"; then
              echo "*.nosync" >> "$gitignore_path"
              echo "Added '*.nosync' to $gitignore_path."
            else
              echo "'*.nosync' is already in $gitignore_path."
            fi
          else
            echo "*.nosync" > "$gitignore_path"
            echo "Created $gitignore_path and added '*.nosync'."
          fi
          ;;
        *)
          echo "Skipped adding '*.nosync' to .gitignore."
          ;;
      esac
    fi

    echo "Processed: '$original_file' -> '$nosync_file'"
  else
    echo "Error: Failed to move '$original_file'. Skipping."
  fi
}

# Ensure at least one argument is passed
if [ $# -eq 0 ]; then
  echo "Usage: nosync <file1> [file2 ... fileN]"
  exit 1
fi

# Process all arguments
while [ -n "$1" ]; do
  nosync "$1"
  shift
done
