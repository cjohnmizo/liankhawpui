# Release Checklist

1. Upload a post image from device and confirm both full + thumb objects are created.
2. Verify feed/list cards load thumbnail image (bandwidth-friendly).
3. Verify post detail screen loads full image.
4. Upload a document and confirm open/download uses a signed URL.
5. Toggle Low Data Mode and verify smaller upload presets are used.
6. Run smoke checks:
   - `bash scripts/run_checks.sh`
   - `flutter test integration_test/app_functional_smoke_test.dart`
