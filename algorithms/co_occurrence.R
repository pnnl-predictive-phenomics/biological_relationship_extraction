library(tidyverse)
library(data.table)
library(pubmed.mineR)

#' Extract sentences where terms co-occur. Note whether there is a relational term
#'    between them. Optionally, include the pmid in the output. If there is co-occurrence,
#'    a data.table with the R-based count of co-occurring sentences will be returned,
#'    followed by the sentence position in R, the extracted relational terms, and
#'    the pmid if provided. 
#'    
#' @param text (character) A single string containing the text to parse
#' @param term1 (character) The first term in a potential relationship
#' @param term2 (character) The second term in a potential relationship
#' @param pmid (character) An optional character for returning a paper ID.
co_occurrence <- function(text, term1, term2, pmid = NULL) {

  #############################
  ## LIST RELATIONSHIP TERMS ##
  #############################
  
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
    
    
  ############################
  ## DETERMINE CO-OCCURENCE ##
  ############################
  
  # Use pubmed.mineR tokenizer
  Sentences <- SentenceToken(text)
  
  # Create an abstracts class (name of an abstracts object, not an abstract object)
  MyAbs <- new("Abstracts", 
               Journal = rep("Unknown", length(Sentences)),
               Abstract = Sentences,
               PMID = 1:length(Sentences))
  
  # Get co-occurence count
  co_occur <- tdm_for_lsa(MyAbs, c(term1, term2)) %>%
    apply(1, function(x) {ifelse(x > 1, 1, x)}) %>%
    data.frame()
  co_occur$Sum <- co_occur[,1] + co_occur[,2]
  
  #########################
  ## RUN RELATIONAL TEST ##
  #########################

  RelationTest <- lapply(Sentences[which(co_occur$Sum == 2)], function(sent) {
    VerbTest <- lapply(verbs_relational, function(x) {grepl(x, sent)}) %>% unlist()
    Verbs <- verbs_relational[VerbTest]
    return(paste0(Verbs, collapse = " "))
  }) %>% unlist()
  
  return(
    data.table(#"Co-Occurring Sentences" = Sentences[which(co_occur$Sum == 2)],
               "Sentence Position in R" = which(co_occur$Sum == 2),
               "Relational Terms" = RelationTest,
               "Term1" = term1,
               "Term2" = term2,
               "PMID" = pmid)
  )
  
  

}

