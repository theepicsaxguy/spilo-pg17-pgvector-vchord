# Spilo PostgreSQL 17 with pgvector & VectorChord

A PostgreSQL 17 Docker image based on [Zalando Spilo](https://github.com/zalando/spilo) with VectorChord extension added for vector similarity search.

## What's Included

- **Base:** `ghcr.io/zalando/spilo-17:4.0-p2` 
- **Extensions:**
  - `pgvector` (pre-installed in Spilo)
  - `vchord` (VectorChord - added by this image)
- **Architecture:** `linux/amd64` and `linux/arm64`

## Quick Start

```bash
docker run -d --name postgres-vector \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 \
  ghcr.io/theepicsaxguy/spilo-pg17-pgvector-vchord:latest
```

Test the extensions:

```sql
-- Connect and create extensions
CREATE EXTENSION pgvector;
CREATE EXTENSION vchord;

-- Test vector operations
CREATE TABLE test_vectors (id serial, embedding vector(3));
INSERT INTO test_vectors (embedding) VALUES ('[1,2,3]'), ('[4,5,6]');
SELECT * FROM test_vectors ORDER BY embedding <-> '[1,2,3]' LIMIT 1;
```

## Zalando Postgres Operator

```yaml
apiVersion: acid.zalan.do/v1
kind: postgresql
metadata:
  name: vector-db
spec:
  teamId: myteam
  volume:
    size: 10Gi
  numberOfInstances: 1
  dockerImage: ghcr.io/theepicsaxguy/spilo-pg17-pgvector-vchord:latest
  
  users:
    app: 
      - superuser
      - createdb
      
  databases:
    vectordb: app
    
  preparedDatabases:
    vectordb:
      extensions:
        pgvector: public
        vchord: public
        
  postgresql:
    version: "17"
    parameters:
      shared_preload_libraries: "bg_mon,pg_stat_statements,pgextwlist,pg_auth_mon,set_user,vchord"
```

## Usage

### Basic Vector Search

```sql
CREATE EXTENSION pgvector;
CREATE EXTENSION vchord;

-- Create table
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    content TEXT,
    embedding vector(384)
);

-- Create VectorChord index
CREATE INDEX ON documents USING vchord (embedding vector_cosine_ops);

-- Search similar documents
SELECT id, content 
FROM documents 
ORDER BY embedding <=> $1 
LIMIT 10;
```

### Performance Notes

- **VectorChord** is faster than pgvector's indexes for large datasets
- **pgvector** provides the vector data type that VectorChord uses
- Use VectorChord indexes (`vchord`) instead of `ivfflat` or `hnsw` for better performance

## Migrating from pgvector to VectorChord

If you're already using pgvector indexes:

```sql
-- Drop old indexes
DROP INDEX IF EXISTS old_ivfflat_index;

-- Create VectorChord index
CREATE INDEX new_vchord_index ON your_table USING vchord (embedding vector_cosine_ops);
```

## License

MIT License