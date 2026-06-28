# Estada Professional Automation

Home Assistant Add-on for professional TypeScript based automation rules.

## Rule directory

The add-on manages user rules in:

```text
/config/Estada_PA
```

On first start, the add-on copies the starter project from `project-template/` into this directory.
Existing files are never overwritten.

## SFTP access (optional)

This add-on can start an internal SFTP server so rule files can be edited remotely.

Enable these options in the add-on configuration:

```yaml
enable_sftp: true
sftp_port: 2222
sftp_username: estada
sftp_password: "your-strong-password"
```

Connection details:

- Host: Home Assistant host/IP
- Port: `sftp_port` (default `2222`)
- User: `sftp_username`
- Password: `sftp_password`
- Remote start directory: `/Estada_PA`

## Debugging (optional)

Node Inspector can be enabled for runtime debugging.

Enable these options in the add-on configuration:

```yaml
enable_debug: true
debug_port: 9229
```

Notes:

- Inspector listens on the configured `debug_port` (default `9229`).
- Source maps are enabled for app code and dynamically compiled rule files.
- Restart the add-on after changing debug options.
