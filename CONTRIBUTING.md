# Contributing to Liankhawpui

Thanks for your interest in improving Liankhawpui.

## Development setup
1. Fork and clone this repository.
2. Copy `.env.example` to `.env` and set your own values.
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run static checks:
   ```bash
   flutter analyze
   flutter test
   ```

## Branches and commits
- Create focused branches from `main`.
- Keep commits small and descriptive.
- Use clear commit messages in imperative form (e.g. `Add CI lint workflow`).

## Pull requests
- Describe the problem and the solution.
- Include testing evidence (`flutter analyze`, `flutter test`, integration command if relevant).
- Attach screenshots for UI changes.
- Keep secrets and private keys out of commits.

## Code style
- Follow existing Flutter/Dart patterns in the repository.
- Prefer feature-first structure and keep logic in the correct layer.
- Run `dart format .` before opening a PR.
