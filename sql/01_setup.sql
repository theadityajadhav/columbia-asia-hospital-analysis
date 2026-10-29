-- Columbia Asia Hospital Analysis
-- Step 1: create the database and load both CSV files
-- Aditya Jadhav

-- allow loading files from the local machine
SET GLOBAL local_infile = 1;

DROP DATABASE IF EXISTS columbia_asia;
CREATE DATABASE columbia_asia;
USE columbia_asia;

-- table for hospital_er.csv (one row per visit)
CREATE TABLE hospital_er (
  visit_datetime       DATETIME,
  patient_id           VARCHAR(20),
  patient_gender       VARCHAR(5),
  patient_age          INT,
  patient_sat_score    INT,
  patient_first_inital VARCHAR(5),
  patient_last_name    VARCHAR(60),
  patient_race         VARCHAR(60),
  patient_admin_flag   BOOLEAN,
  patient_waittime     INT,
  department_referral  VARCHAR(40)
);

-- table for doctor_patients.csv (doctor, fee and bill per patient)
CREATE TABLE doctor_patients (
  patient_id          VARCHAR(20),
  department_referral VARCHAR(40),
  doctor_name         VARCHAR(40),
  appointment_fees    INT,
  total_bill          INT,
  doctor_id           VARCHAR(10)
);

-- loading the files, change the two paths below to where your CSV files are
-- the date is text like 01-04-2019 01:13, so I convert it while loading
-- a blank satisfaction score becomes NULL, not 0
LOAD DATA LOCAL INFILE '/path/to/hospital_er.csv'
INTO TABLE hospital_er
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@date, patient_id, patient_gender, patient_age, @score, patient_first_inital,
 patient_last_name, patient_race, @flag, patient_waittime, @dept)
SET visit_datetime      = STR_TO_DATE(@date, '%d-%m-%Y %H:%i'),
    patient_sat_score   = NULLIF(@score, ''),
    patient_admin_flag  = (@flag = 'TRUE'),
    department_referral = TRIM(TRAILING '\r' FROM @dept);

LOAD DATA LOCAL INFILE '/path/to/doctor_patients.csv'
INTO TABLE doctor_patients
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(patient_id, department_referral, doctor_name, appointment_fees, total_bill, @doc)
SET doctor_id = TRIM(TRAILING '\r' FROM @doc);

-- check 1: row counts, all should be 9216
SELECT 'hospital_er' AS table_name, COUNT(*) AS total_rows FROM hospital_er
UNION ALL
SELECT 'doctor_patients', COUNT(*) FROM doctor_patients;

-- check 2: is every patient_id unique? both numbers should be 9216
SELECT 'hospital_er' AS table_name, COUNT(patient_id) AS all_ids, COUNT(DISTINCT patient_id) AS unique_ids FROM hospital_er
UNION ALL
SELECT 'doctor_patients', COUNT(patient_id), COUNT(DISTINCT patient_id) FROM doctor_patients;

-- ids are unique, so now I can add the primary key
ALTER TABLE hospital_er     ADD PRIMARY KEY (patient_id);
ALTER TABLE doctor_patients ADD PRIMARY KEY (patient_id);

-- one view that joins both tables, so I don't repeat the join in every query
CREATE VIEW vw_hospital_full AS
SELECT h.patient_id, h.visit_datetime,
       DATE(h.visit_datetime)                 AS visit_date,
       DATE_FORMAT(h.visit_datetime, '%Y-%m') AS visit_month,
       HOUR(h.visit_datetime)                 AS visit_hour,
       h.patient_gender, h.patient_age, h.patient_sat_score,
       h.patient_first_inital, h.patient_last_name, h.patient_race,
       h.patient_admin_flag, h.patient_waittime, h.department_referral,
       d.doctor_id, d.doctor_name, d.appointment_fees, d.total_bill
FROM hospital_er h
JOIN doctor_patients d ON d.patient_id = h.patient_id;

-- check 3: no rows lost in the join (9216) and data looks right
SELECT COUNT(*)                       AS view_rows,          -- 9216
       MIN(visit_datetime)            AS first_visit,        -- 2019-04-01 01:13
       MAX(visit_datetime)            AS last_visit,         -- 2020-10-30 23:44
       SUM(visit_datetime IS NULL)    AS bad_dates,          -- 0
       SUM(patient_sat_score IS NULL) AS blank_scores,       -- 6699
       COUNT(patient_sat_score)       AS scores_present,     -- 2517
       SUM(patient_gender = 'NC')     AS gender_nc           -- 24
FROM vw_hospital_full;

-- check 4: department should be same in both files (0 mismatches)
SELECT COUNT(*) AS dept_mismatch
FROM hospital_er h
JOIN doctor_patients d ON d.patient_id = h.patient_id
WHERE h.department_referral <> d.department_referral;

-- check 5: totals that the Power BI report should also show
SELECT SUM(total_bill) AS total_revenue,                   -- 509309117
       ROUND(AVG(patient_waittime), 2) AS avg_wait_time    -- 35.26
FROM vw_hospital_full;
