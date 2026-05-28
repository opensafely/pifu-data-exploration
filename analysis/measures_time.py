

from ehrql import create_dataset, case, when, years, days, weeks, show, Measures, INTERVAL, months, minimum_of
from ehrql.tables.tpp import patients, practice_registrations, clinical_events, opa, ons_deaths
from datetime import date

# all outpatient visits
all_opa = opa.where(
        opa.appointment_date.is_on_or_after("2020-01-01")
        & opa.treatment_function_code.is_in(["410"])
        & opa.attendance_status.is_in(["5","6"])
    )

# pfu only
pfu_only = all_opa.where(
        all_opa.outcome_of_attendance.is_in(["4","5"])
    )
    
# first personalised pathway record
first_pfu_date = pfu_only.sort_by(
        pfu_only.appointment_date
    ).first_for_patient().appointment_date

tmp_start_date = "2000-01-01"

all_opa.tmp_opa_date = tmp_start_date + days((all_opa.appointment_date - (first_pfu_date - days(720))).days)

count_opa = all_opa.where(
    all_opa.tmp_opa_date.is_during(INTERVAL)
    ).count_for_patient()

dod = minimum_of(patients.date_of_death, ons_deaths.date)

registrations = practice_registrations.spanning(
        first_pfu_date - days(182), first_pfu_date
    ).sort_by(
        practice_registrations.end_date
    ).last_for_patient()

reg_end_date = registrations.end_date
end_date = minimum_of(reg_end_date, dod, date(2026, 6, 30))

# Standardise end date relative to RTT start and end dates
tmp_end_date = tmp_start_date + days((end_date - (first_pfu_date - days(720))).days)

### Measures setup
measures = Measures()
measures.configure_disclosure_control(enabled=False)
measures.configure_dummy_data(population_size=10000)

denominator = (
    (patients.age_on(first_pfu_date) >= 18)
    & (patients.age_on(first_pfu_date) < 110)
    & ((patients.sex == "male") | (patients.sex == "female")) 
    & registrations.exists_for_patient()
    & first_pfu_date.is_on_or_before("2025-07-01") 
    & first_pfu_date.is_not_null()
    & (tmp_end_date.is_after(INTERVAL.end_date) | tmp_end_date.is_null())
)

measures.define_defaults(
    intervals = [
    (date(2000, 1, 1), date(2000, 1, 28)),
    (date(2000, 1, 29), date(2000, 2, 25)),
    (date(2000, 2, 26), date(2000, 3, 24)),
    (date(2000, 3, 25), date(2000, 4, 21)),
    (date(2000, 4, 22), date(2000, 5, 19)),
    (date(2000, 5, 20), date(2000, 6, 16)),
    (date(2000, 6, 17), date(2000, 7, 14)),
    (date(2000, 7, 15), date(2000, 8, 11)),
    (date(2000, 8, 12), date(2000, 9, 8)),
    (date(2000, 9, 9), date(2000, 10, 6)),
    (date(2000, 10, 7), date(2000, 11, 3)),
    (date(2000, 11, 4), date(2000, 12, 29)),
    (date(2000, 12, 30), date(2001, 1, 26)),
    (date(2001, 1, 27), date(2001, 2, 23)),
    (date(2001, 2, 24), date(2001, 3, 23)),
    (date(2001, 3, 24), date(2001, 4, 20)),
    (date(2001, 4, 21), date(2001, 5, 18)),
    (date(2001, 5, 19), date(2001, 6, 15)),
    (date(2001, 6, 16), date(2001, 7, 13)),
    (date(2001, 7, 14), date(2001, 8, 10)),
    (date(2001, 8, 11), date(2001, 9, 7)),
    (date(2001, 9, 8), date(2001, 10, 5)),
    (date(2001, 10, 6), date(2001, 11, 2))
    ]
    )

########################

# Total outpatient visits
measures.define_measure(
    name="opa_count",
    numerator=count_opa,
    denominator=denominator,
    )
