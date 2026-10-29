# Power BI measures and queries

Everything here is copied from the report file. The report has one main table, `hospital_data`, which joins the two source files, plus four helper tables.

## Model

| Table | Type | Purpose |
|---|---|---|
| `hospital_data` | Power Query | One row per visit: hospital data joined with doctor, fee and bill |
| `date_table` | DAX | Calendar from 1 Apr 2019 to 31 Oct 2020, linked to the visit date |
| `compare_labels` | DAX | Three labels for the patient comparison charts |
| `Department metric` | Field parameter | Lets the Main tab switch the department chart between four measures |
| `discount_rules` | DAX | Four discount rules with patients reached and cost |

## Measures (all in `hospital_data`)

### Core measures

**`total_visits`**: Number of visits (one row per visit).

```dax
total_visits =
COUNTROWS(hospital_data)
```

**`total_revenue`**: Sum of total bill.

```dax
total_revenue =
SUM(hospital_data[total_bill])
```

**`avg_wait_time`**: Average wait in minutes.

```dax
avg_wait_time =
AVERAGE(hospital_data[patient_waittime])
```

**`avg_satisfaction`**: Average satisfaction score. Blank scores are ignored.

```dax
avg_satisfaction =
AVERAGE(hospital_data[patient_sat_score])
```

**`avg_bill`**: Average total bill.

```dax
avg_bill =
AVERAGE(hospital_data[total_bill])
```

**`avg_appointment_fee`**: Average appointment fee.

```dax
avg_appointment_fee =
AVERAGE(hospital_data[appointment_fees])
```

**`avg_patient_age`**: Average patient age.

```dax
avg_patient_age =
AVERAGE(hospital_data[patient_age])
```

**`avg_daily_visits`**: Visits divided by the number of days with visits.

```dax
avg_daily_visits =
DIVIDE([total_visits], DISTINCTCOUNT(hospital_data[visit_date]))
```

**`revenue_millions`**: Revenue divided by 1,000,000.

```dax
revenue_millions =
DIVIDE([total_revenue], 1000000)
```

**`doctor_count`**: Number of distinct doctors.

```dax
doctor_count =
DISTINCTCOUNT(hospital_data[doctor_id])
```

**`visits_per_doctor`**: Visits divided by doctors.

```dax
visits_per_doctor =
DIVIDE([total_visits], [doctor_count])
```

### Data quality (satisfaction scores)

**`scores_count`**: Visits that have a score.

```dax
scores_count =
COUNT(hospital_data[patient_sat_score])
```

**`blank_scores`**: Visits with no score.

```dax
blank_scores =
[total_visits] - [scores_count]
```

**`blank_score_pct`**: Share of visits with no score.

```dax
blank_score_pct =
DIVIDE([blank_scores], [total_visits])
```

### Shares and mix

**`visit_share`**: Visits as a share of all visits, ignoring the gender filter.

```dax
visit_share =
DIVIDE(
    [total_visits],
    CALCULATE([total_visits], ALL(hospital_data[patient_gender]))
)
```

**`revenue_share`**: Revenue as a share of all revenue, ignoring the department filter.

```dax
revenue_share =
DIVIDE(
    [total_revenue],
    CALCULATE([total_revenue], ALL(hospital_data[department_referral]))
)
```

**`mix_share`**: Visits as a share within the same department.

```dax
mix_share =
DIVIDE(
    [total_visits],
    CALCULATE([total_visits], ALLEXCEPT(hospital_data, hospital_data[department_referral]))
)
```

**`specialist_share`**: Share of visits that go to a department other than General Practice.

```dax
specialist_share =
DIVIDE(
    CALCULATE([total_visits], hospital_data[department_referral] <> "General Practice"),
    [total_visits]
)
```

### Month comparison and trend

**`previous_month_visits`**: Visits in the previous month (uses date_table).

```dax
previous_month_visits =
CALCULATE([total_visits], PREVIOUSMONTH(date_table[Date]))
```

**`visits_vs_previous`**: Yes / No / N/A: are visits higher than last month.

```dax
visits_vs_previous =
IF(
    ISBLANK([previous_month_visits]),
    "N/A",
    IF([total_visits] > [previous_month_visits], "Yes", "No")
)
```

**`visits_vs_previous_color`**: Font colour for the Yes / No column.

```dax
visits_vs_previous_color =
IF([visits_vs_previous] = "Yes", "#2E8B57",
   IF([visits_vs_previous] = "No", "#D1495B", "#6C8EAD"))
```

**`visits_7day_avg`**: Average of the last 7 days (rolling).

```dax
visits_7day_avg =
AVERAGEX(
    DATESINPERIOD(date_table[Date], MAX(date_table[Date]), -7, DAY),
    [total_visits]
)
```

