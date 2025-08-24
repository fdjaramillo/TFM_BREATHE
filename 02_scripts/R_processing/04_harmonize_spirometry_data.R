# -----------------------------------------------------------------------------
# SCRIPT: 04_harmonize_spirometry_data.R
# OBJETIVO: Cargar, unir y armonizar los datos de espirometría
#           de fuentes automáticas y manuales, siguiendo la lógica original.
# -----------------------------------------------------------------------------
library(tidyverse)
library(stringr)

harmonize_spirometry_data <- function(raw_path, processed_path) {
  
  # --- 1. Cargar y Procesar Datos Automáticos ---
  
  auto_file_path <- file.path(raw_path, "automatic_extraction", "spirometry", "spirometry.csv")
  spirometry_auto_raw <- read_csv(auto_file_path, show_col_types = FALSE)
  
  spiro_complete <- spirometry_auto_raw |>
    filter(phase != "Not applicable") |>
    pivot_wider(names_from = c(phase, value_type), values_from = value)
  
  spiro_na <- spirometry_auto_raw |>
    filter(phase == "Not applicable") |>
    select(!phase) |>
    pivot_wider(names_from = value_type, values_from = value)
  
  spirometry_auto <- spiro_complete |>
    left_join(spiro_na, by = c("id", "parameter")) |>
    relocate(theorical, lin, .after = Pre_raw)
  
  # --- 2. Cargar Datos Manuales ---
  
  manual_file_path <- file.path(raw_path, "manual_entry", "spirometry", "spirometry_manual.csv")
  spirometry_manual <- read_csv(manual_file_path, show_col_types = FALSE) |>
    filter(!if_all(everything(), is.na)) |>
    mutate(across(everything(), as.character))
  
  # --- 3. Armonizar y Limpiar ---
  
  param_dict <- c(
    "fef50%\\(l/s\\)"       = "fef50(l/s)",
    "fef25%-75%\\(l/s\\)"   = "fef25-75(l/s)"
  )
  
  spirometry_all <- bind_rows(
    spirometry_auto |> mutate(source = "automatic"),
    spirometry_manual |> select(!any_of("obs")) |> mutate(source = "manual")
  ) |>
    # Cadena de limpieza de nombres de columna
    rename_with(tolower) |>
    rename_with(~ str_replace_all(.x, "-", "_")) |>
    rename_with(~ str_replace_all(.x, "bd", "")) |>
    rename_with(~ str_replace_all(.x, "%", "pct_")) |>
    rename_with(~ str_replace_all(.x, "teòric", "pred")) |>
    rename_with(~ str_replace_all(.x, "_raw", "")) |>
    # Limpieza de la columna 'parameter' y valores
    mutate(
      parameter = tolower(parameter) |>
        str_replace_all("\\s*", "") |>
        str_replace_all("\\[", "(") |>
        str_replace_all("\\]", ")"),
      parameter = str_replace_all(parameter, sapply(param_dict, coll)),
      across(pre:pct_change, ~ str_replace_all(., ",", ".")),
      across(pre:pct_change, ~ as.numeric(.))
    )
  
  # guardar para futuros analisis
  long_format_path <- file.path(processed_path, "long_format_archive")
  dir.create(long_format_path, showWarnings = FALSE, recursive = TRUE)
  saveRDS(spirometry_all, file.path(long_format_path ,"spirometry_long.rds"))
  
  # --- 4. Pivotear a wide ---
  
  params_to_extract <- c("fvc(l)", "fev1(l)", "fev1/fvc(%)")
  
  spirometry_wide <- spirometry_all |>
    filter(parameter %in% params_to_extract) |>
    pivot_wider(
      id_cols = id,
      names_from = parameter,
      values_from = c(pre, pre_pct_pred) # Y otros valores que necesites
    ) |> 
    rename_with(~ .x |>
                  str_remove("\\(.*\\)") |>
                  str_remove("^pre_") |> 
                  str_replace_all("/", "_"))  
  
  # --- 5. Guardar Resultado ---
  saveRDS(spirometry_wide, file.path(processed_path, "spirometry_wide.rds"))
  print(paste("Datos de espirometría armonizados y guardados en:", file.path(processed_path, "spirometry_harmonized.rds")))
}
