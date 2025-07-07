####################################################################
# This code extracts all people who had a rheumatology outpatient visit
####################################################################


from ehrql import create_dataset, case, when, years, days, weeks, show
from ehrql.tables.tpp import patients, practice_registrations, clinical_events, opa

dataset = create_dataset()
dataset.configure_dummy_data(population_size=9000)


# rheumatology outpatient visits - to measure before / after start of personalised follow-up
rheum_opa = opa.where(
        opa.appointment_date.is_on_or_after("2018-06-01")
        & opa.treatment_function_code.is_in(["410"])
        & opa.attendance_status.is_in(["5","6"])
    ).sort_by(
        opa.appointment_date
)

# everyone with an outpatient visit
first_opa = rheum_opa.where(
        rheum_opa.appointment_date.is_on_or_after("2022-06-01")
    ).sort_by(
        rheum_opa.appointment_date
    ).first_for_patient()

# first personalised pathway record
first_pfu = rheum_opa.where(
        rheum_opa.outcome_of_attendance.is_in(["4","5"]) 
        & rheum_opa.appointment_date.is_on_or_after("2022-06-01")
    ).sort_by(
        rheum_opa.appointment_date
    ).first_for_patient()


dataset.pfu_cat = first_pfu.outcome_of_attendance
dataset.first_pfu_date = first_pfu.appointment_date
dataset.first_pfu_year = dataset.first_pfu_date.year
dataset.any_pfu = dataset.first_pfu_date.is_not_null() 
dataset.count_pfu = rheum_opa.where(
        rheum_opa.outcome_of_attendance.is_in(["4","5"]) 
        & rheum_opa.appointment_date.is_on_or_after("2022-06-01")
    ).count_for_patient() # number of pfu records

dataset.any_opa = first_opa.exists_for_patient()
dataset.treatment_function_code = first_opa.treatment_function_code # specialty
dataset.pfu_treatment_function_code = first_pfu.treatment_function_code

###################################

# outpatient visits before start of personalised followup
dataset.before_3yr = rheum_opa.where(
        rheum_opa.appointment_date.is_on_or_between(dataset.first_pfu_date - years(3), dataset.first_pfu_date - days(1))
        & dataset.any_pfu
    ).count_for_patient()

dataset.before_2yr = rheum_opa.where(
        rheum_opa.appointment_date.is_on_or_between(dataset.first_pfu_date - years(2), dataset.first_pfu_date - days(1))
        & dataset.any_pfu
    ).count_for_patient()

dataset.before_1yr = rheum_opa.where(
        rheum_opa.appointment_date.is_on_or_between(dataset.first_pfu_date - years(1), dataset.first_pfu_date - days(1))
        & dataset.any_pfu
    ).count_for_patient()

# outpatient visits 1 year after start of personalised followup
dataset.after_1yr = rheum_opa.where(
        rheum_opa.appointment_date.is_on_or_between(dataset.first_pfu_date + days(1), dataset.first_pfu_date + years(1))
        & dataset.any_pfu
    ).count_for_patient()


###

dataset.before_last_date = rheum_opa.where(
        rheum_opa.appointment_date.is_on_or_between(dataset.first_pfu_date - years(3), dataset.first_pfu_date - days(1))
        & dataset.any_pfu
    ).sort_by(
        rheum_opa.appointment_date
    ).last_for_patient().appointment_date

dataset.after_next_date = rheum_opa.where(
        rheum_opa.appointment_date.is_after(dataset.first_pfu_date)
        & dataset.any_pfu
    ).sort_by(
        rheum_opa.appointment_date
    ).first_for_patient().appointment_date

dataset.days_from_last_visit = (dataset.first_pfu_date - dataset.before_last_date).days
dataset.days_to_next_visit = (dataset.after_next_date - dataset.first_pfu_date).days


###################################


# demographics
dataset.sex = patients.sex

dataset.age = patients.age_on("2022-06-01")
dataset.age_group = case(
        when(dataset.age < 30).then("18-29"),
        when(dataset.age < 40).then("30-39"),
        when(dataset.age < 50).then("40-49"),
        when(dataset.age < 60).then("50-59"),
        when(dataset.age < 70).then("60-69"),
        when(dataset.age < 80).then("70-79"),
        when(dataset.age < 90).then("80-89"),
        when(dataset.age >= 90).then("90+"),
        otherwise="missing",
)

dataset.region = practice_registrations.for_patient_on("2022-06-01").practice_nuts1_region_name


# define population - everyone with an outpatient visit
dataset.define_population(
    (dataset.age >= 18) 
    & (dataset.age < 110) 
    & ((patients.sex == "male") | (patients.sex == "female"))
    & (patients.date_of_death.is_after("2022-06-01") | patients.date_of_death.is_null())
    & (practice_registrations.for_patient_on("2022-06-01").exists_for_patient())
    & dataset.any_opa.is_not_null()
)

