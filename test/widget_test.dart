// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feedback_review_app/main.dart';
import 'package:feedback_review_app/models/feedback_model.dart';
import 'package:feedback_review_app/screens/feedback_detail_sheet.dart';
import 'package:feedback_review_app/screens/auth/login_screen.dart';
import 'package:feedback_review_app/screens/auth/signup_screen.dart';
import 'package:feedback_review_app/screens/submit_feedback_sheet.dart';
import 'package:feedback_review_app/screens/user/feedback_form_screen.dart';
import 'package:feedback_review_app/widgets/feedback_card.dart';
import 'package:feedback_review_app/widgets/star_rating.dart';

void main() {
  testWidgets('app opens on the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('login-email')))
          .decoration
          ?.hintText,
      'Email address',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('login-password')))
          .decoration
          ?.hintText,
      'Password',
    );
    expect(find.text("Don't have an account? Sign Up"), findsOneWidget);
  });

  testWidgets('login screen provides an admin login mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.tap(find.byKey(const Key('login-role-toggle')));
    await tester.pump();

    expect(find.text('Administrator access'), findsOneWidget);
    expect(find.text('Admin Log In'), findsOneWidget);
    expect(find.text('User Login'), findsOneWidget);
  });

  testWidgets('public signup does not allow assigning the admin role', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

    expect(find.text('Role'), findsNothing);
    expect(find.text('Admin'), findsNothing);
    expect(find.text('User / Intern'), findsNothing);
  });

  testWidgets('star rating reports the selected value', (
    WidgetTester tester,
  ) async {
    var selectedRating = 0.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StarRating(
            rating: selectedRating,
            onRatingChanged: (value) => selectedRating = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(IconButton).at(2));

    expect(selectedRating, 3.0);
  });

  testWidgets('feedback form requires a name and rating', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: FeedbackFormScreen()));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Feedback'));
    await tester.pump();

    expect(
      find.text('Task/Course name aur rating dono zaroori hain'),
      findsOneWidget,
    );
  });

  testWidgets('submit feedback sheet requires a name and rating', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SubmitFeedbackSheet())),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Feedback'));
    await tester.pump();

    expect(
      find.text('Task/Course name aur rating dono zaroori hain'),
      findsOneWidget,
    );
  });

  testWidgets('edit feedback sheet prepopulates the existing entry', (
    WidgetTester tester,
  ) async {
    final feedback = FeedbackModel(
      id: 'feedback-edit',
      userId: 'user-1',
      userName: 'Intern',
      taskOrCourse: 'Flutter Basics',
      category: 'General',
      rating: 4,
      comment: 'Clear and useful',
      status: 'Reviewed',
      timestamp: DateTime(2026, 9, 26, 14),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SubmitFeedbackSheet(existingFeedback: feedback)),
      ),
    );

    expect(find.text('Edit Feedback'), findsOneWidget);
    expect(find.text('Update Feedback'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('feedback-topic')))
          .controller
          ?.text,
      'Flutter Basics',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('feedback-message')))
          .controller
          ?.text,
      'Clear and useful',
    );
    expect(find.text('General'), findsOneWidget);
  });

  testWidgets('feedback card displays feedback details', (
    WidgetTester tester,
  ) async {
    final feedback = FeedbackModel(
      id: 'feedback-1',
      userId: 'user-1',
      userName: 'Intern',
      taskOrCourse: 'Flutter Basics',
      category: 'Course',
      rating: 4,
      comment: 'Clear and useful',
      timestamp: DateTime(2026, 9, 26, 14),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FeedbackCard(feedback: feedback)),
      ),
    );

    expect(find.text('Flutter Basics'), findsOneWidget);
    expect(find.text('Course'), findsOneWidget);
    expect(find.text('Clear and useful'), findsOneWidget);
    expect(find.textContaining('Intern'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(4));
  });

  testWidgets('user feedback details show status without edit controls', (
    WidgetTester tester,
  ) async {
    final feedback = FeedbackModel(
      id: 'feedback-2',
      userId: 'user-1',
      userName: 'Intern',
      taskOrCourse: 'Flutter Basics',
      category: 'Course',
      rating: 4,
      comment: 'Clear and useful',
      status: 'Reviewed',
      timestamp: DateTime(2026, 9, 26, 14),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedbackDetailSheet(feedback: feedback, canEditStatus: false),
        ),
      ),
    );

    expect(find.text('Status: Reviewed'), findsOneWidget);
    expect(find.text('Update Status'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
  });
}
