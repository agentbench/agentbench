-- Schema for company.db
-- Tables: employees, departments, sales
-- This file describes the schema. The actual database is created by setup.sh.

CREATE TABLE departments (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    location TEXT NOT NULL
);

CREATE TABLE employees (
    id INTEGER PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    department_id INTEGER REFERENCES departments(id),
    salary REAL NOT NULL,
    hire_date TEXT NOT NULL  -- YYYY-MM-DD format
);

CREATE TABLE sales (
    id INTEGER PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    amount REAL NOT NULL,
    sale_date TEXT NOT NULL,  -- YYYY-MM-DD format
    product TEXT NOT NULL
);
