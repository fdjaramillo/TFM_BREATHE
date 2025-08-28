# contexto general
Actualmente estoy cursando un máster en análisis de datos omicos. Paralelamente estoy trabajando en un estudio clínico observacional BREATHE de pacientes asmáticos que detallo más abajo. La situación es la siguiente: Para mi tesis de máster, tengo que realizar un proyecto final, para lo cual voy a aprovechar los datos disponibles de este estudio BREATHE. Mi proyecto debe usar los datos de 60 pacientes (HCB001 a HCB060) disponibles hasta el momento, recopilados durante la visita basal en el Hospital Clínic de Barcelona. 

# structure of the WRITTEN REPORT:

The written report is the first thing the members of the committee will evaluate. Thus, the written report has a very important value and requires a precise and accurate writing, with a formal presentation and linguistic accuracy that is proper of a university level.

Since this is a Master in Data Analysis/Bioinformatics, you should provide enough information on the bioinformatic part of the project so that the jury is able to evaluate the value and difficulty of the computational part: description of pipelines, computational workflows, description of computational tools used or developed.

It is recommended to upload the code used at Github and providing the link in the Methods Section.Supplementary data file can also be submitted as a link.


WRITTEN REPORT IN THE FORM OF A SCIENTIFIC PAPER :

Usual structure of a scientific paper: summary (abstract), introduction, material and methods, results and conclusions. Goals should be added at the end of the Introduction section.
The length of the paper should be less than 15 pages. Additional material that you consider is important for the evaluation of your work should be placed as Supplementary Material. A link to the Supplementary Material should be available within the manuscript.
The paper should be completely written by the student.


# summary of the BREATHE study

Section 1: General Information

Title: Blocking Respiratory Exacerbations: AI and Data-Driven Technology for Health Enhancement
Protocol Code: BREATHE-01
Version: 2.0, dated July 1, 2024
Sponsor: Eversens S.L.
Principal Investigators: Irina Diana Bobolea Popa (Spain), Cláudia Loureiro (Portugal)
Study Sites: Hospital Clínic de Barcelona and Centro Hospitalar e Universitário de Coimbra

Study Design:
This is an observational, randomized, prospective, open-label study with two parallel groups. It aims to evaluate the ability of daily FeNO (Fractional Exhaled Nitric Oxide) measurements to predict asthma exacerbations.

Study Population:
The study will include 120 patients aged 18 to 80 years with a confirmed diagnosis of Type 2 severe asthma, with or without upper airway comorbidities.

Primary Objective:
To assess whether daily FeNO measurements can forecast asthma exacerbations.

Secondary Objectives:

To evaluate a combined risk indicator that includes FeNO, disease-related information, and standardized questionnaires.
To compare the predictive power of FeNO alone versus the combined indicator.
To assess the performance of the Evernoa solution in terms of sensitivity, specificity, positive predictive value, and negative predictive value.
To evaluate the usability of the Evernoa solution in a home setting.
Primary Endpoint:
Concordance index (C-index) of FeNO as a prognostic indicator of asthma exacerbations.

Secondary Endpoints:

C-index of the Evernoa risk indicator
Sensitivity, specificity, positive and negative predictive values
Cost-effectiveness of home FeNO monitoring
Benefit-risk analysis
User satisfaction score
Error history and patient-reported difficulties
Section 1: General Information

Device Description:
Evernoa LUX is a CE-marked in vitro diagnostic device designed to measure nitric oxide in exhaled breath. It provides automated, quantitative FeNO readings in parts per billion.

Intended Use:
FeNO is a biomarker for airway inflammation. It is useful for diagnosing asthma, monitoring treatment response, identifying steroid responsiveness, and predicting exacerbations.

Users:

Healthcare professionals in clinical settings
Patients or caregivers at home, after receiving training
Use Environment:

Clinical and home settings
Environmental conditions: temperature 10 to 30 degrees Celsius, humidity 25 to 75 percent, atmospheric pressure 91.19 to 111.45 kPa
Avoid use in areas with volatile organic compounds
Device Components:

