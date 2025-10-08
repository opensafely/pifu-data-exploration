####################################################################
####################################################################


from ehrql import create_dataset, case, when, years, days, weeks, minimum_of
from ehrql.tables.tpp import patients, practice_registrations, clinical_events, opa, ons_deaths

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
    
    dataset.pfu_cat = first_pfu.outcome_of_attendance
    dataset.first_pfu_date = first_pfu.appointment_date
    dataset.first_pfu_year = dataset.first_pfu_date.year
    dataset.any_pfu = dataset.first_pfu_date.is_not_null() 
    dataset.count_pfu = pfu_only.opa_ident.count_distinct_for_patient() # number of pfu records
    dataset.count_opa = all_opa.where(
            all_opa.appointment_date.is_on_or_after("2022-06-01")
        ).opa_ident.count_distinct_for_patient() # number of outpatient attendances
    dataset.first_opa_date = first_opa.appointment_date
    dataset.any_opa = first_opa.exists_for_patient()

    # By treatment specialty (only include top 10 most common groups reported in public statistics)
    # from here: https://v3.datadictionary.nhs.uk/web_site_content/supporting_information/main_specialty_and_treatment_function_codes_table.asp%40shownav%3D1.html
    all_opa.trt_func_code_gp = case(
        when(all_opa.treatment_function_code.is_in(["180","190","191","192","200","300","301","302","303",
            "304","305","306","307","308","309","310","311","313","314","315","317","318","319","320","322",
            "323","324","325","326","327","328","329","330","331","333","335","340","341","342","343","344","345",
            "346","347","348","350","352","360","361","370","371","400","401","410","420","422","424","430","431","450",
            "451","460","461","501","502","503","504","505","834"])).then("MED"),
        when(all_opa.treatment_function_code.is_in(["100","101","102","103","104","105","106","107","108","109",
            "110","111","113","115","120","130","140","141","143","144","145","150","160","161","170","172","173","174"])).then("SUR"),
        when(all_opa.treatment_function_code.is_in(["142","171","211","212","213","214","215","216","217","218","219",
            "220","221","222","223","230","240","241","242","250","251","252","253","254","255","256","257","258","259",
            "260","261","262","263","264","270","280","290","291","321","421"])).then("PAE"),
        when(all_opa.treatment_function_code.is_in(["656","700","710","711","712","713","715","720","721","722","723",
            "724","725","726","727","730"])).then("MEN"),
        when(all_opa.treatment_function_code.is_in(["560","650","651","652","653","654","655","657","658","659","660",
            "661","662","663","670","673","675","677","800","811","812","822","840","920"])).then("OTH"),
        otherwise=all_opa.treatment_function_code
    )

    pfu_only.trt_func_code_gp = case(
        when(pfu_only.treatment_function_code.is_in(["180","190","191","192","200","300","301","302","303",
            "304","305","306","307","308","309","310","311","313","314","315","317","318","319","320","322",
            "323","324","325","326","327","328","329","330","331","333","335","340","341","342","343","344","345",
            "346","347","348","350","352","360","361","370","371","400","401","410","420","422","424","430","431","450",
            "451","460","461","501","502","503","504","505","834"])).then("MED"),
        when(pfu_only.treatment_function_code.is_in(["100","101","102","103","104","105","106","107","108","109",
            "110","111","113","115","120","130","140","141","143","144","145","150","160","161","170","172","173","174"])).then("SUR"),
        when(pfu_only.treatment_function_code.is_in(["142","171","211","212","213","214","215","216","217","218","219",
            "220","221","222","223","230","240","241","242","250","251","252","253","254","255","256","257","258","259",
            "260","261","262","263","264","270","280","290","291","321","421"])).then("PAE"),
        when(pfu_only.treatment_function_code.is_in(["656","700","710","711","712","713","715","720","721","722","723",
            "724","725","726","727","730"])).then("MEN"),
        when(pfu_only.treatment_function_code.is_in(["560","650","651","652","653","654","655","657","658","659","660",
            "661","662","663","670","673","675","677","800","811","812","822","840","920"])).then("OTH"),
        otherwise=pfu_only.treatment_function_code
    )


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
    
    # outpatient visits 1 year after start of personalised followup
    dataset.after_1yr = all_opa.where(
            all_opa.appointment_date.is_on_or_between(dataset.first_pfu_date + days(1), dataset.first_pfu_date + years(1))
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

    dataset.days_from_last_visit = (dataset.first_pfu_date - dataset.before_last_date).days
    dataset.days_to_next_visit = (dataset.after_next_date - dataset.first_pfu_date).days


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

    dataset.deregister_date = practice_registrations.for_patient_on(dataset.first_opa_date).end_date
    
    dataset.tpp_dod = patients.date_of_death

    dataset.ons_dod = ons_deaths.date

    dataset.dod = minimum_of(dataset.tpp_dod, dataset.ons_dod)

    dataset.fu_days = (minimum_of(dataset.dod, dataset.deregister_date, "2025-05-31") - dataset.first_pfu_date).days

    return dataset

