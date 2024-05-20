import requests

## Steps to running SOLAR:
# 1. Install text-generation-webui from https://github.com/oobabooga/text-generation-webui
# 2. Run the `update_macos.sh` script (or whatever version for your current computer)
# 3. Use the `download-model.py` script to install upstage/SOLAR-10.7B-Instruct-v1.0
# 4. Run `python3 server.py --listen --api --model-menu --chat-buttons`, select the model, and then run the following script.

URL = "http://localhost:5000/v1/chat/completions"
MODEL_URL = "http://localhost:5000/v1/internal/model/load/"
REQUEST_HEADERS = {
    "Content-Type": "application/json"
}

def run_llm(system_prompt, content):

    chat_history = [{"role": "system", "content": system_prompt},{"role": "user", "content": content},]

    model_params = {'model_name': 'SOLAR-10.7B-Instruct-v1.0','args': {'n_gpu_layers': 999},'settings': {'instruction_template': 'Alpaca'}}

    data = {"model_name": "SOLAR-10.7B-Instruct-v1.0", "mode": "instruct", "character": "Assistant", "max_new_tokens": 5, "instruction_template": "Alpaca", "messages": chat_history}

    response = requests.post(URL, headers=REQUEST_HEADERS, json=data, verify=False)
    clean_response = response.json()["choices"][0]["message"]["content"]
    clean_response = clean_response.strip("\n")
    clean_response = clean_response[0:4]
    return(clean_response)