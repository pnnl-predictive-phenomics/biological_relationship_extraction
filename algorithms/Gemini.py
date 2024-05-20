import google.generativeai as genai
from google.generativeai.types import HarmCategory, HarmBlockThreshold

def use_gemini(key, number, query, PMID, outfile):

    # Pull API key, model, and generate the response 
    genai.configure(api_key = key)
    model = genai.GenerativeModel("models/gemini-1.5-pro-latest")
    response = model.generate_content(query,
    safety_settings={
            HarmCategory.HARM_CATEGORY_HATE_SPEECH: HarmBlockThreshold.BLOCK_NONE,
            HarmCategory.HARM_CATEGORY_HARASSMENT: HarmBlockThreshold.BLOCK_NONE,
            HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT: HarmBlockThreshold.BLOCK_NONE
    })

    # Write output
    to_write = open(outfile, "a")
    to_write.writelines(str(number) + "\t" + str(PMID) + "\t" + response.text.replace("\n", "") + "\n")
    to_write.close()