import os
import re

def process_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # Replace specific ScaffoldMessenger Error blocks
    # e.g.:
    # ScaffoldMessenger.of(context).showSnackBar(
    #   SnackBar(
    #     content: Text('Error: $e'),
    #     backgroundColor: Theme.of(context).colorScheme.error,
    #   ),
    # );
    error_pattern = re.compile(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\('Error:\s*\$e'\),\s*backgroundColor:\s*Theme\.of\(context\)\.colorScheme\.error,\s*\),\s*\);", re.DOTALL)
    content = error_pattern.sub(r"PremiumSnackbar.showError(context, e);", content)

    # Replace typical success strings using l10n
    success_pattern_1 = re.compile(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\((.*?)\),\s*\),\s*\);", re.DOTALL)
    
    # We want to be careful with success_pattern_1. If it's a simple match, we can replace it.
    def repl_success(match):
        text_arg = match.group(1).strip()
        # If the text_arg doesn't contain a SnackBar or something weird
        if 'SnackBar' not in text_arg:
            return f"PremiumSnackbar.showSuccess(context, {text_arg});"
        return match.group(0)

    content = success_pattern_1.sub(repl_success, content)

    if content != original_content:
        # Check if PremiumSnackbar is imported
        if 'PremiumSnackbar' in content and 'import \'../shared/premium_snackbar.dart\'' not in content:
            # Not foolproof, but we can try to inject it after the last import
            if 'import \'../../' in content:
                # find last import
                pass # let's just do it manually if it fails
        
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {path}")

def main():
    features_dir = r"C:\Users\PC\.gemini\antigravity\worktrees\ivra_refill\resume-unfinished-devin-session\lib\src\features"
    for root, dirs, files in os.walk(features_dir):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
