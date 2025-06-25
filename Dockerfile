# Stage 1: Builder for preparing source code
FROM registry.access.redhat.com/ubi9/nodejs-18:latest AS builder
USER 0
RUN dnf update -y && dnf clean all

# Add labels for metadata
LABEL maintainer="Sock Shop Team"       description="Builder stage for Sock Shop front-end"

# Set working directory
WORKDIR /usr/src/app

# Copy application source code from the local context
COPY . /usr/src/app

# Stage 2: Production runtime environment
FROM registry.access.redhat.com/ubi9/nodejs-18-minimal:latest

# Add labels for metadata
LABEL maintainer="Sock Shop Team"       description="Production image for Sock Shop front-end"

# Application environment configuration
ENV NODE_ENV=production
ENV PORT=8079
EXPOSE 8079

# User/Group configuration
ENV	SERVICE_USER=myuser \
	SERVICE_UID=10001 \
	SERVICE_GROUP=mygroup \
	SERVICE_GID=10001

# System setup and security configuration
USER 0
RUN microdnf install -y nc \
    && microdnf clean all \
    && groupadd -r -g ${SERVICE_GID} ${SERVICE_GROUP} \
    && useradd -r -u ${SERVICE_UID} -g ${SERVICE_GROUP} -m -d /home/${SERVICE_USER} -s /sbin/nologin ${SERVICE_USER}

# Application directory setup
WORKDIR /usr/src/app

# Copy dependency manifests first for better layer caching
COPY --from=builder /usr/src/app/package.json /usr/src/app/
COPY --from=builder /usr/src/app/yarn.lock /usr/src/app/

# Dependency installation and configuration
RUN mkdir -p /opt/app-root/src/.npm \
    && npm install -g npm \
    && npm install -g yarn@1.22.19 \
    && chown -R ${SERVICE_USER}:${SERVICE_GROUP} /opt/app-root/src/ \
    && chown -R ${SERVICE_USER} /usr/src/

# Switch to non-privileged user for dependency installation
USER ${SERVICE_USER}
# Install project dependencies
RUN yarn install

# Copy application source code
COPY --from=builder /usr/src/app/ /usr/src/app

# Healthcheck for the container
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3   CMD nc -z 127.0.0.1 ${PORT} || exit 1

# Application entrypoint
CMD ["/usr/bin/npm", "start"]
