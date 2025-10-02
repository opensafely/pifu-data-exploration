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


# By treatment specialty (only include top 10 most common groups reported in public statistics)
# from here: https://v3.datadictionary.nhs.uk/web_site_content/supporting_information/main_specialty_and_treatment_function_codes_table.asp%40shownav%3D1.html
all_opa.trt_func_code_gp= case(
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

all_pfu.trt_func_code_gp = case(
    when(all_pfu.treatment_function_code.is_in(["180","190","191","192","200","300","301","302","303",
        "304","305","306","307","308","309","310","311","313","314","315","317","318","319","320","322",
        "323","324","325","326","327","328","329","330","331","333","335","340","341","342","343","344","345",
        "346","347","348","350","352","360","361","370","371","400","401","410","420","422","424","430","431","450",
        "451","460","461","501","502","503","504","505","834"])).then("MED"),
    when(all_pfu.treatment_function_code.is_in(["100","101","102","103","104","105","106","107","108","109",
        "110","111","113","115","120","130","140","141","143","144","145","150","160","161","170","172","173","174"])).then("SUR"),
    when(all_pfu.treatment_function_code.is_in(["142","171","211","212","213","214","215","216","217","218","219",
        "220","221","222","223","230","240","241","242","250","251","252","253","254","255","256","257","258","259",
        "260","261","262","263","264","270","280","290","291","321","421"])).then("PAE"),
    when(all_pfu.treatment_function_code.is_in(["656","700","710","711","712","713","715","720","721","722","723",
        "724","725","726","727","730"])).then("MEN"),
    when(all_pfu.treatment_function_code.is_in(["560","650","651","652","653","654","655","657","658","659","660",
        "661","662","663","670","673","675","677","800","811","812","822","840","920"])).then("OTH"),
    otherwise=all_pfu.treatment_function_code
)


trt_func = ["110","120","330","410","101","502"]
trt_func_gp = ["MED","SUR","PAE","MEN","OTH"]

count_var = {}

for code in trt_func:

    count_var["any_opa_" + code] = all_opa.where(
        all_opa.treatment_function_code.is_in([code])
    ).exists_for_patient()

    count_var["any_pfu_" + code] = all_pfu.where(
        all_pfu.treatment_function_code.is_in([code])
    ).exists_for_patient()

    count_var["count_opa_" + code] = all_opa.where(
        all_opa.treatment_function_code.is_in([code])
    ).opa_ident.count_distinct_for_patient()
    
    count_var["count_pfu_" + code] = all_pfu.where(
        all_pfu.treatment_function_code.is_in([code])
    ).opa_ident.count_distinct_for_patient()

for code in trt_func_gp:

    count_var["any_opa_" + code] = all_opa.where(
        all_opa.trt_func_code_gp.is_in([code])
    ).exists_for_patient()

    count_var["any_pfu_" + code] = all_pfu.where(
        all_pfu.trt_func_code_gp.is_in([code])
    ).exists_for_patient()

    count_var["count_opa_" + code] = all_opa.where(
        all_opa.trt_func_code_gp.is_in([code])
    ).opa_ident.count_distinct_for_patient()
    
    count_var["count_pfu_" + code] = all_pfu.where(
        all_pfu.trt_func_code_gp.is_in([code])
    ).opa_ident.count_distinct_for_patient()



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
    intervals=months(41).starting_on("2022-01-01")
    )

########################

# Total outpatient visits
measures.define_measure(
    name="total_opa",
    numerator=check_opa,
    denominator=denominator,
    )

#########################


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


###########################################

for code in trt_func:
    measures.define_measure(
        name=f"any_opa_{code}",
        numerator=count_var["any_opa_" + code],
        denominator = denominator,
    )
    measures.define_measure(
        name=f"any_pfu_{code}",
        numerator=count_var["any_pfu_" + code],
        denominator = denominator & any_opa,
    )
    measures.define_measure(
        name=f"count_opa_{code}",
        numerator=count_var["count_opa_" + code],
        denominator = denominator,
    )
    measures.define_measure(
        name=f"count_pfu_{code}",
        numerator=count_var["count_pfu_" + code],
        denominator = denominator & any_opa,
    )
