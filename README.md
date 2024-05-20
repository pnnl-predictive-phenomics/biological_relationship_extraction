# Biological Relationship Extraction

This repository contains all code and results from the "Protein-Protein Interaction Networks Derived from Classical and Machine Learning-Based Natural Language Processing Tools" publication. 

Please cite **Degnan et al. 2024** when using code for this repository. 

Link to publication: Publication coming soon. 

## Repository Structure

| Folder | Subfolder | Description |
|--------|-----------|-------------|
| algorithms | --- | Scripts to run all algorithms |
| algorithms | BERT_training | Code to train BERT models |
| benchmarks | --- | Results from each of the 3 main studies |
| benchmarks | benchmark1 | Results from the study with the GPGP and BioRed datasets |
| benchmarks | benchmark1/.../raw_output/ | Raw results from the tool without any processing |
| benchmarks | benchmark1/.../processed_output/ | Tool output with truth annotations, following processing by ___ |

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