# Changelog

## 0.2.8

- Describe changes.

## 0.2.7

- Describe changes.

## 0.2.6

- Describe changes.

## 0.2.5

- Describe changes.

## 0.2.4

- Describe changes.

## 0.2.3

- Describe changes.

## 0.2.2

- Simplified SSH/SFTP configuration for better compatibility
- Fixed internal-sftp subsystem configuration
- Improved SFTP chroot directory setup

## 0.2.1

- Fixed SSH/SFTP configuration (removed unsupported UsePAM option)
- Improved error handling for SSH and Samba startup
- Added error checks and better logging for service initialization

## 0.2.0

- Added optional Samba/SMB share support (`enable_samba`) for direct network folder access.
- Added automatic detection of standard Home Assistant Samba add-on with warning if both are active.
- Reverted default access method from Remote-SSH to SFTP + Node Inspector for simpler development workflow.
- Enhanced VS Code documentation with step-by-step SFTP setup guide.
- Added VS Code debug configuration (launch.json) for easy Node Inspector attachment.
- Provided sftp.json configuration file for automatic SFTP connection.
- Added Samba vs SSH/SFTP comparison table in README.
- Improved troubleshooting section with both SFTP and Samba scenarios.

## 0.1.4

- Switched from SFTP-only mode to default-enabled SSH/Remote-SSH access (still switchable in config).
- Enabled debugging by default (`enable_debug: true`) to lower onboarding friction.
- Added detailed VS Code Remote-SSH and debugger attach instructions to add-on README.

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








