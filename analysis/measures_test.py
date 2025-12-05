#################################################################
# This code extracts monthly counts of people on personalised
#   folloup pathways, stratified by relevant characteristics
#################################################################


from ehrql import months, INTERVAL, Measures, case, when
from ehrql.tables.tpp import (
    patients, 
    practice_registrations,
    opa)

from codelists import *


# For study
# All OP visits that were attended
all_opa = opa.where(
        opa.appointment_date.is_on_or_between(INTERVAL.start_date, INTERVAL.end_date)
        & opa.attendance_status.is_in(["5","6"])
    )

# Any outpatient visit
any_opa = all_opa.exists_for_patient()

# Number of outpatient visits 
count_opa = all_opa.opa_ident.count_distinct_for_patient()

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
    intervals=months(48).starting_on("2022-01-01")
    )

########################

measures.define_measure(
    name="count_opa",
    numerator=count_opa,
    denominator=denominator,
    )


