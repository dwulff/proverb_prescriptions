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


proverb_tbl = pd.read_csv("1_data/processing/proverb_explanations_tags_gemma3_27.csv")
proverbs = proverb_tbl["proverb"].values
gists = proverb_tbl["gist_clean"].values

texts = [f"**Proverb and Gist:**\nProverb: {proverb}\nGist: {gist}" for proverb, gist in zip(proverbs, gists)]

system_prompt = "You are an expert on proverbs and decision making who accurately assesses the meanings of proverbs."

assessments = [
  "Does the proverb provide guidance on how to act or make decisions?",
  "Does the proverb favor risk or caution?",
  "Does the proverb favor short-term or long-term consequences?",
  "Does the proverb favor your own or other people’s interests?",
  "Does the proverb favor autonomy or compliance?",
  "Does the proverb favor trust or suspicion?",
  "Does the proverb favor honesty or deception?",
  "Does the proverb favor equality or hierarchy?",
  "Does the proverb favor kindness or malice?",
  "Does the proverb favor cooperation or competition?"
]

assessments = ["Your task is to carry out the following assessment: " + ass + " To assess this, carefully examine both the proverb and its gist." for ass in assessments]

responses = [
  "'strong no', 'no', 'indifferent', 'yes', 'strong yes'",
  "'strongly favoring caution', 'favoring caution', 'indifferent', 'favoring risk', 'strongly favoring risk'",
  "'strongly favoring long-term consequences', 'favoring long-term consequences', 'indifferent', 'favoring short-term consequences', 'strongly favoring short-term consequences'",
  "'strongly favoring other people’s interests', 'favoring other people’s interests', 'indifferent', 'favoring your own interests', 'strongly favoring your own interests'",
  "'strongly favoring compliance', 'favoring compliance', 'indifferent', 'favoring autonomy', 'strongly favoring autonomy'",
  "'strongly favoring trust', 'favoring trust', 'indifferent', 'favoring suspicion', 'strongly favoring suspicion'",
  "'strongly favoring honesty', 'favoring honesty', 'indifferent', 'favoring deception', 'strongly favoring deception'",
  "'strongly favoring equality', 'favoring equality', 'indifferent', 'favoring hierarchy', 'strongly favoring hierarchy'",
  "'strongly favoring kindness', 'favoring kindness', 'indifferent', 'favoring malice', 'strongly favoring malice'",
  "'strongly favoring cooperation', 'favoring cooperation', 'indifferent', 'favoring competition', 'strongly favoring competition'"
]

chain = "**Reasoning**:\nBefore finalizing your assessment, briefly reason through the assessment. This reasoning is part of your process and should not appear in the final output." 
response = "**Output**:\nAt the very end, provide the answer on the assessment using one of the following five possible response options: {response_set}. Return your answer strictly in the following format: Answer=[response]"

dimensions = ["prescriptivity","risk","time","social","autonomy","trust","honesty","equality","kindness","cooperation"]
# for dim in dimensions:
#   proverb_tbl[dim] = ""


proverb_tbl = pd.read_csv("1_data/processing/proverb_explanations_tags_ratings_gemma3_27_tmp.csv")


for dim in range(9, len(dimensions)):
  
  user_prompts = []
  for i in range(len(proverbs)):
    proverb = texts[i]
    assessment = assessments[dim]
    response_set = responses[dim]
    user_message = assessment + "\n\n" + proverb + "\n\n"  + chain + "\n\n" + response.format(response_set = response_set)
    user_prompts.append(user_message)

  # --- Revised Loop ---
  batch_size = 300
  num_prompts = len(user_prompts)
  for i in range(109 * batch_size, num_prompts, batch_size):
      begin = i
      end = min(begin + batch_size, num_prompts)
      current_prompts = user_prompts[begin:end]
      start = time.time()
      batch_results = run_parallel_map(system_prompt, current_prompts, workers=300)
      proverb_tbl.iloc[begin:end, proverb_tbl.columns.get_loc(dimensions[dim])] = batch_results
      duration = round(time.time() - start, 2)
      print(f"Processing dimension: {dimensions[dim]}, Batch: {begin//batch_size + 1}, Prompts: {begin} to {end-1}, Duration: {duration}s")
            
proverb_tbl.to_csv("1_data/processing/proverb_explanations_tags_ratings_gemma3_27.csv", index=False)



