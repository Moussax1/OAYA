import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:oaya_flutter/main.dart' as app;
import 'package:oaya_flutter/services/stripe_service.dart';
import 'package:oaya_flutter/widgets/product_card.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<String> _dumpScreenText(WidgetTester tester) async {
  final allText = find
      .textContaining('')
      .evaluate()
      .map((e) {
        final w = e.widget;
        String? text;
        if (w is Text) text = w.data;
        if (w is EditableText) text = w.controller.text;
        return text ?? '';
      })
      .where((t) => t.isNotEmpty)
      .toSet()
      .join(' | ');
  return allText.isEmpty ? '(empty)' : allText;
}

/// Launches the app and waits until either the shell or login screen is ready.
Future<void> _startApp(WidgetTester tester) async {
  app.main();
  for (var i = 0; i < 30; i++) {
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 3)));
    await tester.pump(const Duration(milliseconds: 100));
    final shellVisible = find.text('Accueil').evaluate().isNotEmpty &&
        find.text('Panier').evaluate().isNotEmpty &&
        find.byType(CircularProgressIndicator).evaluate().isEmpty;
    final loginVisible = find.text('Se connecter').evaluate().isNotEmpty ||
        find.text('Adresse email').evaluate().isNotEmpty;
    if (shellVisible || loginVisible) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.text('Accueil').evaluate().isNotEmpty &&
          find.text('Panier').evaluate().isNotEmpty &&
          find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
      if (find.text('Se connecter').evaluate().isNotEmpty ||
          find.text('Adresse email').evaluate().isNotEmpty) return;
    }
  }
  throw Exception(
    'App not ready after 90 s. Screen: ${await _dumpScreenText(tester)}',
  );
}

/// Taps back arrows until the bottom nav is visible.
Future<void> _ensureOnShell(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    if (find.text('Panier').evaluate().isNotEmpty) return;

    final returnHome = find.text("Retour à l'accueil");
    if (returnHome.evaluate().isNotEmpty) {
      await tester.tap(returnHome.first);
      await tester.pump(const Duration(milliseconds: 500));
      continue;
    }

    final arrowLeft = find.byIcon(FeatherIcons.arrowLeft);
    if (arrowLeft.evaluate().isNotEmpty) {
      await tester.tap(arrowLeft.first);
      await tester.pump(const Duration(milliseconds: 500));
      continue;
    }
    final iconBack = find.byIcon(Icons.arrow_back);
    if (iconBack.evaluate().isNotEmpty) {
      await tester.tap(iconBack.first);
      await tester.pump(const Duration(milliseconds: 500));
      continue;
    }
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// Polls every 500 ms for up to 20 s until ProductCard widgets appear.
Future<void> _waitForProductCards(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byType(ProductCard).evaluate().isNotEmpty) return;
  }
}

