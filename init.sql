-- Create todos table for the application
CREATE TABLE IF NOT EXISTS todos (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_todos_completed ON todos(completed);
CREATE INDEX IF NOT EXISTS idx_todos_created_at ON todos(created_at DESC);

-- Sample data (optional)
-- INSERT INTO todos (title, description, completed) VALUES 
-- ('Learn Docker', 'Complete Docker tutorial', FALSE),
-- ('Setup PostgreSQL', 'Install and configure PostgreSQL', TRUE),
-- ('Deploy to Production', 'Deploy application to servers', FALSE);