### Doctor and department

**`dr_smith_patients`**: Patients of Dr. Smith, using CALCULATE with COUNTX.

```dax
dr_smith_patients =
CALCULATE(
    COUNTX(hospital_data, hospital_data[patient_id]),
    hospital_data[doctor_name] = "Dr. Smith"
)
```

**`avg_age_orthopedics`**: Average age with the Orthopedics filter forced on.

```dax
avg_age_orthopedics =
CALCULATE([avg_patient_age], hospital_data[department_referral] = "Orthopedics")
```

**`most_visited_dept`**: Department with the most visits in the current filter.

```dax
most_visited_dept =
MAXX(
    TOPN(1, VALUES(hospital_data[department_referral]), [total_visits], DESC),
    hospital_data[department_referral]
)
```

### Patient tab

**`patient_name_sel`**: Name shown on the Patients tab for the selected patient.

```dax
patient_name_sel =
SELECTEDVALUE(hospital_data[patient_name], "All Patients")
```

**`patient_race_sel`**: Race of the selected patient.

```dax
patient_race_sel =
SELECTEDVALUE(hospital_data[patient_race], "All")
```

**`patient_gender_sel`**: Gender of the selected patient.

```dax
patient_gender_sel =
SELECTEDVALUE(hospital_data[patient_gender], "All")
```

**`patient_doctor_sel`**: Doctor of the selected patient.

```dax
patient_doctor_sel =
SELECTEDVALUE(hospital_data[doctor_name], "All")
```

**`hospital_avg_wait`**: Hospital-wide average wait, ignoring every filter.

```dax
hospital_avg_wait =
CALCULATE([avg_wait_time], ALL(hospital_data))
```

**`dept_avg_wait`**: Average wait of the selected patient's department.

```dax
dept_avg_wait =
VAR d = SELECTEDVALUE(hospital_data[department_referral])
RETURN CALCULATE([avg_wait_time], ALL(hospital_data), hospital_data[department_referral] = d)
```

**`wait_compare`**: Patient vs department vs hospital wait, driven by compare_labels.

```dax
wait_compare =
IF(
    HASONEVALUE(hospital_data[patient_id]),
    SWITCH(
        SELECTEDVALUE(compare_labels[label]),
        "This patient", [avg_wait_time],
        "Department average", [dept_avg_wait],
        "Hospital average", [hospital_avg_wait]
    )
)
```

**`hospital_avg_bill`**: Hospital-wide average bill.

```dax
hospital_avg_bill =
CALCULATE(AVERAGE(hospital_data[total_bill]), ALL(hospital_data))
```

**`dept_avg_bill`**: Average bill of the selected patient's department.

```dax
dept_avg_bill =
VAR d = SELECTEDVALUE(hospital_data[department_referral])
RETURN CALCULATE(AVERAGE(hospital_data[total_bill]), ALL(hospital_data), hospital_data[department_referral] = d)
```

**`bill_compare`**: Patient vs department vs hospital bill, driven by compare_labels.

```dax
bill_compare =
IF(
    HASONEVALUE(hospital_data[patient_id]),
    SWITCH(
        SELECTEDVALUE(compare_labels[label]),
        "This patient", [total_revenue],
        "Department average", [dept_avg_bill],
        "Hospital average", [hospital_avg_bill]
    )
)
```

**`patient_prompt`**: Hint text shown until a patient is selected.

```dax
patient_prompt =
IF(
    HASONEVALUE(hospital_data[patient_id]),
    "",
    "Select a patient ID above to see this comparison"
)
```

## Calculated tables

### `date_table`

```dax
date_table =
ADDCOLUMNS(
    CALENDAR(DATE(2019, 4, 1), DATE(2020, 10, 31)),
    "year", YEAR([Date]),
    "month_number", MONTH([Date]),
    "month_name", FORMAT([Date], "MMM"),
    "year_month", FORMAT([Date], "YYYY-MM")
)
```

### `compare_labels`

```dax
compare_labels =
DATATABLE(
    "label", STRING,
    "sort_order", INTEGER,
    {{"This patient", 1}, {"Department average", 2}, {"Hospital average", 3}}
)
```

### `Department metric`

```dax
Department metric =
{
    ("Visits", NAMEOF('hospital_data'[total_visits]), 0),
    ("Revenue (millions)", NAMEOF('hospital_data'[revenue_millions]), 1),
    ("Avg wait time (min)", NAMEOF('hospital_data'[avg_wait_time]), 2),
    ("Average satisfaction", NAMEOF('hospital_data'[avg_satisfaction]), 3)
}
```

### `discount_rules`

