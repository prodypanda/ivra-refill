# MANDATORY DEVELOPER WORKFLOW (FOR ALL UPDATES)

Any AI developer, coding assistant, or agent working on this codebase MUST follow these steps exactly:

1. **Update the App Version**:
   - Every single update/feature MUST bump the version in `pubspec.yaml` (e.g., from `1.0.19+20` to `1.0.20+21`).
   - Run `.\scripts\generate_version.ps1` to update `lib/src/version.dart`.
2. **Commit and Create a Pull Request**:
   - Stage and commit all code changes.
   - Push your branch and create a Pull Request from `resume-unfinished-devin-session` to the `main` branch.
3. **Wait for Code Review**:
   - DO NOT deploy or publish until you receive a review from Devin AI on the pull request.
   - If changes are requested, apply them and update the Pull Request.
4. **Compile Both Web and Android Versions**:
   - Run `flutter build apk --release --tree-shake-icons` (or use the deploy scripts) to compile the Android app.
   - Run the Flutter web build.
5. **Publish the Web Version**:
   - Publish the compiled web build to Firebase Hosting.
