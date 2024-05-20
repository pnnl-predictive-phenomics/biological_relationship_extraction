import pandas as pd
from transformers import BioGptTokenizer, BioGptForCausalLM, pipeline

# Extract terms and text
data = pd.read_csv("input/path")

# Pull tokens, model, and generator
tokenizer = BioGptTokenizer.from_pretrained("microsoft/BioGPT-Large-PubMedQA")
model = BioGptForCausalLM.from_pretrained("microsoft/BioGPT-Large-PubMedQA")

# Iterate through file
for row in range(len(data)):

	# Build query
	query = data["Query"][row] + "_response: "

	# Generate the response
	generator = pipeline("text-generation", model = model, tokenizer = tokenizer)
	res = generator(query, max_new_tokens = 100, num_return_sequences = 1, do_sample = True)
	clean_res = res[0]["generated_text"].split("_response: ")[1]

	# Write response
	file = open("/out/path", "a")
	file.writelines(str(row) + "\t" + str(data["PMID"][row]) + "\t" + clean_res + "\n")
	file.close()