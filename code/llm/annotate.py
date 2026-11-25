"""Adapted rerun, NOT historical generation code; see historical/ and docs/llm.md."""
import argparse
import csv
import json
import os
from pathlib import Path
import re
import urllib.request

import prompts

ROOT = Path(__file__).resolve().parents[2]
MODEL = "google/gemma-3-27b-it"


def messages(stage, proverb, gist=""):
    if stage == "gist":
        system, user = prompts.GIST_SYSTEM, prompts.GIST_USER.format(proverb=proverb)
    elif stage == "tags":
        system, user = prompts.TAG_SYSTEM, prompts.TAG_USER.format(proverb=proverb, gist=gist)
    else:
        i = prompts.dimensions.index(stage)
        system = prompts.system_msg
        user = (prompts.assessments[i] + "\n\n" +
                f"**Proverb and Gist:**\nProverb: {proverb}\nGist: {gist}" +
                "\n\n" + prompts.chain + "\n\n" +
                prompts.response.format(response_set=prompts.responses[i]))
    return [{"role": role, "content": [{"type": "text", "text": text}]}
            for role, text in (("system", system), ("user", user))]


def clean_gist(raw):
    # Preserve the original tagging script's cleanup, including newline removal.
    return re.sub(r"Gist=\[?", "", raw, count=1).replace("]", "").replace("\n", "")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run", action="store_true", help="Send requests; otherwise preview one synthetic prompt per stage")
    parser.add_argument("--limit", type=int, default=1, help="Number of nonempty proverbs; default 1")
    parser.add_argument("--output-name", default="annotations.jsonl", help="Checkpoint filename within private/llm/")
    args = parser.parse_args()
    stages = ["gist", "tags"] + prompts.dimensions
    if not args.run:
        for stage in stages:
            print(json.dumps({"stage": stage, "model": MODEL, "max_tokens": 500,
                              "messages": messages(stage, "<PROVERB>", "<GIST>")}, ensure_ascii=False))
        return
    if args.limit < 1 or Path(args.output_name).name != args.output_name:
        parser.error("Use a positive --limit and a plain --output-name filename")
    endpoint = os.environ["LLM_API_URL"]
    authorization = os.environ["LLM_AUTHORIZATION"]  # Complete value, e.g. Bearer ...
    if not endpoint.startswith("https://"):
        parser.error("LLM_API_URL must use HTTPS")
    output = ROOT / "private" / "llm" / args.output_name
    output.parent.mkdir(parents=True, exist_ok=True)
    records = {}
    if output.exists():
        for line in output.read_text().splitlines():
            record = json.loads(line)
            records[(record["proverb_id"], record["stage"])] = record
    with (ROOT / "private" / "proverb_lookup.csv").open(newline="", encoding="utf-8") as f:
        rows = [row for row in csv.DictReader(f) if row["proverb"]][:args.limit]
    for row in rows:
        pid, proverb = int(row["proverb_id"]), row["proverb"]
        gist = ""
        for stage in stages:
            payload = {"model": MODEL, "max_tokens": 500, "messages": messages(stage, proverb, gist)}
            key = (pid, stage)
            if key in records:
                record = records[key]
                if record["request"] != payload or record["endpoint"] != endpoint:
                    raise ValueError("Checkpoint configuration differs; choose a new --output-name")
            else:
                request = urllib.request.Request(endpoint, data=json.dumps(payload).encode(), headers={
                    "Authorization": authorization, "Content-Type": "application/json"})
                with urllib.request.urlopen(request, timeout=120) as response:
                    result = json.load(response)
                answer = result["choices"][0]["message"]["content"]
                if not isinstance(answer, str):
                    raise ValueError("Expected a text response")
                record = {"proverb_id": pid, "stage": stage, "endpoint": endpoint,
                          "request": payload, "response": result, "answer": answer}
                with output.open("a", encoding="utf-8") as f:
                    f.write(json.dumps(record, ensure_ascii=False) + "\n")
                records[key] = record
            if stage == "gist":
                gist = clean_gist(record["answer"])
        print(f"Completed proverb_id={pid}")


if __name__ == "__main__":
    main()
