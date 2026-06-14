# MANDATORY DEVELOPER WORKFLOW (FOR ALL UPDATES)

Any AI developer, coding assistant, or agent working on this codebase MUST follow these steps exactly:

1. **Update the App Version**:
   - Every single update/feature MUST bump the version in `pubspec.yaml` (e.g., from `1.0.19+20` to `1.0.20+21`).
   - Run `.\scripts\generate_version.ps1` to update `lib/src/version.dart`.
2. **Commit and Create a Pull Request**:
   - Stage and commit all code changes.
   - Push your branch and create a Pull Request from `resume-unfinished-devin-session` to the `main` branch.
3. **Wait for Code Review and Resolve Conflicts**:
   - Wait for Devin AI / code review feedback on the Pull Request.
   - If changes are requested, apply them and update the Pull Request.
   - Resolve any merge conflicts that arise.
4. **Merge the Pull Request**:
   - Once all conflicts are fixed, code review is passed, and checks are green, merge the Pull Request on GitHub.
5. **Update the Local Branch**:
   - Switch to the `main` branch locally.
   - Pull the latest changes from `origin/main`.
6. **Compile Both Web and Android Versions**:
   - Compile both the Web app and the Android app (APK).
   - **CRITICAL**: Copy the compiled Android APK from the build directory to the user's workspace directory at `C:\tek\ivra_refill\build\app\outputs\flutter-apk\app-release.apk`.
7. **Publish the Web Version**:
   - Publish the compiled web build to Firebase Hosting.
