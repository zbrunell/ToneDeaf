# ToneDeaf 🎸

ToneDeaf is a real-time guitar tuning app for iOS built with UIKit and Firebase. It listens to your guitar through the microphone, detects the pitch using audio signal processing, and displays tuning accuracy through an animated dial — telling you instantly whether you're flat, in tune, or sharp.

The app supports multiple tuning presets, adjustable reference pitch, user accounts with Firebase authentication, and a fully customizable profile. It's designed to be fast, minimal, and accurate — getting out of the way so you can focus on playing.

---

## Features

###  Real-Time Pitch Detection
- Live microphone input processed using `AVAudioEngine`
- Autocorrelation algorithm detects the fundamental frequency of each guitar string
- Bootstrapping confidence system filters noisy or unstable readings — only reports a note when multiple consecutive readings agree
- Supports standard guitar frequency range (E2 to E4)

###  Visual Tuner Dial
- Fully custom-drawn semicircular dial using Core Graphics
- Color-coded zones — yellow for flat, green for in tune, blue for sharp
- Animated needle rotates smoothly using `CABasicAnimation`
- Needle color changes to match tuning status in real time

### Tuning Settings
- Five tuning presets: Standard, Drop D, D Standard, Eb Standard, C# Standard
- Adjustable reference pitch from 400–460 Hz
- Guitar type selection: Electric or Acoustic
- All settings saved to Firebase Firestore and restored on next login

###  User Accounts
- Email and password authentication via Firebase Auth
- Login with either email address or username
- Automatic username generated from email on registration
- Password reset via email
- Settings and preferences tied to individual user accounts

###  User Profile
- Upload a profile picture from the photo library or take one with the camera
- Update email address with confirmation
- Log out or permanently delete account and all associated data

###  Dark Mode
- Full dark and light mode support
- Toggle via switch in profile settings
- Persisted across launches using `UserDefaults`
- All view controllers update instantly via `NotificationCenter`

---

## Tech Stack

| Area | Technology |
|---|---|
| Language | Swift |
| UI Framework | UIKit |
| Authentication | Firebase Auth |
| Database | Firebase Firestore |
| Audio Input | AVAudioEngine / AVAudioSession |
| Signal Processing | Autocorrelation + Bootstrapping |
| Custom Drawing | Core Graphics / UIBezierPath / CAShapeLayer |
| Animation | CABasicAnimation |
| Persistence | Firebase Firestore + UserDefaults |
| Fonts | Poppins, TiltPrism |

---
---

## How to Use

1. **Create an account** or log in with your email or username
2. **Go to Settings** to choose your tuning preset, guitar type, and reference pitch
3. **Return to the main screen** — the app starts listening automatically
4. **Play a string** and watch the dial — tune up if the needle is left (yellow), tune down if it's right (blue)
5. **You're in tune** when the needle centers and turns green

---

## Requirements

- iOS 26.3+
- Xcode 15+
- Physical device recommended for microphone access (simulator has no mic input)



---

## Author

Zachary Brunell  
The University of Texas at Austin
