# Estada Home Assistant Add-ons

This repository contains standalone Home Assistant add-ons.

## Add-ons

- **Estada Professional Automation** (`estada_professional_automation`)

## Installation

1. In Home Assistant, open **Settings -> Add-ons -> Add-on Store**.
2. Open the menu (three dots) and select **Repositories**.
3. Add this repository URL:

   ```text
   https://github.com/MichaelWeller/estada_homeassistant_professional_automation
   ```

4. Find **Estada Professional Automation** in the store and install it.

## Development

The add-on source is located in `estada_professional_automation/`.

## Versioning

Use semantic versioning for releases:

- Patch (`x.y.z` -> `x.y.z+1`): bug fixes and small internal changes.
- Minor (`x.y.z` -> `x.y+1.0`): new backward-compatible features.
- Major (`x.y.z` -> `x+1.0.0`): breaking changes.

For Home Assistant add-ons, bump the version on every published change.

### Version bump script

PowerShell script:

`scripts/bump-version.ps1`

Examples:

```powershell
# Preview next patch version without writing files
./scripts/bump-version.ps1 -Type patch -DryRun

# Bump patch version and add a changelog placeholder entry
./scripts/bump-version.ps1 -Type patch -ReleaseNote "- Fix rule loader behavior."

# Set an explicit version
./scripts/bump-version.ps1 -SetVersion 0.2.0 -ReleaseNote "- First feature release."

# Bump and create a commit
./scripts/bump-version.ps1 -Type patch -Commit -ReleaseNote "- Fix startup issue in HA."
```
