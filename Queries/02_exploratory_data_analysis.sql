/* ==============================================================================
PROJECT: Open University Learning Analytics (OULAD)
PHASE 2: Exploratory Data Analysis (EDA)

DESCRIPTION: 
This script profiles the data to understand its shape, identify the 
grain of the tables, quantify missing data, and establish baseline 
distributions for the student population. 

Doing this ensures there are no hidden data traps (like orphaned records or 
impossible outliers) that could skew the final retention and performance metrics.
============================================================================== */

-- ==========================================
-- 1. TABLE GRAIN & DUPLICATE PROFILING
-- ==========================================

-- Check the total row count to get a sense of scale
SELECT COUNT(*) AS total_student_rows
FROM studentinfo;

-- Find out if 'id_student' is truly unique, or if students take multiple courses
SELECT 
    id_student, 
    COUNT(*) as enrollment_count
FROM studentInfo
GROUP BY id_student
HAVING COUNT(*) > 1
ORDER BY enrollment_count DESC;


-- ==========================================
-- 2. MISSING DATA PROFILING (THE NULL HUNT)
-- ==========================================

-- Calculate the raw volume of course withdrawals vs. course retentions
-- Using the 'date_unregistration' column to bucket the students
SELECT 
    COUNT(*) as total_registrations,
    SUM(CASE WHEN date_unregistration IS NULL THEN 1 ELSE 0 END) as retained_students,
    SUM(CASE WHEN date_unregistration IS NOT NULL THEN 1 ELSE 0 END) as withdrawn_students
FROM studentRegistration;

-- Check for missing assessment scores
-- If a huge chunk of grades are missing, we can't trust the final averages
SELECT 
    COUNT(*) as total_submissions,
    SUM(CASE WHEN score IS NULL THEN 1 ELSE 0 END) as missing_scores
FROM studentAssessment;


-- ==========================================
-- 3. ESTABLISHING BASELINE METRICS
-- ==========================================

-- Get the baseline distribution of final outcomes (Pass, Fail, Withdrawn, etc.)
-- This gives us the overall university average to compare against later
SELECT 
    final_result, 
    COUNT(*) as student_count,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM studentInfo)), 2) as percentage_of_total
FROM studentInfo
GROUP BY final_result
ORDER BY student_count DESC;

-- Check the distribution of prior education levels
-- Ensures we have large enough cohort sizes to do demographic comparisons
SELECT 
    highest_education, 
    COUNT(*) as student_count,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM studentInfo)), 2) as percentage_of_total
FROM studentInfo
GROUP BY highest_education
ORDER BY student_count DESC;


-- ==========================================
-- 4. OUTLIERS & REFERENTIAL INTEGRITY
-- ==========================================

-- Check for extreme outliers in the virtual learning engagement (VLE) data
-- Making sure there are no negative clicks or bizarre system glitches
SELECT 
    MIN(sum_click) as minimum_clicks,
    MAX(sum_click) as maximum_clicks,
    AVG(sum_click) as average_clicks
FROM studentVle;

-- Perform an anti-join to check for "orphaned" assessment records
-- Are there assessment scores for students who don't exist in our demographic table?
SELECT 
    COUNT(DISTINCT sa.id_student) as orphaned_students
FROM studentAssessment sa
LEFT JOIN studentInfo si 
    ON sa.id_student = si.id_student
WHERE si.id_student IS NULL;