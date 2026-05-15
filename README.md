# Save & Share

Save & Share is a read-it-later prototype with swipe-based folder movement, a shared feed, likes, memos, and friend following.

## iOS app

Open `SaveShare.xcodeproj` in Xcode and run the `SaveShare` scheme on an iPhone Simulator or a real device.

Before installing on a real device, update the target settings:

1. Select the `SaveShare` project in Xcode.
2. Select the `SaveShare` target.
3. Set **Signing & Capabilities > Team** to your Apple Developer team.
4. Change **Bundle Identifier** from `com.example.SaveShare` to your own unique identifier.

The iOS implementation is a native SwiftUI app. It persists demo data to `UserDefaults`, so uploaded URLs, memos, likes, and follow state remain on the device between launches.

## Static web prototype

The original static web prototype is still available.

```bash
npm run start
```

Then open <http://127.0.0.1:4173>.

## Checks

```bash
npm run check
```


## GitHub merge conflicts

If GitHub says this branch has conflicts, update the PR branch locally and keep the Save & Share app version from this branch:

```bash
git fetch origin
git checkout <your-pr-branch>
git merge origin/main
scripts/resolve-save-share-conflicts.sh
git commit
git push
```

The helper resolves the known conflicts in the SwiftUI app and static web prototype files by choosing the PR branch version. Open `SaveShare.xcodeproj` after pushing to confirm the app still runs.
