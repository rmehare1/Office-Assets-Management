import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:office_assets_app/main.dart';
import 'package:office_assets_app/services/api_service.dart';
import 'package:office_assets_app/providers/auth_provider.dart';
import 'package:office_assets_app/providers/asset_provider.dart';
import 'package:office_assets_app/providers/theme_provider.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    final apiService = ApiService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
          ChangeNotifierProvider(create: (_) => AssetProvider(apiService)),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const OfficeAssetsApp(),
      ),
    );
    expect(find.text('Office Assets'), findsOneWidget);
  });
}
