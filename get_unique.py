import re
with open("supabase/migrations/0001_initial_schema.sql", "r") as f:
    content = f.read()

# find all occurrences of client_request_id and check if unique
pattern = re.compile(r'(create table.*?\(.*?client_request_id.*?)\);', re.DOTALL | re.IGNORECASE)
for match in pattern.finditer(content):
    table_block = match.group(1)
    if 'unique' in table_block.lower():
        print("Found unique in a table with client_request_id")
