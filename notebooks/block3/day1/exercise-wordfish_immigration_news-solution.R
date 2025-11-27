# +~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~ #  
#
#' @title  Examining difference in UK newspapers' immigration stances
#' @author Hauke Licht
#' @date   2025-11-26
#
# +~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~ #

# setup ---- 
library(quanteda)
library(quanteda.corpora)  # TODO (if needed): `renv::install("quanteda/quanteda.corpora")``
library(quanteda.textmodels) # TODO (if needed): `renv::install("quanteda.textmodels")`
library(quanteda.textplots) # TODO (if needed): `renv::install("quanteda.textplots")`
library(dplyr)
library(ggplot2)

# load and prepare the data ----

# NOTE: we use the "Immigration News" corpus that contains 
#  UK news articles (2,833) from 2014 that mention immigration
data("data_corpus_immigrationnews", package = "quanteda.corpora")

# inspect the document variables
glimpse(docvars(data_corpus_immigrationnews))

# how many articles per newspaper
docvars(data_corpus_immigrationnews) |> 
  count(paperName) |> 
  arrange(desc(n))

# NOTE: remove "the-sunday-telegraph" given very few articles
data_corpus_immigrationnews <- corpus_subset(data_corpus_immigrationnews, paperName != "the-sunday-telegraph")


# understand the data ----

# to understand how newspapers' discussion of the topic of immigration may differe,
#  it's helpful to first explore the data a bit
# For example, we can look at the keyword "immigra*" in context 
# see https://tutorials.quanteda.io/basic-operations/tokens/kwic/
options(width = 150)

# for The Guardian
set.seed(1234)
data_corpus_immigrationnews |> 
  corpus_subset(paperName == "guardian") |>
  corpus_sample(10) |> 
  tokens() |> 
  kwic(pattern = "immigra*", window = 6)

# for The Daily Mail
set.seed(1234)
data_corpus_immigrationnews |> 
  corpus_subset(paperName == "mail") |>
  corpus_sample(10) |> 
  tokens() |> 
  kwic(pattern = "immigra*", window = 6)




# create the document-term matrix ----

dtm <- data_corpus_immigrationnews |> 
  tokens(remove_symbols = TRUE, remove_numbers = TRUE, remove_punct = FALSE) |> 
  tokens_tolower() |> 
  tokens_wordstem() |> 
  tokens_remove(stopwords("en")) |>
  dfm() |> 
  dfm_trim(
    min_termfreq = 30, termfreq_type = "count",
    max_docfreq = 0.80, docfreq_type = "prop"
  )

# aggregate the data by news paper ----


# NOTE: the news articles are too sparse and its too much data to efficiently fit
#        a Wordfish model Therefore, we aggregate the data by newspaper
dtm_grouped <- dfm_group(dtm, group = docvars(dtm, "paperName"))

docnames(dtm_grouped)
dim(dtm_grouped)

# fit the Wordfish model ----

# NOTE: let's assume that The Guardian < The Daily Mail on the latent dimension
#        This makes sense because The Guardian is known to be more liberal 
#        whereas the Daily Mail is known to be more conservative tabloid media
# get the indexes of these news paper's in the DTM
low_ <- which(docid(dtm_grouped) == "guardian") 
high_ <- which(docid(dtm_grouped) == "mail")

# fit the model
wf_papers <- textmodel_wordfish(dtm_grouped, dir = c(low_, high_))

# inspect the estimate
summary(wf_papers)

# plot the position estimates
textplot_scale1d(wf_papers, "documents")
# NOTE: we can interpret these results as follows:
#  - given is the constraint that The Guardian < The Daily Mail
#  - so higher values likely indicate more conservative/restrictive
#     stance on immigration/portrayal of immigrants
#  - but The Sun turns out to be even more "right" than 
#     the Daily Mail
#  - lower values likely correspond to more liberal/permissive 
#     immigration stance

# NOTE: the assumption that the estimated scale captures (mostly) immigration
#  stance would need to be further evaluate, e.g., by correlating Wordfish 
#  scores with external measures
