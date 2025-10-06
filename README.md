# eDirectory Docker Automation

Automated setup for OpenText eDirectory and Identity Console

## Requirements

- Docker installed and running
- LDAP utilities (for testing):
  - RHEL/CentOS/Rocky: `sudo dnf install openldap-clients`
  - Debian/Ubuntu: `sudo apt install ldap-utils`

## Quick Start

```bash
./setup.sh  # Install and configure (interactive)
./test.sh   # Verify with test user creation via CLI
./reset.sh  # Clean up
```

**⚠️ WARNING**: `reset.sh` removes **ALL** Docker containers and volumes on the system, not just eDirectory. Images are preserved. Use with caution.

### Setup Workflow

1. Run `./setup.sh`
2. During eDirectory setup, press ENTER to accept all defaults
3. When asked for admin password, choose a strong password
4. At the end, press `Ctrl+P` then `Ctrl+Q` to detach
5. Edit `.env` and set `ADMIN_PASSWORD` to match the password you entered

Default values (press ENTER):
- Admin name: `admin.org`
- Tree name: `--<hostname>-NDStree`
- Server context: `org`
- EBA: `n`
- NCP port: `524`
- IP addresses: `3` (All)
- LDAP port: `389`
- LDAPS port: `636`

## Configuration

`.env` is auto-created during setup. Edit it to match values you entered during installation:
- `ADMIN_PASSWORD`: Admin password (required for test.sh)
- `ORG`: LDAP organization (default: org)
- `ADMIN_CN`: Admin CN (default: admin)
- `CERT_PASSWORD`: Auto-generated
- `EDIR_IMAGE`: eDirectory Docker image (default: edirectory:9.3.0)
- `IDCONSOLE_IMAGE`: Identity Console Docker image (default: identityconsole:1.9.0.0000)

## Access

### Identity Console Web UI

URL: `https://<server-ip>:9000/identityconsole/`

Login credentials:
- Username: `cn=admin,o=org` (or your custom values from `.env`)
- Password: Your admin password
- Server IP: Your server IP address

### Service Ports

| Service | Port |
|---------|------|
| NCP     | 524  |
| LDAP    | 389  |
| LDAPS   | 636  |

## Usage

### Testing LDAP Connections

Test LDAP connection:
```bash
ldapsearch -H ldap://localhost:389 \
  -x -D "cn=admin,o=org" \
  -W -b "o=org" \
  -Z \
  -o tls_reqcert=never
```

Test LDAPS connection:
```bash
ldapsearch -H ldaps://localhost:636 \
  -x -D "cn=admin,o=org" \
  -W -b "o=org" \
  -o ldif-wrap=no \
  -o nettimeout=5 \
  -o tls_reqcert=never
```

Both commands connect as admin.org and perform a base search to verify service functionality.

### Creating Users via Web UI

1. Navigate to Home > User Management
2. Click the "+" icon (Add User)
3. Fill required fields:
   - Username: e.g., `test_user`
   - Context: Select appropriate context (e.g., `--<hostname>-ndstree/o=org`)
   - Last Name: e.g., `Test`
4. Click "Create"

## Troubleshooting

### View Container Logs

```bash
# eDirectory logs
docker logs edir

# Identity Console logs
docker logs idconsole
```
