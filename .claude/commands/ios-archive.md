Build an iOS archive with an incremented build number.

1. Read the current CURRENT_PROJECT_VERSION from `ios/ReaderApp.xcodeproj/project.pbxproj`
2. Increment the build number by 1
3. Update all occurrences of CURRENT_PROJECT_VERSION in the project file
4. Create the archive directory for today if it doesn't exist:
   ```
   mkdir -p ~/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)
   ```
5. Run xcodebuild archive (archives go to Xcode's standard location so they appear in Organizer):
   ```
   xcodebuild -project ios/ReaderApp.xcodeproj -scheme ReaderApp -configuration Release -archivePath ~/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)/ReaderApp\ $(date +%Y-%m-%d\ %H.%M.%S).xcarchive archive
   ```
6. Verify the archive was created and display the version info from the archive's Info.plist

Output the final version (MARKETING_VERSION) and build number (CURRENT_PROJECT_VERSION) when complete.

The archive will appear in Xcode's Organizer (Window > Organizer) for distribution to TestFlight.
