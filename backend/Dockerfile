# Use Node.js 18 LTS as base image
FROM node:18-bullseye

# Install LibreOffice, Python, and dependencies for headless operation
RUN apt-get update && apt-get install -y \
    libreoffice \
    libreoffice-writer \
    libreoffice-java-common \
    fonts-liberation \
    fonts-dejavu-core \
    fontconfig \
    curl \
    python3 \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies for document signing
RUN pip3 install python-docx pillow

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install Node.js dependencies
RUN npm install --only=production

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p uploads signed temp

# Set permissions for LibreOffice temp directories
RUN chmod 755 /tmp

# Expose port
EXPOSE 3500

# Set environment variables for LibreOffice
ENV SOFFICE_PATH=/usr/bin/soffice
ENV NODE_ENV=production

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3500/health || exit 1

# Start the application
CMD ["npm", "start"]
