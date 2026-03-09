/* ==============================================================================
PROJECT: Open University Learning Analytics (OULAD)
PHASE 1: Database Setup & Data Cleaning

DESCRIPTION: 
This script sets up the tables for the OULAD dataset. 

THE CHALLENGE & WORKAROUND:
While importing the raw CSV files, PostgreSQL kept throwing syntax errors. 
The issue was that several numeric columns contained empty text strings 
instead of NULLs, which violates strict INT/FLOAT rules during a standard import.

To solve this without losing data, I temporarily set the problematic columns 
to VARCHAR to safely bring the data into the database. Afterward, I ran a 
cleaning script to convert those empty strings into SQL NULLs and cast the 
columns back to their original data types for analysis.

I also intentionally left the PRIMARY KEY off the `studentInfo` table because 
the dataset tracks students enrolling in multiple courses, meaning their ID 
appears multiple times and would violate a strict primary key constraint.
============================================================================== */

-- ==========================================
-- STEP 1: CREATE TABLES (WITH IMPORT WORKAROUNDS)
-- ==========================================

-- 1. Create the courses table
CREATE TABLE courses (
    code_module VARCHAR(45),
    code_presentation VARCHAR(45),
    module_presentation_length INT,
    PRIMARY KEY (code_module, code_presentation)
);

-- 2. Create the assessments table 
-- Note: 'date' set to VARCHAR temporarily to handle blank strings in the CSV
CREATE TABLE assessments (
    code_module VARCHAR(45),
    code_presentation VARCHAR(45),
    id_assessment INT PRIMARY KEY,
    assessment_type VARCHAR(45),
    date VARCHAR(20), 
    weight FLOAT
);

-- 3. Create the vle table 
-- Note: 'week_from' and 'week_to' set to VARCHAR temporarily
CREATE TABLE vle (
    id_site INT PRIMARY KEY,
    code_module VARCHAR(45),
    code_presentation VARCHAR(45),
    activity_type VARCHAR(45),
    week_from VARCHAR(20),
    week_to VARCHAR(20)
);

-- 4. Create the studentInfo table 
-- Note: Primary Key omitted here to prevent errors from valid duplicate student IDs
CREATE TABLE studentInfo (
    code_module VARCHAR(45),
    code_presentation VARCHAR(45),
    id_student INT,
    gender VARCHAR(3),
    region VARCHAR(45),
    highest_education VARCHAR(45),
    imd_band VARCHAR(16),
    age_band VARCHAR(16),
    num_of_prev_attempts INT,
    studied_credits INT,
    disability VARCHAR(3),
    final_result VARCHAR(45)
);

-- 5. Create the studentRegistration table 
-- Note: Registration dates set to VARCHAR temporarily
CREATE TABLE studentRegistration (
    code_module VARCHAR(45),
    code_presentation VARCHAR(45),
    id_student INT,
    date_registration VARCHAR(20),
    date_unregistration VARCHAR(20)
);

-- 6. Create the studentAssessment table 
-- Note: 'score' set to VARCHAR temporarily
CREATE TABLE studentAssessment (
    id_assessment INT,
    id_student INT,
    date_submitted INT,
    is_banked SMALLINT,
    score VARCHAR(10) 
);

-- 7. Create the studentVle table
CREATE TABLE studentVle (
    code_module VARCHAR(45),
    code_presentation VARCHAR(45),
    id_student INT,
    id_site INT,
    date INT,
    sum_click INT
);

/* ==============================================================================
   * RAW CSV DATA WAS IMPORTED HERE VIA PGADMIN.
============================================================================== */

-- ==========================================
-- STEP 2: CLEANING & RESTORING DATA TYPES
-- ==========================================
/*
Now that the data is safely loaded, these updates convert the empty strings
into true SQL NULLs. This allows us to cast the columns back to integers and 
floats so we can perform aggregations in the analysis phase.
*/

-- 1. Clean and cast the assessments table
UPDATE assessments 
SET date = NULL 
WHERE date = '';

ALTER TABLE assessments 
ALTER COLUMN date TYPE INT 
USING date::integer;

-- 2. Clean and cast the studentAssessment table
UPDATE studentassessment 
SET score = NULL 
WHERE score = '';

ALTER TABLE studentassessment 
ALTER COLUMN score TYPE FLOAT 
USING score::double precision;

-- 3. Clean and cast the studentRegistration table
UPDATE studentregistration 
SET date_registration = NULL WHERE date_registration = '';

UPDATE studentregistration 
SET date_unregistration = NULL WHERE date_unregistration = '';

ALTER TABLE studentregistration 
ALTER COLUMN date_registration TYPE INT USING date_registration::integer;

ALTER TABLE studentregistration 
ALTER COLUMN date_unregistration TYPE INT USING date_unregistration::integer;

-- 4. Clean and cast the vle table
UPDATE vle SET week_from = NULL WHERE week_from = '';
UPDATE vle SET week_to = NULL WHERE week_to = '';

ALTER TABLE vle ALTER COLUMN week_from TYPE INT USING week_from::integer;
ALTER TABLE vle ALTER COLUMN week_to TYPE INT USING week_to::integer;