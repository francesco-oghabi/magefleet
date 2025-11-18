# Upgrading from Warden to MageFleet

This guide helps you migrate from Warden to MageFleet.

## Key Differences

### 1. Command Name
- **Warden**: `warden`
- **MageFleet**: `magefleet`

### 2. Home Directory
- **Warden**: `~/.warden`
- **MageFleet**: `~/.magefleet`

### 3. Project Configuration Directory
- **Warden**: `.warden/`
- **MageFleet**: `.magefleet/`

### 4. Environment Variables
All environment variables have been renamed from `WARDEN_*` to `MAGEFLEET_*`:
- `WARDEN_ENV_NAME` → `MAGEFLEET_ENV_NAME`
- `WARDEN_ENV_TYPE` → `MAGEFLEET_ENV_TYPE`
- `WARDEN_HOME_DIR` → `MAGEFLEET_HOME_DIR`
- etc.

### 5. Traefik Version Update
MageFleet uses **Traefik 2.11** by default (instead of 2.2) to support modern Docker API versions (1.44+).

**Important**: This fixes the "client version 1.24 is too old" error that occurs with recent Docker installations.

## Migration Steps

### 1. Install MageFleet
```bash
# Clone the repository
git clone https://github.com/yourusername/magefleet.git
cd magefleet

# Install
./bin/magefleet install
```

### 2. Migrate Global Configuration
```bash
# Copy your Warden configuration
cp ~/.warden/.env ~/.magefleet/.env

# Update Traefik version in ~/.magefleet/.env
echo "TRAEFIK_VERSION=2.11" >> ~/.magefleet/.env
```

### 3. Migrate Project Configuration
For each project using Warden:

```bash
cd /path/to/your/magento/project

# Rename project configuration directory
mv .warden .magefleet

# Update environment variables in .env
sed -i 's/WARDEN_/MAGEFLEET_/g' .env

# Optionally add TRAEFIK_ENABLE if it's not set
echo "TRAEFIK_ENABLE=true" >> .env
```

### 4. Stop Warden Services
```bash
warden svc down
```

### 5. Start MageFleet Services
```bash
magefleet svc up
```

### 6. Restart Your Project
```bash
cd /path/to/your/magento/project
magefleet env down
magefleet env up -d
```

## Compatibility Notes

- **Magento 1 & 2**: Fully supported (only supported platforms)
- **Other platforms**: Not supported (Laravel, Symfony, Shopware, etc. have been removed)
- **Docker API**: Requires Docker API 1.44+ (Docker Engine 20.10+)
- **Traefik**: Uses version 2.11 for compatibility with modern Docker

## Troubleshooting

### "client version 1.24 is too old" Error
This is fixed by using Traefik 2.11. Ensure your `~/.magefleet/.env` contains:
```bash
TRAEFIK_VERSION=2.11
```

### SSL Certificate Issues
Regenerate SSL certificates if you experience SSL errors:
```bash
magefleet sign-certificate your-domain.test
```

### 404 Errors
Ensure `TRAEFIK_ENABLE=true` is set in your project's `.env` file.

## Rollback to Warden

If you need to rollback:

```bash
# Stop MageFleet
magefleet svc down

# Start Warden
warden svc up

# Restore project configuration
mv .magefleet .warden
sed -i 's/MAGEFLEET_/WARDEN_/g' .env
```
