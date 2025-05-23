
# Spilo PostgreSQL 17 with pgvector & VectorChord

This repository builds a Spilo 17 Docker image bundled with the `pgvector` and `VectorChord` extensions for PostgreSQL 17, suitable for use with the Zalando Postgres Operator.

- **Base:** `registry.opensource.zalan.do/acid/spilo-17:2.2-p3`
- **Extensions:** `pgvector`, `vectorchord`, `contrib`, `snowball`

## Usage

Pushes to `main` will build and publish `ghcr.io/theepicsaxguy/spilo-pgvector-vectorchord:latest` (and version tags).

### To use with Zalando Postgres Operator:

```yaml
spec:
  dockerImage: ghcr.io/theepicsaxguy/spilo-pgvector-vectorchord:latest
  postgresql:
    version: "17"
    parameters:
      shared_preload_libraries: "vchord,pgextwlist"
````

## Build Locally

```sh
docker build -t ghcr.io/theepicsaxguy/spilo-pgvector-vectorchord:latest .
```