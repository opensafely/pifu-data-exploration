########################################################################################
# This code extracts all people who had an outpatient visit for a specific specialty
########################################################################################

from ehrql import create_dataset, get_parameter
from ehrql.tables.tpp import patients, practice_registrations, opa
from analysis.variable_function import opa_characteristics

dataset = create_dataset()
dataset.configure_dummy_data(population_size=9000)

trt_func_code = get_parameter("trt_func_code", type=str)

# outpatient visits 
all_opa = opa.where(
        opa.appointment_date.is_on_or_between("2022-06-01","2025-12-31")
        & opa.treatment_function_code.is_in([trt_func_code])
        & opa.attendance_status.is_in(["5","6"])
    )

# pfu only
pfu_only = all_opa.where(
        all_opa.outcome_of_attendance.is_in(["4","5"])
        & all_opa.appointment_date.is_on_or_between("2022-06-01","2025-12-31")
    )

dataset = opa_characteristics(all_opa, pfu_only)

######################################

# define population - everyone with an outpatient visit for given specialty
dataset.define_population(
    (dataset.age_opa >= 0)
    & (dataset.age_opa < 110) 
    & ((dataset.sex == "male") | (dataset.sex == "female"))
    & (patients.date_of_death.is_after(dataset.first_opa_date) | patients.date_of_death.is_null())
    & (practice_registrations.for_patient_on(dataset.first_opa_date).exists_for_patient())
    & dataset.first_opa_date.is_not_null()
)