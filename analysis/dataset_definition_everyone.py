#################################################################
# This code extracts all people who had an outpatient visit
#################################################################


from ehrql import create_dataset, case, when, years, days, weeks, show
from ehrql.tables.tpp import patients, practice_registrations, clinical_events, opa

dataset = create_dataset()
dataset.configure_dummy_data(population_size=5000)

# all outpatient visits - to measure before / after start of personalised follow-up
all_opa = opa.where(
        opa.appointment_date.is_on_or_between("2022-06-01","2025-12-31")
        & opa.attendance_status.is_in(["5","6"])
    )

# pfu only
pfu_only = all_opa.where(
        all_opa.outcome_of_attendance.is_in(["4","5"])
        & all_opa.appointment_date.is_on_or_between("2022-06-01","2025-12-31")
    )

from analysis.variable_function import opa_characteristics

dataset = opa_characteristics(all_opa, pfu_only)


###################################

# define population - everyone with an outpatient visit
dataset.define_population(
    (dataset.age_opa >= 0)
    & (dataset.age_opa < 110) 
    & ((dataset.sex == "male") | (dataset.sex == "female"))
    & (patients.date_of_death.is_after(dataset.first_opa_date) | patients.date_of_death.is_null())
    & (practice_registrations.for_patient_on(dataset.first_opa_date).exists_for_patient())
    & dataset.first_opa_date.is_not_null()
)
