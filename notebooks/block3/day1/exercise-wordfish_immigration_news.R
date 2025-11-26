# +~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~ #  
#
#' @title  Examining difference in UK newspapers' immigration stances
#' @author Hauke Licht
#' @date   2025-11-26
#' @note   look for keyword `TODO` to see which steps you need to complete
#
# +~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~ #

# setup ---- 
library(quanteda)
library(quanteda.corpora)  # if needed: `renv::install("quanteda/quanteda.corpora")``
library(quanteda.textmodels) # if needed: `renv::install("quanteda.textmodels")`
library(quanteda.textplots) # if needed: `renv::install("quanteda.textplots")`
library(dplyr)
library(ggplot2)

# load and prepare the data ----

# NOTE: we use the "Immigration News" corpus that contains UK news articles 
#        from 2014 that mention immigration
data("data_corpus_immigrationnews", package = "quanteda.corpora")

# inspect the document variables
glimpse(docvars(data_corpus_immigrationnews))

# how many articles per newspaper
docvars(data_corpus_immigrationnews) |> 
  count(paperName) |> 
  arrange(desc(n))

# NOTE: remove "the-sunday-telegraph" given very few articles
data_corpus_immigrationnews <- corpus_subset(data_corpus_immigrationnews, paperName != "the-sunday-telegraph")

# TODO: create the document-term matrix
#  - remove symbols, numbers, and punctuation
#  - convert to lowercase
#  - stem the tokens
#  - remove stopwords
#  - trim the DTM to remove very infrequent and very frequent terms
#  ! IMPORTANT: name the resulting object "dtm"

# aggregate the data by news paper
# NOTE: the news articles are too sparse and its too much data to efficiently fit
#        a Wordfish model Therefore, we aggregate the data by newspaper
dtm_grouped <- dfm_group(dtm, group = docvars(dtm, "paperName"))

# NOTE: let's assume that The Guardian < The Daily Mail on the latent dimension
#        This makes sense because The Guardian is known to be more liberal 
#        whereas the Daily Mail is known to be more conservative tabloid media
# get the indexes of these news papers' in the DTM
low_ <- which(docid(dtm_grouped) == "guardian") 
high_ <- which(docid(dtm_grouped) == "mail")

# TODO: fit the model using function `textmodel_wordfish` 
#    and arguments x = `dtm_grouped` and `dir = c(low_, high_)`
#  ! IMPORTANT: name the resulting object "wf_papers"


# TODO: plot the position estimates using `textplot_scale1d`

# TODO: interpret the plot
#  - what might high scores indicate?
#  - which newspapers are more "right" or "left" on the estimated scale?

