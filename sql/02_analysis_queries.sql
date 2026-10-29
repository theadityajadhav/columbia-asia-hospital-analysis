-- Columbia Asia Hospital Analysis
-- Step 2: analysis queries
-- Aditya Jadhav
-- All queries use the view vw_hospital_full created in 01_setup.sql

USE columbia_asia;

-- 1. Top 5 doctors by revenue among doctors with fewer patients than average
-- Dr. Smith has 65% of all patients, so plain top 5 by revenue would only show busy doctors.
-- So I keep doctors with below average patients and take the top 5 by revenue.
SELECT doctor_id, doctor_name,
       COUNT(*)        AS total_patients,
       SUM(total_bill) AS total_revenue
FROM vw_hospital_full
GROUP BY doctor_id, doctor_name
HAVING COUNT(*) < (SELECT AVG(c) FROM (SELECT COUNT(*) AS c FROM vw_hospital_full GROUP BY doctor_id) t)
ORDER BY total_revenue DESC, doctor_id
LIMIT 5;

-- 2. Departments where average wait time fell 3 months in a row
-- First average wait per department per month, then LAG() to see the earlier months.
-- Small departments have few visits per month, so their averages jump around a lot.
WITH monthly AS (
  SELECT department_referral AS department, visit_month,
         ROUND(AVG(patient_waittime), 2) AS avg_wait
  FROM vw_hospital_full
  GROUP BY department_referral, visit_month
),
earlier AS (
  SELECT department, visit_month, avg_wait,
         LAG(avg_wait, 1) OVER (PARTITION BY department ORDER BY visit_month) AS prev_1,
         LAG(avg_wait, 2) OVER (PARTITION BY department ORDER BY visit_month) AS prev_2,
         LAG(avg_wait, 3) OVER (PARTITION BY department ORDER BY visit_month) AS prev_3
  FROM monthly
)
SELECT department, visit_month AS third_drop_month,
       prev_3, prev_2, prev_1, avg_wait
FROM earlier
WHERE avg_wait < prev_1 AND prev_1 < prev_2 AND prev_2 < prev_3
ORDER BY department, visit_month;

-- 3. Male to female patient ratio for each doctor, ranked
-- Ratio = male patients / female patients. NC patients are not counted.
-- If a doctor has no female patients the ratio is NULL and ranks last.
WITH ratios AS (
  SELECT doctor_id, doctor_name,
         SUM(patient_gender = 'M') AS male_patients,
         SUM(patient_gender = 'F') AS female_patients,
         SUM(patient_gender = 'M') / NULLIF(SUM(patient_gender = 'F'), 0) AS ratio
  FROM vw_hospital_full
  GROUP BY doctor_id, doctor_name
)
SELECT doctor_id, doctor_name, male_patients, female_patients,
       ROUND(ratio, 2) AS male_to_female_ratio,
       RANK() OVER (ORDER BY ratio DESC) AS ratio_rank
FROM ratios
ORDER BY ratio_rank, doctor_id;

-- 4. Average satisfaction score for each doctor
-- AVG() skips blank scores by itself. I also show how many scores each average uses,
-- because only about 27% of patients gave a score.
SELECT doctor_id, doctor_name,
       COUNT(*)                         AS total_patients,
       COUNT(patient_sat_score)         AS patients_with_score,
       ROUND(AVG(patient_sat_score), 2) AS avg_satisfaction
FROM vw_hospital_full
GROUP BY doctor_id, doctor_name
ORDER BY avg_satisfaction DESC, doctor_id;

-- 5. Races treated by each doctor and how diverse their patients are
-- Diversity score = 1 - sum of (share of each race squared).
-- It goes from 0 to 1, higher means a more mixed patient base.
-- 'Declined to Identify' is counted as its own group.
WITH race_counts AS (
  SELECT doctor_id, doctor_name, patient_race,
         COUNT(*) AS n,
         SUM(COUNT(*)) OVER (PARTITION BY doctor_id) AS doctor_total
  FROM vw_hospital_full
  GROUP BY doctor_id, doctor_name, patient_race
)
SELECT doctor_id, doctor_name,
       MAX(doctor_total) AS total_patients,
       COUNT(*)          AS different_races_treated,
       ROUND(1 - SUM(POW(n / doctor_total, 2)), 3) AS diversity_score
FROM race_counts
GROUP BY doctor_id, doctor_name
ORDER BY diversity_score DESC, doctor_id;

-- 6. Ratio of total bills, male to female patients, for each department
SELECT department_referral AS department,
       SUM(CASE WHEN patient_gender = 'M' THEN total_bill ELSE 0 END) AS male_total_bill,
       SUM(CASE WHEN patient_gender = 'F' THEN total_bill ELSE 0 END) AS female_total_bill,
       ROUND(SUM(CASE WHEN patient_gender = 'M' THEN total_bill ELSE 0 END)
           / NULLIF(SUM(CASE WHEN patient_gender = 'F' THEN total_bill ELSE 0 END), 0), 2) AS male_to_female_ratio
FROM vw_hospital_full
GROUP BY department_referral
ORDER BY male_to_female_ratio DESC, department;

-- 7. What-if: add 2 to the satisfaction score of General Practice patients who waited over 30 minutes
-- Score can not go above 10. This changes data, so I run it on a copy table
-- and the original table stays safe. Blank scores stay blank.
-- Workbench safe update mode blocks this update, so I switch it off and on again after.
DROP TABLE IF EXISTS hospital_er_whatif;
CREATE TABLE hospital_er_whatif AS SELECT * FROM hospital_er;

-- before
SELECT COUNT(*) AS patients_to_update, ROUND(AVG(patient_sat_score), 2) AS avg_score_before
FROM hospital_er_whatif
WHERE department_referral = 'General Practice' AND patient_waittime > 30 AND patient_sat_score IS NOT NULL;

SET SQL_SAFE_UPDATES = 0;

UPDATE hospital_er_whatif
SET patient_sat_score = LEAST(patient_sat_score + 2, 10)
WHERE department_referral = 'General Practice'
  AND patient_waittime > 30
  AND patient_sat_score IS NOT NULL;

SET SQL_SAFE_UPDATES = 1;

-- after
SELECT COUNT(*) AS patients_updated, ROUND(AVG(patient_sat_score), 2) AS avg_score_after,
       MAX(patient_sat_score) AS highest_score
FROM hospital_er_whatif
WHERE department_referral = 'General Practice' AND patient_waittime > 30 AND patient_sat_score IS NOT NULL;

-- original table is not changed
SELECT ROUND(AVG(patient_sat_score), 4) AS original_table_avg_score FROM hospital_er;
