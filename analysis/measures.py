#################################################################
# This code extracts monthly counts of people on personalised
#   folloup pathways, stratified by relevant characteristics
#################################################################


from ehrql import months, INTERVAL, Measures, case, when, weeks
from ehrql.tables.tpp import (
    patients, 
    practice_registrations,
    clinical_events,
    opa)


# Extract data in interval
all_opa = opa.where(
        opa.appointment_date.is_on_or_between(INTERVAL.start_date, INTERVAL.end_date)
    )
all_pfu = opa.where(
        opa.appointment_date.is_on_or_between(INTERVAL.start_date, INTERVAL.end_date)
        & opa.outcome_of_attendance.is_in(["4","5"])
    )

# Any outpatient visit - total and personalised 
any_opa = all_opa.exists_for_patient()
any_pfu = all_pfu.exists_for_patient()

# Number of outpatient visits - total and personalised
count_opa = all_opa.count_for_patient()
count_pfu = all_pfu.count_for_patient()


### Measures setup
measures = Measures()
measures.configure_disclosure_control(enabled=False)
measures.define_defaults(intervals=months(72).starting_on("2019-01-01"))
measures.configure_dummy_data(population_size=1000)

denominator = (
        (patients.age_on(INTERVAL.start_date) >= 18) 
        & (patients.age_on(INTERVAL.start_date) < 110)
        & ((patients.sex == "male") | (patients.sex == "female"))
        & (patients.date_of_death.is_after(INTERVAL.start_date) | patients.date_of_death.is_null())
        & (practice_registrations.for_patient_on(INTERVAL.start_date).exists_for_patient())
    )

### 

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

# Number of people with an a personalised follow-up visit
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


