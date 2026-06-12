import json

file_path = 'lib/src/data/supabase_ivra_repository.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

with open('chunks.json', 'r', encoding='utf-16') as f:
    chunks = json.load(f)

for chunk in chunks:
    # Just replace target with replacement
    content = content.replace(chunk['TargetContent'], chunk['ReplacementContent'])

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Applied chunks to " + file_path)
