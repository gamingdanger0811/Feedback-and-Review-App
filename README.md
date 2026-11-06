# Feedback and Review App

A cross-platform feedback app built with Flutter and Firebase. Users can review tasks, courses, internships, and services; administrators can manage responses and view feedback summaries.

## Features

- Email and password authentication with separate user and admin login modes
- User profiles and role-based access
- Submit feedback with a category, topic, 1–5 star rating, and comment
- View, edit, and delete your own feedback
- Live admin inbox with search, category, status, and rating filters
- Admin feedback status updates and replies
- User directory and feedback detail views
- Rating, category, and status summaries with charts
- Optional, repeat-safe insertion of 15 clearly labeled sample feedback entries
- Light and dark themes

## Technology

- Flutter and Dart
- Firebase Authentication
- Cloud Firestore
- `fl_chart` for analytics visualizations

## Firebase configuration

The checked-in FlutterFire configuration targets the Firebase project `sohaib-feedback-review-app`. To use another Firebase project, configure Firebase for the required Flutter platforms and regenerate `lib/firebase_options.dart` and the platform configuration files.

The Firestore rules are in `firestore.rules`, with the deployment path in `firebase.json`. Review the rules against your project's data and access requirements before deploying them.

Admin access requires both:

1. A Firebase Authentication account in the configured project.
2. A Firestore document at `users/{uid}` with the string field `role` set to `admin`.

Public sign-up creates regular user accounts only. Provision administrator roles through a trusted Firebase project administrator. Passwords and users from a different Firebase project do not transfer when changing projects; use the configured project's password-reset flow if needed.

## Run locally

Prerequisites: Flutter SDK, a supported platform toolchain (such as Android Studio for Android), and access to the configured Firebase project.

```sh
flutter pub get
flutter run
```

Run the widget tests and static analysis with:

```sh
flutter test
flutter analyze
```

## Sample feedback

After signing in as an admin, use **Add 15 sample feedback entries** on the admin dashboard to add clearly labeled demonstration data. The action asks for confirmation and uses stable document IDs, so repeating it does not duplicate those entries.
