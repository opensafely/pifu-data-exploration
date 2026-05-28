

from ehrql import create_dataset, case, when, years, days, weeks, show, Measures, INTERVAL, minimum_of
from ehrql.tables.tpp import patients, practice_registrations, clinical_events, opa, ons_deaths
from datetime import date

dataset = create_dataset()
dataset.configure_dummy_data(population_size=9000)

# rheumatology outpatient visits - to measure before / after start of personalised follow-up
all_opa = opa.where(
        opa.appointment_date.is_on_or_between("2022-06-01","2025-12-31")
        & opa.treatment_function_code.is_in(["410"])
        & opa.attendance_status.is_in(["5","6"])
    )

# pfu only
pfu_only = all_opa.where(
        all_opa.outcome_of_attendance.is_in(["4","5"])
        & all_opa.appointment_date.is_on_or_between("2022-06-01","2025-12-31")
    )
    
# first personalised pathway record
first_pfu = pfu_only.sort_by(
        pfu_only.appointment_date
    ).first_for_patient()

first_pfu_date = first_pfu.appointment_date

opa_date = all_opa.appointment_date


tmp_start_date = "2000-01-01"

tmp_opa = all_opa.where(
    all_opa.appointment_date.is_on_or_between(first_pfu_date - weeks(104), first_pfu_date + weeks(104))
)

tmp_opa_date = tmp_start_date + days((opa_date - (first_pfu_date - weeks(104))).days)

count_opa = tmp_opa.where(
    tmp_opa_date.is_during(INTERVAL)
).count_for_patient()

dod = minimum_of(patients.date_of_death, ons_deaths.date)

registrations = practice_registrations.spanning(
        first_pfu_date - days(182), first_pfu_date
    ).sort_by(
        practice_registrations.end_date
    ).last_for_patient()

reg_end_date = registrations.end_date
end_date = minimum_of(reg_end_date, dod, date(2026, 6, 30))

# Standardise end date relative to RTT start and end dates
tmp_end_date = tmp_start_date + days((end_date - (first_pfu_date - weeks(104))).days)

### Measures setup
measures = Measures()
measures.configure_disclosure_control(enabled=False)
measures.configure_dummy_data(population_size=1000)

denominator = (
    (patients.age_on(INTERVAL.start_date) >= 18)
    & (patients.age_on(INTERVAL.start_date) < 110)
    & ((patients.sex == "male") | (patients.sex == "female")) 
    & registrations.exists_for_patient()
    & first_pfu_date.is_on_or_before("2025-07-01")
    & tmp_end_date.is_after(INTERVAL.end_date)
)

measures.define_defaults(
    intervals=weeks(104).starting_on("2000-01-01")
    )

########################

# Total outpatient visits
measures.define_measure(
    name="opa_before",
    numerator=count_opa,
    denominator=denominator,
    )
