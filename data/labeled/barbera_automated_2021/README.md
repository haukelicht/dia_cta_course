# News articles coded for economic news topic and sentiment from Barberá et al. (2021)

author: Hauke Licht & Naomi Yagai\
date: 2024-01-12

## Description

In their 2021 *Political Analysis* paper "Automated Text Classification of News Articles: A Practical Guide," Barberá and colleagues analyze the tone of coverage of the US national economy in the New York Times. To this end, they identify articles about the economy and their tone (positive--negative).

Their measurements are generated through supervised text classification based on trained as well as crowd coders' annotations of news articles' texts.

## Annotation procedure

The authors have distributed multiple samples for annotation by trained coders and/or crowd coders. Here, we focus on dataset **5AC**, which records article-segment-level codings (i.e., of the first five sentences of an article) by 3-10 crowd coders. Each article segment was coded by each coder along two coding dimensions:

-   *relevance:* 'yes' if the article gives a coder indication of how the economy is performing, 'not sure' if a coder could not determine, and 'no' otherwise
-   *positivity:* a score ranging from 1 (very negative) to 9 (very positive) coders assign to relevant news articles (i.e., those for which *relevance* == 'yes')

## Datasets

I provide one data set based on the 

1. `econ_topic`: This data set records news articles classified by human coders according to whether or not the article is about how the economy is performing.
	- texts are in column `text`
	- classification are in column `label` and `"yes"` if a given article is about how the economy is performing and `"no"`otherwise 
	- metadata (columns `metadata__*`) records the date and headline of the article
2. `econ_sentiment`: This data set records the sentiment of news articles that are about how the economy is performing.
	- texts are in column `text`
	- average human raters sentiment scores are in column `label` and range from 1 to 9 (theoretical range)
	- metadata (columns `metadata__*`) records the date and headline of the article


### Data source

source: replication data on Political Analysis' Harvard Dataverse: <https://dataverse.harvard.edu/file.xhtml?persistentId=doi:10.7910/DVN/MXKRDE/SCOMRU&version=1.2>

### Download data files

| dataset key            | file                                           | url                                                                                                                                   |
|:-----------------------|:-----------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------|
| econ_topic | barbera_automated_2021-econ_topic.csv | https://cta-text-datasets.s3.eu-central-1.amazonaws.com/labeled/barbera_automated_2021/barbera_automated_2021-econ_topic.csv |
| econ_sentiment | barbera_automated_2021-econ_sentiment.csv | https://cta-text-datasets.s3.eu-central-1.amazonaws.com/labeled/barbera_automated_2021/barbera_automated_2021-econ_sentiment.csv |