Mouthpiece connector
LED indicator (Bluetooth, charging, low battery)
Power port
Accessories:

Evernoa App for remote control and data entry
CE-marked bacterial and viral filters
Training:
Training is mandatory for both investigators and patients. Materials include manuals, videos, quick guides, and FAQs.

Indications Under Investigation:

Extending use from clinical to home environments
Evaluating FeNO’s predictive capabilities
Assessing a combined risk indicator
Sponsor Contact:
Eversens S.L., Pamplona, Spain

Investigators:

Irina Diana Bobolea Popa (Hospital Clínic de Barcelona)
Cláudia Loureiro (CHUC, Coimbra)
Co-Investigators:
Includes specialists in pulmonology, allergology, and ENT from both centers

Clinical Sites:
Selected based on infrastructure, experience, and patient availability

Study Duration:
17 months total
Each patient will be observed for 24 weeks

Section 2: Rationale for the Study

Asthma is the most common chronic respiratory disease worldwide, affecting more than 360 million people across all age groups. Despite significant advances in asthma management, including the introduction of inhaled corticosteroids and educational initiatives, asthma outcomes have plateaued. Hospitalizations and mortality rates are once again increasing (McIntyre A, 2022; Global Initiative for Asthma, 2022; Spanish Society of Pulmonology and Thoracic Surgery, 2023).

Exacerbations, or asthma attacks, are particularly problematic. They cause severe breathlessness, impaired lung function, and in severe cases, respiratory failure and potentially death. Patients may also experience a diminished quality of life, such as missing work or school, being excluded from sports, not getting regular exercise, and struggling with everyday activities (Global Initiative for Asthma, 2021).

In the long term, asthma can lead to additional complications. Frequent exacerbations can cause harmful changes in the airways and a significant decline in lung function. Studies show that lung function deteriorates twice as fast in patients who frequently experience exacerbations. Moreover, untreated exacerbation risks increase healthcare costs due to unscheduled doctor visits and hospital stays (Tsuburai, 2017). Exacerbations are a major contributor to the overall burden of asthma, leading to significant health, social, and economic impacts.

Current guidelines for managing asthma have limitations in preventing exacerbations. These events often occur suddenly and are triggered by factors such as upper respiratory tract infections, allergen exposure, and non-adherence to treatment (McDonald VM, 2019). Traditional asthma management strategies, which typically involve biannual clinical consultations, fail to capture the rapid changes in patient condition that can lead to exacerbations. This approach often results in reactive rather than proactive care, with interventions occurring only after an exacerbation has already taken place (Sabatelli, 2017).

To address these shortcomings, there is a critical need for more dynamic and continuous monitoring of personal risk factors associated with asthma exacerbations (Castillo JA, 2023).

Fractional exhaled nitric oxide (FeNO) levels have been identified as a key biomarker linked to exacerbation risk. However, the current practice of measuring FeNO during infrequent consultations does not adequately capture the rapid fluctuations in nitric oxide levels that can signal impending exacerbations (McIntyre A, 2022). Studies have demonstrated that changes in FeNO can occur within days or even hours, underscoring the need for regular monitoring to effectively predict and prevent asthma attacks.

In addition to being a good predictor of exacerbation risk, FeNO is also a helpful indicator for optimizing treatment selection (Hanania, Massanari, and Jain, 2018) and assessing patient adherence to medication, both of which are key parameters for asthma control (Apter A, 2021).

The primary objective of this clinical performance study is to evaluate the prognostic value of FeNO as an indicator of asthma exacerbation risk (MedTech Europe, 2023).

The secondary objectives are:

