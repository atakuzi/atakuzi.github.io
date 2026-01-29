# Docker Setup for Jekyll Site

This directory contains Docker configuration for running your Beautiful Jekyll site in both development and production environments.

## Quick Start

### Development Mode (with live reload)
```bash
docker compose --profile dev up
```
Access the site at http://localhost:4000

### Production Mode
```bash
docker compose --profile prod up
```
Access the site at http://localhost:8080

## Docker Files

- **Dockerfile**: Multi-stage build with development and production targets
- **docker-compose.yml**: Orchestration for dev and prod environments
- **.dockerignore**: Optimizes build context

## Features

### Development
✅ Live reload on file changes  
✅ Fast incremental builds  
✅ Volume mounts for instant editing  
✅ Bundle cache for faster rebuilds

### Production
✅ Multi-stage build (Ruby → Nginx)  
✅ Optimized nginx configuration  
✅ Gzip compression enabled  
✅ Security headers configured  
✅ Static asset caching  
✅ Health checks configured  
✅ Runs as non-root user  
✅ Minimal image size (~25MB)

## Commands

### Build production image
```bash
docker compose build jekyll-prod
```

### Run in background
```bash
docker compose --profile dev up -d
```

### View logs
```bash
docker compose logs -f jekyll-dev
```

### Stop all containers
```bash
docker compose --profile dev down
```

### Clean rebuild
```bash
docker compose --profile dev down -v
docker compose --profile dev build --no-cache
docker compose --profile dev up
```

## Production Deployment

The production image uses nginx to serve static files with:
- Gzip compression
- Browser caching
- Security headers
- Custom 404 handling

To deploy to production:
```bash
docker compose --profile prod up -d
```

## Best Practices Implemented

1. **Multi-stage builds** - Separate build and runtime stages
2. **Layer caching** - Dependencies installed before copying source
3. **.dockerignore** - Excludes unnecessary files from build context
4. **Non-root user** - Production container runs as nginx user
5. **Health checks** - Automatic container health monitoring
6. **Named volumes** - Persistent bundle cache for development
7. **Build arguments** - Pinned Ruby and nginx versions
8. **Security headers** - XSS, clickjacking, and MIME-sniffing protection

## Troubleshooting

### Port already in use
Change the port mapping in docker-compose.yml:
```yaml
ports:
  - "4001:4000"  # Use different host port
```

### Slow on Windows
This is due to volume mount performance. Consider using WSL2 or Docker Desktop with improved filesystem performance.

### Permission issues
Ensure your user has Docker permissions:
```bash
docker compose --profile dev down
docker compose --profile dev up
```
