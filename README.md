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
