# -----------------------------------------------------------------------------
# SCRIPT: 05_process_treatment_data.R
# OBJETIVO: Cargar, limpiar, categorizar y resumir los datos de tratamiento.
# Esta es una refactorización completa y fiel del pipeline original.
# -----------------------------------------------------------------------------
library(tidyverse)
library(stringr)
library(stringi)

process_treatment_data <- function(raw_path, processed_path, scripts_path) {
  
  # --- 1. Cargar Diccionarios Externos ---
  source(file.path(scripts_path, "00_load_dictionaries.R"))

  # --- 2. Cargar y Combinar Datos de Tratamiento ---
  to_read_path <- file.path(raw_path, "manual_entry", "treatment", "to_read")
  to_read_files <- list.files(to_read_path, full.names = TRUE, pattern = "\\.csv$")
  to_read_data <- to_read_files |>
    map_df(~ read_csv(.x, show_col_types = FALSE) |>
             filter(!if_all(everything(), is.na)) |>
             mutate(source = basename(.x) |> str_remove("\\.csv$"))
    )
  
  to_parse_path <- file.path(raw_path, "manual_entry", "treatment", "to_parse", "processed")
  processed_files <- list.files(to_parse_path, full.names = TRUE, pattern = "\\.csv$")
  processed_data <- processed_files |>
    map_df(~ read_csv(.x, show_col_types = FALSE) |>
             mutate(source = basename(.x) |> str_remove("\\.csv$"))
    )
  
  medication <- bind_rows(to_read_data, processed_data)
  
  # --- 3. Aplicar Correcciones Manuales Específicas ---
  ids_with_corrections <- c("HCB051", "HCB049")
  dict_corrections <- tribble(
    ~medication_raw,   ~medication_corr, ~posology_corr,
    "Dupilumab",       "DUPILUMAB", "300 MG / C/2 SEMANAS C",
    "Spiriva",         "Tiotropio (SPIRIVA RESPIMAT 2,5MCG)", "5 MCG / DE-0-0 / PULMONAR (SEGONS EVOLUCIÓ)",
    "Formodual",       "BECLOMETASONA + FORMOTEROL (FORMODUAL NEXTHALER 100/6)", "2 INH / C/12H / PULMONAR (SEGONS EVOLUCIÓ)",
    "Tezepelumab",     "TEZEPELUMAB", "210 MG / C/MES SC",
    "relvar",          "FLUTICASONA + VILANTEROL (RELVAR ELLIPTA 184/22)", "1 INH / C/24H / PULMONAR (SEGONS EVOLUCIÓ)",
    "montelukast",     "MONTELUKAST (SINGULAIR 10 MG)", "10 MG / C/24H / ORAL (SEGONS EVOLUCIÓ)",
    "spiriva",         "Tiotropio (SPIRIVA RESPIMAT 2,5MCG)", "5 MCG / C/24H / PULMONAR (SEGONS EVOLUCIÓ)"
  )
  
  corrected_rows <- medication |>
    filter(id %in% ids_with_corrections) |>
    left_join(dict_corrections, by = c("medication" = "medication_raw")) |>
    select(id, medication = medication_corr, posology = posology_corr, source)
  
  medication <- medication |>
    filter(!(id %in% ids_with_corrections)) |>
    bind_rows(corrected_rows) |>
    distinct(id, medication, posology, .keep_all = TRUE)
  
  # --- 4. Limpieza y Estandarización de Texto ---
  
  replacements_details <- c(
    "\\(R\\)" = "", " MG" = "MG", "MICROFRAMOS" = "MICROGRAMOS", "MICROGRAMOS" = "MCG",
    " MCG" = "MCG", "\\bSOLUCION\\b" = "SOLUC", "\\bSOLUC\\b" = "SOL", "SOL " = "SOLUCION ",
    "SOL$" = "SOLUCION", "\\bINHALADHOR\\b" = "INHALADOR", "\\bINHAHADOR\\b" = "INHALADOR",
    "\\b1 INHALADOR\\b" = "1 INHAL", "\\b1 INHAL\\b" = "1 INHALADOR", "\\bINHALACION\\b" = "INHALAC",
    "\\bINHALAC\\b" = "INHAL", "\\bINHAL\\b" = "INH", "/INH" = " POR INH", "/DOSIS" = " POR DOSIS",
    "/PULSACION" = "/PULS", "/PULS" = " POR PULSACION", "/APLICACION" = " POR APLICACION",
    "/PULVERIZACIO" = " POR PULVERIZACIO", "(\\d+) %" = "\\1%", "(\\d+) G" = "\\1G",
    "(\\d+) ML" = "\\1ML", "(\\d+) UI" = "\\1UI", "\\(ADRENALINA\\)" = "ADRENALINA",
    "REVINTY ELLIPTA 184/" = "REVINTY ELLIPTA 184MCG/"
  )
  
  medication_cleaned <- medication |>
    separate_wider_delim(
      medication, " (", names = c("medication", "med_details"),
      too_few = "align_start", too_many = "merge"
    ) |>
    mutate(med_details = str_remove(med_details, "\\)$")) |> 
    mutate(
      across(everything(), ~ stri_trans_general(as.character(.), "Latin-ASCII")),
      
      medication = str_replace_all(medication, "\\bglicopirroni\\b", "glicopirronio"),
      
      med_details = str_to_upper(med_details) |>
        str_replace_all("\\s*/\\s*", "/") |>
        str_replace_all("\\s+,\\s*", ", ") |>
        str_replace_all(replacements_details),
    )
  
  # Extract brand_name and presentation
  medication_cleaned <- medication_cleaned |> 
    mutate(
      # extract the market name and presentation
      med_name = str_extract(med_details, "^[A-Z\\s\\-]+"), # parte fija del nombre
      med_name = str_squish(med_name),
      # clean med_presentation
      med_presentation = str_remove(med_details, "^[A-Z\\s\\-]+"), # resto
      med_presentation = str_squish(med_presentation),
      med_presentation = str_remove(med_presentation, "^[,\\(]"), # remove leading commas and parentheses
      med_presentation = str_squish(med_presentation),
    ) |> 
    select(id, medication, med_name, med_presentation, posology)
  
  # Separar med_presentation en dosis y presentación
  medication_cleaned <- medication_cleaned |> 
    separate_wider_delim(
      med_presentation, " ", names = c("dose", "presentation"), 
      too_few = "align_start", too_many = "merge"
    ) |> 
    mutate(
      # cleaning
      dose = str_remove(dose, ",$"), # remove trailing commas
      dose = str_replace_all(dose, ",", "."),
      dose = na_if(dose, ""),
      # maneja puntos de miles "25<.>000UI/2,5ML"
      dose = str_replace_all(dose, "(?<=\\d)\\.(?=\\d{3}(?:[A-Z]))", ""),
      # data entry corrections
      # 12	1.000GAMMAS (=1MG), 5 AMPOLLAS DE 2ML			
      # 40	COMPRIMIDOS			
      # 80	COMPRIMIDOS CON CUBIERTA PELICULAR, 60 COMPRIMIDOS
      med_name = ifelse(dose == 12, paste0(med_name, dose), med_name),
      presentation = ifelse(dose %in% c("40", "80"), paste(dose, presentation), presentation),
      dose = ifelse(dose %in% c("12","40", "80"), NA_character_, dose),
    )
  
  # Separar posología en dosis total, frecuencia y ruta
  medication_cleaned <- medication_cleaned |> 
    separate_wider_delim(
      posology, names = c("dose_total", "freq", "route"), delim = " / ", 
      too_few = "align_start", too_many = "merge"
    ) |> 
    separate_wider_delim(
      route, names = c("route", "route_details"), delim = "(", 
      too_few = "align_start", too_many = "merge"
    ) |> 
    select(!route_details)
  
  # Limpiar y estandarizar las columnas
  medication_cleaned <- medication_cleaned |> 
    mutate(
      # FREQ
      freq = str_replace(freq, "SEMANA\\s*SC", "SEMANAS"),
      freq = str_remove(freq, "SC$"),
      freq = str_squish(freq),
      freq = case_when(
        str_detect(freq,"C/24H|24 HORES|^1 DIES$|365 DIES|105 DIES") ~ "C/24H",
        # algunas pautas
        str_detect(freq,"DE-0-0|0-0-CE|0-CO-0") ~ "C/24H",
        # horas fijas
        str_detect(freq,"^\\d{1,2}:\\d{2}$") ~ "C/24H",
        str_detect(freq, "C/12H|12 HORES|DE-0-CE|DE-0-0-N") ~ "C/12H",
        str_detect(freq, "C/8H|8 HORES|DE-CO-CE") ~ "C/8H",
        str_detect(freq, "C/72H|72 HORES") ~ "C/72H",
        str_detect(freq, "C/4 SEMANAS|C/28 DIAS") ~  "C/4 SEMANAS",
        # otras pautas hospitalarias
        str_detect(freq, "0-CO-0-N|0-CO-CE") ~ "otra pauta",
        str_detect(freq, "SEGONS PAUTA") ~ "otra pauta",
        str_detect(freq, "1 MESOS") ~ NA_character_,
        TRUE ~ freq
      ),
      # ROUTE
      route = case_when(
        str_detect(medication, "umab") ~ "SUBCUTANEA",
        TRUE ~ route
      ),
      # unificar
      across(dose:route, str_squish),
    )
  
  # --- 5. Categorización de Fármacos ---
  
  medication_categorized <- medication_cleaned |>
    mutate(active_ingredient = str_split(medication, "\\+")) |>
    unnest(active_ingredient) |>
    mutate(active_ingredient = str_squish(active_ingredient) |> str_to_lower()) |>
    left_join(translation_dict, by = c("active_ingredient" = "spanish")) |>
    left_join(drug_dict, by = c("english" = "active_ingredient")) |> 
    select(!english) |> 
    select(id, medication, active_ingredient, category, med_name:last_col())
  
  combined_cat <- medication_categorized |>
    group_by(id, medication) |>
    summarise(medication_cat = paste(unique(na.omit(category)), collapse = "+"), .groups = "drop")

  medication_final <- medication_cleaned |>
    left_join(combined_cat, by = c("id", "medication")) |> 
    relocate(medication_cat, .after = medication)
  
  # SAVE for later use
  long_format_path <- file.path(processed_path, "long_format_archive")
  dir.create(long_format_path, showWarnings = FALSE, recursive = TRUE)
  saveRDS(medication_final, file.path(long_format_path, "medication_final.rds"))
  
  # --- 6. Crear Tabla Resumen ---
  
  medication_summary <- medication_final |>
    group_by(id) |>
    summarise(
      is_on_ics_laba = any(medication_cat == "ICS+LABA", na.rm = TRUE),
      is_on_lama = any(medication_cat == "LAMA", na.rm = TRUE),
      is_on_triple_therapy = any(medication_cat == "ICS+LABA+LAMA", na.rm = TRUE),
      is_on_ics = any(medication_cat == "ICS", na.rm = TRUE),
      is_on_antihistamine = any(medication_cat == "Antihistamine (H1)", na.rm = TRUE),
      is_on_ics_antihistamine = any(medication_cat == "ICS+Antihistamine (H1)", na.rm = TRUE),
      is_on_biologic = any(medication_cat == "BIOLOGIC", na.rm = TRUE),
      is_on_ltra = any(medication_cat == "LTRA", na.rm = TRUE)
    )
  
  # --- 7. Guardar Resultado ---
  saveRDS(medication_summary, file.path(processed_path, "medication_summary.rds"))
  print(paste("Datos de tratamiento procesados y guardados en:", file.path(processed_path, "medication_summary.rds")))
}
