# iCloud-nosync

[![Update Homebrew Tap](https://github.com/PeterBrain/icloud-nosync/actions/workflows/update-tap.yml/badge.svg)](https://github.com/PeterBrain/icloud-nosync/actions/workflows/update-tap.yml)

Prevent a file or directory from syncing with iCloud by adding the nosync extension. This process appends the nosync extension to the file or directory and then creates a symlink that points back to the original name, preserving any naming conventions (e.g.: node_modules).

> [!WARNING]
> Please read all of the instructions carefully before use.

## Features

* prevent file or folder from syncing with iCloud
* add to gitignore
* undo symlink and .nosync extension
* hide .nosync file or folder with chflags
* non-interactive mode

## Install

### Homebrew

```bash
brew tap peterbrain/tap
brew install icloud-nosync
```
or
```bash
brew install peterbrain/tap/icloud-nosync
```

### Manually

Clone this repository

```bash
install nosync.sh /usr/local/bin/nosync
```

## Usage

```bash
nosync [options] <file1> [file2 ... fileN]

Options:
  -v, --verbose                Enable verbose output
  -n, --no, --non-interactive  Automatically respond no to all prompts
  -y, --yes                    Automatically respond yes to all prompts
  -u, --undo                   Undo symlink and .nosync extension
  -x, --hidden                 Hide the .nosync file with chflags
  -h, --help                   Show this help message
```

> [!NOTE]
> What happens if I want to exclude the directory or file "important", but there is already a "important.nosync" directory or file present?
>
> Answer: Nothing, this directory or file will be skipped.

## Caveats

* **OS**: This script will only work on macOS.
* **Renaming**: If you need to rename a file or directory with the nosync extension, you'll need to recreate the symlink. Although Finder can still locate the renamed file or directory through the old symlink, the symlink itself will continue pointing to the original location, which isn't the case in Terminal.
  * My recommendation is to delete the symlink, remove the nosync extension, and then rerun the command.
* **Git**: If the file or folder is in a git repository and the .nosync file or extension is added to `.gitignore`, the symlink will still be tracked.
* **Undo**: If the symlink name differs from the .nosync name, the symlink will be left unchanged. The undo process does not involve or modify the `.gitignore` file. ~~There’s no dedicated undo function. To reverse an action, simply delete the symlink and remove the nosync extension from the file or folder.~~
* **Files**: Files with the nosync extension wont open with their associated application anymore. Images wont be opened in preview, docs won't start Word or Pages.
  * Avoid using nosync on files. Use it on directories whenever possible.

> [!CAUTION]
> The list contains only the known limitations of this program. Proceed with caution!

## Uninstall

### Homebrew

```bash
brew uninstall icloud-nosync
```
or
```bash
brew uninstall peterbrain/tap/icloud-nosync
```

### Manually

This is only possible if nosync was installed manually.
```bash
rm /usr/local/bin/nosync
```
