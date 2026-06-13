import os

def fix_imports():
    files_to_fix = [
        r"C:\Users\PC\.gemini\antigravity\worktrees\ivra_refill\resume-unfinished-devin-session\lib\src\features\account\account_screen.dart",
        r"C:\Users\PC\.gemini\antigravity\worktrees\ivra_refill\resume-unfinished-devin-session\lib\src\features\hotels\hotels_screen.dart",
        r"C:\Users\PC\.gemini\antigravity\worktrees\ivra_refill\resume-unfinished-devin-session\lib\src\features\notifications\send_notification_screen.dart",
        r"C:\Users\PC\.gemini\antigravity\worktrees\ivra_refill\resume-unfinished-devin-session\lib\src\features\products\products_screen.dart",
        r"C:\Users\PC\.gemini\antigravity\worktrees\ivra_refill\resume-unfinished-devin-session\lib\src\features\settings\settings_screen.dart",
    ]

    for path in files_to_fix:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        if 'premium_snackbar.dart' not in content:
            # find the last import and insert it after
            lines = content.split('\n')
            last_import_idx = -1
            for i, line in enumerate(lines):
                if line.startswith('import '):
                    last_import_idx = i
            
            if last_import_idx != -1:
                # determine relative path
                if 'features/account' in path.replace('\\', '/'):
                    lines.insert(last_import_idx + 1, "import '../shared/premium_snackbar.dart';")
                elif 'features/hotels' in path.replace('\\', '/'):
                    lines.insert(last_import_idx + 1, "import '../shared/premium_snackbar.dart';")
                elif 'features/notifications' in path.replace('\\', '/'):
                    lines.insert(last_import_idx + 1, "import '../shared/premium_snackbar.dart';")
                elif 'features/products' in path.replace('\\', '/'):
                    lines.insert(last_import_idx + 1, "import '../shared/premium_snackbar.dart';")
                elif 'features/settings' in path.replace('\\', '/'):
                    lines.insert(last_import_idx + 1, "import '../shared/premium_snackbar.dart';")
            
            with open(path, 'w', encoding='utf-8') as f:
                f.write('\n'.join(lines))
            print(f"Added import to {path}")

if __name__ == '__main__':
    fix_imports()
