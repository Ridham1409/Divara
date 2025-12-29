import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> init() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    await _remoteConfig.setDefaults(<String, dynamic>{
      'welcome_message': 'Welcome to DIVARA',
      'is_sale_on': false,
    });

    await _remoteConfig.fetchAndActivate();
  }

  String getWelcomeMessage() => _remoteConfig.getString('welcome_message');
  bool getSaleStatus() => _remoteConfig.getBool('is_sale_on');
}
