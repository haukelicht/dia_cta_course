# +~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~ #  
#
#' @title  Example code for reading and parsing doccano-style sequence labeling 
#'          annotations from a JSONlines file
#' @author Hauke Licht
#' @date   2025-10-09
#
# +~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~ #

# reading JSONlines data ----

library(readr)
library(jsonlite)
library(dplyr)
library(purrr)

data_path <- file.path("assignments", "take_home_1", "data", "annotation")

fp <- file.path(data_path, "dev.jsonl")
lines <- read_lines(fp)
docs <- map(lines, fromJSON, simplifyVector = FALSE) 

text <- docs[[4]]$text
print(text)
label <- docs[[4]]$label
print(label)


# converting sentence-level annotations to mention-in-sentence-context level data ----

library(purrr)
library(dplyr)

text = "Cambodia has added its own specific goal related to
mine action — namely,
a “Mine-Free Cambodia by 2025”."
label = list(
  list(0, 8, "sovereign state"),
  list(87, 95, "sovereign state")
)

# NOTE: reusing the `text` and `label` variables defined above
doc <- list(text = text, label = label)
doc <- as_tibble(doc)


# helper function for extracting mention phrase
extract_phrase <- function(text, annotation) substr(text, annotation[[1]]+1L, annotation[[2]])

mutate(
  doc,
  # get entity number (within sentence)
  entity_mention_nr = row_number(),
  # get entity mention phrase
  entity_mention = map2_chr(text, label, extract_phrase),
  # get entity type label
  entity_type = map_chr(label, 3),
  # remove original annotation
  label = NULL
)

