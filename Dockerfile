# syntax=docker/dockerfile:1

# Base stage with common dependencies
FROM ruby:3.1-alpine AS base

# Install common dependencies in a single layer
RUN apk add --no-cache \
    build-base \
    git \
    nodejs

WORKDIR /srv/jekyll

# Install bundler once
RUN gem install bundler:2.4.22

# Development stage - live reload with Jekyll
FROM base AS development

# Copy dependency files for caching
COPY beautiful-jekyll-theme.gemspec Gemfile ./

# Install gems (without deployment mode for development)
RUN bundle install --jobs 4 --retry 3

# Expose Jekyll default port
EXPOSE 4000

# Default command for development
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--livereload", "--force_polling", "--incremental"]

# Build stage
FROM base AS builder

# Copy gemspec and Gemfile first for better layer caching
COPY beautiful-jekyll-theme.gemspec Gemfile ./

# Install gems for production
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copy the rest of the application
COPY . .

# Build the Jekyll site
RUN bundle exec jekyll build --destination /srv/jekyll/_site

# Production stage - lightweight nginx server
FROM nginx:1.25-alpine AS production

# Copy custom nginx configuration
COPY <<EOF /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Enable gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # HTML files - shorter cache
    location ~* \.html?$ {
        expires 1h;
        add_header Cache-Control "public, must-revalidate";
    }

    # Handle 404 errors
    error_page 404 /404.html;
    location = /404.html {
        internal;
    }

    # Try files, fallback to 404
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# Copy built site from builder stage
COPY --from=builder /srv/jekyll/_site /usr/share/nginx/html

# Use non-root user
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

# Switch to non-root user
USER nginx

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

EXPOSE 80
