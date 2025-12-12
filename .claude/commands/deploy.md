Deploy the full application: Cloudflare Worker and iOS archive.

## Steps

### 1. Deploy Cloudflare Worker
```
cd worker && npm run deploy
```
If `npm run deploy` doesn't exist, use:
```
cd worker && npx wrangler deploy
```

Verify the deployment succeeded and note the worker URL.

### 2. Build iOS Archive
Follow the ios-archive process:

1. Read the current CURRENT_PROJECT_VERSION from `ios/ReaderApp.xcodeproj/project.pbxproj`
2. Increment the build number by 1
3. Update all occurrences of CURRENT_PROJECT_VERSION in the project file
4. Create the archive directory for today if it doesn't exist:
   ```
   mkdir -p ~/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)
   ```
5. Run xcodebuild archive:
   ```
   xcodebuild -project ios/ReaderApp.xcodeproj -scheme ReaderApp -configuration Release -archivePath ~/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)/ReaderApp\ $(date +%Y-%m-%d\ %H.%M.%S).xcarchive archive
   ```
6. Verify the archive was created

### 3. Summary
Output a summary showing:
- Worker deployment status and URL
- iOS version (MARKETING_VERSION) and build number (CURRENT_PROJECT_VERSION)
- Location of the archive in Xcode Organizer

The iOS archive will appear in Xcode's Organizer (Window > Organizer) for distribution to TestFlight.
