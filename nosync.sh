#!/usr/bin/env bash

# Default flag values
verbose=0
non_interactive=0  # 0 - interactive; 1 - automatic no; 2 - automatic yes
undo=0             # 0 - nosync, 1 - undo nosync
hide_file=0        # Hide .nosync file
exit_status=0

# Display help message
show_help () {
  cat << EOF
Usage: nosync [options] <file1> [file2 ... fileN]

Options:
  -v, --verbose                Enable verbose output
  -n, --no, --non-interactive  Automatically respond no to all prompts
  -y, --yes                    Automatically respond yes to all prompts
  -u, --undo                   Undo symlink and .nosync extension
  -x, --hidden                 Hide the .nosync file with chflags
  -h, --help                   Show this help message
EOF
}

# Consolidated logging function for both verbose and error handling
log () {
  if [ "$1" == "error" ]; then
    shift
    echo "Error: $@" >&2
  elif [ "$verbose" -eq 1 ]; then
    echo "$@"
  fi
}

# Add .nosync extension and create a symbolic link
nosync () {
  local original_file="$1"
  local nosync_file="${original_file}.nosync"

  # Check if the file is a symlink
  if [ -L "$original_file" ]; then
    local linked_file
    linked_file=$(readlink "$original_file")

    if [ ! -e "$linked_file" ]; then
      log "error" "Warning: '$original_file' is a symlink to non-existent '$linked_file'."
      return 1
    elif [ "$linked_file" == "$nosync_file" ]; then
      log "Skipping: '$original_file' is already linked to '$nosync_file'."
      return 0
    else
      log "error" "'$original_file' is a symlink to '$linked_file', not '$nosync_file'."
      return 1
    fi
  fi

  # If file already has .nosync extension
  if [ "${original_file%.nosync}" != "$original_file" ]; then
    log "Skipping: '$original_file' already has .nosync extension."
    return 0
  fi

  # Move the original file and create a symlink
  if mv "$original_file" "$nosync_file"; then
    if ! ln -s "$nosync_file" "$original_file"; then
      log "error" "Failed to create symlink for '$nosync_file'."
      return 1
    fi

    # Check if inside git repository and handle .gitignore update
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      log "Inside a git repository."
      handle_gitignore "$original_file"
    fi

    # Hide nosync file if requested
    if [ "$hide_file" -eq 1 ]; then
      chflags hidden "$nosync_file"
      log "$nosync_file has been hidden using the hidden attribute."
    fi

    log "Processed: '$original_file' -> '$nosync_file'"
  else
    log "error" "Failed to move '$original_file'. Skipping."
    return 1
  fi
}

# Handle gitignore update for .nosync files
handle_gitignore () {
  local git_root
  git_root=$(git rev-parse --show-toplevel)
  local gitignore_path="${git_root}/.gitignore"
  local answer

  case "$non_interactive" in
    1) answer="n" ;;
    2) answer="y" ;;
    *) read -rp "Add '*.nosync' to .gitignore? [y/N]: " answer ;;
  esac

  case "$answer" in
    [yY][eE][sS]|[yY])
      if [ -f "$gitignore_path" ] && ! grep -qx '*.nosync' "$gitignore_path"; then
        echo "*.nosync" >> "$gitignore_path"
        log "Added '*.nosync' to $gitignore_path."
      elif [ ! -f "$gitignore_path" ]; then
        echo "*.nosync" > "$gitignore_path"
        log "Created $gitignore_path and added '*.nosync'."
      else
        log "'*.nosync' already in $gitignore_path."
      fi
      ;;
    *)
      log "Skipped adding '*.nosync' to .gitignore."
      ;;
  esac
}

# Undo .nosync by removing the symlink and restoring the original file
cnyson () {
  local symlink_file="$1"
  local nosync_file="${symlink_file}.nosync"

  if [ -L "$symlink_file" ]; then
    local linked_file
    linked_file=$(readlink "$symlink_file")

    if [ "$linked_file" == "$nosync_file" ]; then
      log "Restoring '$symlink_file' from '$nosync_file'."
      if [ -e "$nosync_file" ]; then
        rm "$symlink_file" && mv "$nosync_file" "$symlink_file" && chflags nohidden "$symlink_file"
        log "Restored '$symlink_file'."
      else
        log "error" "The destination file '$nosync_file' does not exist. Cannot restore."
        return 1
      fi
    else
      log "'$symlink_file' is not pointing to '$nosync_file'. Skipping."
      return 1
    fi
  else
    log "'$symlink_file' is not a symlink. Skipping."
  fi
}

# Parse flags and arguments using getopts
while getopts ":vnyuxh-:" opt; do
  case $opt in
    v) verbose=1 ;;
    n) non_interactive=1 ;;
    y) non_interactive=2 ;;
    u) undo=1 ;;
    x) hide_file=1 ;;
    h) show_help; exit 0 ;;
    -)
      case "${OPTARG}" in
        verbose) verbose=1 ;;
        no|non-interactive) non_interactive=1 ;;
        yes) non_interactive=2 ;;
        undo) undo=1 ;;
        hidden) hide_file=1 ;;
        help) show_help; exit 0 ;;
        *) log "error" "Unknown option --${OPTARG}"; show_help; exit 1 ;;
      esac ;;
    \?) log "error" "Unknown option: -$OPTARG"; show_help; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

# Ensure at least one file argument is provided
if [ $# -eq 0 ]; then
  log "error" "No file arguments provided."
  show_help
  exit 1
fi

# Process each file argument
for file in "$@"; do
  if [ "$undo" -eq 1 ]; then
    cnyson "$file" || exit_status=1
  else
    nosync "$file" || exit_status=1
  fi
done

exit $exit_status
