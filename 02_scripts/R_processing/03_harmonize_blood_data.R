# -----------------------------------------------------------------------------
# SCRIPT: 03_harmonize_blood_data.R
# OBJETIVO: Cargar, unir y armonizar los datos de análisis de sangre
#           de fuentes automáticas y manuales.
# -----------------------------------------------------------------------------
library(tidyverse)
library(stringr)

harmonize_blood_data <- function(raw_path, processed_path) {
  
  # === PARTE 1: Procesar Datos Automáticos (Lógica Original) ===
  
  # --- Cargar y procesar Hematología ---
  auto_hematology_path <- file.path(raw_path, "automatic_extraction", "blood_analysis", "hematology")
  hematology_files <- list.files(auto_hematology_path, full.names = TRUE)
  
  hematology_names <- sub(".*\\/", "", hematology_files) |> sub("\\.csv$", "", x = _)
  
  params_haemogram <- c("Leucòcits")
  params_leukocytes <- c("Eosinòfils", "Limfòcits")
  
  rename_dict <- c(
    "Leucòcits" = "leukocytes", "Eosinòfils" = "eosinophils", "Neutròfils" = "neutrophils",
    "Limfòcits" = "lymphocytes", "Monòcits" = "monocytes", "Plaquetes" = "platelets",
    "Hemoglobina" = "hemoglobin", "Hematòcrit" = "hematocrit",
    "Volum corpuscular mitjà" = "mean_corpuscular_volume",
    "Concentració d'hemoglobina corpuscular mitjà" = "mean_corpuscular_hemoglobin_concentration",
    "Amplitud de distribució de glòbuls vermells" = "red_blood_cell_distribution_width"
  )
  
  hematology_auto_list <- lapply(hematology_files, function(file) {
    read_csv(file, show_col_types = FALSE) |>
      mutate(
        parameter = str_squish(parameter),
        value = str_replace_all(value, "/[AB]", "") |> str_replace_all("[<>]", "") |> as.numeric()
      ) |>
      filter(parameter %in% c(params_haemogram, params_leukocytes)) |>
      mutate(parameter = str_replace_all(parameter, rename_dict)) |>
      pivot_wider(id_cols = id, names_from = c(parameter, unit), values_from = value) |>
      rename_with(~ str_replace_all(.x, " ", "_") |> str_replace_all("%", "pct") |> str_replace_all("10\\^9/L", "n"))
  }) |> setNames(hematology_names)
  
  # --- Cargar y procesar Inmunología ---
  auto_immuno_path <- file.path(raw_path, "automatic_extraction", "blood_analysis", "immunology")
  
  ige_total_auto <- read_csv(file.path(auto_immuno_path, "ige_total.csv"), show_col_types = FALSE) |>
    mutate(value = str_replace_all(value, "/[AB]|<|>", "") |> as.numeric()) |>
    rename(ige_total = value)
  
  ige_specific_auto <- read_csv(file.path(auto_immuno_path, "ige_specific.csv"), show_col_types = FALSE) |>
    mutate(
      value = str_replace_all(value, "/[AB]", ""),
      value = str_replace_all(value, "[<>]", ""),
      value = as.numeric(value)
    )
  # SAVE for later use
  long_format_path <- file.path(processed_path, "long_format_archive")
  dir.create(long_format_path, showWarnings = FALSE, recursive = TRUE)
  saveRDS(ige_specific_auto, file.path(long_format_path, "ige_specific_auto.rds"))

  ige_specific_summary <- ige_specific_auto |>
    group_by(id) |>
    summarise(
      is_sensitized = any(value >= 0.35),
      n_sensitizations = sum(value >= 0.35),
      main_sensitization = if (any(value >= 0.35)) subgroup[which.max(value)] else NA_character_
    )

  # Unir los dataframes automáticos
  auto_blood_data <- c(hematology_auto_list, list(ige_total_auto, ige_specific_summary)) |>
    reduce(full_join, by = "id")
  
  # === PARTE 2: Procesar Datos Manuales (Lógica Original) ===
  
  manual_path <- file.path(raw_path, "manual_entry", "blood_analysis")
  manual_files <- list.files(manual_path, full.names = TRUE, pattern = "\\.csv$")
  
  manual_names <- str_extract(manual_files, "(?<=\\().*?(?=\\))")
  
  manual_blood_data <- lapply(manual_files, function(file) {
    read_csv(file, show_col_types = FALSE)
  }) |>
    setNames(manual_names) |>
    reduce(full_join, by = "id")
  
  # === PARTE 3: Armonizar y Guardar ===
  
  # Asegurarse de que los nombres de las columnas coincidan!!
  
  blood_data_final <- bind_rows(
    auto_blood_data |> mutate(source = "automatic"),
    manual_blood_data |> mutate(source = "manual")
  ) |>
    group_by(id) |>
    slice_min(order_by = factor(source, levels = c("automatic", "manual")), n = 1, with_ties = FALSE) |>
    ungroup()
  
  # --- Guardar Resultado ---
  saveRDS(blood_data_final, file.path(processed_path, "blood_data_harmonized.rds"))
  print(paste("Datos de análisis de sangre armonizados y guardados en:", file.path(processed_path, "blood_data_harmonized.rds")))
}
