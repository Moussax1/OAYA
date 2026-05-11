import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:oaya_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('COD: Full user journey with notification', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Ensure we are on the Home screen or navigate to login
      final profileTab = find.text('Profil').first;
      expect(profileTab, findsOneWidget);
      await tester.tap(profileTab);
      await tester.pumpAndSettle();

      // Tap "Se connecter"
      final loginBtn = find.text('Se connecter');
      if (loginBtn.evaluate().isNotEmpty) {
        await tester.tap(loginBtn);
        await tester.pumpAndSettle();

        // Enter credentials
        final emailField = find.byType(TextField).first;
        final passField = find.byType(TextField).last;

        await tester.enterText(emailField, 'test@example.com');
        await tester.enterText(passField, 'password123');
        await tester.pumpAndSettle();

        final submitBtn = find.text('Se connecter');
        await tester.tap(submitBtn);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Go back to home
      final homeTab = find.text('Accueil');
      await tester.tap(homeTab);
      await tester.pumpAndSettle();

      // Find a product and tap it
      final productCard = find.byType(GestureDetector).first;
      await tester.tap(productCard);
      await tester.pumpAndSettle();

      // Tap "Ajouter au panier"
      final addBtn = find.text('Ajouter au panier');
      if (addBtn.evaluate().isNotEmpty) {
        await tester.tap(addBtn);
        await tester.pumpAndSettle();
      }

      // Go to cart
      final cartTab = find.text('Panier');
      await tester.tap(cartTab);
      await tester.pumpAndSettle();

      // Tap "Passer la commande"
      final checkoutBtn = find.text('Passer la commande');
      if (checkoutBtn.evaluate().isNotEmpty) {
        await tester.tap(checkoutBtn);
        await tester.pumpAndSettle();

        // Address screen -> Tap Continue
        final continueBtn = find.text('Continuer vers le paiement');
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        // Select COD
        final codOption = find.text('Paiement à la livraison');
        await tester.tap(codOption);
        await tester.pumpAndSettle();

        // Confirm
        final confirmBtn = find.text('Confirmer la commande');
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Verify Order confirmation
        expect(find.text('Commande Confirmée !'), findsOneWidget);

        // Verify in-app notification dialog appears
        expect(find.text('Paiement réussi'), findsOneWidget);
        expect(find.text('Votre commande a été confirmée !'), findsOneWidget);

        // Dismiss dialog
        final okBtn = find.text('OK');
        if (okBtn.evaluate().isNotEmpty) {
          await tester.tap(okBtn);
          await tester.pumpAndSettle();
        }

        // Go to order history
        final historyBtn = find.text('Voir mes commandes');
        await tester.tap(historyBtn);
        await tester.pumpAndSettle();

        expect(find.text('Mes Commandes'), findsOneWidget);
      }
    });

    testWidgets('Stripe: Full user journey with card selection', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Log in if needed
      final profileTab = find.text('Profil').first;
      await tester.tap(profileTab);
      await tester.pumpAndSettle();

      final loginBtn = find.text('Se connecter');
      if (loginBtn.evaluate().isNotEmpty) {
        await tester.tap(loginBtn);
        await tester.pumpAndSettle();

        final emailField = find.byType(TextField).first;
        final passField = find.byType(TextField).last;

        await tester.enterText(emailField, 'test@example.com');
        await tester.enterText(passField, 'password123');
        await tester.pumpAndSettle();

        final submitBtn = find.text('Se connecter');
        await tester.tap(submitBtn);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Navigate home and add product
      final homeTab = find.text('Accueil');
      await tester.tap(homeTab);
      await tester.pumpAndSettle();

      final productCard = find.byType(GestureDetector).first;
      await tester.tap(productCard);
      await tester.pumpAndSettle();

      final addBtn = find.text('Ajouter au panier');
      if (addBtn.evaluate().isNotEmpty) {
        await tester.tap(addBtn);
        await tester.pumpAndSettle();
      }

      // Go to cart and checkout
      final cartTab = find.text('Panier');
      await tester.tap(cartTab);
      await tester.pumpAndSettle();

      final checkoutBtn = find.text('Passer la commande');
      if (checkoutBtn.evaluate().isNotEmpty) {
        await tester.tap(checkoutBtn);
        await tester.pumpAndSettle();

        // Address screen -> Continue
        final continueBtn = find.text('Continuer vers le paiement');
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        // Select Stripe card payment
        final cardOption = find.text('Carte Bancaire');
        await tester.tap(cardOption);
        await tester.pumpAndSettle();

        // Verify Stripe info banner is shown
        expect(find.textContaining('4242 4242 4242 4242'), findsOneWidget);

        // Verify the button text changes to "Payer par carte"
        expect(find.text('Payer par carte'), findsOneWidget);

        // Note: Stripe PaymentSheet is a native UI element
        // It cannot be automated in Flutter integration tests.
        // In a real CI environment, this would use a Stripe test card.
        // Here we verify the UI state before the native sheet is presented.

        // Verify order summary is displayed
        expect(find.text('Récapitulatif'), findsOneWidget);
        expect(find.text('Paiement sécurisé SSL'), findsOneWidget);
      }
    });

    testWidgets('Notification: Verify in-app SnackBar on cart add', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Log in
      final profileTab = find.text('Profil').first;
      await tester.tap(profileTab);
      await tester.pumpAndSettle();

      final loginBtn = find.text('Se connecter');
      if (loginBtn.evaluate().isNotEmpty) {
        await tester.tap(loginBtn);
        await tester.pumpAndSettle();

        final emailField = find.byType(TextField).first;
        final passField = find.byType(TextField).last;
        await tester.enterText(emailField, 'test@example.com');
        await tester.enterText(passField, 'password123');
        await tester.pumpAndSettle();

        final submitBtn = find.text('Se connecter');
        await tester.tap(submitBtn);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Navigate home
      final homeTab = find.text('Accueil');
      await tester.tap(homeTab);
      await tester.pumpAndSettle();

      // Find and tap a product
      final productCard = find.byType(GestureDetector).first;
      await tester.tap(productCard);
      await tester.pumpAndSettle();

      // Add to cart
      final addBtn = find.text('Ajouter au panier');
      if (addBtn.evaluate().isNotEmpty) {
        await tester.tap(addBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify SnackBar notification appears
        expect(find.textContaining('ajouté au panier'), findsOneWidget);
      }
    });
  });
}
