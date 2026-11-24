# harvesta

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase Functions

Install the Functions dependencies and deploy the Auth account cleanup trigger:

```sh
cd functions
npm install
cd ..
firebase deploy --only functions --project harvesta-87528
```

Deleting a Firebase Authentication user triggers deletion of the matching `users/{uid}`
Firestore profile, which removes that account from the admin dashboard.
