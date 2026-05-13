# PreSold iOS

Native SwiftUI app for UK resellers.

## Initial Xcode bootstrap (one-time)

The repository ships with the `PreSold/` source folder structure and
some files (Models, etc.) already populated, but the actual
`PreSold.xcodeproj` has to be created in Xcode (Claude Code can't
generate a working Xcode project reliably from chat).

1. In Xcode 15+: File → New → Project → iOS → App.
2. Product Name: `PreSold`. Interface: SwiftUI. Language: Swift.
   Storage: None. Tick "Include Tests."
3. When saving, navigate to `ios/` and use that as the project root —
   Xcode will create `ios/PreSold.xcodeproj` and a `PreSold/` source
   folder. **If Xcode complains that `PreSold/` already exists, point
   it at a temporary directory first, then move the generated
   `.xcodeproj` into `ios/`.** The existing source folder is what we
   keep.
4. In Project → General: set Deployment Target to **iOS 17.0**.
5. Right-click the project navigator → Add Files to "PreSold"...
   → select the existing `Models/`, `Services/`, `Views/`,
   `Utilities/`, `Config/`, `Resources/` folders inside `PreSold/`.
   Choose "Create groups" (not folder references). Check the
   "Add to target: PreSold" box.
6. Add Swift package dependency `https://github.com/supabase/supabase-swift`
   via File → Add Package Dependencies. Branch: `main`.
7. Copy `PreSold/Config/Secrets.xcconfig.example` to
   `PreSold/Config/Secrets.xcconfig` and fill in values from the
   project Supabase + (eventually) eBay accounts.
8. Run on a real device for camera testing. The simulator's camera
   support is limited and won't exercise the capture flow properly.

## Architecture

See `CLAUDE.md` in this directory.

## Conventions

See `CLAUDE.md` in this directory.

## Architecture

See `CLAUDE.md` in this directory.

## Conventions

See `CLAUDE.md` in this directory.
