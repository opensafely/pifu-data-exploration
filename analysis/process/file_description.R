# Description of outpatient_time* files 

#These files capture the number of outpatient attendances per 100 patients over 4-week periods relative to when patients 
#were placed on PIFU (patient-initiated follow-up). This was done for rheumatology, gastroenterology, and dermatology.
#The study population is all people who had a recorded flag for having been placed on a PIFU pathway for each
#specialty. 

#- n_patients: Number of patients with a PIFU flag who were still alive and registered in that 4-week period;
#- n_attendances: Number of outpatient attendances in that 4-week period;
#- time: Time period;
#- period: Whether the time period is pre- or post- being placed on a PIFU pathway;
#- type: Whether the row is for people MOVED (4) vs DISCHARGED (5) to a PIFU pathway, or all combined (NA);
#- group: Whether the row is group by type ("PFU type"), or all combined ("All PFU");
#- specialist: Whether the attendances included are ALL outpatient attendances, or just those for the given specialty (rheumatology, gastro, dermatology).
