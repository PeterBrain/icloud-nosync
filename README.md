# iCloud nosync

Prevent a file or directory from syncing with iCloud by adding the nosync extension. This process appends the nosync extension to the file or directory and then creates a symlink that points back to the original name, preserving any naming conventions (e.g.: node_modules).

## Usage

```bash
nosync <file1> [file2 ... fileN]
```

## Install

### Homebrew

```bash
brew tap peterbrain/tap
brew install icloud-nosync
```
or without tapping
```bash
brew install peterbrain/tap/icloud-nosync
```

### Manually

Clone this repository

```bash
install nosync.sh /usr/local/bin/nosync
```

## Caveats

* **Renaming**: If you need to rename a file or directory with the nosync extension, you'll need to recreate the symlink. Although Finder can still locate the renamed file or directory through the old symlink, the symlink itself will continue pointing to the original location, which isn't the case in Terminal.
  * My recommendation is to delete the symlink, remove the nosync extension, and then rerun the command.
* **Git**: Currently, both the symlink and the file or directory will be included in any repository unless they’re specifically excluded via `.gitignore`. Updates to this process are coming soon.
* **CLI**: This is a command-line tool for now, with plans to integrate it into Finder's context menu in the future.
* **Undo**: There’s no dedicated undo function. To reverse an action, simply delete the symlink and remove the nosync extension from the file or folder.

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
