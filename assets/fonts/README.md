# Fonts — Plus Jakarta Sans

IbuDaya's brand face is **Plus Jakarta Sans** (a warm Indonesian humanist sans,
by Tokotype). It is **not bundled in this repo yet** — the app currently renders
with the platform humanist sans and the tuned scale in
`lib/core/design/typography.dart`.

## To bundle it (offline, no runtime download)

1. Download the family (SIL Open Font License 1.1 — free for commercial use):
   https://fonts.google.com/specimen/Plus+Jakarta+Sans
   or https://github.com/tokotype/PlusJakartaSans/releases

2. Copy these static weights into this folder:

   ```
   assets/fonts/PlusJakartaSans-Regular.ttf   (400)
   assets/fonts/PlusJakartaSans-Medium.ttf    (500)
   assets/fonts/PlusJakartaSans-SemiBold.ttf  (600)
   assets/fonts/PlusJakartaSans-Bold.ttf      (700)
   assets/fonts/PlusJakartaSans-ExtraBold.ttf (800)
   ```

3. Uncomment the `fonts:` block in `pubspec.yaml`.

4. Set the family in `lib/core/design/typography.dart`:

   ```dart
   static const String? fontFamily = 'PlusJakartaSans';
   ```

5. `flutter pub get` — done. All text (via `Theme.of(context).textTheme` and
   `AppTypography.numeric`) picks it up automatically.

## License

SIL Open Font License, Version 1.1. Keep the `OFL.txt` from the download in this
folder when you add the `.ttf` files.
