#################################################################
# This code extracts monthly counts of outpatient attendances
# before and after start of personalised follow-up
#################################################################

from ehrql import get_parameter, days, Measures, INTERVAL, minimum_of
from ehrql.tables.tpp import patients, practice_registrations, opa, ons_deaths
from datetime import date

trt_func_code = get_parameter("trt_func_code", type=str)

# all outpatient visits
all_opa = opa.where(
        opa.appointment_date.is_on_or_after("2020-01-01")
        & opa.attendance_status.is_in(["5","6"])
    )

spec_opa = all_opa.where(all_opa.treatment_function_code.is_in([trt_func_code]))

pfu_only = spec_opa.where(spec_opa.outcome_of_attendance.is_in(["4","5"]))
pfu_type = pfu_only.outcome_of_attendance
    
first_pfu_date = pfu_only.sort_by(
        pfu_only.appointment_date
    ).first_for_patient().appointment_date

# b/c measures works with calendar dates, standardise first_pfu_date to 2000-01-01
tmp_start_date = "2000-01-01"

# standardise outpatient visit dates relative to 2000-01-01
all_opa.tmp_opa_date = tmp_start_date + days((all_opa.appointment_date - first_pfu_date).days)
spec_opa.tmp_opa_date = tmp_start_date + days((spec_opa.appointment_date - first_pfu_date).days)

# number of outpatient visits per interval
count_opa = all_opa.where(
    all_opa.tmp_opa_date.is_during(INTERVAL)
    ).count_for_patient()
count_spec_opa = spec_opa.where(
    spec_opa.tmp_opa_date.is_during(INTERVAL)
    ).count_for_patient()

dod = minimum_of(patients.date_of_death, ons_deaths.date)

# registered for at least 6 months pre-PFU
registrations = practice_registrations.spanning(
        first_pfu_date - days(182), first_pfu_date
    ).sort_by(
        practice_registrations.end_date
    ).last_for_patient()

reg_end_date = registrations.end_date
end_date = minimum_of(reg_end_date, dod, date(2025, 12, 1))
reg_start_date = registrations.start_date

# standardise start / end date relative to 2000-01-01
tmp_end_date = tmp_start_date + days((end_date - first_pfu_date).days)
tmp_start_date = tmp_start_date + days((reg_start_date - first_pfu_date).days)

### Measures setup
measures = Measures()
measures.configure_dummy_data(population_size=10000)

denominator = (
    (patients.age_on(first_pfu_date) >= 0)
    & (patients.age_on(first_pfu_date) < 110)
    & ((patients.sex == "male") | (patients.sex == "female")) 
    & registrations.exists_for_patient()
    & (first_pfu_date.is_on_or_after("2025-07-01"))
    & first_pfu_date.is_not_null()
    & (tmp_end_date.is_after(INTERVAL.end_date) | tmp_end_date.is_null())
    & (tmp_start_date.is_on_or_before(INTERVAL.start_date))
)

measures.define_defaults(
    intervals = [
    (date(2000,1,1) - days(28*15), date(2000,1,1) - days(28*14 - 1)),
    (date(2000,1,1) - days(28*14), date(2000,1,1) - days(28*13 - 1)),
    (date(2000,1,1) - days(28*13), date(2000,1,1) - days(28*12 - 1)),
    (date(2000,1,1) - days(28*12), date(2000,1,1) - days(28*11 - 1)),
    (date(2000,1,1) - days(28*11), date(2000,1,1) - days(28*10 - 1)),
    (date(2000,1,1) - days(28*10), date(2000,1,1) - days(28*9 - 1)),
    (date(2000,1,1) - days(28*9), date(2000,1,1) - days(28*8 - 1)),
    (date(2000,1,1) - days(28*8), date(2000,1,1) - days(28*7 - 1)),
    (date(2000,1,1) - days(28*7), date(2000,1,1) - days(28*6 - 1)),
    (date(2000,1,1) - days(28*6), date(2000,1,1) - days(28*5 - 1)),
    (date(2000,1,1) - days(28*5), date(2000,1,1) - days(28*4 - 1)),
    (date(2000,1,1) - days(28*4), date(2000,1,1) - days(28*3 - 1)),
    (date(2000,1,1) - days(28*3), date(2000,1,1) - days(28*2 - 1)),
    (date(2000,1,1) - days(28*2), date(2000,1,1) - days(28 - 1)),
    (date(2000,1,1) - days(28), date(2000,1,1) - days(1)),

    (date(2000, 1, 1), date(2000, 1, 1) + days(28 - 1)),
    
    (date(2000, 1, 1) + days(28), date(2000, 1, 1) + days(28*2 - 1)),
    (date(2000, 1, 1) + days(28*2), date(2000, 1, 1) + days(28*3 - 1)),
    (date(2000, 1, 1) + days(28*3), date(2000, 1, 1) + days(28*4 - 1)),
    (date(2000, 1, 1) + days(28*4), date(2000, 1, 1) + days(28*5 - 1)),    
    (date(2000, 1, 1) + days(28*5), date(2000, 1, 1) + days(28*6 - 1)),
    (date(2000, 1, 1) + days(28*6), date(2000, 1, 1) + days(28*7 - 1)),
    (date(2000, 1, 1) + days(28*7), date(2000, 1, 1) + days(28*8 - 1)),
    (date(2000, 1, 1) + days(28*8), date(2000, 1, 1) + days(28*9 - 1)),
    (date(2000, 1, 1) + days(28*9), date(2000, 1, 1) + days(28*10 - 1)),
    (date(2000, 1, 1) + days(28*10), date(2000, 1, 1) + days(28*11 - 1)),
    (date(2000, 1, 1) + days(28*11), date(2000, 1, 1) + days(28*12 - 1)),
    (date(2000, 1, 1) + days(28*12), date(2000, 1, 1) + days(28*13 - 1)),
    (date(2000, 1, 1) + days(28*13), date(2000, 1, 1) + days(28*14 - 1)),
    (date(2000, 1, 1) + days(28*14), date(2000, 1, 1) + days(28*15 - 1)),
    (date(2000, 1, 1) + days(28*15), date(2000, 1, 1) + days(28*16 - 1))
    ]
    )

########################

# Total outpatient visits
measures.define_measure(
    name="opa_count",
    numerator=count_opa,
    denominator=denominator,
    group_by={"type": pfu_type}
    )
measures.define_measure(
    name="opa_rheum_count",
    numerator=count_spec_opa,
    denominator=denominator,
    group_by={"type": pfu_type}
    )
