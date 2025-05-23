-- Test script to verify pgvector and vchord extensions work properly
-- This script will be run during CI/CD to ensure both extensions are functional

\echo 'Testing PostgreSQL Vector Extensions...'

-- Enable extensions
\echo 'Creating extensions...'
CREATE EXTENSION IF NOT EXISTS pgvector;
CREATE EXTENSION IF NOT EXISTS vchord;

-- Verify extensions are installed
\echo 'Verifying extensions are installed...'
SELECT extname, extversion, extrelocatable 
FROM pg_extension 
WHERE extname IN ('pgvector', 'vchord')
ORDER BY extname;

-- Test pgvector functionality
\echo 'Testing pgvector functionality...'

-- Create test table with vector column
CREATE TABLE pgvector_test (
    id SERIAL PRIMARY KEY,
    name TEXT,
    embedding vector(3)
);

-- Insert test data
INSERT INTO pgvector_test (name, embedding) VALUES 
    ('vector_1', '[1.0, 2.0, 3.0]'),
    ('vector_2', '[4.0, 5.0, 6.0]'),
    ('vector_3', '[7.0, 8.0, 9.0]'),
    ('vector_4', '[1.5, 2.5, 3.5]');

-- Test L2 distance (euclidean)
\echo 'Testing L2 distance...'
SELECT name, embedding, embedding <-> '[1.0, 2.0, 3.0]' AS l2_distance
FROM pgvector_test
ORDER BY embedding <-> '[1.0, 2.0, 3.0]'
LIMIT 3;

-- Test cosine distance
\echo 'Testing cosine distance...'
SELECT name, embedding, embedding <=> '[1.0, 2.0, 3.0]' AS cosine_distance
FROM pgvector_test
ORDER BY embedding <=> '[1.0, 2.0, 3.0]'
LIMIT 3;

-- Test inner product
\echo 'Testing inner product...'
SELECT name, embedding, embedding <#> '[1.0, 2.0, 3.0]' AS inner_product
FROM pgvector_test
ORDER BY embedding <#> '[1.0, 2.0, 3.0]' DESC
LIMIT 3;

-- Test VectorChord functionality
\echo 'Testing VectorChord functionality...'

-- Create VectorChord index
CREATE INDEX pgvector_test_vchord_l2_idx ON pgvector_test USING vchord (embedding vector_l2_ops);
CREATE INDEX pgvector_test_vchord_cosine_idx ON pgvector_test USING vchord (embedding vector_cosine_ops);

-- Verify indexes were created
\echo 'Verifying VectorChord indexes...'
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes 
WHERE tablename = 'pgvector_test' AND indexname LIKE '%vchord%';

-- Test query with VectorChord index
\echo 'Testing query performance with VectorChord index...'
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT name, embedding
FROM pgvector_test
ORDER BY embedding <-> '[1.0, 2.0, 3.0]'
LIMIT 2;

-- Test with larger dataset to verify index performance
\echo 'Creating larger test dataset...'
CREATE TABLE large_vector_test (
    id SERIAL PRIMARY KEY,
    embedding vector(128)
);

-- Insert random vectors
INSERT INTO large_vector_test (embedding)
SELECT array_to_string(
    array(SELECT (random() * 2 - 1)::text FROM generate_series(1, 128)), 
    ','
)::vector(128)
FROM generate_series(1, 1000);

-- Create VectorChord index on larger dataset
CREATE INDEX large_vector_test_vchord_idx ON large_vector_test USING vchord (embedding vector_l2_ops);

-- Test query on larger dataset
\echo 'Testing VectorChord performance on larger dataset...'
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT id 
FROM large_vector_test 
ORDER BY embedding <-> (SELECT embedding FROM large_vector_test LIMIT 1)
LIMIT 10;

-- Test vector operations combinations
\echo 'Testing combined vector operations...'
CREATE TABLE mixed_test (
    id SERIAL PRIMARY KEY,
    category TEXT,
    vec_small vector(3),
    vec_large vector(512)
);

INSERT INTO mixed_test (category, vec_small, vec_large) VALUES
    ('A', '[1,2,3]', array_to_string(array(SELECT random()::text FROM generate_series(1,512)), ',')::vector(512)),
    ('B', '[4,5,6]', array_to_string(array(SELECT random()::text FROM generate_series(1,512)), ',')::vector(512)),
    ('C', '[7,8,9]', array_to_string(array(SELECT random()::text FROM generate_series(1,512)), ',')::vector(512));

-- Create multiple indexes
CREATE INDEX mixed_test_small_vchord ON mixed_test USING vchord (vec_small vector_cosine_ops);
CREATE INDEX mixed_test_large_vchord ON mixed_test USING vchord (vec_large vector_l2_ops);

-- Test multi-column vector queries
\echo 'Testing multi-column vector queries...'
SELECT category, 
       vec_small <=> '[1,2,3]' as small_similarity,
       vec_large <-> array_to_string(array(SELECT 0.5::text FROM generate_series(1,512)), ',')::vector(512) as large_distance
FROM mixed_test
ORDER BY vec_small <=> '[1,2,3]';

-- Verify all extensions and their versions
\echo 'Final verification - all extensions:'
SELECT 
    e.extname,
    e.extversion,
    n.nspname as schema,
    e.extrelocatable,
    e.extowner::regrole as owner
FROM pg_extension e
JOIN pg_namespace n ON e.extnamespace = n.oid
WHERE e.extname IN ('pgvector', 'vchord')
ORDER BY e.extname;

-- Show available vector operators
\echo 'Available vector operators:'
SELECT 
    oprname,
    oprleft::regtype,
    oprright::regtype,
    oprresult::regtype,
    oprcode
FROM pg_operator 
WHERE oprname IN ('<->', '<=>', '<#>')
ORDER BY oprname, oprleft;

\echo 'All tests completed successfully!'

-- Cleanup test tables
DROP TABLE IF EXISTS pgvector_test CASCADE;
DROP TABLE IF EXISTS large_vector_test CASCADE;
DROP TABLE IF EXISTS mixed_test CASCADE;