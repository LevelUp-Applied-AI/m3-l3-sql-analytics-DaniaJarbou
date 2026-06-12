-- schema.sql — Levant Tech Solutions Database Schema
-- Module 3: SQL Analytics Lab
--
-- Run this file first to create all tables.
-- Usage: psql -h localhost -U postgres -d testdb -f schema.sql

DROP TABLE IF EXISTS project_assignments CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

-- ============================================================
-- Table: departments
-- ============================================================
CREATE TABLE departments (
    dept_id      SERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL UNIQUE,
    location     VARCHAR(100) NOT NULL,
    budget       NUMERIC(12,2) DEFAULT 0 
);

-- ============================================================
-- Table: employees
-- ============================================================
CREATE TABLE employees (
    emp_id       SERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    email        VARCHAR(150),
    title        VARCHAR(100) NOT NULL,
    salary       NUMERIC(10,2) NOT NULL CHECK (salary > 0),
    hire_date    DATE NOT NULL,
    dept_id      INTEGER NOT NULL REFERENCES departments(dept_id)
   
    
);
-- ============================================================
-- Table: projects
-- ============================================================
CREATE TABLE projects (
    project_id   SERIAL PRIMARY KEY,
    name         VARCHAR(150) NOT NULL,
    dept_id      INTEGER REFERENCES departments(dept_id), -- ربط المشروع بالقسم مطلوب في Q4/Q5
    start_date   DATE NOT NULL,
    end_date     DATE,
    budget       NUMERIC(12,2) NOT NULL CHECK (budget >= 0)
);

-- ============================================================
-- Table: project_assignments
-- ============================================================
CREATE TABLE project_assignments (
    assignment_id   SERIAL PRIMARY KEY,
    emp_id          INTEGER NOT NULL REFERENCES employees(emp_id),
    project_id      INTEGER NOT NULL REFERENCES projects(project_id),
    hours_allocated INTEGER NOT NULL CHECK (hours_allocated > 0),
    role            VARCHAR(100) NOT NULL
);
-- ============================================================
-- Table: certificationss
-- ============================================================
CREATE TABLE IF NOT EXISTS certifications (
    cert_id      SERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    issuing_org  VARCHAR(100),
    level        VARCHAR(50) 
);
-- ============================================================
-- Table: employee_certifications
-- ============================================================
CREATE TABLE IF NOT EXISTS employee_certifications (
    id                 SERIAL PRIMARY KEY,
    emp_id             INTEGER REFERENCES employees(emp_id),
    cert_id            INTEGER REFERENCES certifications(cert_id),
    certification_date DATE NOT NULL
);