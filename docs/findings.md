# Findings and recommendations

A short case study of the Columbia Asia Hospital data: 9,216 visits, 22 doctors and 7 departments, from 1 April 2019 to 30 October 2020. All numbers match between MySQL and Power BI.

## The problem
The hospital's management wanted to know where patients wait, which departments and doctors carry the load and the revenue, how satisfied patients are, and where to spend: new doctors, discounts and shift timings. I built a Power BI report with three views (hospital, doctor, patient) and used MySQL to check the numbers and answer the deeper questions.

## The hospital at a glance

| Measure | Value |
|---|---|
| Visits | 9,216 |
| Revenue (sum of total bills) | 509,309,117 |
| Average wait | 35.26 minutes |
| Average satisfaction | 4.99 (only 2,517 visits have a score) |
| Monthly visits | 431 to 530, no clear season |

## 1. Work is concentrated in one department and one doctor
- General Practice has 7,240 of the 9,216 visits (78.6%), with 3 doctors.
- Dr. Smith alone has 5,986 patients, 65% of all visits.
- Orthopedics has 995 visits but brings the most revenue: 172.9M (34.0%). General Practice is second with 164.1M (32.2%).
- The other five departments have 29 to 83 visits per doctor, so they are not short of doctors.
- Appointment fees are only 1.05% of revenue. Most money comes from treatment and services.

## 2. Waiting time is the same everywhere
- Neurology has the longest average wait (36.80 minutes) and Renal the shortest (34.70). The whole gap is 2.1 minutes.
- Three departments showed a wait that fell three months in a row (Neurology, Orthopedics, Gastroenterology), but they have few visits a month, so I would not call it a real improvement.
- The problem is the hospital-wide wait of 35 minutes, not one department.

## 3. Satisfaction does not follow wait time
- Satisfaction by wait band is 5.26, 4.91, 4.80, 5.04 and 4.94. There is no steady pattern. The correlation is about -0.02.
- By age: 46-60 is highest (5.19) and 61+ is lowest (4.80). The gap is small, but 61+ is the biggest group (2,198 visits).
- 72.7% of visits have no score, so department-level results rest on small numbers.

## 4. No sign of unequal treatment by race or gender
- By race, average wait is between 34.65 and 35.69 minutes, satisfaction between 4.83 and 5.33, and the share sent to a specialist department between 19.2% and 22.5%.
- By gender, wait is 35.11 (F) and 35.40 (M), and satisfaction is 4.96 and 5.03.
- The 24 patients marked NC are too few to say anything.
- This data cannot show quality of treatment, so it cannot prove there is no discrimination. It only shows no gap on wait, satisfaction, bill and specialist referral.

## 5. Doctor results from SQL
- Dr. Miller is first on revenue among doctors with fewer patients than average: 61.3M from 355 patients.
- Dr. Harris (26.7M from 71 patients) and Dr. Martin (26.1M from 69) earn about 370,000 per patient, against about 55,000 for the hospital overall.
- Doctor satisfaction runs from 3.78 (Dr. Robinson, 9 scores) to 7.12 (Dr. Taylor, 17 scores). The extremes come from doctors with very few scores.
- 18 of 22 doctors have treated all 7 race groups.
- The male to female bill ratio is highest in Orthopedics (1.19) and lowest in Gastroenterology (0.75). Part of that is only because there are more male patients.

## Recommendations

**Hire 3 doctors: 2 in General Practice and 1 in Orthopedics.**
General Practice has 2,413 visits per doctor. Orthopedics is second busiest and brings the most revenue. The other departments do not need more doctors now.

**Run General Practice in two shifts: 10:00 to 22:00 and 22:00 to 10:00.**
Visits are almost flat through the day (269 to 342 per hour). Cutting at the quietest hours puts the handover when fewer patients wait. The two shifts get 3,573 and 3,667 visits. One doctor per shift cannot carry about 3,600 visits, so this only works together with the new hires.

**Start with two discounts: patients who waited 50+ minutes, and patients aged 61+.**

| Rule | Patients | Share | Cost of 10% off |
|---|---|---|---|
| Waited 50+ minutes | 2,036 | 22.1% | 11.6M |
| Age 61+ | 2,198 | 23.8% | 11.4M |
| Bill in top 10% | 922 | 10.0% | 24.4M |
| Satisfaction 3 or below | 900 | 9.8% | 5.3M |

Waited 50+, satisfaction 3 or below and age 61+ together would reach 4,764 patients (51.7%), which is too many. Check satisfaction after three months before adding more.

**Keep staffing steady across months.**
Visits stay between 431 and 530 a month. February 2020 was the quietest month, so it suits planned leave and maintenance.

**Collect more data.**
Cost data, scores from more patients, repeat visits and complaints would make most of the open questions answerable.

## Limits
- It is a case-study dataset, not real company data.
- Revenue is the sum of bills. The data does not show what was actually collected, and has no costs, so I cannot say whether the hospital is profitable.
- Each patient visits once, so loyalty and repeat visits cannot be studied.
- Only 27.3% of visits have a satisfaction score.
- Doctor and department numbers for small groups move a lot from chance, so I did not read patterns into them.
