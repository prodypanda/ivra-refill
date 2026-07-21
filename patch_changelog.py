with open("CHANGELOG.md", "r") as f:
    lines = f.readlines()

with open("CHANGELOG.md", "w") as f:
    found = False
    for line in lines:
        if line.startswith("- Updated safe package dependencies"):
            if not found:
                f.write(line)
                found = True
        else:
            f.write(line)
