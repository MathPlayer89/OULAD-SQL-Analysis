/* ==============================================================================
PROJECT: Open University Learning Analytics (OULAD)
PHASE 3: Core Business Analysis

DESCRIPTION: 
With the data cleaned and baselines established, this script tackles the primary 
business questions. The goal here is to transform raw demographic, academic, 
and behavioral data into actionable insights. 

These queries utilize Common Table Expressions (CTEs), multi-table JOINs, 
conditional aggregations, and Window Functions to map out student attrition, 
demographic performance gaps, and the impact of virtual learning engagement.
============================================================================== */

-- =====================================================
-- QUESTION 1: Module and Semester Attrition Rates
-- =====================================================
/* I used conditional aggregation (SUM CASE WHEN) to effectively pivot the 
categorical 'final_result' string into distinct numeric columns. This allows us 
to calculate clean, readable percentage rates for success, failure, and 
withdrawal for every single course offering.
*/
SELECT 
    code_module,
    code_presentation,
    COUNT(id_student) AS total_enrollments,
    
    -- Calculate Success (Pass + Distinction) Count and Percentage
    SUM(CASE WHEN final_result IN ('Pass', 'Distinction') THEN 1 ELSE 0 END) AS success_count,
    ROUND((SUM(CASE WHEN final_result IN ('Pass', 'Distinction') THEN 1 ELSE 0 END) * 100.0) / COUNT(id_student), 2) AS success_rate_pct,
    
    -- Calculate Fail Count and Percentage
    SUM(CASE WHEN final_result = 'Fail' THEN 1 ELSE 0 END) AS fail_count,
    ROUND((SUM(CASE WHEN final_result = 'Fail' THEN 1 ELSE 0 END) * 100.0) / COUNT(id_student), 2) AS fail_rate_pct,
    
    -- Calculate Withdrawn Count and Percentage
    SUM(CASE WHEN final_result = 'Withdrawn' THEN 1 ELSE 0 END) AS withdrawn_count,
    ROUND((SUM(CASE WHEN final_result = 'Withdrawn' THEN 1 ELSE 0 END) * 100.0) / COUNT(id_student), 2) AS withdrawn_rate_pct

FROM studentInfo
GROUP BY 
    code_module,
    code_presentation
ORDER BY 
    code_module,
    code_presentation;


-- ==========================================
-- QUESTION 2: Demographic Performance Gaps
-- ==========================================
/* Here, I am joining the demographic dimension table (studentInfo) with the 
transactional fact table (studentAssessment) to see if a student's prior 
educational background acts as a statistical predictor for their final grades. 
I used COUNT(DISTINCT) to ensure students enrolled in multiple courses 
aren't double-counted in the demographic totals.
*/
SELECT 
    si.highest_education,
    COUNT(DISTINCT si.id_student) AS total_students,
    ROUND(CAST(AVG(sa.score) AS NUMERIC), 2) AS average_assessment_score
FROM studentinfo si
JOIN studentAssessment sa 
    ON si.id_student = sa.id_student
GROUP BY 
    si.highest_education
ORDER BY 
    average_assessment_score DESC;


-- ==========================================
-- QUESTION 3: The Digital Engagement Factor
-- ==========================================
/* The studentVle table contains over 10 million rows of click data. Instead of 
trying to join that massive table directly (which would destroy query performance), 
I used a Common Table Expression (CTE) to pre-aggregate the total clicks per 
student. This optimizes the query and prevents row duplication when joining 
the behavioral data back to the demographic outcomes.
*/
WITH StudentClicks AS (
    -- Step 1: Pre-aggregate the 10 million clicks down to a single total per student
    SELECT 
        id_student,
        code_module,
        code_presentation,
        SUM(sum_click) AS total_clicks
    FROM studentVle
    GROUP BY 
        id_student, code_module, code_presentation
)
-- Step 2: Join the aggregated behavioral data with the final academic results
SELECT 
    si.final_result,
    COUNT(si.id_student) AS number_of_students,
    ROUND(AVG(sc.total_clicks), 0) AS average_clicks_per_student
FROM studentInfo si
JOIN StudentClicks sc 
    ON si.id_student = sc.id_student 
    AND si.code_module = sc.code_module 
    AND si.code_presentation = sc.code_presentation
GROUP BY 
    si.final_result
ORDER BY 
    average_clicks_per_student DESC;


-- ==========================================
-- QUESTION 4: Ranking Academic Excellence
-- ==========================================
/* To determine if courses are graded on different curves, I needed to isolate the 
top 10% of students per module. I used a CTE combined with the NTILE(10) window 
function to chop the cohorts into strict performance deciles. This allowed me 
to filter for just 'Bucket 1' and calculate the exact minimum score threshold 
needed to achieve elite status in each specific class.
*/
WITH StudentAverages AS (
    -- Step 1: Calculate the overall average score for each student per module
    SELECT 
        si.code_module,
        si.id_student,
        ROUND(CAST(AVG(sa.score) AS NUMERIC), 2) AS overall_avg_score
    FROM studentInfo si
    JOIN studentAssessment sa 
        ON si.id_student = sa.id_student
    GROUP BY 
        si.code_module, 
        si.id_student
),
RankedCohorts AS (
    -- Step 2: Use NTILE window function to partition the students into 10 equal deciles based on score
    SELECT 
        code_module,
        id_student,
        overall_avg_score,
        NTILE(10) OVER(PARTITION BY code_module ORDER BY overall_avg_score DESC) AS performance_decile
    FROM StudentAverages
    WHERE overall_avg_score IS NOT NULL
)
-- Step 3: Filter for ONLY the Top 10% (Decile 1) to find the entry threshold
SELECT 
    code_module,
    COUNT(id_student) as top_10_percent_student_count,
    MIN(overall_avg_score) as minimum_score_to_enter_top_10,
    MAX(overall_avg_score) as highest_score_in_module
FROM RankedCohorts
WHERE performance_decile = 1
GROUP BY 
    code_module
ORDER BY 
    code_module;