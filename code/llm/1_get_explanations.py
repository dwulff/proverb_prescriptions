import requests
import concurrent.futures
import pandas as pd
import time
import sys
from functools import partial # Import partial


with open("1_data/api.txt", "r") as f:
  api = f.readlines()

url = api[0]

headers = {
    'Authorization': api[1],
    'Content-Type': 'application/json'
}

def run(system, user):
    data = {
        "model": "google/gemma-3-27b-it",
        "messages": [
            {"role": "system", "content": [{"type": "text", "text": system}]},
            {"role": "user", "content": [{"type": "text", "text": user}]}
        ],
        "max_tokens": 500
    }
    
    response = requests.post(url, headers=headers, json=data)
    return response.json()["choices"][0]["message"]["content"]

def run_parallel_map(system_prompt, users, workers=10):
    func = partial(run, system_prompt) 
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as executor:
        results = list(executor.map(func, users, chunksize=max(1, len(users)//workers))) # chunksize can help performance
    return results


link = "PRIVATE_CORPUS_URL_REMOVED"
text = requests.get(link)
proverbs = text.text.split("\n")

system_prompt = "You are a proverb scholar who provides accurate and short explanations of the gist of proverbs."
user_prompts = [f"Provide a 30-word explanation of the gist of the proverb '{proverb}'.\nReturn your answer strictly using this format: Gist=[explanation]" for proverb in proverbs]

gists = pd.DataFrame({"proverb": proverbs, "gist": [None] * len(proverbs)})

# --- Revised Loop ---
batch_size = 200
num_prompts = len(user_prompts)
for i in range(0 * batch_size, num_prompts, batch_size):
    begin = i
    end = min(begin + batch_size, num_prompts) 
    current_prompts = user_prompts[begin:end]
    start = time.time()
    batch_results = run_parallel_map(system_prompt, current_prompts, workers=200) 
    gists.iloc[begin:end, gists.columns.get_loc('gist')] = batch_results 
    duration = round(time.time() - start, 2)
    print(f"Processing batch: {begin//batch_size + 1}, Prompts: {begin} to {end-1}, Duration: {duration}s")

gists.to_csv("1_data/processing/proverb_explanations_gemma3_27.csv", index=False)



