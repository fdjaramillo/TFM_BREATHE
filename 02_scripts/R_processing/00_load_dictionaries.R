# -----------------------------------------------------------------------------
# SCRIPT: 00_load_dictionaries.R
# OBJETIVO: Cargar y crear todos los diccionarios de traducción y
#           categorización de fármacos para el proyecto.
# -----------------------------------------------------------------------------
library(tidyverse)

# --- 1. Diccionario de Categorización de Fármacos ---
# NOTA: Sería ideal que los tribbles estuvieran en un único CSV en una carpeta 'utilities'
drug_dict_path <- "../05_utilities/drug_dict.csv" # Usando una ruta relativa
drug_dict <- read_csv(drug_dict_path) |>
  # Normalizar nombres de columnas y filtrar solo las que importan
  rename_with(tolower) |>
  rename_with(~ str_replace_all(.x, " ", "_")) |>
  select(category, active_ingredient) |>
  # Separar categorías y activos en listas
  mutate(
    category = str_split(category, "\\+"),
    active_ingredient = str_split(active_ingredient, "/")
  ) |>
  # Expandir filas paralelamente
  unnest(c(category, active_ingredient)) |>
  mutate(
    category = str_trim(category),
    active_ingredient = str_trim(active_ingredient),
    active_ingredient = str_to_lower(active_ingredient),
  ) |> 
  distinct()


drug_dict <- drug_dict |> 
  bind_rows(
    tribble(
      ~category, ~active_ingredient,
      "SABA", "salbutamol",
      "SABA", "terbutaline",
      "SAMA", "ipratropium",
      "LAMA", "tiotropium",
      "LAMA", "umeclidinium",
      "ICS", "budesonide",
      "ICS", "ciclesonide",
      "ICS", "fluticasone propionate",
      "ICS", "fluticasone propionate",
      "BIOLOGIC","omalizumab",        # anti (IgE)
      "BIOLOGIC","mepolizumab",       # anti (IL-5)
      "BIOLOGIC","reslizumab",        # anti (IL-5)
      "BIOLOGIC","benralizumab",      # anti (IL-5Rα)
      "BIOLOGIC","dupilumab",         # anti (IL-4Rα)
      "BIOLOGIC","tezepelumab"        # anti (TSLP)
    ),
    tribble(
      ~active_ingredient,      ~category,
      "montelukast",           "LTRA",              # leukotriene receptor antagonist
      "azelastine",            "Antihistamine (H1)",
      "ebastine",              "Antihistamine (H1)",
      "bilastine",             "Antihistamine (H1)",
      "glycopyrronium",        "LAMA",
      "omeprazole",            "PPI",               # proton pump inhibitor
      "diazepam",              "Benzodiazepine",
      "lorazepam",             "Benzodiazepine",
      "lormetazepam",          "Benzodiazepine",
      "levothyroxine",         "Thyroid hormone",
      "paracetamol",           "Analgesic/antipyretic",
      "calcifediol",           "Vitamin D analogue",
      "cholecalciferol",       "Vitamin D3",
      "epinephrine",           "Adrenergic agonist",
      "quetiapine",            "Antipsychotic",
      "tramadol",              "Opioid analgesic",
      "citalopram",            "SSRI",          # selective serotonin reuptake inhibitor
      "sertraline",            "SSRI",          # selective serotonin reuptake inhibitor
      "paroxetine",            "SSRI",          # selective serotonin reuptake inhibitor
      "amitriptyline",         "TCA",           # tricyclic antidepressant
      "venlafaxine",           "SNRI",
      "duloxetine",            "SNRI",
      "empagliflozin",         "SGLT2 inhibitor",
      "metformin",             "Biguanide (antidiabetic)",
      "naproxen",              "NSAID",
      "diclofenac",            "NSAID",
      "acetylsalicylic acid",  "NSAID (antiplatelet)",
      "indacaterol",           "LABA",
      "cetirizine",            "Antihistamine (H1)",
      "loratadine",            "Antihistamine (H1)",
      "desloratadine",         "Antihistamine (H1)",
      "ketotifen",             "Antihistamine (H1)",
      "olopatadine",           "Antihistamine (H1)",
      "cyanocobalamin",        "Vitamin B12",
      "calcium carbonate",     "Calcium supplement",
      "dienogest",             "Progestin",
      "ethinylestradiol",      "Estrogen (synthetic)",
      "etonogestrel",          "Progestin",
      "ondansetron",           "5-HT3 antagonist (antiemetic)",
      "rizatriptan",           "Triptan",
      "sumatriptan",           "Triptan",
      "prednisone",            "Corticosteroid (oral)",
      "acetylcysteine",        "Mucolytic",
      "amoxicillin",           "Antibiotic",
      "cefuroxime",            "Antibiotic",
      "clobetasol",            "Corticosteroid (topical)",
      "hydrocortisone",        "Corticosteroid (oral)",
    )
  ) |> 
  distinct()

# --- 2. Diccionario de Traducción Español -> Inglés ---
# Vector original
spanish <- c(
  "fluticasona", "formoterol", "tiotropi", "tiotropio", "beclometasona",
  "salbutamol", "vilanterol", "mometasona", "montelukast",
  "azelastina", "ebastina", "bilastina", "dupilumab",
  "tezepelumab", "budesonida", "glicopirronio", "ipratropio",
  "omeprazol", "diazepam", "levotiroxina", "paracetamol",
  "benralizumab", "calcifediol", "epinefrina", "loracepam", "quetiapina",
  "tramadol", "citalopram", "colecalciferol", "empagliflozina", "ketotifeno",
  "naproxeno", "sertralina", "amitriptilina", "carbonato de calcio",
  "cetirizina", "cianocobalamina", "ciclesonida", "dienogest", "indacaterol",
  "loratadina", "lormetazepam", "metformina", "metilfenidato", "olopatadina",
  "omalizumab", "ondansetron", "paroxetina", "prednisona", "rizatriptan",
  "sumatriptan"
)

# Vector de traducción al inglés
english <- c(
  "fluticasone", "formoterol", "tiotropium", "tiotropium", "beclomethasone",
  "salbutamol", "vilanterol", "mometasone", "montelukast",
  "azelastine", "ebastine", "bilastine", "dupilumab",
  "tezepelumab", "budesonide", "glycopyrronium", "ipratropium",
  "omeprazole", "diazepam", "levothyroxine", "paracetamol",
  "benralizumab", "calcifediol", "epinephrine", "lorazepam", "quetiapine",
  "tramadol", "citalopram", "cholecalciferol", "empagliflozin", "ketotifen",
  "naproxen", "sertraline", "amitriptyline", "calcium carbonate",
  "cetirizine", "cyanocobalamin", "ciclesonide", "dienogest", "indacaterol",
  "loratadine", "lormetazepam", "metformin", "methylphenidate", "olopatadine",
  "omalizumab", "ondansetron", "paroxetine", "prednisone", "rizatriptan",
  "sumatriptan"
)

# Crear dataframe de mapeo
translation_dict <- tibble(spanish, english)

rm(drug_dict_path, spanish, english)
