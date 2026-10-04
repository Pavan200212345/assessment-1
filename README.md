# Todo Application - Project Structure & Setup Guide

## Project Files Created

```
project/
├── app.py                 # Main Flask application with all routes
├── requirements.txt       # Python dependencies
├── Dockerfile            # Docker image configuration
├── docker-compose.yml    # Multi-container orchestration
├── nginx.conf           # Nginx load balancer config
├── init.sql             # Database schema and initialization
└── README.md            # This file
```

## Project Components

### 1. **app.py** - Flask Application
- ✅ Health check endpoint (`/health`)
- ✅ Todo CRUD operations (Create, Read, Update, Delete)
- ✅ Stats endpoint (`/stats`)
- ✅ Database connection handling
- ✅ Error handling and logging
- ✅ Server identification (tracks which server served the request)

**Key Routes:**
- `GET /` - Home endpoint
- `GET /health` - Health check with DB status
- `GET /todos` - List all todos
- `POST /todos` - Create new todo
- `GET /todos/<id>` - Get specific todo
- `PUT /todos/<id>` - Update todo
- `DELETE /todos/<id>` - Delete todo
- `GET /stats` - Get statistics

### 2. **requirements.txt** - Dependencies
- Flask 2.3.3
- psycopg2-binary (PostgreSQL driver)
- gunicorn (production WSGI server)
- python-dotenv (environment variables)

### 3. **Dockerfile** - Container Image
- Python 3.9 slim base image
- Includes PostgreSQL client for troubleshooting
- Health check configured
- Uses Gunicorn (4 workers) for production
- Optimized for performance

### 4. **docker-compose.yml** - Full Stack Orchestration
- PostgreSQL database container
- App Server 1 (port 5001 → 5000 internal)
- App Server 2 (port 5002 → 5000 internal)
- Nginx load balancer (port 80)
- Automatic startup and health checks
- Volume for code hot-reload
- All containers in same network

### 5. **nginx.conf** - Load Balancer
- Least connections load balancing algorithm
- Health checks (3 failures = 30s timeout)
- Connection pooling & keep-alive
- Proper header forwarding
- Security (denies access to dot files)
- Gzip compression ready

### 6. **init.sql** - Database Schema
- Creates `todos` table with proper types
- Indexes for performance
- Timestamps for tracking
- Ready for sample data

---

## Quick Start - Local Development

### Prerequisites
- Docker & Docker Compose installed
- Git (optional, for version control)

### Step 1: Clone/Download Project Files
```bash
mkdir todo-app
cd todo-app
# Place all files in this directory
```

### Step 2: Build and Start
```bash
# Build Docker image and start all services
docker-compose up --build

# Or run in background
docker-compose up -d --build
```

### Step 3: Verify Services
```bash
# Check all containers running
docker-compose ps

# View logs
docker-compose logs -f

# Check database
docker-compose exec db psql -U postgres -d tododb -c "SELECT * FROM todos;"
```

### Step 4: Test the Application
```bash
# Health check
curl http://localhost/health

# Get todos (should be empty initially)
curl http://localhost/todos

# Create a todo
curl -X POST http://localhost/todos \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Learn Docker",
    "description": "Complete Docker tutorial"
  }'

# Get all todos
curl http://localhost/todos

# Get statistics
curl http://localhost/stats

# Update a todo (ID 1)
curl -X PUT http://localhost/todos/1 \
  -H "Content-Type: application/json" \
  -d '{"completed": true}'

# Delete a todo
curl -X DELETE http://localhost/todos/1
```

---

## Load Balancing Test

### Test Which Server Handled Request
```bash
# Make multiple requests and check which server responded
for i in {1..10}; do
  echo "Request $i:"
  curl http://localhost/health | jq '.server'
done
```

You should see alternating "Server-1" and "Server-2" responses.

### Test Server Resilience
```bash
# Stop one server
docker-compose stop app-server-1

# Make requests - should still work via Server-2
curl http://localhost/todos

# Start it back
docker-compose start app-server-1
```

---

## Production Deployment (On Two Separate VMs)

### On Each VM:

**1. Copy Project Files**
```bash
mkdir -p ~/app
cd ~/app
# Copy all files (app.py, requirements.txt, Dockerfile, etc.)
```

**2. Build Image (Optional - can use pre-built)**
```bash
docker build -t python-app:latest .
```

**3. Run Single Server (not docker-compose)**
```bash
# Server 1
docker run -d \
  --name web-app \
  -p 8000:5000 \
  -v ~/app/app.py:/usr/src/app/app.py \
  -e DB_HOST=<database-server-ip> \
  -e DB_PORT=5432 \
  -e DB_NAME=tododb \
  -e DB_USER=postgres \
  -e DB_PASSWORD=<secure-password> \
  -e SERVER_NAME="Server-1" \
  --restart always \
  python-app:latest
```

**4. Setup Nginx Load Balancer (Separate VM)**
```bash
# Copy nginx.conf to /etc/nginx/nginx.conf
# Start nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| DB_HOST | localhost | Database server IP/hostname |
| DB_PORT | 5432 | PostgreSQL port |
| DB_NAME | tododb | Database name |
| DB_USER | postgres | Database user |
| DB_PASSWORD | password | Database password |
| SERVER_NAME | hostname | Server identifier |

---

## Monitoring & Logs

```bash
# View app logs
docker-compose logs app-server-1 -f

# View nginx logs
docker-compose logs nginx -f

# View database logs
docker-compose logs db -f

# View all logs
docker-compose logs -f
```

---

## Troubleshooting

### Connection Refused
```bash
# Check if services are running
docker-compose ps

# Check network connectivity
docker-compose exec app-server-1 ping app-server-2
docker-compose exec app-server-1 psql -U postgres -h db -d tododb -c "SELECT 1"
```

### Database Not Initialized
```bash
# Reinitialize database
docker-compose down -v  # Remove volumes
docker-compose up --build
```

### Load Balancer Not Working
```bash
# Check nginx config
docker-compose exec nginx nginx -t

# Check upstream servers
docker-compose exec nginx curl http://app-server-1:5000/health
docker-compose exec nginx curl http://app-server-2:5000/health
```

---

## Next Steps

1. ✅ Build project (done)
2. Test locally with docker-compose
3. Deploy to production (2 VMs + 1 DB server)
4. Setup monitoring (optional)
5. Configure CI/CD pipeline (optional)

---

## API Examples

### Create Todo
```bash
curl -X POST http://localhost/todos \
  -H "Content-Type: application/json" \
  -d '{
    "title": "My Task",
    "description": "Task description"
  }'
```

### Response
```json
{
  "todo": {
    "id": 1,
    "title": "My Task",
    "description": "Task description",
    "completed": false,
    "created_at": "2024-01-01T12:00:00"
  },
  "server": "Server-1"
}
```

### Get All Todos
```bash
curl http://localhost/todos
```

### Get Stats
```bash
curl http://localhost/stats
```

```json
{
  "total_todos": 5,
  "completed_todos": 2,
  "pending_todos": 3,
  "server": "Server-1"
}
```

---

## Support

For issues or questions, check logs:
```bash
docker-compose logs [service-name]
```
