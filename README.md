# FHIR IG Publisher scripts

This repository contains scripts for launching the FHIR IG Publisher, managing the publishing environment, and keeping the scripts and publisher current.

Run the scripts from the implementation guide's root directory. Relative locations such as `input-cache` and `../publisher.jar` are resolved from the current working directory.

## Publisher location

By default, the scripts install and share the publisher at:

- Unix: `~/.fhir/tools/publisher/publisher.jar`
- Windows: `%USERPROFILE%\.fhir\tools\publisher\publisher.jar`

Set `FHIR_PUBLISHER_HOME` to use another directory. The value is the directory that contains `publisher.jar`, not the path to the jar itself.

Unix example:

```sh
FHIR_PUBLISHER_HOME=/some/path ./_build.sh build
```

Windows example:

```bat
SET "FHIR_PUBLISHER_HOME=C:\some path"
_build.bat build
```

All launchers use the same lookup order:

1. `./input-cache/publisher.jar` — an explicit project-local publisher
2. `../publisher.jar` — the legacy shared location
3. `$FHIR_PUBLISHER_HOME/publisher.jar` — the shared publisher (or the platform default above)

The parent-folder location remains supported for backward compatibility, but publisher updates no longer install there.

## Updating the publisher

Use `_build.sh update` or `_build.bat update`, or run `_updatePublisher.sh` or `_updatePublisher.bat` directly.

If `./input-cache/publisher.jar` already exists, the scripts update it in place. Otherwise, they create the publisher home if necessary and install or update the shared `publisher.jar` there. This means an existing project-local publisher remains project-local, while a setup that only has `../publisher.jar` keeps working and gains a global publisher after the next explicit update.

The standalone update scripts first check whether the FHIR terminology server is reachable. The update commands offer to download the latest publisher from its [permanent location](https://github.com/HL7/fhir-ig-publisher/releases/latest/download/publisher.jar) and update the launcher scripts.

Pass `-y` or `--yes` to the Unix update script to skip all prompts. The existing force flags remain accepted by the standalone Unix and Windows update scripts.

## Building

`_genonce.bat` and `_genonce.sh` check whether `tx.fhir.org` is reachable, then build the IG from the current directory and exit. `_gencontinuous.bat` and `_gencontinuous.sh` use the same launcher with `-watch`, rebuilding when files change.

The consolidated `_build.bat` and `_build.sh` scripts provide equivalent build, update, no-SUSHI, offline, Jekyll, and cleanup commands through command-line options or an interactive menu.

## Security note

These scripts download executable code and may trigger antivirus or organizational security controls. If automatic download is blocked, download `publisher.jar` manually into one of the supported locations above. You can also invoke Java directly, for example:

```sh
java -jar "${FHIR_PUBLISHER_HOME:-$HOME/.fhir/tools/publisher}/publisher.jar" -ig .
```
