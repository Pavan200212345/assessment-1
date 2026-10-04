"""
Production-Grade Todo Application Server
Handles database operations and serves HTTP requests
"""

from flask import Flask, jsonify, request, render_template_string, send_from_directory
import psycopg2
from psycopg2.extras import RealDictCursor
import os
import logging
from datetime import datetime
import socket

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__, static_folder='.', static_url_path='')

# Database configuration
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = os.getenv('DB_PORT', '5432')
DB_NAME = os.getenv('DB_NAME', 'tododb')
DB_USER = os.getenv('DB_USER', 'postgres')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'password')
SERVER_NAME = os.getenv('SERVER_NAME', socket.gethostname())

# Database connection string
DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"


def get_db_connection():
    """Create a database connection"""
    try:
        conn = psycopg2.connect(DATABASE_URL)
        return conn
    except psycopg2.OperationalError as e:
        logger.error(f"Database connection failed: {e}")
        return None


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    conn = get_db_connection()
    db_status = 'connected' if conn else 'disconnected'
    if conn:
        conn.close()
    
    return jsonify({
        "status": "healthy",
        "server": SERVER_NAME,
        "database": db_status,
        "timestamp": datetime.now().isoformat()
    }), 200


@app.route('/', methods=['GET'])
def home():
    """Serve the HTML UI"""
    try:
        with open('index.html', 'r') as f:
            return f.read()
    except FileNotFoundError:
        return jsonify({
            "message": "Todo Application Server Running",
            "server": SERVER_NAME,
            "version": "1.0.0",
            "endpoints": {
                "GET /health": "Health check",
                "GET /todos": "Get all todos",
                "POST /todos": "Create new todo",
                "GET /todos/<id>": "Get specific todo",
                "PUT /todos/<id>": "Update todo",
                "DELETE /todos/<id>": "Delete todo"
            }
        }), 200


@app.route('/todos', methods=['GET'])
def get_todos():
    """Get all todos"""
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 503
        
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        cursor.execute("SELECT id, title, description, completed, created_at FROM todos ORDER BY created_at DESC")
        todos = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify({
            "todos": [dict(todo) for todo in todos],
            "count": len(todos),
            "server": SERVER_NAME
        }), 200
    
    except Exception as e:
        logger.error(f"Error fetching todos: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/todos', methods=['POST'])
def create_todo():
    """Create a new todo"""
    try:
        data = request.get_json()
        
        if not data or 'title' not in data:
            return jsonify({"error": "Title is required"}), 400
        
        title = data.get('title')
        description = data.get('description', '')
        
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 503
        
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        cursor.execute(
            "INSERT INTO todos (title, description, completed) VALUES (%s, %s, %s) RETURNING id, title, description, completed, created_at",
            (title, description, False)
        )
        new_todo = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()
        
        logger.info(f"Todo created: {new_todo['id']} on server {SERVER_NAME}")
        
        return jsonify({
            "todo": dict(new_todo),
            "server": SERVER_NAME
        }), 201
    
    except Exception as e:
        logger.error(f"Error creating todo: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/todos/<int:todo_id>', methods=['GET'])
def get_todo(todo_id):
    """Get a specific todo"""
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 503
        
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        cursor.execute("SELECT id, title, description, completed, created_at FROM todos WHERE id = %s", (todo_id,))
        todo = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if not todo:
            return jsonify({"error": "Todo not found"}), 404
        
        return jsonify({
            "todo": dict(todo),
            "server": SERVER_NAME
        }), 200
    
    except Exception as e:
        logger.error(f"Error fetching todo {todo_id}: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/todos/<int:todo_id>', methods=['PUT'])
def update_todo(todo_id):
    """Update a todo"""
    try:
        data = request.get_json()
        
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 503
        
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Build dynamic update query
        update_fields = []
        update_values = []
        
        if 'title' in data:
            update_fields.append("title = %s")
            update_values.append(data['title'])
        
        if 'description' in data:
            update_fields.append("description = %s")
            update_values.append(data['description'])
        
        if 'completed' in data:
            update_fields.append("completed = %s")
            update_values.append(data['completed'])
        
        if not update_fields:
            return jsonify({"error": "No fields to update"}), 400
        
        update_values.append(todo_id)
        query = f"UPDATE todos SET {', '.join(update_fields)} WHERE id = %s RETURNING id, title, description, completed, created_at"
        
        cursor.execute(query, update_values)
        updated_todo = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()
        
        if not updated_todo:
            return jsonify({"error": "Todo not found"}), 404
        
        logger.info(f"Todo updated: {todo_id} on server {SERVER_NAME}")
        
        return jsonify({
            "todo": dict(updated_todo),
            "server": SERVER_NAME
        }), 200
    
    except Exception as e:
        logger.error(f"Error updating todo {todo_id}: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/todos/<int:todo_id>', methods=['DELETE'])
def delete_todo(todo_id):
    """Delete a todo"""
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 503
        
        cursor = conn.cursor()
        cursor.execute("DELETE FROM todos WHERE id = %s", (todo_id,))
        conn.commit()
        rows_deleted = cursor.rowcount
        cursor.close()
        conn.close()
        
        if rows_deleted == 0:
            return jsonify({"error": "Todo not found"}), 404
        
        logger.info(f"Todo deleted: {todo_id} on server {SERVER_NAME}")
        
        return jsonify({
            "message": f"Todo {todo_id} deleted",
            "server": SERVER_NAME
        }), 200
    
    except Exception as e:
        logger.error(f"Error deleting todo {todo_id}: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/stats', methods=['GET'])
def get_stats():
    """Get application statistics"""
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 503
        
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) as total, SUM(CASE WHEN completed THEN 1 ELSE 0 END) as completed FROM todos")
        stats = cursor.fetchone()
        cursor.close()
        conn.close()
        
        return jsonify({
            "total_todos": stats[0],
            "completed_todos": stats[1] or 0,
            "pending_todos": (stats[0] or 0) - (stats[1] or 0),
            "server": SERVER_NAME
        }), 200
    
    except Exception as e:
        logger.error(f"Error fetching stats: {e}")
        return jsonify({"error": str(e)}), 500


@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Endpoint not found"}), 404


@app.errorhandler(500)
def internal_error(e):
    return jsonify({"error": "Internal server error"}), 500


if __name__ == '__main__':
    logger.info(f"Starting server: {SERVER_NAME}")
    logger.info(f"Database: {DB_HOST}:{DB_PORT}/{DB_NAME}")
    app.run(host='0.0.0.0', port=5000, debug=False)
