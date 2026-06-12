-- queries.sql — SQL Analytics Lab
-- Module 3: SQL & Relational Data
--
-- Instructions:
--   Write your SQL query beneath each comment block.
--   Do NOT modify the comment markers (-- Q1, -- Q2, etc.) — the autograder uses them.
--   Test each query locally: psql -h localhost -U postgres -d testdb -f queries.sql
--
-- ============================================================

-- Q1: Employee Directory with Departments
-- List all employees with their department name, sorted by department (asc) then salary (desc).
-- Expected columns: first_name, last_name, title, salary, department_name
-- SQL concepts: JOIN, ORDER BY
SELECT 
    e.name, 
    e.title, 
    e.salary, 
    d.name AS department_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
ORDER BY d.name ASC, e.salary DESC;


-- Q2: Department Salary Analysis
-- Total salary expenditure by department. Only departments with total > 150,000.
-- Expected columns: department_name, total_salary
-- SQL concepts: GROUP BY, HAVING, SUM
SELECT d.name AS department_name, SUM(e.salary) AS total_salary
FROM departments d
JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.name
HAVING SUM(e.salary) > 150000;

-- Q3: Highest-Paid Employee per Department
-- For each department, find the employee with the highest salary.
-- Expected columns: department_name, first_name, last_name, salary
-- SQL concepts: Window function (ROW_NUMBER or RANK), CTE
SELECT department_name, name, salary
FROM (
    SELECT d.name AS department_name, 
           e.name, 
           e.salary,
           RANK() OVER (PARTITION BY e.dept_id ORDER BY e.salary DESC) as salary_rank
    FROM employees e
    JOIN departments d ON e.dept_id = d.dept_id
) AS ranked_staff
WHERE salary_rank = 1;


-- Q4: Project Staffing Overview
-- All projects with employee count and total hours. Include projects with 0 assignments.
-- Expected columns: project_name, employee_count, total_hours
-- SQL concepts: LEFT JOIN, GROUP BY, COALESCE
SELECT 
    p.name AS project_name, 
    COUNT(pa.emp_id) AS employee_count, -- تعديل اسم العمود هنا
    COALESCE(SUM(pa.hours_allocated), 0) AS total_hours
FROM projects p
LEFT JOIN project_assignments pa ON p.project_id = pa.project_id
GROUP BY p.project_id, p.name
ORDER BY total_hours DESC;


-- Q5: Above-Average Departments
-- Departments where average salary exceeds the company-wide average salary.
-- Expected columns: department_name, avg_salary
-- SQL concepts: CTE
WITH CompanyAvg AS (
    SELECT AVG(salary) AS global_avg FROM employees
),
DeptAvg AS (
    SELECT d.name AS department_name, AVG(e.salary) AS dept_avg
    FROM departments d
    JOIN employees e ON d.dept_id = e.dept_id
    GROUP BY d.name
)
SELECT 
    da.department_name, 
    ROUND(da.dept_avg, 2) AS department_average, 
    ROUND(ca.global_avg, 2) AS company_average
FROM DeptAvg da, CompanyAvg ca
WHERE da.dept_avg > ca.global_avg;


