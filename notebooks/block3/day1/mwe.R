library(quanteda)
library(quanteda.textmodels)
library(quanteda.textplots)

data("data_corpus_irishbudget2010", package = "quanteda.textmodels")
dtm <- dfm(tokens(data_corpus_irishbudget2010, remove_punct = TRUE))

model <- textmodel_wordfish(dtm, dir = c(6, 5))

textplot_scale1d(model, "documents")
