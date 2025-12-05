#################################################################
# This code extracts monthly counts of people on personalised
#   followup pathways, stratified by relevant characteristics
#################################################################


from ehrql import months, INTERVAL, Measures, get_parameter, case, when
from ehrql.tables.tpp import (
    patients, 
    practice_registrations,
    opa)

# All OP visits that were attended
all_opa = opa.where(
        opa.appointment_date.is_on_or_between(INTERVAL.start_date, INTERVAL.end_date)
        & opa.attendance_status.is_in(["5","6"])
    )

# All PIFU visits that were attended
all_pfu = opa.where(
        opa.appointment_date.is_on_or_between(INTERVAL.start_date, INTERVAL.end_date)
        & opa.attendance_status.is_in(["5","6"])
        & opa.outcome_of_attendance.is_in(["4","5"])
    )

# Any outpatient visit - total and personalised 
any_opa = all_opa.exists_for_patient()
any_pfu = all_pfu.exists_for_patient()

# Number of outpatient visits - total and personalised
count_opa = all_opa.opa_ident.count_distinct_for_patient()
count_pfu = all_pfu.opa_ident.count_distinct_for_patient()

stp = practice_registrations.for_patient_on(INTERVAL.start_date).practice_stp

### Measures setup
measures = Measures()
measures.configure_disclosure_control(enabled=False)
measures.configure_dummy_data(population_size=1000)

denominator = (
      # (patients.age_on(INTERVAL.start_date) >= 18) 
        (patients.age_on(INTERVAL.start_date) >= 0)
        & (patients.age_on(INTERVAL.start_date) < 110)
        & ((patients.sex == "male") | (patients.sex == "female"))
        & (patients.date_of_death.is_after(INTERVAL.start_date) | patients.date_of_death.is_null())
        & (practice_registrations.for_patient_on(INTERVAL.start_date).exists_for_patient())
    )

measures.define_defaults(
    intervals=months(48).starting_on("2022-01-01"),
    group_by={"stp": stp}
    )


##################

measures.define_measure(
    name="patients_pfu",
    numerator=any_pfu,
    denominator=denominator & any_opa
    )


###########################################


    