/// Logs in with test credentials if the login button is visible.
Future<void> _loginIfNeeded(WidgetTester tester) async {
  if (find.text('Se connecter').evaluate().isEmpty) return;

  await tester.tap(find.text('Se connecter').first);
  await tester.pumpAndSettle();

  final emailField = find.byKey(const Key('login_email_field'));
  final passField = find.byKey(const Key('login_password_field'));
  for (var i = 0; i < 25; i++) {
    if (emailField.evaluate().isNotEmpty && passField.evaluate().isNotEmpty) break;
    await tester.pump(const Duration(milliseconds: 200));
  }

  expect(emailField, findsOneWidget,
      reason: 'Email input must be visible on login screen');
  expect(passField, findsOneWidget,
      reason: 'Password input must be visible on login screen');

  await tester.enterText(emailField, 'test@example.com');
  await tester.enterText(passField, 'password123');
  await tester.pumpAndSettle();

  final submitBtn = find.byKey(const Key('login_submit_button'));
  expect(submitBtn, findsOneWidget);
  await tester.tap(submitBtn);
  await tester.pump();
  // Let signIn HTTP + mergeLocalCart + loadCart complete.
  await tester.runAsync(() => Future.delayed(const Duration(seconds: 5)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Goes to Profil tab, logs in if needed, then navigates back to home.
Future<void> _loginAndGoHome(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    if (find.text('Profil').evaluate().isNotEmpty) {
      await tester.tap(find.text('Profil').first);
      await tester.pump();
      break;
    }
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pumpAndSettle();

  final neededLogin = find.text('Se connecter').evaluate().isNotEmpty;
  await _loginIfNeeded(tester);

  if (!neededLogin) {
    for (var i = 0; i < 10; i++) {
      if (find.text('Accueil').evaluate().isNotEmpty) {
        await tester.tap(find.text('Accueil').first);
        await tester.pump();
        break;
      }
      await tester.pump(const Duration(seconds: 1));
    }
    await _pump(tester);
  }
}

/// Fills the 5 address fields by position.
Future<void> _fillAddressForm(WidgetTester tester) async {
  final editableTexts = find.byType(EditableText);
  for (var i = 0; i < 25; i++) {
    if (editableTexts.evaluate().length >= 5) break;
    await tester.pump(const Duration(milliseconds: 200));
  }

  expect(editableTexts, findsAtLeastNWidgets(5),
      reason: 'Address screen must expose five editable fields');

  final nameField = find.byType(EditableText).at(0);
  final phoneField = find.byType(EditableText).at(1);
  final addressField = find.byType(EditableText).at(2);
  final postalField = find.byType(EditableText).at(3);
  final cityField = find.byType(EditableText).at(4);

  await tester.enterText(nameField, 'Test User');
  await tester.enterText(phoneField, '+216 99 999 999');
  await tester.enterText(addressField, '123 Rue de la Liberté');
  await tester.enterText(postalField, '1000');
  await tester.enterText(cityField, 'Tunis');
  await tester.pumpAndSettle();
}

/// Waits for products, taps the first one, and adds it to the cart.
Future<void> _addFirstProductToCart(WidgetTester tester) async {
  await tester.runAsync(() => Future.delayed(const Duration(seconds: 10)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.runAsync(() => Future.delayed(const Duration(seconds: 10)));
  await _waitForProductCards(tester);

  if (find.byType(ProductCard).evaluate().isEmpty) {
    throw Exception(
      'ProductCard not found. Screen: ${await _dumpScreenText(tester)}',
    );
  }

  await tester.tap(find.byType(ProductCard).first);
  // Let product detail API call complete.
  await tester.runAsync(() => Future.delayed(const Duration(seconds: 5)));
  await _pump(tester);

  final addBtn = find.text('Ajouter au panier');
  expect(addBtn, findsOneWidget,
      reason: 'Add to cart button must be visible on product detail screen');
  await tester.tap(addBtn);
  await tester.runAsync(() => Future.delayed(const Duration(seconds: 3)));
  await _pump(tester);
}

/// Navigates to cart tab and taps a button by text label.
Future<void> _goToCartAndTap(WidgetTester tester, String buttonText) async {
  await _ensureOnShell(tester);

  final cartTab = find.text('Panier');
  if (cartTab.evaluate().isEmpty) {
    throw Exception(
      'Panier tab not found. Screen: ${await _dumpScreenText(tester)}',
    );
  }
  await tester.tap(cartTab);
  await tester.runAsync(() => Future.delayed(const Duration(seconds: 5)));
  await _pump(tester);

  final btn = find.text(buttonText);
  if (btn.evaluate().isNotEmpty) {
    await tester.ensureVisible(btn.first);
    await tester.pump(const Duration(seconds: 1));
    if (find.text(buttonText).evaluate().isNotEmpty) {
      await tester.tap(find.text(buttonText).first);
      await _pump(tester);
    }
  }
}

/// Runs through the checkout flow up to the payment screen.
/// Returns true if the payment screen was reached.
Future<bool> _reachPaymentScreen(WidgetTester tester) async {
  // Dismiss SnackBar from cart add, then go to cart.
  await tester.pump(const Duration(seconds: 3));
  await _pump(tester);
  await _goToCartAndTap(tester, 'Passer la commande');
  await tester.pump(const Duration(seconds: 3));
  await _pump(tester);

  // Address screen.
  final continueBtn = find.byKey(const Key('address_continue_button'));
  if (continueBtn.evaluate().isEmpty) return false;
  await tester.pump(const Duration(seconds: 1));
  await _fillAddressForm(tester);
  await tester.ensureVisible(continueBtn.first);
  await tester.pump();
  await tester.tap(continueBtn.first);
  await _pump(tester);

  // Payment screen reached when either payment option is visible.
  return find.text('Paiement à la livraison').evaluate().isNotEmpty ||
      find.text('Carte Bancaire').evaluate().isNotEmpty;
}

/// Fixed-frame pump — never use pumpAndSettle with shimmer or
/// CircularProgressIndicator that never stops.
Future<void> _pump(WidgetTester tester, [int count = 3]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _selectPaymentMethod(WidgetTester tester, String label) async {
  final method = find.text(label, skipOffstage: false);
  for (var i = 0; i < 60; i++) {
    if (method.evaluate().isNotEmpty) break;
    await tester.pump(const Duration(milliseconds: 200));
  }
  expect(method, findsOneWidget, reason: 'Payment method "$label" must be visible');
  await tester.ensureVisible(method.first);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(method.first);
  await _pump(tester, 15);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    // -----------------------------------------------------------------------
    // Test 1 — Full COD journey + in-app notification
    // -----------------------------------------------------------------------
    testWidgets(
      'COD: Full user journey with notification',
      (tester) async {
        await _startApp(tester);
        await _ensureOnShell(tester);
        await _loginAndGoHome(tester);
        await _addFirstProductToCart(tester);
        await _ensureOnShell(tester);

        final reached = await _reachPaymentScreen(tester);
        expect(reached, isTrue,
            reason: 'Should reach the payment screen after filling address');

        // Select COD.
        final codOption = find.text('Paiement à la livraison');
        expect(codOption, findsOneWidget);
        await tester.ensureVisible(codOption.first);
        await tester.pump();
        await tester.tap(codOption.first);
        await _pump(tester);

        // Confirm order.
        final confirmBtn = find.text('Confirmer la commande');
        expect(confirmBtn, findsOneWidget);
        await tester.ensureVisible(confirmBtn.first);
        await tester.pump();
        await tester.tap(confirmBtn.first);

        // Wait for createOrder + clearCart + createNotification API calls.
        await tester.runAsync(
          () => Future.delayed(const Duration(seconds: 10)),
        );
        await _pump(tester, 10);

        // Success dialog must appear.
        expect(
          find.text('Paiement réussi'),
          findsOneWidget,
          reason:
              'Success dialog must appear after COD order. Screen: '
              '${await _dumpScreenText(tester)}',
        );
        expect(find.text('Votre commande a été confirmée !'), findsOneWidget);

        // Dismiss dialog.
        final okBtn = find.text('OK');
        expect(okBtn, findsOneWidget);
        await tester.tap(okBtn.first);
        await tester.runAsync(
          () => Future.delayed(const Duration(seconds: 5)),
        );
        await _pump(tester, 10);

        // Confirmation screen.
        expect(find.text('Commande Confirmée !'), findsOneWidget);

        // Order history.
        final historyBtn = find.text('Voir mes commandes');
        expect(historyBtn, findsOneWidget);
        await tester.tap(historyBtn.first);
        await _pump(tester);
        expect(find.text('Mes Commandes'), findsOneWidget);

        // Leave the app on the shell so the next E2E test starts cleanly.
        await _ensureOnShell(tester);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    // -----------------------------------------------------------------------
    // Test 2 — Full Stripe journey using the mock sheet
    //
    // Flutter integration tests cannot drive the native Stripe PaymentSheet,
    // so this test enables the in-app mock sheet and validates the full
    // checkout flow end to end without leaving Flutter.
    // -----------------------------------------------------------------------
    testWidgets(
      'Stripe: Full journey with mock payment sheet',
      (tester) async {
        StripeService.useMockPaymentSheet = true;
        addTearDown(() => StripeService.useMockPaymentSheet = false);

        await _startApp(tester);
        await _ensureOnShell(tester);
        await _loginAndGoHome(tester);
        await _addFirstProductToCart(tester);
        await _ensureOnShell(tester);

        final reached = await _reachPaymentScreen(tester);
        expect(reached, isTrue,
            reason: 'Should reach the payment screen after filling address');

        // --- Payment screen UI assertions (card selection) ---

        // Select card payment.
        await _selectPaymentMethod(tester, 'Carte Bancaire');

        // Test card hint must be visible.
        expect(
          find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains('4242'),
          ),
          findsOneWidget,
          reason: 'Stripe test card hint must be shown when card is selected',
        );

        // Button label must change to "Payer par carte".
        expect(find.text('Payer par carte'), findsOneWidget);

        // Order summary and security badge must be visible.
        expect(find.text('Récapitulatif'), findsOneWidget);
        expect(find.text('Paiement sécurisé SSL'), findsOneWidget);

        // --- Tap "Payer par carte" to trigger the mock sheet ---

        final payBtn = find.text('Payer par carte');
        await tester.ensureVisible(payBtn.first);
        await tester.pump();
        await tester.tap(payBtn.first);

        final cardNumber = find.byKey(const Key('stripe_card_number_field'));
        for (var i = 0; i < 25; i++) {
          if (cardNumber.evaluate().isNotEmpty) break;
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(cardNumber, findsOneWidget,
            reason: 'Mock Stripe sheet must show the card number field');

        final fakeCardOption = find.text('Card');
        expect(fakeCardOption, findsOneWidget);
        await tester.tap(fakeCardOption.first);
        await _pump(tester, 3);

        await tester.enterText(cardNumber, '4242 4242 4242 4242');
        await tester.enterText(
          find.byKey(const Key('stripe_card_expiry_field')),
          '12/26',
        );
        await tester.enterText(
          find.byKey(const Key('stripe_card_cvc_field')),
          '123',
        );
        await _pump(tester, 2);

        final fakePayBtn = find.byKey(const Key('stripe_card_pay_button'));
        expect(fakePayBtn, findsOneWidget,
            reason: 'Mock Stripe sheet must show a pay button');
        await tester.tap(fakePayBtn.first);

        await tester.runAsync(
          () => Future.delayed(const Duration(seconds: 10)),
        );
        await _pump(tester, 10);

        expect(find.text('Paiement réussi'), findsOneWidget,
            reason: 'Stripe flow should complete after entering the test card');
        expect(find.text('Votre paiement a été accepté !'), findsOneWidget);

        final okBtn = find.text('OK');
        expect(okBtn, findsOneWidget);
        await tester.tap(okBtn.first);
        await tester.runAsync(() => Future.delayed(const Duration(seconds: 3)));
        await _pump(tester, 10);

        expect(find.text('Commande Confirmée !'), findsOneWidget);

        // Leave the app on the shell so the next E2E test starts cleanly.
        await _ensureOnShell(tester);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    // -----------------------------------------------------------------------
    // Test 3 — SnackBar notification on cart add
    // -----------------------------------------------------------------------
    testWidgets(
      'Notification: Verify in-app SnackBar on cart add',
      (tester) async {
        await _startApp(tester);
        await _ensureOnShell(tester);
        await _loginAndGoHome(tester);

        await tester.runAsync(
          () => Future.delayed(const Duration(seconds: 10)),
        );
        await _waitForProductCards(tester);

        expect(
          find.byType(ProductCard),
          findsWidgets,
          reason: 'At least one product must be loaded from Supabase',
        );

        await tester.tap(find.byType(ProductCard).first);
        await _pump(tester);

        final addBtn = find.text('Ajouter au panier');
        expect(addBtn, findsOneWidget,
            reason: 'Add to cart button must exist on product detail screen');
        await tester.ensureVisible(addBtn.first);
        await tester.pump();
        await tester.tap(addBtn.first);

        // Wait for CartService.addItem + loadCart API calls.
        await tester.runAsync(
          () => Future.delayed(const Duration(seconds: 3)),
        );
        await _pump(tester);

        // Poll for the SnackBar (duration is 2 s, so check fast).
        var snackBarFound = false;
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 500));
          if (find.textContaining('ajouté au panier').evaluate().isNotEmpty) {
            snackBarFound = true;
            break;
          }
        }

        expect(
          snackBarFound,
          isTrue,
          reason:
              'SnackBar with "ajouté au panier" must appear after adding '
              'a product to cart',
        );
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}