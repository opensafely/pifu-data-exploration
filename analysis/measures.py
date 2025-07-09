#################################################################
# This code extracts monthly counts of people on personalised
#   folloup pathways, stratified by relevant characteristics
#################################################################


from ehrql import months, INTERVAL, Measures
from ehrql.tables.tpp import (
    patients, 
    practice_registrations,
    opa)


# OPA checks
check_opa = opa.where(
        opa.appointment_date.is_on_or_between(INTERVAL.start_date, INTERVAL.end_date)
    ).sort_by(
        opa.appointment_date
    ).exists_for_patient()

#consult_medium = check_opa.consultation_medium_used
#attendance_status = check_opa.attendance_status
#first_attendance = check_opa.first_attendance


# For study
# All OP visits that were attended
all_opa = opa.where(
        opa.appointment_date.is_on_or_between(INTERVAL.start_date, INTERVAL.end_date)
        & opa.attendance_status.is_in(["5","6"])
    )

rheum_opa = opa.where(
        opa.appointment_date.is_on_or_between(INTERVAL.start_date, INTERVAL.end_date)
        & opa.attendance_status.is_in(["5","6"])
        & opa.treatment_function_code.is_in(["410"])
    )

# All PIFU visits that were attended
all_pfu = opa.where(
        opa.appointment_date.is_on_or_between(INTERVAL.start_date, INTERVAL.end_date)
        & opa.attendance_status.is_in(["5","6"])
        & opa.outcome_of_attendance.is_in(["4","5"])
    )

rheum_pfu = opa.where(
        opa.appointment_date.is_on_or_between(INTERVAL.start_date, INTERVAL.end_date)
        & opa.attendance_status.is_in(["5","6"])
        & opa.outcome_of_attendance.is_in(["4","5"])
        & opa.treatment_function_code.is_in(["410"])
    )

# Any outpatient visit - total and personalised 
any_opa = all_opa.exists_for_patient()
any_pfu = all_pfu.exists_for_patient()
any_pfu_moved = all_pfu.where(
        all_pfu.outcome_of_attendance == "4"
    ).exists_for_patient()   
any_pfu_discharged = all_pfu.where(
        all_pfu.outcome_of_attendance == "5"
    ).exists_for_patient()   

# Rheum outpatient visit - total and personalised
any_rheum_opa = rheum_opa.exists_for_patient()
any_rheum_pfu = rheum_pfu.exists_for_patient()
any_rheum_pfu_moved = rheum_pfu.where(
        rheum_pfu.outcome_of_attendance == "4"
    ).exists_for_patient()   
any_rheum_pfu_discharged = rheum_pfu.where(
        rheum_pfu.outcome_of_attendance == "5"
    ).exists_for_patient()   

# Number of outpatient visits - total and personalised
count_opa = all_opa.count_for_patient()
count_pfu = all_pfu.count_for_patient()
count_pfu_moved = all_pfu.where(
        all_pfu.outcome_of_attendance == "4"
    ).count_for_patient()
count_pfu_discharged = all_pfu.where(
        all_pfu.outcome_of_attendance == "5"
    ).count_for_patient()

# Number of rheum outpatient visits - total and personalised
count_rheum_opa = rheum_opa.count_for_patient()
count_rheum_pfu = rheum_pfu.count_for_patient()
count_rheum_pfu_moved = rheum_pfu.where(
        rheum_pfu.outcome_of_attendance == "4"
    ).count_for_patient()
count_rheum_pfu_discharged = rheum_pfu.where(
        rheum_pfu.outcome_of_attendance == "5"
    ).count_for_patient()



### Measures setup
measures = Measures()
measures.configure_disclosure_control(enabled=False)
measures.define_defaults(intervals=months(39).starting_on("2022-01-01"))
measures.configure_dummy_data(population_size=1000)

denominator = (
        (patients.age_on(INTERVAL.start_date) >= 18) 
        & (patients.age_on(INTERVAL.start_date) < 110)
        & ((patients.sex == "male") | (patients.sex == "female"))
        & (patients.date_of_death.is_after(INTERVAL.start_date) | patients.date_of_death.is_null())
        & (practice_registrations.for_patient_on(INTERVAL.start_date).exists_for_patient())
    )

### 


########################

# Total outpatient visits
measures.define_measure(
    name="total_opa",
    numerator=check_opa,
    denominator=denominator,
    )

##################


# Number of people with an outpatient visit
measures.define_measure(
    name="count_opa",
    numerator=count_opa,
    denominator=denominator,
    )

measures.define_measure(
    name="patients_opa",
    numerator=any_opa,
    denominator=denominator,
    )

# Number of people with a personalised follow-up visit
measures.define_measure(
    name="count_pfu",
    numerator=count_pfu,
    denominator=denominator & any_opa,
    )

measures.define_measure(
    name="patients_pfu",
    numerator=any_pfu,
    denominator=denominator & any_opa,
    )

# Number of people "moved" to personalised follow-up 
measures.define_measure(
    name="count_pfu_moved",
    numerator=count_pfu_moved,
    denominator=denominator & any_pfu,
    )

measures.define_measure(
    name="patients_pfu_moved",
    numerator=any_pfu_moved,
    denominator=denominator & any_pfu,
    )

# Number of people "discharged" to personalised follow-up
measures.define_measure(
    name="count_pfu_discharged",
    numerator=count_pfu_discharged,
    denominator=denominator & any_pfu,
    )

measures.define_measure(
    name="patients_pfu_discharged",
    numerator=any_pfu_discharged,
    denominator=denominator & any_pfu,
    )

###########################################


# Number of people with a rheum outpatient visit
measures.define_measure(
    name="count_rheum_opa",
    numerator=count_rheum_opa,
    denominator=denominator,
    )

measures.define_measure(
    name="patients_rheum_opa",
    numerator=any_rheum_opa,
    denominator=denominator,
    )

# Number of people with a personalised follow-up visit
measures.define_measure(
    name="count_rheum_pfu",
    numerator=count_rheum_pfu,
    denominator=denominator & any_rheum_opa,
    )

measures.define_measure(
    name="patients_rheum_pfu",
    numerator=any_rheum_pfu,
    denominator=denominator & any_rheum_opa,
    )

# Number of people "moved" to personalised follow-up 
measures.define_measure(
    name="count_rheum_pfu_moved",
    numerator=count_rheum_pfu_moved,
    denominator=denominator & any_rheum_pfu,
    )

measures.define_measure(
    name="patients_rheum_pfu_moved",
    numerator=any_rheum_pfu_moved,
    denominator=denominator & any_rheum_pfu,
    )

# Number of people "discharged" to personalised follow-up
measures.define_measure(
    name="count_rheum_pfu_discharged",
    numerator=count_rheum_pfu_discharged,
    denominator=denominator & any_rheum_pfu,
    )

measures.define_measure(
    name="patients_rheum_pfu_discharged",
    numerator=any_rheum_pfu_discharged,
    denominator=denominator & any_rheum_pfu,
    )
