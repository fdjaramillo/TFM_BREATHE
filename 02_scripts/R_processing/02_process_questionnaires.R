# -----------------------------------------------------------------------------
# SCRIPT: 02_process_questionnaires.R
# OBJETIVO: Cargar y procesar los datos de cuestionarios y EVA.
# -----------------------------------------------------------------------------

# --- Cargar Librerías ---
library(tidyverse)
library(data.table)

process_questionnaires <- function(raw_path, processed_path) {
  
  # --- 1. Carga de Cuestionarios ---
  q_path <- file.path(raw_path, "manual_entry", "questionnaires")
  q_files <- list.files(q_path, full.names = TRUE, pattern = "\\.csv$")
  
  questionnaires <- q_files %>%
    set_names(nm = str_extract(basename(.), "(?<=\\().*(?=\\))") %>% str_to_lower()) %>%
    map(~ data.table::transpose(fread(.x, na.strings = c("", "NA")), make.names = "question") %>%
          as_tibble() %>%
          select(-any_of("Observaciones")) %>%
          mutate(id = sprintf("HCB%03d", 1:n())) %>%
          relocate(id) %>%
          filter(!if_all(-id, is.na))
    ) %>%
    map(~ pivot_longer(.x, cols = starts_with("Q"), names_to = "question", values_to = "value") %>%
          mutate(value = as.integer(value)))
  
  # Corrección específica para CARAT
  questionnaires[["carat"]] <- questionnaires[["carat"]] %>%
    mutate(value = ifelse(value == 4, 3, value))
  
  # --- 2. Cálculo de Puntuaciones (Scores) ---
  scores <- questionnaires %>%
    imap(~ .x %>%
           group_by(id) %>%
           summarise(score = if (.y %in% c("acq", "miniaqlq")) mean(value, na.rm = TRUE) else sum(value, na.rm = TRUE)) %>%
           rename(!!.y := score)
    ) %>%
    reduce(full_join, by = "id")
  
  # --- 3. Carga y Procesamiento de EVA ---
  vas_file <- file.path(raw_path, "manual_entry", "vas", "BREATHE_questionnaires_download(EVA).csv")
  vas <- data.table::transpose(fread(vas_file, na.strings = c("", "NA")), make.names = "question") %>%
    as_tibble() %>%
    select(-any_of("Observaciones")) %>%
    mutate(id = sprintf("HCB%03d", 1:n())) %>%
    rename(los_vas = Q1, rhinitis_vas = Q2) %>%
    select(id, los_vas, rhinitis_vas)
  
  # --- 4. Unión y Guardado ---
  final_scores <- scores %>%
    full_join(vas, by = "id")
  
  saveRDS(final_scores, file = file.path(processed_path, "questionnaire_scores.rds"))
  
  print(paste("Puntuaciones de cuestionarios procesadas y guardadas en:", file.path(processed_path, "questionnaire_scores.rds")))
}
