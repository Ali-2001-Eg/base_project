# base_project

A Flutter base project.

## Scaffold this project into a new directory

Use the scaffold script to copy this project into a new location, excluding build artefacts and caches.

### Usage

```bash
./tools/scaffold.sh /absolute/path/to/new_project
```

Notes:
- Provide an absolute destination path.
- Existing destination directory is allowed; existing files are left untouched unless `--force` is used.
- Run from the repository root.

### Options

- `--force`: Overwrite existing files in destination.
- `--name <app_name>`: Replace occurrences of `base_project` with your chosen name in key files.

### What gets excluded

- `build/`, `ios/Pods/`, `android/.gradle/`, platform build artefacts
- system files like `.DS_Store`
- IDE metadata like `.idea/`, `.vscode/`

### Example

```bash
./tools/scaffold.sh ~/StudioProjects/my_new_app --name MyNewApp
```

### Advanced Example

This example demonstrates how to scaffold the project into a new directory and customize its name, display name, and bundle identifiers for Android and iOS.

```bash
cd /Users/alimazen/StudioProjects/base_broject
chmod +x tools/scaffold.sh
./tools/scaffold.sh /Users/alimazen/StudioProjects/pharmacy \
  --name pharmacy \
  --display-name "Pharmacy" \
  --android-id pharmacy.order.app \
  --ios-id pharmacy.order.app
```

**Notes:**
- Make sure to provide absolute paths.
- Customize the flags according to your new app's details.