-- Q6: Running Salary Total
-- Each employee's salary and running total within their department, ordered by hire date.
-- Expected columns: department_name, first_name, last_name, hire_date, salary, running_total
-- SQL concepts: Window function (SUM OVER)
SELECT 
    d.name AS department_name, 
    e.name, 
    e.hire_date, 
    e.salary,
    SUM(e.salary) OVER (
        PARTITION BY e.dept_id 
        ORDER BY e.hire_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
ORDER BY d.name, e.hire_date;


-- Q7: Unassigned Employees
-- Employees not assigned to any project.
-- Expected columns: first_name, last_name, department_name
-- SQL concepts: LEFT JOIN + NULL check (or NOT EXISTS)
SELECT 
    e.name AS employee_name, 
    d.name AS department_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
LEFT JOIN project_assignments pa ON e.emp_id = pa.emp_id
WHERE pa.project_id IS NULL
ORDER BY d.name, e.name;


-- Q8: Hiring Trends
-- Month-over-month hire count.
-- Expected columns: hire_year, hire_month, hires
-- SQL concepts: EXTRACT, GROUP BY, ORDER BY
SELECT 
    EXTRACT(YEAR FROM hire_date) AS hire_year, 
    EXTRACT(MONTH FROM hire_date) AS hire_month, 
    COUNT(emp_id) AS hires
FROM employees
GROUP BY hire_year, hire_month
ORDER BY hire_year DESC, hire_month DESC;


-- Q9: Schema Design — Employee Certifications
-- Design and implement a certifications tracking system.
--
-- Tasks:
-- 1. CREATE TABLE certifications (certification_id SERIAL PK, name VARCHAR NOT NULL, issuing_org VARCHAR, level VARCHAR)
-- 2. CREATE TABLE employee_certifications (id SERIAL PK, employee_id FK->employees, certification_id FK->certifications, certification_date DATE NOT NULL)
-- 3. INSERT at least 3 certifications and 5 employee_certification records
-- 4. Write a query listing employees with their certifications (JOIN across 3 tables)
--    Expected columns: first_name, last_name, certification_name, issuing_org, certification_date
SELECT 
    e.name AS employee_name, 
    c.name AS certification_name, 
    c.issuing_org, 
    ec.certification_date
FROM employees e
JOIN employee_certifications ec ON e.emp_id = ec.emp_id
JOIN certifications c ON ec.cert_id = c.cert_id
ORDER BY ec.certification_date DESC;

--Tier 1 — Complex Analytics Queries

-- 1. Identify "at-risk" projects (Allocated hours > 80% of project budget)
SELECT 
    p.name AS project_name, 
    p.budget AS total_capacity,
    SUM(pa.hours_allocated) AS total_hours_allocated,
    ROUND((SUM(pa.hours_allocated)::numeric / p.budget) * 100, 2) AS usage_percentage
FROM projects p
JOIN project_assignments pa ON p.project_id = pa.project_id
GROUP BY p.project_id, p.name, p.budget
HAVING (SUM(pa.hours_allocated)::numeric / p.budget) > 0.8;

-- 2. Cross-department analysis
SELECT 
    e.name AS employee_name, 
    e.dept_id AS emp_dept, 
    p.name, 
    p.dept_id AS project_dept
FROM employees e
JOIN project_assignments pa ON e.emp_id = pa.emp_id
JOIN projects p ON pa.project_id = p.project_id
WHERE e.dept_id != p.dept_id;


--Tier 2 — Dynamic Reporting with Views and Functions
CREATE OR REPLACE VIEW department_summary AS
SELECT 
    d.name AS department,
    COUNT(e.emp_id) AS employee_count,
    SUM(e.salary) AS total_payroll
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.name;

-- 2. Materialized View (Project Status)

CREATE MATERIALIZED VIEW project_status_view AS
SELECT 
    p.name AS project_name,
    p.budget,
    COUNT(pa.emp_id) AS staff_count,
    SUM(pa.hours_allocated) AS total_hours
FROM projects p
LEFT JOIN project_assignments pa ON p.project_id = pa.project_id
GROUP BY p.project_id, p.name, p.budget;

-- 3. Advanced Function (Returns JSON)
CREATE OR REPLACE FUNCTION get_dept_stats_json(dept_name_input VARCHAR)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'employee_count', COUNT(DISTINCT e.emp_id),
        'total_salary', COALESCE(SUM(e.salary), 0),
        'active_projects', COUNT(DISTINCT pa.project_id)
    ) INTO result
    FROM departments d
    LEFT JOIN employees e ON d.dept_id = e.dept_id
    LEFT JOIN project_assignments pa ON e.emp_id = pa.emp_id
    WHERE d.name = dept_name_input;

    RETURN result;
END;
$$ LANGUAGE plpgsql;


-- ==========================================
-- Testing Tier 2 Components
-- ==========================================

-- 1. Test Standard View
SELECT * FROM department_summary;

-- 2. Test Materialized View
SELECT * FROM project_status_view;

-- 3. Test JSON Function (Engineering Department)
SELECT get_dept_stats_json('Engineering');

-- 4. Test JSON Function (Sales Department)
SELECT get_dept_stats_json('Sales');


-- Tier 3 — Schema Evolution and Migration
-- 1. Create salary_history table
CREATE TABLE IF NOT EXISTS salary_history (
    history_id SERIAL PRIMARY KEY,
    emp_id INTEGER REFERENCES employees(emp_id),
    old_salary DECIMAL(12, 2),
    new_salary DECIMAL(12, 2),
    change_date DATE NOT NULL,
    change_reason VARCHAR(255)
);

-- 2. Seed with realistic historical data (records for some employees)
INSERT INTO salary_history (emp_id, old_salary, new_salary, change_date, change_reason)
VALUES 
(1, 110000.00, 120000.00, '2024-01-10', 'Annual Promotion'),
(1, 100000.00, 110000.00, '2023-01-10', 'Performance Review'),
(2, 90000.00, 98000.00, '2024-02-14', 'Market Adjustment'),
(3, 85000.00, 95000.00, '2023-05-15', 'Senior Role Promotion');

-- Migration Script: Populate from existing employees table
INSERT INTO salary_history (emp_id, old_salary, new_salary, change_date, change_reason)
SELECT 
    emp_id, 
    0,
    salary, 
    CURRENT_DATE, 
    'Initial migration from employees table'
FROM employees
ON CONFLICT DO NOTHING;

-- A. Salary growth rate by department over time
SELECT 
    d.name AS department,
    AVG((sh.new_salary - sh.old_salary) / NULLIF(sh.old_salary, 0) * 100) AS avg_growth_rate
FROM salary_history sh
JOIN employees e ON sh.emp_id = e.emp_id
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.name;

-- B. Employees due for salary review (No change in 12+ months)
SELECT 
    e.name, 
    MAX(sh.change_date) AS last_review_date
FROM employees e
JOIN salary_history sh ON e.emp_id = sh.emp_id
GROUP BY e.emp_id, e.name
HAVING MAX(sh.change_date) < CURRENT_DATE - INTERVAL '12 months';
