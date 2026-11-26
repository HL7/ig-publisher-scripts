# FHIR IG Publisher scripts

`_fhirbuild.bat` (Windows) and `_fhirbuild.sh` (Linux and macOS) build FHIR implementation guides with the IG Publisher. There is one copy per computer, and the implementation guides do not need a copy of the script.

## Setup

1. Put the script for your system somewhere, e.g. in `~/.fhir/tools/scripts` (Windows: `%USERPROFILE%\.fhir\tools\scripts`).
2. Run `_fhirbuild.bat install` or `_fhirbuild.sh install` once, or start the script and choose "Install" in the menu. This associates the `.fhirbuild` and `.fhirbuildonce` extensions with the script, where it is, for the current user. It does not need administrator rights. After moving the script, run `install` again.
3. Run the script with `update` to download the publisher, if it is not there yet.

To remove the associations, run the script with `uninstall`, or choose "Uninstall" in the menu. The script and the publisher are not touched.

What `install` sets up:

- Windows: the file types in the registry, under `HKEY_CURRENT_USER`
- Linux: the MIME types and a desktop entry in `~/.local/share`, which open the script in a terminal
- macOS: a small app, `~/Applications/FHIR IG build.app`, which opens the script in Terminal. The first time, macOS asks to allow it to control Terminal.

## Building

Put a file in the root folder of the implementation guide and open it:

- `_ig.fhirbuild` shows the menu: update the publisher, build, build without SUSHI, build without the terminology server, Jekyll build, clean up
- `_ig.fhirbuildonce` runs the build directly, without the menu

The files can have any name; only the extension matters, and their content is not read. On Linux, the file must not be empty, as desktops such as GNOME do not recognize empty files by their extension; any text will do. The script runs on the folder of the file it is given, so it also works with "Open with". Without a file, it runs on the current folder.

From a terminal, options can be added after the file, e.g. `_fhirbuild.sh _ig.fhirbuild nosushi`, or on Windows `_ig.fhirbuild nosushi`. The options are `update`, `build`, `nosushi`, `notx`, `jekyll`, `clean` and `exit`; other arguments are passed to the publisher.

## Publisher location

By default, the publisher is shared at `~/.fhir/tools/publisher/publisher.jar` (Windows: `%USERPROFILE%\.fhir\tools\publisher\publisher.jar`). Set `FHIR_PUBLISHER_HOME` to use another directory. The value is the directory that contains `publisher.jar`, not the path to the jar itself.

The publisher is looked up in this order:

1. `input-cache/publisher.jar` in the implementation guide, for exceptional cases
2. `../publisher.jar`, the legacy shared location
3. `$FHIR_PUBLISHER_HOME/publisher.jar`, or the default above

`update` updates `input-cache/publisher.jar` if it exists, and otherwise the shared publisher. It then offers to update the script itself, where it is.

## Security note

The scripts download executable code and may trigger antivirus or organizational security controls. If automatic download is blocked, download [`publisher.jar`](https://github.com/HL7/fhir-ig-publisher/releases/latest/download/publisher.jar) manually into one of the locations above.

A publisher in `input-cache` comes first, so opening a `.fhirbuild` file in an implementation guide you downloaded can run a jar that came with it.