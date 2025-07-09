####################################################################
# This code extracts all people who had a rheumatology outpatient visit
####################################################################


from ehrql import create_dataset, case, when, years, days, weeks, show
from ehrql.tables.tpp import patients, practice_registrations, clinical_events, opa

dataset = create_dataset()
dataset.configure_dummy_data(population_size=9000)



# rheumatology outpatient visits - to measure before / after start of personalised follow-up
all_opa = opa.where(
        opa.appointment_date.is_on_or_after("2018-06-01")
        & opa.treatment_function_code.is_in(["410"])
        & opa.attendance_status.is_in(["5","6"])
    )

# everyone with an outpatient visit
first_opa = all_opa.where(
        all_opa.appointment_date.is_on_or_after("2022-06-01")
    ).sort_by(
        all_opa.appointment_date
    ).first_for_patient()

# first personalised pathway record
first_pfu = all_opa.where(
        all_opa.outcome_of_attendance.is_in(["4","5"]) 
        & all_opa.appointment_date.is_on_or_after("2022-06-01")
    ).sort_by(
        all_opa.appointment_date
    ).first_for_patient()


from dataset_definition import opa_characteristics

dataset = opa_characteristics(all_opa, first_opa, first_pfu)


# define population - everyone with an outpatient visit
dataset.define_population(
    (patients.age_on("2022-06-01") >= 18) 
    & (patients.age_on("2022-06-01") < 110) 
    & ((patients.sex == "male") | (patients.sex == "female"))
    & (patients.date_of_death.is_after(first_opa.appointment_date) | patients.date_of_death.is_null())
    & (practice_registrations.for_patient_on(first_opa.appointment_date).exists_for_patient())
    & first_opa.exists_for_patient()
)