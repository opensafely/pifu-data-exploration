#################################################################
# This code extracts all people who had an outpatient visit
#################################################################


from ehrql import create_dataset, case, when, years, days, weeks, show
from ehrql.tables.tpp import patients, practice_registrations, clinical_events, opa

dataset = create_dataset()
dataset.configure_dummy_data(population_size=10000)


total_opa = opa.where(opa.appointment_date.is_on_or_between("2024-01-01","2024-12-31"))
total_opa_date = total_opa.appointment_date

attended_opa = opa.where(
    opa.appointment_date.is_on_or_between("2024-01-01","2024-12-31")
    & opa.attendance_status.is_in(["1","2"])
    )
attended_opa_date = attended_opa.appointment_date

dataset.count_same_day = total_opa_date.count_episodes_for_patient(days(0))
dataset.count_same_day_attended = attended_opa_date.count_episodes_for_patient(days(0))
dataset.count_all = total_opa.count_for_patient()
dataset.count_all_attended = attended_opa.count_for_patient()

all_opa = opa.where(
        opa.appointment_date.is_on_or_between("2024-01-01","2024-12-31")
    ).sort_by(
        opa.appointment_date
    ).first_for_patient()

dataset.any_opa = all_opa.exists_for_patient()
dataset.outcome_of_attendance = all_opa.outcome_of_attendance
dataset.treatment_function_code = all_opa.treatment_function_code  # specialty
dataset.attendance_status = all_opa.attendance_status
dataset.consultation_medium_used = all_opa.consultation_medium_used
dataset.first_attendance = all_opa.first_attendance
dataset.pfu = all_opa.outcome_of_attendance.is_in(["4","5"])

dataset.region = practice_registrations.for_patient_on("2024-01-01").practice_nuts1_region_name


###################################

# define population - everyone with an outpatient visit
dataset.define_population(
    (patients.age_on("2024-01-01") >= 18) 
    & (patients.age_on("2024-01-01") < 110) 
    & ((patients.sex == "male") | (patients.sex == "female"))
    & (patients.date_of_death.is_after("2024-01-01") | patients.date_of_death.is_null())
    & (practice_registrations.for_patient_on("2024-01-01").exists_for_patient())
    & dataset.any_opa
)