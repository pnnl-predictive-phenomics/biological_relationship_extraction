# Biological Relationship Extraction

This repository contains all code and results from the "Protein-Protein Interaction Networks Derived from Classical and Machine Learning-Based Natural Language Processing Tools" publication. 

Please cite **Degnan et al. 2024** when using code for this repository. 

Link to publication: Publication coming soon. 

## Repository Structure

| Folder | Subfolder | Description |
|--------|-----------|-------------|
| algorithms | --- | Scripts to run all algorithms |
| algorithms | BERT_training | Code to train BERT models, adapated from [Lee et al. 2022](https://github.com/ssr01357/BertSRC) |
| benchmarks | --- | Contains all output file for the 3 main studies in this publication |
| benchmarks | benchmark1 | Results from the study with the GPGP and BioRed datasets |
| benchmarks | benchmark1/.../raw_output/ | Raw results from the tools without any processing |
| benchmarks | benchmark1/.../processed_output/ | Cleaned "raw output" with truth annotations, following processing by ___ |
| benchmarks | benchmark2 | Results from the *C. elegans* interactome from UniProt study |
| benchmarks | benchmark2/full_vs_title_abstract | Mini-study to determine algorithm performance of "full text" versus titles & abstracts only | 
| benchmarks | benchmark2/pdf_vs_clean | Mini-study to determine algorithm performance of two "full text" methods - pdfs or "clean text" |
| benchmarks | benchmark2/complete_results | Results of using each tool to reconstruct the UniProt *C. elegans* interactome network | 
| benchmarks | benchmark2/.../extracted_relationships | Raw output of each tool |
| benchmarks | benchmark2/.../binary_relationships | Cleaned raw output, "extracted relationships", with unique protein-protein interactions, using ___ | 
| benchmarks | benchmark2/.../networks | PNG of each network from each study | 
| benchmarks | benchmark3 | Results from the *E. coli* PubMed query. Folder structure follows the extracted relationships, binary relationships, and networks folders from benchmark 2 |
| data | --- | Contains all input files for training and running the NLP tools |
| data | benchmark1 | Holds the training data for the BERT datasets, as well as the GPGP and BioRED testing datasets |
| data | benchmark1/training | Training datasets from [Su & Vijay 2022](https://github.com/udel-biotm-lab/BERT-RE) |
| data | benchmark1/testing | Testing datasets, including the in-house GPGP dataset, and [BioRed](https://huggingface.co/datasets/bigbio/biored) |
| data | benchmark2 | Contains the *C. elegans* interactome and synonyms from UniProt. Also contains csvs of PubMed IDs and whether they were "clean text", PDF, or title and abstract |
| data | benchmark3 | Contains the *E. coli* synonyms from UniProt. Also contains csvs of PubMed IDs and whether they were "clean text", PDF, or title and abstract |
| plots | --- | Holds scripts for building the plots in this publication, including networks and all figures, tables, and supplemental figures and tables | 
| processing | --- | Scripts for various tasks |
| processing | format_BERT | Script for formatting inputs for BERT models |
| processing | format_LLMs | Script for formatting inputs for BioGPT, SOLAR, and Gemini |
| processing | pull_papers | Script for extracting papers as either "clean text", pdf, or titles and abstracts |
| processing | synonym_table | Script for building a synonym table for mapping protein IDs to their common names from UniProt |

## Algorithm Scripts & Names

| Script Name | Algorithm Name in Publication |
|-------------|-------------------------------|
| co_occurrence.R | Sentence CoOccurrence, Relational Term |
| fixed_term.R | Fixed Term |
| pubmedmineR_and_cosine.R | pubmed.mineR & cosine | 
| TRIPS.py | TRIPS |
| REACH.py | REACH |
| BERT.py | PubMedBERT & BioBERT|
| BioGPT.py | BioGPT |
| SOLAR.py | SOLAR |
| Gemini.py | Gemini |