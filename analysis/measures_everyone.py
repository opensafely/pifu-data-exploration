#################################################################
# This code extracts monthly counts of people on personalised
#   folloup pathways
#################################################################

from ehrql import months, INTERVAL, Measures, get_parameter
from ehrql.tables.tpp import (
    patients, 
    practice_registrations,
    opa)

from codelists import *

region = practice_registrations.for_patient_on(INTERVAL.start_date).practice_nuts1_region_name

# All OP visits that were attended
all_opa = opa.where(
        opa.appointment_date.is_on_or_between(INTERVAL.start_date, INTERVAL.end_date)
        & opa.attendance_status.is_in(["5","6"])
    )

# All PIFU visits that were attended
pfu_only = opa.where(
        opa.appointment_date.is_on_or_between(INTERVAL.start_date, INTERVAL.end_date)
        & opa.attendance_status.is_in(["5","6"])
        & opa.outcome_of_attendance.is_in(["4","5"])
    )

any_opa = all_opa.exists_for_patient()
any_pfu = pfu_only.exists_for_patient()
any_pfu4 = (
    pfu_only
    .where(pfu_only.outcome_of_attendance.is_in(["4"]))
    .exists_for_patient()
)
any_pfu5 = (
    pfu_only
    .where(pfu_only.outcome_of_attendance.is_in(["5"]))
    .exists_for_patient()
)

count_opa = all_opa.opa_ident.count_distinct_for_patient()
count_pfu = pfu_only.opa_ident.count_distinct_for_patient()
count_pfu4 = (
    pfu_only
    .where(pfu_only.outcome_of_attendance.is_in(["4"]))
    .opa_ident.count_distinct_for_patient()
)
count_pfu5 = (
    pfu_only
    .where(pfu_only.outcome_of_attendance.is_in(["5"]))
    .opa_ident.count_distinct_for_patient()
)

### Measures setup
measures = Measures()
measures.configure_disclosure_control(enabled=False)
measures.configure_dummy_data(population_size=1000)

denominator = (
        (patients.age_on(INTERVAL.start_date) >= 0)
        & (patients.age_on(INTERVAL.start_date) < 110)
        & ((patients.sex == "male") | (patients.sex == "female"))
        & (patients.date_of_death.is_after(INTERVAL.start_date) | patients.date_of_death.is_null())
        & (practice_registrations.for_patient_on(INTERVAL.start_date).exists_for_patient())
    )

measures.define_defaults(
    intervals=months(60).starting_on("2021-07-01")
    )

###################################################

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
measures.define_measure(
    name="count_pfu4",
    numerator=count_pfu4,
    denominator=denominator & any_opa,
    )
measures.define_measure(
    name="patients_pfu4",
    numerator=any_pfu4,
    denominator=denominator & any_opa,
    )
measures.define_measure(
    name="count_pfu5",
    numerator=count_pfu5,
    denominator=denominator & any_opa,
    )
measures.define_measure(
    name="patients_pfu5",
    numerator=any_pfu5,
    denominator=denominator & any_opa,
    )

##################################################

# By region
measures.define_measure(
    name="count_opa_region",
    numerator=count_opa,
    denominator=denominator,
    group_by={"region": region}
    )
measures.define_measure(
    name="patients_opa_region",
    numerator=any_opa,
    denominator=denominator,
    group_by={"region": region}
    )
measures.define_measure(
    name="count_pfu_region",
    numerator=count_pfu,
    denominator=denominator & any_opa,
    group_by={"region": region}
    )
measures.define_measure(
    name="patients_pfu_region",
    numerator=any_pfu,
    denominator=denominator & any_opa,
    group_by={"region": region}
    )