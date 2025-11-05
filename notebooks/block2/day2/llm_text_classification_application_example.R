# +~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~ #  
#
#' @title  Complete example of zero-shot LLM text classification with 
#'          `ellmer` and hugging face inference providers backend
#' @author Hauke Licht
#' @date   2025-11-06
#' @note   We are using data from the following paper
#' 
#'            Benoit, Kenneth, Drew Conway, Benjamin E. Lauderdale, Michael 
#'              Laver, and Slava Mikhaylov. (2016) "Crowd-sourced Text Analysis:
#'              Reproducible and Agile Production of Political Data", 
#'              _American Political Science Review_, 110(2), pp. 278–295. 
#'              DOI: https://doi.org/10.1017/S0003055416000058.
#'         
#'         See the README file in `data/labeled/benoit_crowdsourced_2016/` for
#'          data source info.
#
# +~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~+~ #

# Packages ----
library(readr)
library(dplyr)
library(stringr)
library(ellmer) # TODO: renv::install("ellmer@0.3.2") in case of loading error
library(yardstick) # TODO: renv::install("yardstick") in case of loading error

# Load and prepare the data ----

data_path <- file.path("data", "labeled", "benoit_crowdsourced_2016")

# specify the file name
fn <- "benoit_crowdsourced_2016-policy_area.csv"
# construct the local file path
fp <- file.path(data_path, fn)
# download if not already present
if (!file.exists(fp)) {
  url <- paste0("https://cta-text-datasets.s3.eu-central-1.amazonaws.com/labeled/", basename(data_path), "/", fn)
  df <- read_csv(url, show_col_types = FALSE)
  dir.create(data_path, recurse = TRUE, showWarnings = FALSE)
  write_csv(df, fp)
}

# read the CSV, selecting relevant columns only
df <- read_csv(fp, show_col_types = FALSE, col_select = c("uid", "text", "label", "metadata__gold"))

# subset to expert-labeled ("gold") examples only
df <- df |>
  filter(metadata__gold) |>
  select(-metadata__gold)


## understanding the data set

#' @note The data set provided by Benoit et al. (2016) contains British parties
#'  election manifestsos. Specifically it covers manifestos from Labour, the 
#'  Conversvative, and the Liberal Democrats.
#'  
#'  The annotation procedure is described in section "A METHOD FOR REPLICABLE 
#'   CODING OF POLITICAL TEXT: "A simple coding scheme for economic and social 
#'   policy" (in page 281 of the paper):
#'   
#'     Our scheme first asks readers to classify each sentence in a document as
#'      referring to economic policy ..., to social policy ..., or to neither.
#'     ...
#'   A sentences' policy area is indicated with the following label categories:
#'   
#'    - 1: neither
#'    - 2: "economic policy"
#'    - 3: "social policy"

# NOTE: the values in column "label" in the data frame record sentences classifications
table(df$label)

# so we recode them 
id2label <- c("neither", "economic", "social")
df$label <- id2label[df$label] 

print(table(df$label))

# show the text and label of an example
cat(str_wrap(df$text[6], exdent= 2))
df$label[6]

# Defining the instructions (system message) ----

#' @note Below, I define the system message that defines the coding task and 
#'  instructions for the LLM. It is strongly based on the original coding 
#'  instructions provided to coders (see page 20 in https://static.cambridge.org/content/id/urn:cambridge.org:id:article:S0003055416000058/resource/name/S0003055416000058sup001.pdf)

instructions <- '
You will provided with a sentence from an election manifesto.

Your task is to classify whether the sentence deals with economic policy, social policy, or neither.

You must classify sentences into one of the following categories: "economic", "social", or "neither".

## Definitions

- Sentences should be coded as "economic" if they deal with aspects such as: the economy, taxes, public spending, employment, inflation, monetary policy, industrial policy, trade, regulation of markets, competition, public vs. private, relations between employers, workers and trade unions.
- Sentences should be coded as "social" if they deal with aspects such as: education, health care, pensions, family, social welfare, equality/anti-discrimination, social housing, immigration-as-social-policy, role of the welfare state in regulating the social and moral behavior of individuals.

## Step-by-step instructions

1. Carefully read the text of the sentence, paying close attention to details.
2. Reason whether the sentence belongs to any of the categories. If not, return "neither" as your response.
3. Classify the sentence with the category it belongs to.
4. Add a one-sentence justification for your classification.

## Response format

Return your response as a JSON dictionary with the following fields:

- "reasoning": your reasoning of what category should be assigned to the text
- "category": the category you assigned to the sentence, one of "economic", "social", or "neither"
'
# NOTE: the instructions end here

# remove leading and trailing white spaces
instructions <- str_trim(instructions)

# Define the corresponing response format ----

#' @note As we instruction the LLM to return a JSON dictionary with two fields
#'  ("reasoning" and "category"), we define the corresponding response format:

response_format <- type_object(
  reasoning = type_string(
    description = "Your reasoning of what category should be assigned to the text"
  ),
  category = type_enum(
    c("neither", "economic", "social"), 
    description = "The category assigned to the sentence"
  ),
  .description = "Response format for manifesto sentence classification task"
)

# create the chat backend ----

#' @note if you have installed ollama , you can run the lines below instead:.
# model <- chat_ollama(
#   model = "gemma3:12b",
#   system_prompt = instructions
#   # NOTE: Ollama generation params (temperature, top_p, etc.) are generally controlled
#   # in the model’s Modelfile, not via per-call args. {ellmer}’s chat_ollama() mirrors
#   # OpenAI-like params, but for most Ollama models you’ll set these in the model config.
#   # See: https://ellmer.tidyverse.org/reference/chat_ollama.html
# )


# NOTE: need to set HUGGINGFACE_API_KEY in .Renviron file
#       see https://docs.posit.co/ide/user/ide/guide/environments/r/managing-r.html#renviron
#       use `usethis::edit_r_environ()` to open the file in RStudio
stopifnot("HUGGINGFACE_API_KEY env variable not see" = !is.na(Sys.getenv("HUGGINGFACE_API_KEY", unset = NA)))

# NOTE: here we use the OpenAI's open-source 20B parameter model via the provider Together AI
model_id = "openai/gpt-oss-20b:together"

model <- chat_huggingface(
  system_prompt = instructions,
  model = model_id,
  params = params(seed = 42),
  echo = NULL,
)

# test
model$chat("A simple sentence")

# Calling with the structured response format ----

# let's use the strucured response format to classify a sentence
response <- model$chat_structured(df$text[6], type = response_format)

# you can see 
response

# compare the classification to the "true" label
df$label[6]

# Classifying multiple texts (batch processing) ----

# let's define a small helper function that allows to classify multiple sentences
classify_sentences <- function(texts) {
  
  # reset the model state to an empty conversations
  # NOTE: this prevents previous model calls from affecting the current one
  model$set_turns(list())
  
  # set the instructions as the system prompt
  # NOTE: we are re-using the `instructions` defined above
  model$set_system_prompt(instructions)
  
  # call the model in parallel to classify multiple sentences
  resp <- parallel_chat_structured(
    model,
    as.list(texts),
    type = response_format, # NOTE: we are re-using the `response_format` defined above
    # on_error = "continue" # NOTE: this feature will be provided in future versions
  )
  
  # return the list of responses as a "tibble" data frame
  return(as_tibble(resp))
}

# Example batch:
texts <- c(
  "We propose cuts in income tax and corporate tax.",
  "Our healthcare system needs more funding to ensure quality care for all citizens.",
  "The sky is blue."
)
res_batch <- classify_sentences(texts)
res_batch

# apply to annotated examples ----

#'@ note: we can now apply the LLM to annotated examples from the data set to 
#'   see how well it performs in the classification task

# sample 25 examples per label class
{ # run both lines together
  set.seed(42)
  examples <- df |> 
    group_by(label) |> 
    sample_n(25) |> 
    ungroup() |> 
    sample_frac(1.0)
}

res_batch <- classify_sentences(examples$text)

# let's combine the texts and model responses
annotated <- bind_cols(examples, res_batch)

# make the "true" labelsa factor vector
annotated$label <- factor(annotated$label, levels = id2label)
  
## evaluate ----

# let's first create a confusion matrix of 
with(annotated, table(true = label, predicted = category))

#' @note many of the entries in the confusion matrix are on the diagonal. This
#'  is a good sign as it indicates that the model is correctly classifying 
#'  many of the sentences.

# F1 (computed with `yardstick` package)
f_meas(
  data = annotated,
  truth = label,
  estimate = category
)

# create full-fledged classification report
classification_report <- metric_set(
  precision, 
  recall,
  f_meas, 
  bal_accuracy, 
  accuracy, 
  mcc
)

# create a classification report
classification_report(
  data = annotated,
  truth = label,
  estimate = category
)

