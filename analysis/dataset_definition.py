from ehrql import create_dataset, case, when, years, days, weeks
from ehrql.tables.tpp import patients, practice_registrations, clinical_events, opa

dataset = create_dataset()


# first personalised pathway record
first_opa = opa.where(
        opa.outcome_of_attendance.is_in("4","5") 
        & opa.appointment_date.is_on_or_after("2021-01-01")
    ).sort_by(
        opa.appointment_date
    ).first_for_patient()

dataset.first_pfu_date = first_opa.appointment_date
dataset.first_pfu_year = dataset.first_pfu_date.year
dataset.treatment_function_code = first_opa.treatment_function_code

# all outpatient visits - to measure before / after start of personalised follow-up
all_opa = opa.where(
        opa.appointment_date.is_on_or_after("2020-01-01")
    ).sort_by(
        opa.appointment_date
)

dataset.opa_before = all_opa.where(
        opa.appointment_date.is_on_or_between(dataset.first_pfu_date - years(1) - days(1), dataset.first_pfu_date - days(1)
    ).count_for_patient()
)
dataset.opa_after = all_opa.where(
        opa.appointment_date.is_on_or_between(dataset.first_pfu_date, dataset.first_pfu_date + years(1)
    ).count_for_patient()
)

# demographics
dataset.sex = patients.sex

age = patients.age_on(dataset.first_pfu_date)
dataset.age_group = case(
        when(age < 30).then("18-29"),
        when(age < 40).then("30-39"),
        when(age < 50).then("40-49"),
        when(age < 60).then("50-59"),
        when(age < 70).then("60-69"),
        when(age < 80).then("70-79"),
        when(age < 90).then("80-89"),
        when(age >= 90).then("90+"),
        otherwise="missing",
)

dataset.region = practice_registrations.for_patient_on(dataset.first_pfu_date).practice_nuts1_region_name


# define population
dataset.define_population(
    (patients.age_on(dataset.first_pfu_date) >= 0) 
    & (patients.age_on(dataset.first_pfu_date) < 110) 
    & ((patients.sex == "male") | (patients.sex == "female"))
    & (patients.date_of_death.is_after(dataset.first_pfu_date) | patients.date_of_death.is_null())
    & (practice_registrations.for_patient_on(dataset.first_pfu_date).exists_for_patient())
)
