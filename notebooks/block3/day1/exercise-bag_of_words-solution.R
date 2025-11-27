# +~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~ #  
#
#' @title  Solutions for exercises 1 and 2 from block 3, day 1
#' @author Hauke Licht
#' @date   2025-11-26
#
# +~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~ #

library(quanteda)
library(quanteda.corpora)

# EXERCISE 1 -----

#' 1. load the corpus named `data_corpus_immigrationnews` from the integrated data of the `quanteda.corpora` package
data("data_corpus_immigrationnews", package = "quanteda.corpora")

#' 
#' 2. Inspect the corpus:
#'     1. How many documents are in the corpus?
ndoc(data_corpus_immigrationnews)
#'     2. How many "document variables" does it have?
ncol(docvars(data_corpus_immigrationnews))

#' 3. Tokenize the documents in the corpus and name the resulting object `toks`. Compute:
#'     1. the lowest number of tokens per document
#'     2. the highest number of tokens per document
#'     3. the average number of tokens per document
toks <- tokens(data_corpus_immigrationnews)
summary(ntoken(toks))

#' 4. Create a document-feature matrix (DFM) from the corpus and name it `dtm`
dtm <- dfm(toks)

stopwords("en")
  
# EXERCISE 2 -----

#' 2. Apply the following pre-processing options to the corpus to create 
#'  object `dtm`: _lowercasing_, _punctuation removal_, _stop word removal_, 
#'  and _stemming_

dtm <- data_corpus_immigrationnews |> 
  tokens(remove_punct = TRUE) |> 
  tokens_tolower() |> 
  tokens_remove(stopwords(language = "en")) |> 
  tokens_wordstem(language = "en")

