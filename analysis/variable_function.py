####################################################################

from ehrql import create_dataset, case, when, years, days, minimum_of
from ehrql.tables.tpp import patients, practice_registrations, ons_deaths, addresses

dataset = create_dataset()
dataset.configure_dummy_data(population_size=9000)

def opa_characteristics(all_opa, pfu_only):

    # everyone with an outpatient visit
    first_opa = all_opa.where(
            all_opa.appointment_date.is_on_or_after("2022-06-01")
        ).sort_by(
            all_opa.appointment_date
        ).first_for_patient()
    
    # first personalised pathway record
    first_pfu = pfu_only.sort_by(
            pfu_only.appointment_date
        ).first_for_patient() 
    
    dataset.first_pfu_date = first_pfu.appointment_date
    dataset.first_pfu_year = dataset.first_pfu_date.year
    dataset.trt_func_code = first_opa.treatment_function_code
    dataset.pfu_trt_func_code = first_pfu.treatment_function_code
    dataset.first_pfu_type = first_pfu.outcome_of_attendance

    dataset.any_pfu_2022 = pfu_only.where(
        pfu_only.appointment_date.is_on_or_between("2022-01-01","2022-12-31")
    ).exists_for_patient()
    dataset.any_pfu_2023 = pfu_only.where(
        pfu_only.appointment_date.is_on_or_between("2023-01-01","2023-12-31")
    ).exists_for_patient()
    dataset.any_pfu_2024 = pfu_only.where(
        pfu_only.appointment_date.is_on_or_between("2024-01-01","2024-12-31")
    ).exists_for_patient()
    dataset.any_pfu_2025 = pfu_only.where(
        pfu_only.appointment_date.is_on_or_between("2025-01-01","2025-12-31")
    ).exists_for_patient()

    dataset.any_pfu = dataset.first_pfu_date.is_not_null() 
    dataset.count_pfu = pfu_only.opa_ident.count_distinct_for_patient() # number of pfu records
    dataset.count_opa = all_opa.where(
            all_opa.appointment_date.is_on_or_after("2022-06-01")
        ).opa_ident.count_distinct_for_patient() # number of outpatient attendances
    dataset.first_opa_date = first_opa.appointment_date
    dataset.any_opa = first_opa.exists_for_patient()

    ###################################

    # outpatient visits before start of personalised followup
    dataset.before_3yr = all_opa.where(
            all_opa.appointment_date.is_on_or_between(dataset.first_pfu_date - years(3), dataset.first_pfu_date - days(1))
        ).opa_ident.count_distinct_for_patient()
    dataset.before_2yr = all_opa.where(
            all_opa.appointment_date.is_on_or_between(dataset.first_pfu_date - years(2), dataset.first_pfu_date - days(1))
        ).opa_ident.count_distinct_for_patient()
    dataset.before_1yr = all_opa.where(
            all_opa.appointment_date.is_on_or_between(dataset.first_pfu_date - years(1), dataset.first_pfu_date - days(1))
        ).opa_ident.count_distinct_for_patient()
    
    # outpatient visits after start of personalised followup
    dataset.after_1yr = all_opa.where(
            all_opa.appointment_date.is_on_or_between(dataset.first_pfu_date + days(1), dataset.first_pfu_date + years(1))
        ).opa_ident.count_distinct_for_patient()
    dataset.after_2yr = all_opa.where(
            all_opa.appointment_date.is_on_or_between(dataset.first_pfu_date + days(1), dataset.first_pfu_date + years(2))
        ).opa_ident.count_distinct_for_patient()

    # time from last / to next outpatient visit from start of personalised follow-up
    dataset.before_last_date = all_opa.where(
            all_opa.appointment_date.is_on_or_between(dataset.first_pfu_date - years(3), dataset.first_pfu_date - days(1))
        ).sort_by(
            all_opa.appointment_date
        ).last_for_patient().appointment_date
    dataset.after_next_date = all_opa.where(
            all_opa.appointment_date.is_after(dataset.first_pfu_date)
        ).sort_by(
            all_opa.appointment_date
        ).first_for_patient().appointment_date

    ###################################

    # demographics
    dataset.sex = patients.sex

    dataset.age_opa = patients.age_on(dataset.first_opa_date)
    dataset.age_opa_group = case(
            when(dataset.age_opa < 18).then("0-17"),
            when(dataset.age_opa < 30).then("18-29"),
            when(dataset.age_opa < 40).then("30-39"),
            when(dataset.age_opa < 50).then("40-49"),
            when(dataset.age_opa < 60).then("50-59"),
            when(dataset.age_opa < 70).then("60-69"),
            when(dataset.age_opa < 80).then("70-79"),
            when(dataset.age_opa < 90).then("80-89"),
            when(dataset.age_opa >= 90).then("90+"),
            otherwise="missing",
    )

    dataset.age_pfu = patients.age_on(dataset.first_pfu_date)
    dataset.age_pfu_group = case(
            when(dataset.age_pfu < 18).then("0-17"),
            when(dataset.age_pfu < 30).then("18-29"),
            when(dataset.age_pfu < 40).then("30-39"),
            when(dataset.age_pfu < 50).then("40-49"),
            when(dataset.age_pfu < 60).then("50-59"),
            when(dataset.age_pfu < 70).then("60-69"),
            when(dataset.age_pfu < 80).then("70-79"),
            when(dataset.age_pfu < 90).then("80-89"),
            when(dataset.age_pfu >= 90).then("90+"),
            otherwise="missing",
    )

    dataset.region = practice_registrations.for_patient_on(dataset.first_opa_date).practice_nuts1_region_name
    dataset.imd_decile = addresses.for_patient_on(dataset.first_opa_date).imd_decile
    dataset.deregister_date = practice_registrations.for_patient_on(dataset.first_opa_date).end_date
    dataset.tpp_dod = patients.date_of_death
    dataset.ons_dod = ons_deaths.date
    dataset.dod = minimum_of(dataset.tpp_dod, dataset.ons_dod)
    dataset.fu_days = (minimum_of(dataset.dod, dataset.deregister_date, "2025-05-31") - dataset.first_pfu_date).days

    return dataset

