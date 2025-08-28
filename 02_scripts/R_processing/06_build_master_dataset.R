# -----------------------------------------------------------------------------
# SCRIPT: 06_build_master_dataset.R
# OBJETIVO: Cargar todos los ficheros de datos procesados, unirlos en un
#           único dataset maestro y prepararlo para el EDA.
# -----------------------------------------------------------------------------
library(tidyverse)

build_master_dataset <- function(processed_path, selected_variables = NULL) {
  
  # --- 1. Cargar y Unir todos los Ficheros Procesados ---
  
  files_to_load <- list.files(
    path = processed_path,
    pattern = "\\.rds$",
    full.names = TRUE
  )
  # remove master_dataset.rds if exists
  files_to_load <- files_to_load[!str_detect(files_to_load, "master_dataset.rds")]
  
  list_of_datasets <- files_to_load |>
    map(~ readRDS(.x))
  
  master_dataset <- list_of_datasets |>
    reduce(full_join, by = "id")
  
  # --- 3. Dfinir tipo de datos ---
  
  columnas_numericas <- c(
    "act", "age", "height", "weight", "bmi", "descendants_n", "dependent_children",
    "dependent_persons", "sick_leaves_past_year", "asthma_sick_leaves", "age_diagnosis",
    "exac_last_year_n", "feno_1", "feno_2", "feno_mean", "miniaqlq",
    "smoking_duration", "pack_year", "acq", "airq", "carat", "rcat", "snot22",
    "tai10", "los_vas", "rhinitis_vas", "leukocytes_n", "eosinophils_pct",
    "lymphocytes_pct", "eosinophils_n", "lymphocytes_n", "ige_total",
    "n_sensitizations", "fvc", "fev1", "fev1_fvc", "pct_pred_fvc",
    "pct_pred_fev1", "pct_pred_fev1_fvc"
  )
  
  columnas_categoricas <- c(
    "comorbidities", "allergic_rhinitis", "crs_w_np", "crs_s_np",
    "atopic_dermatitis", "eosinophilic_esophagitis", "others_comorbidities_1",
    "sex", "residence_area", "country_birth", "marital_status",
    "education", "social_class", "employment", "income_annually", "diagnosis",
    "gina_severity", "gina_control", "exac_last_year", "gina_step",
    "treatment", "smoker", "is_sensitized", "main_sensitization",
    "is_on_ics_laba", "is_on_lama", "is_on_triple_therapy", "is_on_ics",
    "is_on_antihistamine", "is_on_ics_antihistamine", "is_on_biologic", "is_on_ltra"
  )
  
  # --- 4. Selección Final de Variables para EDA ---
  
  # Variables por defecto si no se especifican
  if (is.null(selected_variables)) {
    variables_relevantes_eda <- c(
      "id", "age", "sex", "bmi", "diagnosis", "age_diagnosis", 
      "allergic_rhinitis", "crs_w_np", "exac_last_year_n",
      "miniaqlq", "act",
      "smoker", "pack_year", 
      "airq", "snot22", "tai10",
      "feno_mean", 
      "eosinophils_n", "eosinophils_pct" , "ige_total",
      "pct_pred_fev1", "pct_pred_fvc", "fev1_fvc", "fev1", "fvc",
      "is_on_biologic",
      "treatment"
    )
  } else {
    # Usar las variables especificadas por el usuario
    # Asegurarse de que 'id' esté incluido
    variables_relevantes_eda <- unique(c("id", selected_variables))
  }
  
  eda_dataset <- master_dataset |>
    select(any_of(variables_relevantes_eda)) |> 
    mutate(across(any_of(columnas_numericas), as.numeric)) |>
    mutate(across(any_of(columnas_categoricas), as.factor))
  
  print("Dataset maestro final construido y preparado para EDA.")
  return(eda_dataset)
}
