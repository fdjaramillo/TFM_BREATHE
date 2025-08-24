# -----------------------------------------------------------------------------
# SCRIPT: 01_process_macro_data.R
# OBJETIVO: Cargar, limpiar y transformar los datos exportados de MACRO.
# Esta versión es una refactorización directa de tu Rmd original.
# -----------------------------------------------------------------------------

library(tidyverse)
library(stringr)
library(stringi)

process_macro_data <- function(raw_path, processed_path) {
  
  # --- 1. Carga de Datos ---
  macro_input_path <- file.path(raw_path, "macro_download", "processed")
  macro_files <- list.files(macro_input_path, full.names = TRUE)
  
  macro_names <- macro_files |>
    str_remove(fixed(macro_input_path)) |>
    str_remove("^/") |>
    str_remove("\\.csv$")
  
  macro_data <- lapply(macro_files, read_csv, show_col_types = FALSE, col_types = cols(.default = "c"))
  names(macro_data) <- macro_names
  
  # --- 2. Limpieza en Formato Largo (Usando tus diccionarios) ---
  rename_dict_question <- c(
    "allergic_sensitization" = "sensitization",
    "prick_test_collected_in_the_last_3_years" = "prick_test_last_3y",
    "specified_1" = "specify_1",
    
    "other_comorbidity_1" = "others_comorbidities_1",
    
    "age_years" = "age",
    "biiological_sex" = "sex",
    "does_have_descendents" = "has_descendants",
    "education_level" = "education",
    "employment_status" = "employment",
    "has_it_been_confirmed_that_you_are_not_pregnant" = "not_pregnant_confirmed",
    "number_of_sick_leaves_in_the_past_year" = "sick_leaves_past_year",
    "how_many_of_them_were_related_to_ashtma" = "asthma_sick_leaves",
    "net_monthly_income" = "income_annually",
    "number_of_dependent_children_in_care" = "dependent_children",
    "number_of_dependent_persons_in_care" = "dependent_persons",
    "number_of_descendents" = "descendants_n",
    
    "age_at_diagnosis" = "age_diagnosis",
    "control_gina" = "gina_control",
    "main_diagnosis" = "diagnosis",
    "severity_gina" = "gina_severity",
    
    "feno_ppb_evernoa_base_1st_measurement" = "feno_1",
    "feno_ppb_evernoa_base_2on_measurement" = "feno_2",
    "realiced" = "feno_done",
    "reason" = "feno_reason",
    
    "miniaql" = "miniaqlq",
    
    "years" = "smoking_years",
    "paciente_fumador" = "smoker",
    "sunum" = "packs_day",
    "year_in_which_started_smoking" = "smoking_start_year",
    "year_in_which_stopped_smoking" = "smoking_stop_year"
  )
  
  rename_dict_value <- c(
    # Comorbilidades: special names that may lose the meaning)
    "crswnp" = "crs_w_np",
    "crssnp" = "crs_s_np",
    
    "sleep apnea" = "sleeep apnea",
    "hypothyroidism" = "hipothyroidysm",
    
    # Diagnóstico
    "asthma and copd overlap" = "asthma and copd overlkad (aco)",
    
    # exacerbations
    "leve" = "mild",
    "seve" = "severe"
  )
  
  macro_data <- lapply(macro_data, function(df) {
    df |>
      mutate(
        question = str_to_lower(question) |> str_squish() |> str_remove_all("his/her|he/she") |> str_remove_all("[:punct:]") |> str_replace_all("\\s+", "_"),
        question = str_replace_all(question, sapply(rename_dict_question, coll)),
        value = str_to_lower(value) |> str_squish() |> str_replace_all(sapply(rename_dict_value, coll))
      )
  })
  
  # --- 3. Pivoteo y Transformaciones Finales ---
  
  macro_data_processed <- lapply(macro_data, function(df) {
    df |>
      mutate(
        value = case_when(
          is.na(value) & status == "Not Applicable" ~ "not applicable",
          TRUE ~ value
        )
      ) |>
      select(id, question, value) |>
      pivot_wider(id_cols = id, names_from = question, values_from = value)
  })
  
  # Eliminar dataframes que no se usarán más
  macro_data_processed[["allergic_sensitization"]] <- NULL
  
  # Aplicar transformaciones específicas a cada dataframe
  
  if ("comorbidities" %in% names(macro_data_processed)) {
    names <- macro_data_processed[["comorbidities"]] |> select(starts_with("type")) |> distinct() |> as_vector() |> str_replace_all(" ", "_")
    lookup <- paste0("yn_", seq_along(names))
    names(lookup) <- names
    macro_data_processed[["comorbidities"]] <- macro_data_processed[["comorbidities"]] |> rename(all_of(lookup)) |> select(!starts_with("type"))
  }
  
  if ("demographics" %in% names(macro_data_processed)) {
    macro_data_processed[["demographics"]] <- macro_data_processed[["demographics"]] |>
      mutate(across(c(height, weight), as.numeric), bmi = weight / (height / 100)^2) |>
      relocate(bmi, .after = weight) |>
      mutate(
        descendants_n = if_else(has_descendants == "no", "00", descendants_n),
        dependent_children = if_else(has_descendants == "no", "00", dependent_children),
        income_annually = if_else(is.na(income_annually), "prefer not to answer", income_annually),
        asthma_sick_leaves = if_else(sick_leaves_past_year == "00", "000", asthma_sick_leaves)
      )
  }
  
  if ("exacerbations" %in% names(macro_data_processed)) {
    macro_data_processed[["exacerbations"]] <- macro_data_processed[["exacerbations"]] |>
      select(id, exac_last_year = exacerbations_in_the_last_period, exac_last_year_n = total_number_of_exacerbations_in_the_period) |> 
      mutate(
        # complete the missing values
        exac_last_year_n = if_else(exac_last_year == "no", "00", exac_last_year_n),
      )
  }
  
  if ("smoking_habits" %in% names(macro_data_processed)) {
    smoking_extra <- tribble(
      ~id, ~packs_day, "HCB014", 0.5, "HCB026", 0.5, "HCB028", 0.286, "HCB034", 0.5, "HCB039", 0.5, "HCB048", 0.143,
      "HCB051", 0.5, "HCB052", 0.071, "HCB053", 0.25, "HCB055", 0.05, "HCB056", 0.002, "HCB060", 1.5
    )
    macro_data_processed[["smoking_habits"]] <- macro_data_processed[["smoking_habits"]] |>
      mutate(smoking_years = map_chr(smoking_years, ~ .x[2]), across(everything(), unlist), across(c(smoking_start_year, smoking_stop_year, packs_day), as.numeric)) |>
      left_join(smoking_extra, by = "id", suffix = c("", ".new")) |>
      mutate(packs_day = coalesce(packs_day.new, packs_day)) |> select(-packs_day.new) |>
      mutate(smoking_duration = abs(smoking_stop_year - smoking_start_year), pack_year = packs_day * smoking_duration,
             pack_year = if_else(smoker == "non-smoker", 0, pack_year)) |>
      select(id, smoker, smoking_duration, pack_year)
  }
  
  if ("feno" %in% names(macro_data_processed)) {
    macro_data_processed[["feno"]] <- macro_data_processed[["feno"]] |>
      mutate(across(c(feno_1, feno_2), as.numeric), feno_mean = (feno_1 + feno_2) / 2,
             feno_mean = if_else(is.na(feno_mean), feno_1, feno_mean))
  }
  
  
  macro_final_df <- macro_data_processed |>
    reduce(full_join, by = "id")
  
  # --- 5. Guardar el resultado ---
  saveRDS(macro_final_df, file = file.path(processed_path, "macro_data.rds"))
  print(paste("Datos de MACRO procesados y guardados en:", file.path(processed_path, "macro_data.rds")))
}