To evaluate the ability of a risk indicator to forecast asthma exacerbations. This indicator will combine regularly measured FeNO values with scientifically validated risk factors, disease-related information, and standardized questionnaires.
To compare the predictive ability of FeNO alone versus a combined indicator that includes other risk factors.
To evaluate other performance parameters of the Evernoa LUX device, including sensitivity, specificity, positive predictive value, and negative predictive value.
To evaluate the usability of the Evernoa solution in a home environment.
A longitudinal observational study design has been chosen to capture the dynamic nature of asthma and the rapid changes in risk factors that contribute to exacerbations. This design allows for continuous monitoring of FeNO levels and other relevant biomarkers, providing regular data that will be analyzed at the completion of the study to evaluate the prognostic value of the risk indicator.

We hypothesize that regular monitoring of FeNO along with other risk factors will lead to the identification of patients at risk of experiencing an exacerbation.

Section 3: Objectives and Purpose
Primary Objective: Evaluate whether daily FeNO measurements can predict asthma exacerbations.
Secondary Objectives:
Assess a combined risk indicator (FeNO + clinical data + standardized questionnaires).
Compare predictive power of FeNO alone vs. the combined indicator.
Evaluate Evernoa’s performance: sensitivity, specificity, positive and negative predictive values.
Analyze cost-effectiveness, benefit-risk ratio, and usability in home settings.
Endpoints:
Primary: Concordance index (C-index) of FeNO.
Secondary: C-index of Evernoa indicator, performance metrics, cost-effectiveness, user satisfaction, error history, patient-reported difficulties.
Section 4: Study Design
Type: Observational, randomized, open-label, two parallel groups.
Groups:
G1: Standard of Care.
G2: Standard of Care + Evernoa monitoring.
Duration: 17 months total; 24 weeks per patient.
Inclusion Criteria: Age 18–80, confirmed diagnosis of severe T2 asthma, informed consent.
Exclusion Criteria: Recent exacerbation, other severe respiratory diseases, pregnancy.
Visits: Baseline, daily monitoring (G2), final visit.
Section 5: Variables and Questionnaires
Collected Data: Demographics, environmental conditions, clinical history, FeNO, spirometry, blood eosinophils.
Questionnaires:
TAI (inhaler adherence), Mini-AQLQ (quality of life), ACT and ACQ (asthma control), AIRQ, CARAT, SNOT22, LoS, CRS Severity.
FeNO Measurement:
Daily in G2; baseline and final visits for all.
Data sent anonymously to Evernoa server; not visible to patients or clinicians.
Usability:
Assessed via questionnaire and test.
User Satisfaction Score (USS) calculated; score ≥3 indicates good usability.
Section 6: Statistical Considerations
Analysis:
ROC curve (AUC), C-index, sensitivity, specificity, PPV, NPV.
Negative binomial regression for annual exacerbation rate.
Fisher’s exact test, t-test, Mann-Whitney U test.
Sample Size:
60 per group (120 total), accounting for 20% dropout.
Expected AUC = 0.8; estimated exacerbation rate = 56.4%.
Software: SAS 9.4 or higher.
Usability Metrics:
Weighted: ease of use (40%), clarity (30%), comfort (20%), satisfaction (10%).
Section 7: Suspension or Early Termination
Reasons:
Safety concerns.
Protocol deviations.
Regulatory non-compliance.
Decision Process:
Led by Principal Investigator, in consultation with sponsor and authorities.
Section 8: Data Management
Confidentiality:
GDPR-compliant, anonymized data.
Codified identifiers, secure storage.
Security:
HTTPS, Docker, PostgreSQL, AES-256 encryption, SSL/TLS.
Role-based access, session tokens, multi-factor authentication.
eCRF:
MACRO® system, validated, traceable.
Storage:
Minimum 10 years.
Consent requested for AI training use.
Section 9: Ethical and Legal Aspects
Ethics:
Declaration of Helsinki, Good Clinical Practice.
Ethics Committee approval required.
Benefit-Risk Assessment:
No added risk compared to routine care.
Benefits: 40% fewer exacerbations, improved quality of life, €440/year savings, 0.05 QALYs gained.
Prescribing Habits:
No interference; standard care maintained.
