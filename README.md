![iCloud noSync](https://repository-images.githubusercontent.com/843961044/fb0274fc-b4a1-489e-a0a8-b890de6b1cf0)

# iCloud noSync

[![Update Homebrew Tap](https://github.com/PeterBrain/icloud-nosync/actions/workflows/update-tap.yml/badge.svg)](https://github.com/PeterBrain/icloud-nosync/actions/workflows/update-tap.yml)

Prevent a file or directory from syncing with iCloud by adding the nosync extension. This process appends the nosync extension to the file or directory and then creates a symlink that points back to the original name, preserving any naming conventions (e.g.: node_modules, vendor).

Background story: iCloud can become very CPU-intensive when handling a large number of small files, such as those commonly found in `node_modules` or `vendor` folders. This is because iCloud’s synchronization process has to monitor, queue, and upload each file individually. When there are many small files, the synchronization process becomes inefficient due to overhead associated with tracking changes and managing each file's upload process.

## Features

- Prevent file or folder from syncing with iCloud
- Add to gitignore (optional)
- Undo symlink and .nosync extension
- Hide .nosync file or folder with chflags (optional)
- Non-interactive mode
- Finder quick actions

## Install

### Homebrew

```bash
brew tap peterbrain/tap
brew install icloud-nosync
cp -r /usr/local/opt/icloud-nosync/workflows/* ~/Library/Services/
```

or

```bash
brew install peterbrain/tap/icloud-nosync
cp -r /usr/local/opt/icloud-nosync/workflows/* ~/Library/Services/
```

> [!NOTE]
> Workflows for Finder Quick Actions require to be copied to `~/Library/Services` manually. This is due to a security limitation of the homebrew installer. Instructions to do so are displayed during installation.

### Manually

Clone this repository

```bash
install nosync.sh /usr/local/bin/nosync
cp -r ./workflows/* ~/Library/Services/
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

> [!NOTE]
> What happens if I want to undo nosync for the directory or file "important.nosync", but there is already a "important" directory or file present?
>
> Answer: Nothing, to prevent any issues the undo process will abort. Manual conflict resolution is required.
>
> This is usually the case when the nosync file or folder gets created manually, the symlink was removed and a file or folder with the same name has taken its place.

## Caveats

- **OS**:
  - Work on macOS for iCloud only.
  - Minimum version is macOS Sierra 10.12.
  - Other cloud services (e.g. OneDrive, Dropbox, Google Drive) are unsupported.
- **Files**:
  - Files with the nosync extension wont open with their associated application anymore. Images wont be opened in preview, docs won't start Word or Pages. Avoid using nosync on files. Use it on directories whenever possible.
- **Renaming**:
  - If you need to rename a file or directory with the nosync extension, you'll need to recreate the symlink. Although Finder can still locate the renamed file or directory through the old symlink, the symlink itself will continue pointing to the original location, which isn't the case in Terminal. It's recommended to delete the symlink, remove the nosync extension, and then rerun the nosync command.
- **Git**:
  - If the file or folder is in a git repository and the .nosync file or extension is added to `.gitignore`, the symlink will still be tracked.
- **Undo**:
  - If the symlink is provided and it does not point to the corresponding `.nosync` file, the undo process will be aborted.
  - If the `.nosync` file is provided and the matching symlink (by name) does not point to it, the undo process will be aborted.
  - If the `.nosync` file is provided and there is no matching symlink (e.g.: manually created), the undo process will try to restore the file.
  - The undo process does not involve or modify the `.gitignore` file.
- **Quick Action**:
  - Workflows require to be copied to `~/Library/Services` manually. This is due to a security limitation of the homebrew installer. Instructions to do so are displayed during install with homebrew.
  - Service workflows may need to be manually enabled. Please refer to these instructions: [https://support.apple.com/guide/automator/use-quick-action-workflows-aut73234890a/mac](https://support.apple.com/guide/automator/use-quick-action-workflows-aut73234890a/mac#aut067d4e77d)

> [!CAUTION]
> The list contains only the known limitations of this program. Proceed with caution!

## Uninstall

### Homebrew

```bash
brew uninstall icloud-nosync
rm ~/Library/Services/nosync_*
```

or

```bash
brew uninstall peterbrain/tap/icloud-nosync
rm ~/Library/Services/nosync_*
```

### Manually

This is only possible if nosync was installed manually.

```bash
rm /usr/local/bin/nosync ~/Library/Services/nosync_*
```
