# Publish this folder on GitHub

1. Extract the archive and open `feedback_app`, where README.md and pubspec.yaml are located.
2. Run `dart tool/setup.dart`, then `flutter analyze` and `flutter test`.
3. Create an empty repository on GitHub. Choose its visibility; do not initialize a second README.
4. In this project terminal run:

```powershell
git init
git branch -M main
git add .
git status
# Inspect staged files before committing: no private credentials/signing keys.
git commit -m "Add Flutter feedback app, documentation and screenshots"
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
git push -u origin main
```

Replace both placeholders with your actual repository URL. If Git requests identity, set your own git user.name and user.email. If this folder already has a remote, check `git remote -v` rather than adding it again.

Commit generated Android/iOS/web sources and pubspec.lock after setup. Do not commit build output. The screenshot paths are relative, so upload the entire docs/screenshots directory with the README. Uploading only README.md leaves the gallery broken.

Open GitHub → Actions to inspect the validation result. The workflow validates demo behaviour and a demo web build; it does not deploy Firebase rules or validate your live Firebase account.
