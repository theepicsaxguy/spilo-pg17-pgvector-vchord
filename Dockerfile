FROM ghcr.io/zalando/spilo-17:4.0-p2
ARG VCHORD_VERSION=0.3.0
ARG TARGETARCH

USER root

# Install VectorChord based on architecture
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends wget ca-certificates; \
    \
    if [ "$TARGETARCH" = "amd64" ]; then \
        wget -O /tmp/vchord.deb "https://github.com/tensorchord/VectorChord/releases/download/${VCHORD_VERSION}/postgresql-17-vchord_${VCHORD_VERSION}-1_amd64.deb"; \
        dpkg -i /tmp/vchord.deb; \
        rm /tmp/vchord.deb; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        apt-get install -y --no-install-recommends \
            build-essential \
            cmake \
            postgresql-server-dev-17 \
            git; \
        cd /tmp; \
        git clone --depth 1 --branch v${VCHORD_VERSION} https://github.com/tensorchord/VectorChord.git; \
        cd VectorChord; \
        make install; \
        cd /; \
        rm -rf /tmp/VectorChord; \
        apt-get purge -y build-essential cmake git; \
        apt-get autoremove -y; \
    fi; \
    \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Include both vector and vchord for migration phase
ENV SHARED_PRELOAD_LIBRARIES="bg_mon,pg_stat_statements,pgextwlist,pg_auth_mon,set_user,vector,vchord"

USER 101

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD pg_isready -U postgres || exit 1