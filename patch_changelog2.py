with open("CHANGELOG.md", "r") as f:
    lines = f.readlines()

with open("CHANGELOG.md", "w") as f:
    for line in lines:
        if line.startswith("- Updated safe package dependencies"):
            continue
        f.write(line)
