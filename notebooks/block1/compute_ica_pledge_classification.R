# +~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~ #  
#
#' @title  Computing inter-annotator agreement for sentence classification task
#' @author Hauke Licht
#' @date   2025-10-08
#' 
#' @description We want to compute to what extent annotators' sentence-level 
#'  classifications agree with each other. Specifically, we use Krippendorff's 
#'  alpha (α) for nominal data. α adjusts for the probability that an agreement 
#'  arises by chance.
#
#' @details This script reads sentence-level classification annotations from 
#'  separate, annotator-specific CSV files exported from _doccano_.
#'  We then construct an M×N annotation matrix (M annotators × N items), and 
#'  computes α via `irr::kripp.alpha`.
#'  Finally, we compute the entropy ("disorder") in each text's set of 
#'   annotations to identify cases with annotation disagreements
#' 
#' - Expects one CSV file per annotator containing at least columns "text_id", "text", "label".
#' - Assumes *classification* labels are "Pledge" or "No Pledge"
#' - Missing annotations are treated as NA.
#' - sentence-level disagreement is computed as the (normalized) Shannon entropy
#'   to measures disagreement indicator:
#'    $$
#'    H_\text{norm} = H / \log_2(K)
#'    $$
#'    with K=2 for binary labels (Pledge vs No Pledge)
#
# +~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~ #

# setup ----
library(readr)
library(dplyr)
library(tidyr)
library(purrr)
library(stringr)
library(irr)

# NOTE: it's assumed here that you've opened this file in the context of 
#  an RStudio project with root path ../../.. (i.e., the repo root)
data_path <- file.path("data", "labeled", "fornaciari_we_2021")

group_name <- "llms" # TODO: change to your group's ID

# Step 1: read the annotations ----

annotations_dir <- file.path(data_path, "annotations", "classification", group_name)

# check that it exists
stopifnot("Annotation directory does not exist" = dir.exists(annotations_dir))

# gather all annotator files
csv_files <- list.files(annotations_dir, pattern = "\\.csv$", full.names = TRUE)
stopifnot("Annotations directory must contain at least two CSV files." = length(csv_files)>1)

annotations <- map_dfr(set_names(csv_files), read_csv, .id = "file", show_col_types = FALSE, progress = FALSE)

stopifnot(
  "CSV files must have columns 'text_id', 'text', 'label'" = length(setdiff(c("text_id", "text", "label"), names(annotations))) == 0,
  "Label values must be either 'Pledge' or 'No Pledge'" = all(annotations$label %in% c("Pledge", "No Pledge")),
  "No rows loaded from annotation JSONL files." = nrow(annotations)>0
)

annotations$annotator <- str_remove(basename(annotations$file), "\\.csv")
annotations$file <- NULL

# sanity check
annotations |> 
  count(annotator, label) |> 
  arrange(annotator, desc(n))

# Step 2: compute K's alpha ----

# build the M×N annotation matrix (M=annotators, N=text items)
annotations_matrix <- annotations |> 
  select(annotator, text_id, label) |> 
  mutate(label = as.integer(factor(label, levels = c("No Pledge", "Pledge")))) |> 
  distinct() |> 
  pivot_wider(names_from = text_id, values_from = label) |> 
  select(-annotator) |> 
  as.matrix()

# compute Krippendorff's alpha (nominal)
# NOTE: irr::kripp.alpha expects a matrix with raters in rows, items in columns
irr::kripp.alpha(annotations_matrix, method = "nominal")


# Step 3: sentence-level disagreement analysis ----

# For binary labels, normalize by log2(2)=1, giving values in [0,1].
# If more than 2 labels are present, normalize by log2(K) with K=number of observed labels for that item.
compute_entropy <- function(x) {
  vals <- x[!is.na(x)]
  if (length(vals) == 0L) 
    return(NA_real_)
  tab <- prop.table(table(vals))
  H <- -sum(tab * log2(tab))
  K <- length(tab)
  if (K <= 1)
    return(0.0)
  return(H / log2(K))
}

# compute annotation entropy (disagreement) per text item
entropies <- annotations |> 
  group_by(text_id) |> 
  summarise(entropy = compute_entropy(label), .groups = "drop")

# tabulate
entropies |>
  count(entropy) |> 
  arrange(entropy)

# get disagreement instances (entropy < 1)
disagreement_cases <- entropies |> 
  # filter sentence-level entropies data frame for examples with non-zero entropy
  filter(!is.na(entropy), entropy > 0) |> 
  # add texts
  left_join(
    annotations |>
      select(text_id, text) |> 
      distinct(), 
    by = "text_id"
  ) |> 
  # add annotations (gathered at sentence level)
  left_join(
    annotations |> 
      group_by(text_id) |> 
      summarise(annotations = paste(sort(label), collapse = ", ")),
    by = "text_id"
  ) |> 
  arrange(annotations)

# split by annotation pattern ... 
tmp <- disagreement_cases |> 
  group_by(entropy, annotations) |>
  group_split() |> 
  as.list()
  
# ... and show some examples
for (subdf in tmp) {
  set.seed(42)
  message(sprintf("annotations pattern: [%s] (entropy: %0.3f)", subdf$annotations[1], subdf$entropy[1]))
  expls <- sample_n(subdf, min(5, nrow(subdf)))$text
  cat(expls, sep="\n")
  cat("\n")
}
