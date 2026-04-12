# Firebase Functions for partner photo notifications

This directory contains the Firebase-only backend used to notify the partner when a new photo is created at `couples/{coupleId}/photos/{photoId}`.

## What it does

- reads the newly created photo document
- finds the other user in `couples/{coupleId}.memberIds`
- loads active FCM tokens from `users/{partnerUid}/devices/*`
- sends a push notification only to the partner
- removes invalid tokens automatically

## Local install

```bash
cd /Users/dodaoanhtuan/AndroidStudioProjects/dear_embeiu/functions
npm install
```

## Syntax check

```bash
cd /Users/dodaoanhtuan/AndroidStudioProjects/dear_embeiu/functions
npm run lint
```

## Deploy

```bash
cd /Users/dodaoanhtuan/AndroidStudioProjects/dear_embeiu
firebase deploy --only functions
```

## Required Firebase setup

- Firestore enabled
- Cloud Messaging enabled
- for iOS, APNs key/certificate uploaded in Firebase Console
- if this is your first time deploying functions, a billing-enabled Firebase plan may be required

