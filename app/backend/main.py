from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import psycopg
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(
    title="Employee Management API",
    description="Backend API for Employee Management System",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# -----------------------------
# Employee model
# -----------------------------

class Employee(BaseModel):
    name: str
    email: str
    role: str
    department: str


# -----------------------------
# PostgreSQL connection
# -----------------------------

def get_connection():
    return psycopg.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )


# -----------------------------
# Root
# -----------------------------

@app.get("/")
def root():
    return {
        "message": "Employee Management API is running"
    }


# -----------------------------
# Health check
# -----------------------------

@app.get("/api/health")
def health_check():
    return {
        "status": "healthy"
    }


# -----------------------------
# Database test
# -----------------------------

@app.get("/api/db-test")
def database_test():

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT version();")
    result = cursor.fetchone()

    cursor.close()
    conn.close()

    return {
        "database": "connected",
        "version": result[0]
    }


# -----------------------------
# GET all employees
# -----------------------------

@app.get("/api/employees")
def get_employees():

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT id, name, email, role, department, created_at
        FROM employees
        ORDER BY id;
    """)

    employees = cursor.fetchall()

    cursor.close()
    conn.close()

    return [
        {
            "id": employee[0],
            "name": employee[1],
            "email": employee[2],
            "role": employee[3],
            "department": employee[4],
            "created_at": employee[5]
        }
        for employee in employees
    ]


# -----------------------------
# POST - create employee
# -----------------------------

@app.post("/api/employees")
def create_employee(employee: Employee):

    conn = get_connection()
    cursor = conn.cursor()

    try:

        cursor.execute("""
            INSERT INTO employees (name, email, role, department)
            VALUES (%s, %s, %s, %s)
            RETURNING id, name, email, role, department, created_at;
        """, (
            employee.name,
            employee.email,
            employee.role,
            employee.department
        ))

        new_employee = cursor.fetchone()

        conn.commit()

        return {
            "id": new_employee[0],
            "name": new_employee[1],
            "email": new_employee[2],
            "role": new_employee[3],
            "department": new_employee[4],
            "created_at": new_employee[5]
        }

    except psycopg.errors.UniqueViolation:

        conn.rollback()

        raise HTTPException(
            status_code=400,
            detail="Email already exists"
        )

    finally:

        cursor.close()
        conn.close()


# -----------------------------
# PUT - update employee
# -----------------------------

@app.put("/api/employees/{employee_id}")
def update_employee(employee_id: int, employee: Employee):

    conn = get_connection()
    cursor = conn.cursor()

    try:

        cursor.execute("""
            UPDATE employees
            SET
                name = %s,
                email = %s,
                role = %s,
                department = %s
            WHERE id = %s
            RETURNING id, name, email, role, department, created_at;
        """, (
            employee.name,
            employee.email,
            employee.role,
            employee.department,
            employee_id
        ))

        updated_employee = cursor.fetchone()

        if updated_employee is None:

            conn.rollback()

            raise HTTPException(
                status_code=404,
                detail="Employee not found"
            )

        conn.commit()

        return {
            "id": updated_employee[0],
            "name": updated_employee[1],
            "email": updated_employee[2],
            "role": updated_employee[3],
            "department": updated_employee[4],
            "created_at": updated_employee[5]
        }

    except psycopg.errors.UniqueViolation:

        conn.rollback()

        raise HTTPException(
            status_code=400,
            detail="Email already exists"
        )

    finally:

        cursor.close()
        conn.close()


# -----------------------------
# DELETE - delete employee
# -----------------------------

@app.delete("/api/employees/{employee_id}")
def delete_employee(employee_id: int):

    conn = get_connection()
    cursor = conn.cursor()

    try:

        cursor.execute("""
            DELETE FROM employees
            WHERE id = %s
            RETURNING id;
        """, (employee_id,))

        deleted_employee = cursor.fetchone()

        if deleted_employee is None:

            conn.rollback()

            raise HTTPException(
                status_code=404,
                detail="Employee not found"
            )

        conn.commit()

        return {
            "message": "Employee deleted successfully",
            "id": deleted_employee[0]
        }

    finally:

        cursor.close()
        conn.close()