# Changelog

## 0.1.3

- Added optional SFTP endpoint with dedicated user credentials and restricted `/config/Estada_PA` start directory.
- Added optional Node Inspector support on port 9229.
- Enabled source maps in runtime and dynamic rule compilation for TypeScript debugging.

## 0.1.2

- Fixed rule loader to ignore `*.d.ts` files.
- Exposed `EstadaProfessionalAutomationRule` globally for starter rule runtime loading.
- Improved runtime loading checks for invalid default exports.

## 0.1.1

- Prepared as standalone Home Assistant add-on repository structure.
- Added repository metadata for Home Assistant add-on store integration.
- Added maintainer and documentation metadata in add-on config.

## 0.1.0

- Initial Home Assistant add-on scaffold.
- Added `project-template/`.
- Added first-start copy logic for `/config/Estada_PA`.
- Added minimal TypeScript runtime, compiler and rule loader.
