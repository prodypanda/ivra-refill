import os
import re

directories = ['lib/src/features']

# we want to find patterns like ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
# or ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
# and replace with PremiumSnackbar.showError(context, e); / PremiumSnackbar.showError(context, error);

pattern1 = re.compile(r'ScaffoldMessenger\.of\([^)]+\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\((e|error)\.toString\(\)\)\),?\s*\);', re.DOTALL)
pattern2 = re.compile(r'messenger\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\((e|error)\.toString\(\)\)\),?\s*\);', re.DOTALL)

for root, _, files in os.walk('lib/src/features'):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                
            original_content = content
            
            # Find and replace
            def replacer(match):
                var_name = match.group(1)
                return f"PremiumSnackbar.showError(context, {var_name});"
                
            content = pattern1.sub(replacer, content)
            content = pattern2.sub(replacer, content)
            
            if content != original_content:
                # Need to ensure PremiumSnackbar is imported.
                # Usually it is imported, but if not we should add it.
                if 'PremiumSnackbar' in content and 'premium_snackbar.dart' not in content:
                    # Let's just add it after the last import
                    import_idx = content.rfind("import '")
                    if import_idx != -1:
                        end_idx = content.find(";", import_idx) + 1
                        import_stmt = "\nimport '../shared/premium_snackbar.dart';"
                        # Actually we need relative path. Since we don't know it, we can just use absolute package import
                        import_stmt = "\nimport 'package:ivra_refill/src/features/shared/premium_snackbar.dart';"
                        content = content[:end_idx] + import_stmt + content[end_idx:]

                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Patched: {filepath}")
