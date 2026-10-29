# Data dictionary

The analysis uses two files. Both have 9,216 rows and one row per patient. `patient_id` is unique in both, so they join one-to-one. The raw CSV files are not in this repo. The data is loaded inside `powerbi/columbia_asia_dashboard.pbix`.

## hospital_er.csv (one row per visit)

| Column | Type | Meaning | Notes |
|---|---|---|---|
| `visit_datetime` | datetime | Date and time of the visit | Stored as text like `01-04-2019 01:13` (day-month-year). Converted while loading. Range: 1 Apr 2019 to 30 Oct 2020 |
| `patient_id` | text | Patient ID, like `100-34-9587` | Unique, so each patient appears once |
| `patient_gender` | text | `M`, `F` or `NC` | `NC` has 24 patients |
| `patient_age` | integer | Age in years | |
| `patient_sat_score` | integer | Satisfaction score | Blank for 6,699 visits (72.7%). Only 2,517 visits have a score |
| `patient_first_inital` | text | First initial of the patient | Column name spelled this way in the source file |
| `patient_last_name` | text | Last name | |
| `patient_race` | text | Race group | 7 groups. "Declined to Identify" is kept as its own group |
| `patient_admin_flag` | boolean | TRUE / FALSE flag | The source does not explain it, so I did not use it |
| `patient_waittime` | integer | Wait time in minutes | The bands I used in Power BI run from 10 to 60 |
| `department_referral` | text | Department the patient was sent to | 7 departments |

## doctor_patients.csv (one row per patient)

| Column | Type | Meaning | Notes |
|---|---|---|---|
| `patient_id` | text | Patient ID | Joins to `hospital_er` |
| `department_referral` | text | Department | Same as in `hospital_er` for every row (0 mismatches) |
| `doctor_name` | text | Doctor, like `Dr. Smith` | 22 doctors |
| `appointment_fees` | integer | Appointment fee | Between 500 and 1,500, set by department |
| `total_bill` | integer | Total bill of the visit | Includes the appointment fee. Currency is not stated in the data |
| `doctor_id` | text | Doctor ID, like `CAH001` | One doctor (`CAH022`, Dr. Surya) appears in three departments |

## Columns I added

| Column | Where | How it is made |
|---|---|---|
| `visit_date`, `visit_hour`, `visit_month` | SQL view and Power BI | Taken from `visit_datetime` |
| `age_group` | Power BI | 0-17, 18-30, 31-45, 46-60, 61+ |
| `wait_band` | Power BI | 10-19, 20-29, 30-39, 40-49, 50-60 minutes |
| `patient_name` | Power BI | First initial and last name |

## What the data cannot tell
- No cost columns (salary, rent, equipment), so profit cannot be calculated.
- One visit per patient, so repeat visits and loyalty cannot be studied.
- No diagnosis or treatment result.
- Satisfaction is missing for 72.7% of visits.
