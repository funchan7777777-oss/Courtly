import 'package:courtly/atelier/courtly_app.dart';
import 'package:courtly/shared/wallet/courtly_wallet_store.dart';
import 'package:flutter/cupertino.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  CourtlyWalletStore.instance.startPurchaseListener();
  runApp(const CourtlyApp());
}
