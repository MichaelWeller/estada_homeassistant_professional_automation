# Estada Professional Automation

Home Assistant Add-on for professional TypeScript based automation rules.

## Rule directory

The add-on manages user rules in:

```text
/config/Estada_PA
```

On first start, the add-on copies the starter project from `project-template/` into this directory.
Existing files are never overwritten.

## Development Setup

This add-on provides SSH/SFTP for remote development. The recommended workflow is:

1. **Edit code locally** via SFTP sync
2. **Auto-compile** happens on the Home Assistant host
3. **Debug** using Node Inspector if needed

Default add-on options:

```yaml
enable_ssh: true
ssh_port: 2222
ssh_username: estada
ssh_password: estada
enable_debug: true
debug_port: 9229
```

---

## VS Code Development Guide

### Step 1: Install SFTP Extension

1. Open VS Code Extensions (`Ctrl+Shift+X`)
2. Search for **"SFTP"** by liximomo
3. Install the extension

### Step 2: Connect to Home Assistant via SFTP

The SFTP configuration is already provided in `.vscode/sftp.json` with:

- **Host:** Your Home Assistant IP (e.g., `192.168.2.14`)
- **Port:** `2222` (SSH/SFTP)
- **User:** `estada`
- **Password:** `estada`
- **Remote Path:** `/config/Estada_PA`
- **Auto-upload:** Enabled (saves automatically sync to HA)

**To connect:**

1. Open the File Explorer in VS Code
2. Right-click → **SFTP: Connect** (or use Command Palette: `Ctrl+Shift+P` → SFTP: Connect)
3. The remote folder appears in the Explorer (you'll see a connection indicator)

**You now see the files as if they were local!**

### Step 3: Start Editing

1. **Open a file** from the SFTP folder
2. **Make changes**
3. **Save** (`Ctrl+S`)
4. → File is automatically uploaded to Home Assistant
5. → Add-on auto-recompiles (Hot Reload)
6. **Done!** No manual commands needed

### Step 4: Debug Rules (Optional)

If you want to step through your code:

1. Add a breakpoint in your TypeScript file (click on the line number)
2. Open **Run and Debug** (`Ctrl+Shift+D`)
3. Select **"Attach to Estada PA"** from the dropdown
4. Click **Start Debugging** (or press `F5`)
5. The debugger connects to the Node Inspector on port `9229`
6. Execution stops at your breakpoint

**Debug controls:**

- `F10` = Step over
- `F11` = Step into
- `Shift+F11` = Step out
- `F5` = Continue
- `Shift+F5` = Stop debugger

---

## Alternative: Samba/SMB Network Share

Instead of SSH/SFTP, you can enable **Samba (SMB)** to mount the rules folder as a Windows network share. This gives a more traditional "local folder" experience.

### Samba Setup

1. Open Home Assistant add-on config
2. Set `enable_samba: true`
3. Optionally change `samba_share_name` (default: `Estada_PA`)
4. Restart the add-on

### Access the Share from Windows

1. Open **File Explorer**
2. In the address bar type: `\\<HOME_ASSISTANT_IP>\Estada_PA`
   - Replace `<HOME_ASSISTANT_IP>` with your Home Assistant IP (e.g., `192.168.2.14`)
3. Press Enter
4. The folder mounts as a network drive
5. Open it in VS Code as a regular local folder

### VS Code Setup with Samba

1. In VS Code: File → Open Folder
2. Navigate to `\\<HOME_ASSISTANT_IP>\Estada_PA`
3. You now have full VS Code editing (IntelliSense, linting, etc.) **without SFTP Extension**
4. Save files normally → Auto-compile on Home Assistant
5. Optionally: Still configure debugging on port `9229` if needed

### Samba or SSH/SFTP?

| Feature                          | SSH/SFTP                  | Samba               |
| -------------------------------- | ------------------------- | ------------------- |
| Setup complexity                 | Medium (Extension needed) | Low (Network share) |
| Performance                      | Excellent                 | Good                |
| Windows Explorer integration     | No                        | Yes ✓               |
| VS Code IntelliSense             | Yes (with Server)         | Yes (full local)    |
| Debugging                        | Yes                       | Yes (port 9229)     |
| Requires SSH/SFTP Extension      | Yes                       | No                  |
| Works with existing Samba add-on | No                        | Warning\*           |

**Note:** If you already have the standard Home Assistant Samba add-on enabled, the add-on will detect it and warn you. You may want to use only one Samba service to avoid conflicts.

---

## Configuration

### SSH/SFTP Options

Edit Home Assistant add-on config to change:

```yaml
enable_ssh: true # Enable/disable SSH/SFTP
ssh_port: 2222 # SSH/SFTP port
ssh_username: estada # SSH user
ssh_password: estada # SSH password
```

**Note:** Restart the add-on after changing any SSH options.

### Samba Options

```yaml
enable_samba: false # Enable/disable Samba share
samba_share_name: Estada_PA # Network share name
```

**To enable Samba:**

1. Set `enable_samba: true` in add-on config
2. Optionally customize `samba_share_name`
3. Restart the add-on
4. Access via `\\<HA_IP>\<samba_share_name>` in File Explorer

**Note:** The add-on will detect if the standard Home Assistant Samba add-on is also active and warn you about potential conflicts.

### Debug Options

```yaml
enable_debug: true # Enable Node Inspector
debug_port: 9229 # Inspector port
```

**Note:** Source maps are enabled for TypeScript debugging. Restart the add-on after changing debug options.

---

## Troubleshooting

### SFTP connection fails

- Verify Home Assistant IP is correct
- Check that SSH is enabled in add-on config
- Ensure port `2222` is not blocked by firewall
- Try credentials: `estada` / `estada`

### Files don't sync

- Check SFTP status indicator in VS Code status bar
- Verify folder is connected via SFTP
- Try right-click → **SFTP: List** to test connection

### Debugger won't attach

- Ensure `enable_debug: true` in add-on config
- Check firewall allows port `9229`
- Verify Home Assistant IP/port in `launch.json`
- Restart the add-on

### Hot Reload not working

- Check add-on logs in Home Assistant
- Ensure file is in the correct rules directory
- TypeScript compilation errors prevent reload (check logs)

### Samba share won't connect

- Verify Home Assistant IP is correct
- Ensure `enable_samba: true` in add-on config
- Check firewall allows port `445` (SMB)
- Restart the add-on after enabling Samba
- On Windows, try: `net use * /delete` to clear cached credentials, then reconnect

### Samba conflict with standard add-on

- The add-on warns if standard Samba add-on is active
- Both can coexist, but may cause confusion
- Consider disabling one if you only need file access for Estada PA
- If you want to use the standard Samba add-on, set `enable_samba: false`
