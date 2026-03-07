import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/card_list_provider.dart';
import 'providers/smart_pay_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/add_card_provider.dart';
import 'services/data_manager.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final dataManager = DataManager();
  await dataManager.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<DataManager>.value(value: dataManager),
        ChangeNotifierProvider(create: (_) => CardListProvider(dataManager)),
        ChangeNotifierProvider(create: (_) => SmartPayProvider(dataManager)),
        ChangeNotifierProvider(create: (_) => SettingsProvider(dataManager)),
        ChangeNotifierProvider(create: (_) => AddCardProvider(dataManager)),
      ],
      child: const CreditCardApp(),
    ),
  );
}
