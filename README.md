# Open University Student Retention & Performance Analysis

## 📌 Executive Summary
This project analyzes the Open University Learning Analytics Dataset (OULAD) using PostgreSQL to uncover the underlying drivers of student retention, demographic performance gaps, and the impact of virtual engagement. By engineering a relational database and querying over 10 million rows of behavioral logs alongside academic records, this analysis provides actionable, data-driven insights to help educational stakeholders identify at-risk students and standardize curriculum difficulty.

## 🛠️ Tech Stack & Skills Highlighted
* **Relational Database:** PostgreSQL (v18.3), pgAdmin 4
* **Query Language:** SQL
* **Techniques:** Common Table Expressions (CTEs), Window Functions (`NTILE`, `PARTITION BY`), Conditional Aggregations (`CASE WHEN`), Multi-table `JOIN`s, Data Type Casting.

---

## 🔍 Core Business Insights

### 1. The Behavioral Cliff (Digital Engagement as a Leading Indicator)
There is a massive, quantifiable drop-off in digital engagement between passing and failing cohorts. 
* Students who **Pass** interact with the virtual portal an average of **1,922 times**. 
* Students who **Fail** average only **688 interactions**. 
* **Business Value:** Students who eventually withdraw average a dismal floor of **445 clicks**. This establishes digital interaction rates as a highly viable leading indicator, allowing the university to trigger automated intervention emails for low-engagement students weeks before they actually fail an exam.

### 2. Grading Discrepancies & "Weed-Out" Courses
Using Window Functions to isolate the Top 10% of students per module revealed severe inconsistencies in grading curves across the university.
* **Module AAA** is graded on a strict, balanced curve: a score of **81.80** places a student in the elite Top 10%.
* **Module CCC** is highly polarizing. It has the highest withdrawal rate in the university (~46%), yet the surviving cohort scores exceptionally high, requiring a massive **92.50** just to break into the Top 10%. This indicates a severe skill-bifurcation in the curriculum that needs departmental review.

### 3. Demographic Performance Gaps
There is a strict, linear correlation between a student's prior education level and their final academic performance. Average assessment scores step down sequentially from Post Graduate (83.49) to No Formal Qualifications (70.60). This establishes `highest_education` as a statistically significant feature for any future predictive modeling regarding student success.

---

## 🏗️ Data Architecture & Engineering Challenges
The database was locally architected using 7 interconnected tables. Working with raw, uncleaned Kaggle data presented several real-world data ingestion challenges:

* **Handling Nulls & Strict Constraints:** The raw CSV data contained thousands of empty text strings (`""`) in numeric columns (such as dates and scores). To prevent PostgreSQL `COPY` import failures, tables were dynamically rebuilt using `VARCHAR(20)` to successfully ingest the dirty data. `UPDATE` and `ALTER TABLE` scripts were then executed to cast empty strings to true SQL `NULL` values, restoring mathematical `INT`/`FLOAT` integrity for analysis.
* **Primary Key Workarounds:** During the import of demographic data, strict `PRIMARY KEY` constraints flagged false duplicates (e.g., a single student enrolling in multiple semesters). Constraints were temporarily dropped to allow full ingestion, relying on composite grouping (`id_student`, `code_module`, `code_presentation`) downstream to maintain the correct table grain.
* **Referential Integrity Validation:** Executed `LEFT JOIN` anti-join patterns between the transactional assessment table and demographic dimension table, verifying 0 orphaned records prior to executing the core analysis.

---

## 📂 Repository Structure
* `01_database_setup_and_cleaning.sql`: The DDL/ETL script detailing table creation and data type casting.
* `02_exploratory_data_analysis.sql`: Queries validating table grain, missing data volume, and categorical baselines.
* `03_core_business_analysis.sql`: The primary analytical script containing CTEs and Window Functions.
* `/results/`: Folder containing the exported CSV data outputs for the four core business questions.