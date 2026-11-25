"""Original annotation prompt wording; see docs/llm.md for provenance."""

GIST_SYSTEM = "You are a proverb scholar who provides accurate and short explanations of the gist of proverbs."

TAG_SYSTEM = "You are a proverb scholar, skilled in assigning accurate and concise taxonomic tags to proverbs, considering both their general meaning and specific illustrative context."

TAG_USER = """Characterize the following proverb and its gist with up to three taxonomic tags. Pay special attention to capturing both its general wisdom and any specific illustrative imagery or objects mentioned.

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

system_msg = "You are an expert on proverbs and decision making who accurately assesses the meanings of proverbs."

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

GIST_USER = "Provide a 30-word explanation of the gist of the proverb '{proverb}'.\nReturn your answer strictly using this format: Gist=[explanation]"
