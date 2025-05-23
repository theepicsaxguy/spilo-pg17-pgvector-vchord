-- scripts/01-init-extensions.sql
-- Initialize vector extensions and create sample data

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgvector;
CREATE EXTENSION IF NOT EXISTS vchord;

-- Create a sample table for vector similarity search
CREATE TABLE IF NOT EXISTS documents (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT,
    embedding vector(384), -- Common dimension for sentence transformers
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create another table for testing different vector dimensions
CREATE TABLE IF NOT EXISTS images (
    id SERIAL PRIMARY KEY,
    filename TEXT NOT NULL,
    description TEXT,
    feature_vector vector(512), -- Common for image embeddings
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data for testing
INSERT INTO documents (title, content, embedding) VALUES 
    ('PostgreSQL Tutorial', 'Learn PostgreSQL database fundamentals', '[0.1, 0.2, 0.3]'::vector),
    ('Vector Search Guide', 'Understanding vector similarity search', '[0.4, 0.5, 0.6]'::vector),
    ('Machine Learning Basics', 'Introduction to ML concepts', '[0.2, 0.3, 0.4]'::vector)
ON CONFLICT DO NOTHING;

-- Create indexes for performance
-- Traditional pgvector indexes
CREATE INDEX IF NOT EXISTS documents_embedding_idx ON documents USING ivfflat (embedding vector_cosine_ops);
CREATE INDEX IF NOT EXISTS images_feature_vector_idx ON images USING ivfflat (feature_vector vector_l2_ops);

-- VectorChord indexes (more efficient for larger datasets)
CREATE INDEX IF NOT EXISTS documents_vchord_idx ON documents USING vchord (embedding vector_cosine_ops);
CREATE INDEX IF NOT EXISTS images_vchord_idx ON images USING vchord (feature_vector vector_l2_ops);

-- Create a function for similarity search
CREATE OR REPLACE FUNCTION find_similar_documents(
    query_embedding vector(384),
    similarity_threshold float DEFAULT 0.5,
    max_results int DEFAULT 10
)
RETURNS TABLE(
    doc_id int,
    title text,
    content text,
    similarity float
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id,
        d.title,
        d.content,
        1 - (d.embedding <=> query_embedding) as similarity
    FROM documents d
    WHERE 1 - (d.embedding <=> query_embedding) > similarity_threshold
    ORDER BY d.embedding <=> query_embedding
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO postgres;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO postgres;