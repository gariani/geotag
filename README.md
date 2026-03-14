# GeoTag

Add or fix location data on your photos. Pick photos from your gallery, set a place on the map (or search for it), and save. EXIF is written so the location shows up in your photo library. You can apply to originals or export copies to a folder (e.g. Pictures/GeoTag).

**Run**

```bash
flutter pub get
flutter run
```

Android and iOS. Map tiles: OpenStreetMap.

**RAW photo thumbnails (desktop)**

On Linux, macOS, and Windows, RAW files (ARW, CR2, NEF, etc.) need external tools for thumbnails:

- **exiftool** (recommended): `pacman -S perl-image-exiftool` (Arch/Manjaro), `brew install exiftool` (macOS)
- **dcraw** (fallback): `pacman -S dcraw` (Arch/Manjaro)

Call `RawThumbnailService.instance.checkDependencies()` to detect if these are installed.
