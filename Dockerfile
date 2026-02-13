# Use Microsoft's official Playwright base image
FROM mcr.microsoft.com/playwright:v1.49.1-noble

# Install @playwright/mcp globally
RUN npm install -g @playwright/mcp@latest

# Install Playwright browsers (required for @playwright/mcp)
RUN npx playwright install chromium --with-deps

# Create artifacts directory
RUN mkdir -p /app/artifacts && chmod 777 /app/artifacts

# Set working directory
WORKDIR /app

# Expose MCP server port (HTTP/SSE transport)
EXPOSE 8931

# Health check using TCP socket (no HTTP /health endpoint available)
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
    CMD timeout 2 bash -c 'cat < /dev/null > /dev/tcp/localhost/8931' || exit 1

# Run with ARK-optimized defaults
# Environment variables can override these via ConfigMap
CMD ["npx", "@playwright/mcp@latest", \
     "--headless", \
     "--browser", "chromium", \
     "--no-sandbox", \
     "--port", "8931", \
     "--host", "0.0.0.0"]
