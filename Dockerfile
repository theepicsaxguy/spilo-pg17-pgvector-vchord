FROM ghcr.io/zalando/spilo-17:4.0-p2

USER root

# Add PostgreSQL PGDG repo and install pgvector and vchord
RUN apt-get update && \
    apt-get install -y --no-install-recommends wget ca-certificates gnupg lsb-release && \
    echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      postgresql-17-pgvector && \
    wget -O /tmp/vchord.deb https://github.com/tensorchord/VectorChord/releases/download/0.3.0/postgresql-17-vchord_0.3.0-1_amd64.deb && \
    dpkg -i /tmp/vchord.deb && \
    rm /tmp/vchord.deb && \
    rm -rf /var/lib/apt/lists/*

USER 101