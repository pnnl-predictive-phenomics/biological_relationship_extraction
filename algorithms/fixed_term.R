library(tidyverse)
library(pubmed.mineR)

# Update tdm_for_lsa to completely match expression 
tdm_for_lsa2 <- function(object, y) {
  TDM_matrix_new = NULL
  testa2 = NULL
  for (i in 1:length(y)) {
    tempO = gregexpr(paste0("\\b", y[i], "\\b"), object@Abstract)
    tempa = unlist(lapply(tempO, function(x) {
      if (x[1] != -1) 
        return(length(x))
      else return(0)
    }))
    testa2 = matrix(tempa, nrow = 1, ncol = length(object@Abstract))
    rownames(testa2) <- y[i]
    TDM_matrix_new = rbind(TDM_matrix_new, testa2)
  }
  return(TDM_matrix_new)
}

#' @param text (character) A single string containing the text to parse
#' @param term1 (character) The first term in a potential relationship
#' @param term2 (character) The second term in a potential relationship
#' @param pmid (character) An optional character for returning a paper ID.
fixed_term <- function(text, term1, term2, pmid) {
  
  # Any part of this word must match (i.e. 'activate' will also cover activates, deactivate, deactivates, 
  # inactivate, inactivates)
  verbs_relational <- c("abate", "abolish", "acetylate", "acrylate", "activate", 
                        "acylate", "adhere", "affix", "alkylate", "anabolize", 
                        "annex", "append", "assemble", "associate", "attach", 
                        "attenuate", "bind", "block", "butylate", "carboxylate", 
                        "catabolize", "catalyze", "chain", "cleave", "cohere", 
                        "combine", "complex", "confine", "connect", "constrain", 
                        "constrict", "couple", "crylate", "decrease", "detach", 
                        "detain", "deter", "dimerize", "diminish", "dissipate", 
                        "elevate", "eliminate", "enhance", "ethylate", "extenuate", 
                        "facilitate", "fasten", "free", "hemolyze", "hinder", 
                        "hydrolyze", "impair", "impede", "increase", "induce", 
                        "inhibit", "interact", "intercept", "interfere", "join", 
                        "liberate", "ligate", "link", "loosen", "metabolize", 
                        "methylate", "moderate", "modulate", "obstruct", "occlude", 
                        "oligomerize", "osmolyze", "pair", "phosphorylate", 
                        "prevent", "prohibit", "promote", "react", "reduce", 
                        "regulate", "relate", "release", "repress", "restrain", 
                        "restrict", "salicylate", "silence", "slice", "stimulate", 
                        "stop", "strap", "suppress", "tether", "trigger", 
                        "ubiquitinylate", "unite", "weaken", "wrap")
  
  # Make a null table
  NullTable <- data.table(
    "Co-Occurring Sentences" = NULL,
    "Sentence Position in R" = NULL,
    "Fixed Term" = NULL,
    "Term1" = term1,
    "Term2" = term2,
    "PMID" = pmid)
  
  # Use pubmed.mineR tokenizer
  Sentences <- SentenceToken(text)
  
  # Create an abstracts class (name of an abstracts object, not an abstract object)
  MyAbs <- new("Abstracts", 
               Journal = rep("Unknown", length(Sentences)),
               Abstract = Sentences,
               PMID = 1:length(Sentences))
  
  # Get co-occurrence count
  co_occur <- tdm_for_lsa2(MyAbs, c(term1, term2)) %>%
    apply(1, function(x) {ifelse(x > 1, 1, x)}) %>%
    data.frame()
  the_count <- sum(co_occur[,1] == 1 & co_occur[,1] == co_occur[,2])
  
  # If there is no co-occurrence count, we assume the result is a true negative
  if (the_count == 0) {return(NullTable)}
  
  # Otherwise, look for a relationship between the two terms
  sentence_position <- which(co_occur[,1] == 1 & co_occur[,2] == 1)
  
  # Test for a relationship
  RelationTest <- lapply(sentence_position, function(the_position) {
    
    # Return a true positive only if the term exists between the other terms 
    if (grepl(paste0(verbs_relational, collapse = "|"), Sentences[the_position])) {
      
      # Pull the sentence
      sentence <- Sentences[the_position]
      
      # Ensure underscores are between terms so they the don't get split into different words
      term1_fix <- term1 %>% strsplit(" ") %>% unlist() %>% paste0(collapse = "_")
      term2_fix <- term2 %>% strsplit(" ") %>% unlist() %>% paste0(collapse = "_")
      verbs <- verbs_relational[lapply(verbs_relational, function(x) {grepl(x, sentence)}) %>% unlist()] 
      verbs_fix <- gsub(" ", "_", verbs)
      
      # Clean up sentence
      sentence <- gsub(term1, term1_fix, sentence)
      sentence <- gsub(term2, term2_fix, sentence)
      sentence <- gsub(paste0(verbs, collapse = "|"), paste0(verbs_fix, collapse = "|"), sentence)
      
      # Split the sentence
      splitsent <- strsplit(sentence, " ") %>% unlist()
      
      # Determine verb positions
      verb_pos <- which(grepl(paste0(verbs_fix, collapse = "|"), splitsent))
      
      # Term 1 position
      term1_pos <- which(grepl(term1_fix, splitsent))
      
      # Term 2 position
      term2_pos <- which(grepl(term2_fix, splitsent))
      
      # Make a data.frame of relationships
      relationships <- expand_grid(verb_pos, term1_pos, term2_pos) %>%
        data.frame() %>%
        mutate(
          Within = (verb_pos < term1_pos & verb_pos > term2_pos) | (verb_pos > term1_pos & verb_pos < term2_pos)
        )
      
      if (any(relationships$Within)) {
        
        return(
          data.table(
            #"Co-Occurring Sentences" = Sentences[the_position],
            "Sentence Position in R" = the_position,
            "Fixed Term" = splitsent[relationships[relationships$Within, "verb_pos"]] %>% paste0(collapse = " "),
            "Term1" = term1,
            "Term2" = term2,
            "PMID" = pmid)
        )
        
      } else {
        return(NullTable)
      }
      
    } else {
      return(NullTable)
    }
    
  })
  
  return(do.call(dplyr::bind_rows, RelationTest))
  
}



