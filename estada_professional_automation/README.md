# Estada Professional Automation

Home Assistant Add-on for professional TypeScript based automation rules.

## Rule directory

The add-on manages user rules in:

```text
/config/Estada_PA
```

On first start, the add-on copies the starter project from `project-template/` into this directory.
Existing files are never overwritten.

## VS Code Remote-SSH (default)

This add-on starts SSH/SFTP by default, so VS Code can connect directly.

Default add-on options:

```yaml
enable_ssh: true
ssh_port: 2222
ssh_username: estada
ssh_password: estada
```

If needed, you can disable SSH later with `enable_ssh: false`.

### Connect VS Code to Home Assistant

1. Install the VS Code extension **Remote - SSH**.
2. In Home Assistant, open the add-on config and verify SSH options.
3. Restart the add-on after any SSH option changes.
4. In VS Code, run **Remote-SSH: Add New SSH Host...** and add:

```text
ssh estada@<HOME_ASSISTANT_IP> -p 2222
```

5. Connect with **Remote-SSH: Connect to Host...** and enter the password.
6. Open folder `/config/Estada_PA` on the remote host.

Connection parameters:

- Host: Home Assistant host/IP
- Port: `ssh_port` (default `2222`)
- User: `ssh_username` (default `estada`)
- Password: `ssh_password` (default `estada`)

## Debugging (default enabled)

Node Inspector is enabled by default for runtime debugging.

Default debug options:

```yaml
enable_debug: true
debug_port: 9229
```

Notes:

- Inspector listens on the configured `debug_port` (default `9229`).
- Source maps are enabled for app code and dynamically compiled rule files.
- Restart the add-on after changing debug options.

### Attach debugger from VS Code

1. Open **Run and Debug** in VS Code.
2. Create an **Attach** config for Node.js with:
   - address: Home Assistant host/IP
   - port: 9229 (or your `debug_port`)
3. Start the attach configuration.
