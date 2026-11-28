// 5.1 Điểm khởi động: mở Hive (6.2) rồi chạy giao diện.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry, debugPrint;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'data/hive_boxes.dart';
import 'services/accounts_config.dart';
import 'services/firestore_remote_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 5.2 Fonts Baloo 2 and Nunito are bundled in assets/fonts/ (spec 011): nothing is fetched over
  // the network, so the text looks right without wifi too.
  GoogleFonts.config.allowRuntimeFetching = false;
  // Their OFL licences appear in the app's licence page.
  LicenseRegistry.addLicense(() async* {
    for (final (name, file) in const [
      ('Baloo 2', 'Baloo2-OFL.txt'),
      ('Nunito', 'Nunito-OFL.txt'),
    ]) {
      final license = await rootBundle.loadString('assets/fonts/$file');
      yield LicenseEntryWithLineBreaks([name], license);
    }
  });

  await Hive.initFlutter();
  await HiveBoxes.openAll();

  // 6.3 Optional accounts (spec 016, ADR-0013): only when this build carries the Firebase settings.
  // If Firebase cannot start, the app runs as before with accounts hidden.
  if (AccountsConfig.isConfigured) {
    try {
      await Firebase.initializeApp(options: AccountsConfig.options);
      FirestoreRemoteStore.configure();
      AccountsConfig.ready = true;
    } on Object catch (error) {
      debugPrint('Accounts unavailable: Firebase did not start ($error)');
    }
  }

  runApp(const ProviderScope(child: DisGretApp()));
}
