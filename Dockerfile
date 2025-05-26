# theepicsaxguy-spilo-pg17-pgvector-vchord/Dockerfile
# This base image will be built LOCALLY by the GitHub Action workflows
# from the spilo-upstream submodule. It won't be pushed to a registry.
FROM spilo-base-temp:latest
ARG VCHORD_VERSION=0.4.1
ARG TARGETARCH

USER root

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends wget ca-certificates; \
    \
    if [ "$TARGETARCH" = "amd64" ]; then \
        wget -O /tmp/vchord.deb "https://github.com/tensorchord/VectorChord/releases/download/${VCHORD_VERSION}/postgresql-17-vchord_${VCHORD_VERSION}-1_amd64.deb"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        wget -O /tmp/vchord.deb "https://github.com/tensorchord/VectorChord/releases/download/${VCHORD_VERSION}/postgresql-17-vchord_${VCHORD_VERSION}-1_arm64.deb"; \
    else \
        echo "Unsupported architecture: $TARGETARCH"; exit 1; \
    fi; \
    dpkg -i /tmp/vchord.deb; \
    rm /tmp/vchord.deb; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV SHARED_PRELOAD_LIBRARIES="bg_mon,pg_stat_statements,pgextwlist,pg_auth_mon,set_user,vector,vchord"