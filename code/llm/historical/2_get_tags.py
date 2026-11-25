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

proverb_tbl = pd.read_csv("1_data/processing/proverb_explanations_gemma3_27.csv")
proverb_tbl['gist_clean'] = proverb_tbl['gist'].astype(str).str.replace(r"Gist=\[{0,1}", "", n=1, regex=True)
proverb_tbl['gist_clean'] = proverb_tbl['gist_clean'].str.replace(r"\]{0,1}", "", regex=True)
proverb_tbl['gist_clean'] = proverb_tbl['gist_clean'].str.replace(r"\n", "", regex=True)
proverbs = proverb_tbl["proverb"].values
gists = proverb_tbl["gist_clean"].values

system_prompt = "You are a proverb scholar, skilled in assigning accurate and concise taxonomic tags to proverbs, considering both their general meaning and specific illustrative context."
user_prompt = """Characterize the following proverb and its gist with up to three taxonomic tags. Pay special attention to capturing both its general wisdom and any specific illustrative imagery or objects mentioned.

**Proverb and Gist:**
Proverb: {proverb}
Gist: {gist}

**Tagging Rules and Process:**
* **Internal Deliberation:** Before finalizing your tags, briefly reason through your choices to ensure they align with all rules. This reasoning is part of your process and should not appear in the final output.
* **Tag Limit:** Assign no more than three tags.
* **Conciseness:** Tags should be a maximum of two words each.
* **Gist Focus:** Tags must closely capture the proverb's core gist.
* **Context Representation:**
    * Tags must reflect the proverb's general meaning.
    * If the proverb uses specific imagery or a concrete domain to illustrate its point, one tag should directly represent this illustrative context. Strive to name the key element of this imagery.
* **No Acronyms:** Avoid using acronyms in tags.

**Output:**
Return *only* the tags, separated by a semicolon, strictly following this format:
Answer=[tags]"""
user_prompts = [user_prompt.format(proverb = proverb, gist = gist) for proverb, gist in zip(proverbs, gists)]

proverb_tbl["tags"] = ""

# --- Revised Loop ---
batch_size = 400
num_prompts = len(user_prompts)
for i in range(0 * batch_size, num_prompts, batch_size):
    begin = i
    end = min(begin + batch_size, num_prompts) 
    current_prompts = user_prompts[begin:end]
    start = time.time()
    batch_results = run_parallel_map(system_prompt, current_prompts, workers=400) 
    proverb_tbl.iloc[begin:end, proverb_tbl.columns.get_loc('tags')] = batch_results 
    duration = round(time.time() - start, 2)
    print(f"Processing batch: {begin//batch_size + 1}, Prompts: {begin} to {end-1}, Duration: {duration}s")

proverb_tbl.to_csv("1_data/processing/proverb_explanations_tags_gemma3_27.csv", index=False)



