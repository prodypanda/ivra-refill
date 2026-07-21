import re

with open("pubspec.yaml", "r") as f:
    content = f.read()

content = re.sub(
    r"(dependency_overrides:)",
    r"\1\n# TRACKING: path_provider_android build failed on 2026-07-21. Cannot remove pin yet.",
    content
)

with open("pubspec.yaml", "w") as f:
    f.write(content)
