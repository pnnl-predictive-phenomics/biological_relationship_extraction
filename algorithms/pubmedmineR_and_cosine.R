#' Run the pubmed miner tokenizer and lsa::cosine algorithm combination
#' 
#' @param text (character) A single string containing the text to parse
#' @param terms (character) A vector of terms to score the relationships in. There
#'    should be at least two terms. 
pubmedmineR_and_cosine <- function(text, terms) {
  
  # Extract tokenizer
  library(pubmed.mineR)
  
  # Calculate relationship score 
  library(lsa)
  
  # Data housekeeping packages
  library(dplyr)
  library(tidyr)
  
  # The sort function in python is different than in R
  Sys.setlocale(locale = "C")
  
  #################
  ## QUICK CHECK ##
  #################
  
  # Check text
  if (length(text) > 1) {
    stop("text should only be of length 1")
  }
  
  if (!is.character(text)) {
    text <- as.character(text) %>% sort()
  }
  
  # Check term
  if (length(terms) < 2) {
    stop("There should be at least two terms supplied to terms")
  }
  if (!is.character(terms)) {
    terms <- as.character(terms) 
  }
  terms <- terms %>% sort()
  
  ###################
  ## RUN ALGORITHM ##
  ###################
  
  # Tokenize the abstract into sentences
  Sentences <- SentenceToken(text)
  
  # Create an abstracts class (name of an abstracts object, not an abstract object)
  MyAbs <- new("Abstracts", 
               Journal = rep("Unknown", length(Sentences)),
               Abstract = Sentences,
               PMID = 1:length(Sentences))
  
  # Convert dist to a data.frame
  dist.to.df <- function(d){
    size <- attr(d, "Size")
    return(
      data.frame(
        subset(expand.grid(Biomolecule1 = 1:(size-1), Biomolecule2 = 2:size), Biomolecule1 < Biomolecule2),
        Score = as.numeric(d),
        row.names = NULL
      ) 
    )
  }
  
  # Calculate relationships, remove self-self relationships, and duplicate relationships
  tdm_for_lsa(MyAbs, terms) %>%
    as.data.frame() %>%
    arrange(row.names(.)) %>%
    t() %>%
    cosine() %>%
    as.dist() %>%
    dist.to.df() %>%
    mutate(
      Biomolecule1 = terms[Biomolecule1],
      Biomolecule2 = terms[Biomolecule2],
      ScoreName = "pubmed.mineR & Cosine"
    ) %>%
    arrange(Biomolecule1, Biomolecule2) %>%
    return()
  
}
