# MageFleet TODO List

## High Priority

### 1. Create Custom Docker Images
Build custom MageFleet images to replace Warden registry dependencies.

**Images to create:**
- [ ] `magefleet/mariadb` (versions: 10.4, 10.6, 10.11, 11.4)
- [ ] `magefleet/mysql` (versions: 5.7, 8.0)
- [ ] `magefleet/php-fpm` (versions: 7.4, 8.1, 8.2, 8.3, 8.4)
  - [ ] Base variant
  - [ ] `-magento1` variant
  - [ ] `-magento2` variant
  - [ ] `-debug` / `-xdebug3` variants
  - [ ] `-blackfire` variant
  - [ ] `-spx` variant
- [ ] `magefleet/nginx` (version: 1.16, 1.24, 1.26)
- [ ] `magefleet/redis` (versions: 5.0, 6.2, 7.0, 7.2)
- [ ] `magefleet/valkey` (versions: 7.2, 8.0, 8.1)
- [ ] `magefleet/varnish` (versions: 6.0, 7.0, 7.1, 7.7)
- [ ] `magefleet/rabbitmq` (versions: 3.8, 3.9, 4.1)
- [ ] `magefleet/elasticsearch` (versions: 7.10, 8.11)
- [ ] `magefleet/magepack` (versions: 2.3, 2.11)
- [ ] `magefleet/dnsmasq`

**Repository Setup:**
- [ ] Create Docker Hub account/organization: `magefleet`
- [ ] Setup automated builds (GitHub Actions)
- [ ] Create Dockerfiles in separate repository or subfolder
- [ ] Document build process
- [ ] Setup version tagging strategy

**Configuration Updates:**
- [ ] Update default `MAGEFLEET_IMAGE_REPOSITORY` to `docker.io/magefleet`
- [ ] Update `.env.sample` with new repository
- [ ] Update all documentation references

### 2. Documentation
- [ ] Create `IMAGES.md` - Complete image documentation
- [ ] Create `BUILDING.md` - Guide for building custom images
- [ ] Add migration guide from Warden images to MageFleet images
- [ ] Document image customization process

### 3. Testing
- [ ] Test all Magento 2 versions (2.4.6, 2.4.7, 2.4.8)
- [ ] Test Magento 1 compatibility
- [ ] Test all PHP versions with Magento 2
- [ ] Test Valkey as Redis replacement
- [ ] Test OpenSearch 3.0 compatibility
- [ ] Test upgrade path from Warden

## Medium Priority

### 4. GitHub Repository Setup
- [ ] Create public GitHub repository
- [ ] Setup GitHub Actions for CI/CD
- [ ] Create issue templates
- [ ] Create PR templates
- [ ] Setup branch protection rules
- [ ] Add badges (build status, license, version)

### 5. Image Optimization
- [ ] Optimize image sizes
- [ ] Multi-arch builds (amd64, arm64)
- [ ] Security scanning integration
- [ ] Vulnerability patching process
- [ ] Regular updates schedule

### 6. Features
- [ ] Add support for PostgreSQL (Magento Commerce)
- [ ] Add support for Redis Sentinel
- [ ] Add support for Redis Cluster
- [ ] Improve SSL certificate management
- [ ] Add health checks to all services

## Low Priority

### 7. Community
- [ ] Create contributing guidelines
- [ ] Setup discussions/forums
- [ ] Create example projects
- [ ] Video tutorials
- [ ] Blog posts

### 8. Advanced Features
- [ ] Multi-version PHP support in single environment
- [ ] Automatic Magento version detection
- [ ] Performance monitoring integration
- [ ] Log aggregation (ELK stack)
- [ ] Backup/restore utilities

## Done ✅

- [x] Fork Warden repository
- [x] Rename all references from Warden to MageFleet
- [x] Remove non-Magento environment types
- [x] Update Traefik to version 2.11
- [x] Add Valkey support
- [x] Add OpenSearch 3.0 support
- [x] Create initial documentation
- [x] Update README
- [x] Create LICENSE file
- [x] Create UPGRADE_FROM_WARDEN.md
- [x] Create VALKEY_OPENSEARCH.md

## Notes

### Image Repository Strategy

Current images use `docker.io/wardenenv` repository. To make MageFleet independent:

1. **Option A - Fork and Modify Warden Images**:
   - Fork https://github.com/wardenenv/images
   - Rebrand to MageFleet
   - Add MageFleet-specific optimizations
   - Publish to `docker.io/magefleet`

2. **Option B - Build from Scratch**:
   - Create new Dockerfiles optimized for MageFleet
   - Learn from Warden but implement independently
   - Better long-term maintenance

**Recommended**: Option A for faster initial release, then gradually move to Option B for optimized images.

### Priority Order

1. Create basic images (PHP, Nginx, MariaDB) - **Week 1**
2. Setup automated builds - **Week 1**
3. Test with real Magento projects - **Week 2**
4. Create remaining images (Redis, Varnish, etc.) - **Week 2-3**
5. Documentation and community setup - **Week 3-4**
6. Public release - **Week 4**

### Resources Needed

- Docker Hub organization: `magefleet`
- GitHub organization: `magefleet` (optional, can use personal account)
- CI/CD credits (GitHub Actions free tier should be sufficient)
- Domain: `magefleet.dev` or `magefleet.io` (optional, for docs)
