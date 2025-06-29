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
    ).first_for_patient()

check_pfu = check_opa.outcome_of_attendance.is_in(["4","5"])
consult_medium = check_opa.consultation_medium_used
attendance_status = check_opa.attendance_status
first_attendance = check_opa.first_attendance


# For study
all_opa = opa.where(
        opa.appointment_date.is_on_or_between(INTERVAL.start_date, INTERVAL.end_date)
        & opa.attendance_status.is_in(["5","6"])
    )

all_pfu = opa.where(
        opa.appointment_date.is_on_or_between(INTERVAL.start_date, INTERVAL.end_date)
        & opa.attendance_status.is_in(["5","6"])
        & opa.outcome_of_attendance.is_in(["4","5"])
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
any_pfu_rheum = all_pfu.where(
        all_pfu.treatment_function_code == "410"
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
count_pfu_rheum = all_pfu.where(
        all_pfu.treatment_function_code == "410"
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


# OPA descriptive
measures.define_measure(
    name="consult_medium",
    numerator=any_opa,
    denominator=any_opa,
    group_by={"consult_medium": consult_medium,
              "any_pfu": check_pfu}
    )

measures.define_measure(
    name="attendance_status",
    numerator=any_opa,
    denominator=any_opa,
    group_by={"attendance_status": attendance_status,
              "any_pfu": check_pfu}
    )

measures.define_measure(
    name="first_attendance",
    numerator=any_opa,
    denominator=any_opa,
    group_by={"first_attendance": first_attendance,
              "any_pfu": check_pfu}
    )


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

# Number of people with a rheumatology personalised follow-up visit
measures.define_measure(
    name="count_pfu_rheum",
    numerator=count_pfu_rheum,
    denominator=denominator & any_pfu,
    )

measures.define_measure(
    name="patients_pfu_rheum",
    numerator=any_pfu_rheum,
    denominator=denominator & any_pfu,
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
