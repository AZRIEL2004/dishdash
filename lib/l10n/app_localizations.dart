import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settings': 'Settings',
      'language': 'Language',
      'notification': 'Notification',
      'profile_info': 'Profile Information',
      'password_security': 'Password & Security',
      'dark_mode': 'Dark Mode',
      'help_center': 'Help Center',
      'privacy_policy': 'Privacy Policy',
      'about_us': 'About Us',
      'log_out': 'Log Out',
      'delete_account': 'Delete Account',
      'today': 'Today',
      'earlier': 'Earlier',
      'no_notifications': 'No notifications yet.',
      'please_login': 'Please log in to continue.',
    },
    'hi': {
      'settings': 'सेटिंग्स',
      'language': 'भाषा',
      'notification': 'अधिसूचना',
      'profile_info': 'प्रोफ़ाइल जानकारी',
      'password_security': 'पासवर्ड और सुरक्षा',
      'dark_mode': 'ડાર્ક મોડ',
      'help_center': 'सहायता केंद्र',
      'privacy_policy': 'गोपनीयता नीति',
      'about_us': 'हमारे बारे में',
      'log_out': 'लॉग आउट',
      'delete_account': 'खाता हटाएं',
      'today': 'आज',
      'earlier': 'पहले',
      'no_notifications': 'अभी तक कोई सूचना नहीं।',
      'please_login': 'जारी रखने के लिए कृपया लॉगिन करें।',
    },
    'gu': {
      'settings': 'સેટિંગ્સ',
      'language': 'ભાષા',
      'notification': 'સૂચના',
      'profile_info': 'પ્રોફાઇલ માહિતી',
      'password_security': 'પાસવર્ડ અને સુરક્ષા',
      'dark_mode': 'ડાર્ક મોડ',
      'help_center': 'મદદ કેન્દ્ર',
      'privacy_policy': 'ગોપનીયતા નીતિ',
      'about_us': 'અમારા વિશે',
      'log_out': 'લૉગ આઉટ',
      'delete_account': 'ખાતું કાઢી નાખો',
      'today': 'આજે',
      'earlier': 'અગાઉ',
      'no_notifications': 'હજી સુધી કોઈ સૂચના નથી.',
      'please_login': 'ચાલુ રાખવા માટે કૃપા કરીને લોગિન કરો.',
    },
    'es': {
      'settings': 'Ajustes',
      'language': 'Idioma',
      'notification': 'Notificación',
      'profile_info': 'Información del perfil',
      'log_out': 'Cerrar sesión',
      'today': 'Hoy',
      'earlier': 'Antes',
    },
    'fr': {
      'settings': 'Paramètres',
      'language': 'Langue',
      'notification': 'Notification',
      'log_out': 'Se déconnecter',
      'today': 'Aujourd\'hui',
      'earlier': 'Plus tôt',
    }
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']?[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _AppLocalizations._localizedValues.containsKey(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

// Helper to access keys during isSupported check
extension _AppLocalizations on AppLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = AppLocalizations._localizedValues;
}
