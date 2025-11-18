# Valkey and OpenSearch 3.0 Support

MageFleet includes support for modern alternatives and newer versions of search and caching services.

## Valkey Support

[Valkey](https://valkey.io/) is a high-performance, open-source key-value datastore that serves as a drop-in replacement for Redis.

### Why Valkey?

- **100% Open Source**: Truly open-source alternative to Redis
- **Drop-in Replacement**: Compatible with Redis protocols and commands
- **Performance**: Optimized for speed and efficiency
- **Active Development**: Community-driven with frequent updates

### Using Valkey Instead of Redis

To use Valkey instead of Redis in your Magento project:

1. **Update your project's `.env` file**:
```bash
# Disable Redis
MAGEFLEET_REDIS=0

# Enable Valkey
MAGEFLEET_VALKEY=1

# Set Valkey version (optional, defaults to 8.0-alpine)
VALKEY_VERSION=8.0-alpine
```

2. **Restart your environment**:
```bash
magefleet env down
magefleet env up -d
```

### Configuration Notes

- Valkey uses the same container name as Redis (`redis`) for drop-in compatibility
- No Magento configuration changes are required
- The service hostname is `${ENV_NAME}-redis` for consistency

## OpenSearch 3.0 Support

MageFleet now supports OpenSearch 3.0, the latest major version with improved performance and features.

### What's New in OpenSearch 3.0

- Enhanced search performance
- Improved cluster management
- Better resource utilization
- Enhanced security features
- Native multi-tenancy support

### Using OpenSearch 3.0

OpenSearch 3.0 is now the default version for new projects. To use it:

1. **For new projects**, it's already configured in `.env`:
```bash
MAGEFLEET_OPENSEARCH=1
OPENSEARCH_VERSION=3.0
```

2. **For existing projects**, update your `.env`:
```bash
# Make sure OpenSearch is enabled
MAGEFLEET_OPENSEARCH=1

# Update to version 3.0
OPENSEARCH_VERSION=3.0
```

3. **Restart your environment**:
```bash
magefleet env down
magefleet env up -d
```

### OpenSearch 3.0 Configuration

The OpenSearch container includes these important settings for Magento compatibility:

- `DISABLE_SECURITY_PLUGIN=true` - Disables security for local development
- `plugins.security.disabled=true` - Additional security bypass
- `compatibility.override_main_response_version=true` - Ensures Magento compatibility
- Proper ulimits for memory and file descriptors

### Magento Configuration for OpenSearch 3.0

Update your Magento configuration (`app/etc/env.php`):

```php
'search' => [
    'engine' => 'opensearch',
    'opensearch_server_hostname' => 'opensearch',
    'opensearch_server_port' => '9200',
    'opensearch_index_prefix' => 'magento2',
    'opensearch_enable_auth' => 0,
    'opensearch_server_timeout' => 15
],
```

## Version Compatibility Matrix

| Service | Default Version | Supported Versions | Notes |
|---------|----------------|-------------------|-------|
| Redis | 7.2 | 5.0, 6.2, 7.0, 7.2 | Traditional Redis |
| Valkey | 8.0-alpine | 7.2, 8.0 | Redis alternative |
| OpenSearch | 3.0 | 1.2, 2.5, 3.0 | Elasticsearch alternative |

## Migration Tips

### Migrating from Redis to Valkey

1. Stop your environment
2. Update `.env` as shown above
3. Start environment - data will be lost (flush cache)
4. Flush Magento caches:
```bash
magefleet shell
bin/magento cache:flush
```

### Migrating to OpenSearch 3.0

1. Export your current search data (if needed)
2. Stop your environment
3. Update OpenSearch version in `.env`
4. Remove old OpenSearch data volume:
```bash
docker volume rm ${ENV_NAME}_osdata
```
5. Start environment and reindex:
```bash
magefleet env up -d
magefleet shell
bin/magento indexer:reindex catalogsearch_fulltext
```

## Troubleshooting

### Valkey Connection Issues

If Magento can't connect to Valkey:

1. Check the service is running:
```bash
docker ps | grep redis
```

2. Test connection from PHP container:
```bash
magefleet shell
telnet redis 6379
```

### OpenSearch 3.0 Issues

**Memory Errors**:
Increase Java heap size in your override file `.magefleet/magefleet-env.yml`:
```yaml
services:
  opensearch:
    environment:
      - "OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx1024m"
```

**Permission Denied**:
Ensure proper permissions on data volume:
```bash
docker exec -it $(docker ps -qf "name=opensearch") chown -R opensearch:opensearch /usr/share/opensearch/data
```

## Advanced Configuration

### Custom Valkey Configuration

Create `.magefleet/magefleet-env.yml` in your project:

```yaml
services:
  redis:
    image: valkey/valkey:8.0-alpine
    command: valkey-server --maxmemory 256mb --maxmemory-policy allkeys-lru
```

### Custom OpenSearch Configuration

```yaml
services:
  opensearch:
    image: opensearchproject/opensearch:3.0.0
    environment:
      - "OPENSEARCH_JAVA_OPTS=-Xms1g -Xmx1g"
      - cluster.name=my-cluster
      - node.name=node-1
```

## References

- [Valkey Official Documentation](https://valkey.io/docs/)
- [OpenSearch Documentation](https://opensearch.org/docs/latest/)
- [Magento OpenSearch Guide](https://experienceleague.adobe.com/docs/commerce-operations/configuration-guide/search/overview.html)
