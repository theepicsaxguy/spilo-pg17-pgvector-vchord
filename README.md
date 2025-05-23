# Spilo PostgreSQL 17 with pgvector & VectorChord

[![Build Status](https://github.com/theepicsaxguy/spilo-pg17-pgvector-vchord/workflows/Build%20and%20Push%20Docker%20Image/badge.svg)](https://github.com/theepicsaxguy/spilo-pg17-pgvector-vchord/actions)
[![Docker Pulls](https://img.shields.io/docker/pulls/theepicsaxguy/spilo-pgvector-vectorchord)](https://github.com/theepicsaxguy/spilo-pg17-pgvector-vchord/pkgs/container/spilo-pg17-pgvector-vchord)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A production-ready PostgreSQL 17 Docker image built on [Spilo](https://github.com/zalando/spilo) with **pgvector** and **VectorChord** extensions pre-installed and ready to use.

## 🎯 Core Features

This image provides **both pgvector and VectorChord** extensions, fully tested and ready for vector similarity search:

- ✅ **pgvector** - Industry standard vector similarity search
- ✅ **VectorChord** - High-performance vector indexing 
- ✅ **Multi-architecture** - Supports both AMD64 and ARM64
- ✅ **Production Ready** - Built on battle-tested Spilo
- ✅ **Kubernetes Native** - Works with Postgres operators

## 🐳 Quick Start

### Verify Extensions Work

```bash
# Start the container
docker run -d --name vector-db \
  -e POSTGRES_PASSWORD=mypassword \
  -p 5432:5432 \
  ghcr.io/theepicsaxguy/spilo-pg17-pgvector-vchord:latest

# Test both extensions
psql -h localhost -U postgres -c "
  CREATE EXTENSION pgvector;
  CREATE EXTENSION vchord;
  
  -- Create test table
  CREATE TABLE vectors (id serial, embedding vector(3));
  INSERT INTO vectors (embedding) VALUES ('[1,2,3]'), ('[4,5,6]');
  
  -- Test similarity search
  SELECT * FROM vectors ORDER BY embedding <-> '[1,2,3]' LIMIT 1;
  
  -- Create VectorChord index
  CREATE INDEX ON vectors USING vchord (embedding vector_l2_ops);
"
```

### For Development

```bash
git clone https://github.com/theepicsaxguy/spilo-pg17-pgvector-vchord.git
cd spilo-pg17-pgvector-vchord
docker-compose up -d  # Includes pgAdmin and monitoring
```

## 🚀 Production Usage

### Zalando Postgres Operator

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: vector-database
spec:
  instances: 3
  dockerImage: ghcr.io/theepicsaxguy/spilo-pg17-pgvector-vchord:latest
  
  postgresql:
    version: "17"
    parameters:
      shared_preload_libraries: "vchord"  # Enable VectorChord
      max_connections: "200"
      shared_buffers: "256MB"
      
  bootstrap:
    initdb:
      postInitSQL:
        - "CREATE EXTENSION IF NOT EXISTS pgvector;"
        - "CREATE EXTENSION IF NOT EXISTS vchord;"
```

### CloudNativePG

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: vector-cluster
spec:
  instances: 3
  imageName: ghcr.io/theepicsaxguy/spilo-pg17-pgvector-vchord:latest
  
  bootstrap:
    initdb:
      postInitSQL:
        - "CREATE EXTENSION pgvector;"
        - "CREATE EXTENSION vchord;"
```

## 📚 Extension Usage Examples

### Basic Vector Operations

```sql
-- Enable both extensions
CREATE EXTENSION pgvector;
CREATE EXTENSION vchord;

-- Create table with vector column
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    title TEXT,
    embedding vector(384)  -- 384-dimensional vectors
);

-- Insert sample data
INSERT INTO documents (title, embedding) VALUES # Spilo PostgreSQL 17 with pgvector & VectorChord

[![Build Status](https://github.com/theepicsaxguy/spilo-pg17-pgvector-vchord/workflows/Build%20and%20Push%20Docker%20Image/badge.svg)](https://github.com/theepicsaxguy/spilo-pg17-pgvector-vchord/actions)
[![Docker Pulls](https://img.shields.io/docker/pulls/theepicsaxguy/spilo-pgvector-vectorchord)](https://github.com/theepicsaxguy/spilo-pg17-pgvector-vchord/pkgs/container/spilo-pg17-pgvector-vchord)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A production-ready PostgreSQL 17 Docker image built on [Spilo](https://github.com/zalando/spilo) with vector similarity search capabilities, optimized for use with the Zalando Postgres Operator and other Kubernetes PostgreSQL operators.

## Features

- **Base:** `ghcr.io/zalando/spilo-17:4.0-p2` - Battle-tested PostgreSQL for Kubernetes
- **Extensions:**
  - [`pgvector`](https://github.com/pgvector/pgvector) - Vector similarity search with HNSW and IVFFlat indexes
  - [`VectorChord`](https://github.com/tensorchord/VectorChord) - High-performance vector search engine
  - Standard PostgreSQL contrib modules
- **Multi-architecture:** Supports both `linux/amd64` and `linux/arm64`
- **Security:** Regular vulnerability scanning and security updates
- **Monitoring:** Built-in health checks and metrics support

## Quick Start

### Using Docker Compose (Recommended for Development)

```bash
# Clone the repository
git clone https://github.com/theepicsaxguy/spilo-pg17-pgvector-vchord.git
cd spilo-pg17-pgvector-vchord

# Start the stack (PostgreSQL + pgAdmin + Monitoring)
docker-compose up -d

# Connect to the database
psql -h localhost -U postgres -d vectordb
```

### Using Docker Run

```bash
docker run -d --name vector-db \
  -e POSTGRES_PASSWORD=mypassword \
  -e POSTGRES_DB=vectordb \
  -p 5432:5432 \
  ghcr.io/theepicsaxguy/spilo-pg17-pgvector-vchord:latest
```

### Kubernetes with Zalando Postgres Operator

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: vector-database
  namespace: default
spec:
  instances: 3
  dockerImage: ghcr.io/theepicsaxguy/spilo-pg17-pgvector-vchord:latest
  
  postgresql:
    version: "17"
    parameters:
      # Essential for vector extensions
      shared_preload_libraries: "vchord,pgextwlist"
      
      # Performance tuning for vector workloads
      max_connections: "200"
      shared_buffers: "256MB"
      effective_cache_size: "1GB"
      maintenance_work_mem: "64MB"
      
      # Vector-specific optimizations
      max_parallel_workers_per_gather: "2"
      max_parallel_workers: "4"
      
  storage:
    size: "10Gi"
    storageClass: "fast-ssd"
    
  monitoring:
    enabled: true
    customQueries:
      - name: "vector_stats"
        query: |
          SELECT 
            schemaname,
            tablename,
            indexname,
            idx_scan,
            idx_tup_read,
            idx_tup_fetch
          FROM pg_stat_user_indexes 
          WHERE indexname LIKE '%vector%' OR indexname LIKE '%vchord%'
```

### Cloud Native PostgreSQL (CNPG) Operator

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: vector-cluster
spec:
  instances: 3
  imageName: ghcr.io/theepicsaxguy/spilo-pg17-pgvector-vchord:latest
  
  postgresql:
    parameters:
      shared_preload_libraries: "vchord"
      max_connections: "100"
      shared_buffers: "128MB"
      
  bootstrap:
    initdb:
      database: vectordb
      owner: app
      secret:
        name: vector-db-credentials
      postInitSQL:
        - "CREATE EXTENSION IF NOT EXISTS pgvector;"
        - "CREATE EXTENSION IF NOT EXISTS vchord;"
        
  storage:
    size: 20Gi
    storageClass: premium-ssd
```

## Usage Examples

### Basic Vector Operations

```sql
-- Enable extensions
CREATE EXTENSION IF NOT EXISTS pgvector;
CREATE EXTENSION IF NOT EXISTS vchord;

-- Create a table with vector column
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    title TEXT,
    content TEXT,
    embedding vector(384)  -- 384-dimensional vectors
);

-- Insert sample data
INSERT INTO documents (title, content, embedding) VALUES 
    ('AI Tutorial', 'Learn about artificial intelligence', '[0.1, 0.2, 0.3, ...]'),
    ('ML Guide', 'Machine learning fundamentals', '[0.4, 0.5, 0.6, ...]');

-- Create indexes for fast similarity search
CREATE INDEX ON documents USING vchord (embedding vector_cosine_ops);

-- Find similar documents using cosine similarity
SELECT title, embedding <=> '[0.1, 0.2, 0.3, ...]' AS distance
FROM documents
ORDER BY embedding <=> '[0.1, 0.2, 0.3, ...]'
LIMIT 5;
```

### Advanced Similarity Search Function

```sql
CREATE OR REPLACE FUNCTION find_similar_documents(
    query_vector vector(384),
    similarity_threshold float DEFAULT 0.7,
    max_results int DEFAULT 10
) RETURNS TABLE(
    doc_id int,
    title text,
    similarity_score float
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id,
        d.title,
        1 - (d.embedding <=> query_vector) as similarity_score
    FROM documents d
    WHERE 1 - (d.embedding <=> query_vector) > similarity_threshold
    ORDER BY d.embedding <=> query_vector
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql;

-- Usage
SELECT * FROM find_similar_documents('[0.1, 0.2, 0.3, ...]'::vector(384), 0.8, 5);
```

## Performance Optimization

### Recommended PostgreSQL Settings

For vector-heavy workloads, consider these configuration parameters:

```yaml
postgresql:
  parameters:
    # Memory settings
    shared_buffers: "25% of RAM"
    effective_cache_size: "75% of RAM"
    work_mem: "4MB"
    maintenance_work_mem: "2GB"
    
    # Parallel processing
    max_parallel_workers_per_gather: "4"
    max_parallel_workers: "8"
    max_parallel_maintenance_workers: "4"
    
    # Vector-specific
    max_connections: "200"
    random_page_cost: "1.1"
    
    # For VectorChord
    shared_preload_libraries: "vchord"
```

### Index Strategies

| Use Case | Index Type | Best For |
|----------|------------|----------|
| Small datasets (<100K vectors) | `ivfflat` | General purpose |
| Large datasets (>100K vectors) | `vchord` | High performance |
| Exact similarity | `vchord` | Precision critical |
| Approximate similarity | `ivfflat` | Speed over precision |

```sql
-- For small to medium datasets
CREATE INDEX idx_embedding_ivf ON documents USING ivfflat (embedding vector_cosine_ops);

-- For large datasets (recommended)
CREATE INDEX idx_embedding_vchord ON documents USING vchord (embedding vector_cosine_ops);
```

## Monitoring & Observability

### Health Checks

The image includes built-in health checks:

```bash
# Manual health check
docker exec <container_name> pg_isready -U postgres

# Kubernetes health check configuration
livenessProbe:
  exec:
    command: ["pg_isready", "-U", "postgres"]
  initialDelaySeconds: 30
  periodSeconds: 10
```

### Metrics Collection

Monitor vector-specific metrics:

```sql
-- Vector index usage statistics  
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read
FROM pg_stat_user_indexes 
WHERE indexname LIKE '%vector%' OR indexname LIKE '%vchord%';

-- Table sizes with vector columns
SELECT 
    tablename,
    pg_size_pretty(