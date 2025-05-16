
from ehrql import months, INTERVAL, Measures, case, when, weeks
from ehrql.tables.tpp import (
    patients, 
    practice_registrations,
    clinical_events,
    opa)


### Demographics

#sex = patients.sex
#age = patients.age_on("2022-04-01")
#age_group = case(
#        when(age < 30).then("18-29"),
#        when(age < 40).then("30-39"),
#        when(age < 50).then("40-49"),
#        when(age < 60).then("50-59"),
#        when(age < 70).then("60-69"),
#        when(age < 80).then("70-79"),
#        when(age < 90).then("80-89"),
#        when(age >= 90).then("90+"),
#        otherwise="missing",
#)

### outpatient stuff

opa = opa.where(
            opa.appointment_date.is_on_or_between(INTERVAL.start_date, INTERVAL.end_date)
        ).sort_by(
            opa.appointment_date
        ).first_for_patient()
any_opa = opa.exists_for_patient()

treatment_function_code = opa.treatment_function_code
outcome_of_attendance = opa.outcome_of_attendance
personal_pathway = opa.outcome_of_attendance.is_in("4","5")

### measures setup

measures = Measures()
measures.configure_disclosure_control(enabled=False)
measures.define_defaults(intervals=weeks(208).starting_on("2021-01-01"))
measures.configure_dummy_data(population_size=10000)

denominator = (
        (patients.age_on(INTERVAL.start_date) >= 0) 
        & (patients.age_on(INTERVAL.start_date) < 110)
        & ((patients.sex == "male") | (patients.sex == "female"))
        & (patients.date_of_death.is_after(INTERVAL.start_date) | patients.date_of_death.is_null())
        & (practice_registrations.for_patient_on(INTERVAL.start_date).exists_for_patient())
    )

### 

measures.define_measure(
    name="any_opa",
    numerator=any_opa,
    denominator=denominator,
    )

measures.define_measure(
    name="opa_by_specialty",
    numerator=any_opa,
    denominator=denominator,
    group_by={"treatment_function_code": treatment_function_code}
    )

measures.define_measure(
    name="outcome_of_attendance",
    numerator=any_opa,
    denominator=denominator,
    group_by={"outcome_of_attendance": outcome_of_attendance}
    )

measures.define_measure(
    name="personalised_pathway",
    numerator=any_opa,
    denominator=denominator,
    group_by={"personal_pathway": personal_pathway}
    )

measures.define_measure(
    name="personalised_pathway",
    numerator=personal_pathway,
    denominator=denominator,
    group_by={"treatment_function_code": treatment_function_code}
    )