```dax
discount_rules =
VAR p90 = PERCENTILE.INC(hospital_data[total_bill], 0.9)
VAR total_patients = COUNTROWS(hospital_data)
VAR w = FILTER(hospital_data, hospital_data[patient_waittime] >= 50)
VAR l = FILTER(hospital_data, NOT ISBLANK(hospital_data[patient_sat_score]) && hospital_data[patient_sat_score] <= 3)
VAR s = FILTER(hospital_data, hospital_data[patient_age] >= 61)
VAR b = FILTER(hospital_data, hospital_data[total_bill] >= p90)
RETURN
UNION(
    ROW("Rule", "Waited 50+ min", "Patients", COUNTROWS(w), "Share of patients", DIVIDE(COUNTROWS(w), total_patients), "Bills", SUMX(w, hospital_data[total_bill]), "Cost of 10% discount", SUMX(w, hospital_data[total_bill]) * 0.1),
    ROW("Rule", "Satisfaction 3 or below", "Patients", COUNTROWS(l), "Share of patients", DIVIDE(COUNTROWS(l), total_patients), "Bills", SUMX(l, hospital_data[total_bill]), "Cost of 10% discount", SUMX(l, hospital_data[total_bill]) * 0.1),
    ROW("Rule", "Age 61+", "Patients", COUNTROWS(s), "Share of patients", DIVIDE(COUNTROWS(s), total_patients), "Bills", SUMX(s, hospital_data[total_bill]), "Cost of 10% discount", SUMX(s, hospital_data[total_bill]) * 0.1),
    ROW("Rule", "Bill in top 10%", "Patients", COUNTROWS(b), "Share of patients", DIVIDE(COUNTROWS(b), total_patients), "Bills", SUMX(b, hospital_data[total_bill]), "Cost of 10% discount", SUMX(b, hospital_data[total_bill]) * 0.1)
)
```

## Power Query (M)

`hospital_er` and `doctor_patients` are the two source files, loaded as tables. Their file-path steps are left out of this repo because they point to a local folder. The query below builds `hospital_data` from them and is copied unchanged from the report.

```m
let
    Source = Table.NestedJoin(hospital_er, {"patient_id"}, doctor_patients, {"patient_id"}, "doctor_patients", JoinKind.LeftOuter),
    #"Expanded doctor_patients" = Table.ExpandTableColumn(Source, "doctor_patients", {"doctor_name", "appointment_fees", "total_bill", "doctor_id"}, {"doctor_name", "appointment_fees", "total_bill", "doctor_id"}),
    #"Renamed Columns" = Table.RenameColumns(#"Expanded doctor_patients",{{"date", "visit_datetime"}}),
    #"Inserted Date" = Table.AddColumn(#"Renamed Columns", "Date", each DateTime.Date([visit_datetime]), type date),
    #"Renamed Columns1" = Table.RenameColumns(#"Inserted Date",{{"Date", "visit_date"}}),
    #"Inserted Hour" = Table.AddColumn(#"Renamed Columns1", "Hour", each Time.Hour([visit_datetime]), Int64.Type),
    #"Renamed Columns2" = Table.RenameColumns(#"Inserted Hour",{{"Hour", "visit_hour"}}),
    #"Added Conditional Column" = Table.AddColumn(#"Renamed Columns2", "age_group", each if [patient_age] <= 17 then "0-17" else if [patient_age] <= 30 then "18-30" else if [patient_age] <= 45 then "31-45" else if [patient_age] <= 60 then "46-60" else "61+"),
    #"Changed Type" = Table.TransformColumnTypes(#"Added Conditional Column",{{"age_group", type text}}),
    #"Added Conditional Column1" = Table.AddColumn(#"Changed Type", "wait_band", each if [patient_waittime] <= 19 then "10-19" else if [patient_waittime] <= 29 then "20-29" else if [patient_waittime] <= 39 then "30-39" else if [patient_waittime] <= 49 then "40-49" else "50-60"),
    #"Changed Type1" = Table.TransformColumnTypes(#"Added Conditional Column1",{{"wait_band", type text}}),
    #"Added Custom" = Table.AddColumn(#"Changed Type1", "patient_name", each [patient_first_inital] & ". " & [patient_last_name]),
    #"Changed Type2" = Table.TransformColumnTypes(#"Added Custom",{{"patient_name", type text}})
in
    #"Changed Type2"
```

What the steps do:

- Left outer join from `hospital_er` to `doctor_patients` on `patient_id`, so no visit is dropped (9,216 rows before and after).
- Add `visit_date` and `visit_hour` from the visit date and time.
- `age_group`: 0-17, 18-30, 31-45, 46-60, 61+.
- `wait_band`: 10-19, 20-29, 30-39, 40-49, 50-60 minutes.
- `patient_name`: first initial and last name.
