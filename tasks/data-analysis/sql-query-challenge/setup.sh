#!/usr/bin/env bash
set -euo pipefail
WS="$1"
DB="$WS/company.db"

sqlite3 "$DB" <<'SQL'
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
    hire_date TEXT NOT NULL
);
CREATE TABLE sales (
    id INTEGER PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    amount REAL NOT NULL,
    sale_date TEXT NOT NULL,
    product TEXT NOT NULL
);

INSERT INTO departments VALUES (1, 'Engineering', 'San Francisco');
INSERT INTO departments VALUES (2, 'Sales', 'New York');
INSERT INTO departments VALUES (3, 'Marketing', 'Chicago');
INSERT INTO departments VALUES (4, 'HR', 'Boston');

INSERT INTO employees VALUES (1, 'Alice', 'Johnson', 1, 125000, '2022-03-15');
INSERT INTO employees VALUES (2, 'Bob', 'Smith', 1, 115000, '2023-01-10');
INSERT INTO employees VALUES (3, 'Carol', 'Williams', 2, 95000, '2021-06-20');
INSERT INTO employees VALUES (4, 'David', 'Brown', 2, 88000, '2023-04-01');
INSERT INTO employees VALUES (5, 'Eve', 'Davis', 3, 92000, '2022-09-12');
INSERT INTO employees VALUES (6, 'Frank', 'Miller', 3, 85000, '2023-07-22');
INSERT INTO employees VALUES (7, 'Grace', 'Wilson', 4, 78000, '2023-11-05');
INSERT INTO employees VALUES (8, 'Hank', 'Moore', 1, 130000, '2020-02-14');
INSERT INTO employees VALUES (9, 'Ivy', 'Taylor', 2, 91000, '2022-08-30');
INSERT INTO employees VALUES (10, 'Jack', 'Anderson', 4, 82000, '2021-12-01');
INSERT INTO employees VALUES (11, 'Karen', 'Thomas', 1, 118000, '2023-03-18');
INSERT INTO employees VALUES (12, 'Leo', 'Jackson', 2, 97000, '2023-09-25');
INSERT INTO employees VALUES (13, 'Mia', 'White', 3, 89000, '2022-05-07');
INSERT INTO employees VALUES (14, 'Noah', 'Harris', 1, 122000, '2021-01-20');
INSERT INTO employees VALUES (15, 'Olivia', 'Martin', 2, 93000, '2020-11-15');

-- Sales data: Q1 2024 total should be 127350.00
-- Carol Williams should be top performer
INSERT INTO sales VALUES (1, 3, 15000.00, '2024-01-05', 'Enterprise License');
INSERT INTO sales VALUES (2, 4, 8500.00, '2024-01-12', 'Starter Plan');
INSERT INTO sales VALUES (3, 9, 12000.00, '2024-01-20', 'Pro License');
INSERT INTO sales VALUES (4, 3, 22000.00, '2024-02-03', 'Enterprise License');
INSERT INTO sales VALUES (5, 15, 9500.00, '2024-02-14', 'Pro License');
INSERT INTO sales VALUES (6, 12, 7800.00, '2024-02-22', 'Starter Plan');
INSERT INTO sales VALUES (7, 3, 18000.00, '2024-03-01', 'Enterprise License');
INSERT INTO sales VALUES (8, 4, 11500.00, '2024-03-10', 'Pro License');
INSERT INTO sales VALUES (9, 9, 6050.00, '2024-03-15', 'Starter Plan');
INSERT INTO sales VALUES (10, 15, 17000.00, '2024-03-28', 'Enterprise License');
INSERT INTO sales VALUES (11, 3, 14000.00, '2024-04-05', 'Pro License');
INSERT INTO sales VALUES (12, 12, 9200.00, '2024-04-12', 'Starter Plan');
INSERT INTO sales VALUES (13, 4, 13000.00, '2024-04-20', 'Enterprise License');
INSERT INTO sales VALUES (14, 9, 8800.00, '2024-05-01', 'Pro License');
INSERT INTO sales VALUES (15, 3, 21000.00, '2024-05-15', 'Enterprise License');
INSERT INTO sales VALUES (16, 15, 7500.00, '2024-06-01', 'Starter Plan');
INSERT INTO sales VALUES (17, 12, 16000.00, '2024-06-20', 'Enterprise License');
INSERT INTO sales VALUES (18, 4, 5500.00, '2024-07-05', 'Starter Plan');
INSERT INTO sales VALUES (19, 3, 19500.00, '2024-08-10', 'Enterprise License');
INSERT INTO sales VALUES (20, 9, 11000.00, '2024-09-15', 'Pro License');
SQL
