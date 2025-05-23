FROM ghcr.io/zalando/spilo-17:4.0-p2 AS base

# Build arguments for version pinning
ARG VCHORD_VERSION=0.3.0
ARG PGVECTOR_VERSION=0.7.0
ARG TARGETARCH

USER root

# Add PostgreSQL PGDG repo and install extensions
RUN apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        wget \
        ca-certificates \
        gnupg \
        lsb-release \
        curl && \
    # Add PostgreSQL repository
    echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update && \
    # Install pgvector (available for both amd64 and arm64)
    apt-get install -y --no-install-recommends --no-install-suggests \
        postgresql-17-pgvector && \
    # Install VectorChord based on architecture
    if [ "$TARGETARCH" = "amd64" ]; then \
        wget -O /tmp/vchord.deb "https://github.com/tensorchord/VectorChord/releases/download/${VCHORD_VERSION}/postgresql-17-vchord_${VCHORD_VERSION}-1_amd64.deb" && \
        dpkg -i /tmp/vchord.deb && \
        rm /tmp/vchord.deb; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        # VectorChord doesn't provide arm64 packages yet, so we'll build from source
        apt-get install -y --no-install-recommends --no-install-suggests \
            build-essential \
            cmake \
            postgresql-server-dev-17 \
            git && \
        cd /tmp && \
        git clone --depth 1 --branch v${VCHORD_VERSION} https://github.com/tensorchord/VectorChord.git && \
        cd VectorChord && \
        make install && \
        cd / && \
        rm -rf /tmp/VectorChord && \
        apt-get purge -y build-essential cmake git; \
    fi && \
    # Cleanup
    apt-get purge -y wget gnupg curl && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* /var/tmp/*

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pg_isready -U postgres || exit 1

# Labels for better metadata
LABEL org.opencontainers.image.title="Spilo PostgreSQL 17 with pgvector & VectorChord"
LABEL org.opencontainers.image.description="PostgreSQL 17 with pgvector and VectorChord extensions for vector similarity search"
LABEL org.opencontainers.image.vendor="theepicsaxguy"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://github.com/theepicsaxguy/spilo-pg17-pgvector-vchord"

USER 101