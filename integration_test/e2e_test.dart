import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:oaya_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('Full user journey', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Ensure we are on the Home screen or navigate to login
      // Assuming we need to log in first
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
      // Using generic finders since we don't know exact product names
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

        // Go to order history
        final historyBtn = find.text('Voir mes commandes');
        await tester.tap(historyBtn);
        await tester.pumpAndSettle();

        expect(find.text('Mes Commandes'), findsOneWidget);
      }
    });
  });
}
