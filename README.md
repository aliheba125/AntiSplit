# AntiSplit

Merge split APK files (APKS, APKM, XAPK) into a single APK and sign it.

## Dependencies

- `apkeditor` – merges split APKs  
- `apksigner` – signs the APK  
- `gum` – adds a progress spinner  
- `figlet` – displays a banner

## Installation

From the [TermuxVoid Repo](https://termuxvoid.github.io/) repository:

```bash
apt update
apt install antisplit -y
```

## Usage

```bash
antisplit <file.apks|apkm|xapk>
```

The signed APK will be saved in the same directory as the input file, with _signed.apk appended.

## Example:

```bash
antisplit app.apks
```

Output: app_signed.apk
