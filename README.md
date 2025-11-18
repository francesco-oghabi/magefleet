# MageFleet

MageFleet is a specialized fork of [Warden](https://github.com/wardenenv/warden), focused exclusively on Magento development. It's a CLI utility for orchestrating Docker based Magento developer environments, enabling multiple local environments to run simultaneously without port conflicts via centrally run services for proxying requests.

## Why MageFleet?

MageFleet streamlines Magento development by:
- **Magento-focused**: Supports only Magento 1 and Magento 2, removing unnecessary complexity
- **Battle-tested**: Built on the solid foundation of Warden
- **Optimized**: Tailored specifically for Magento workflows

## Features

* **Modern Stack**: Traefik 2.11 for SSL termination and routing (compatible with latest Docker)
* **Flexible Caching**: Choose between Redis or Valkey for session/cache storage
* **Latest Search**: OpenSearch 3.0 support with backward compatibility
* **Portainer**: Quick visibility into running containers
* **Dnsmasq**: Automatic `.test` domain resolution
* **SSH Tunnel**: Database client connections to running containers
* **SSL Certificates**: Wildcard certificates for all local development domains
* **Full Support**: Magento 1 and Magento 2 on both macOS and Linux
* **Customizable**: Override and extend environment definitions per-project

### Key Improvements Over Warden

- ✅ Traefik 2.11 (fixes Docker API compatibility issues)
- ✅ Valkey support as Redis alternative
- ✅ OpenSearch 3.0 support
- ✅ Magento-focused (non-Magento platforms removed)
- ✅ Updated default versions for all services

## Contributing

All contributions to the MageFleet project are welcome: use-cases, documentation, code, patches, bug reports, feature requests, etc. Please submit [Issues](https://github.com/yourusername/magefleet/issues) and [Pull Requests](https://github.com/yourusername/magefleet/pulls) on GitHub.

## License

This work is licensed under the MIT license. See [LICENSE](LICENSE) file for details.

## Credits

MageFleet is a fork of [Warden](https://github.com/wardenenv/warden), originally created by [David Alger](https://davidalger.com/) in 2019.

**Original Warden License**: MIT License, Copyright (c) 2019 David Alger

This fork maintains compatibility with Warden's architecture while focusing exclusively on Magento development.

## Support the Original Project

If you find this tool useful, please consider supporting the original Warden project:
- [Warden on OpenCollective](https://opencollective.com/warden)
- [Warden on GitHub Sponsors](https://github.com/sponsors/wardenenv)
