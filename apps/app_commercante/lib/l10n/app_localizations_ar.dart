// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'متجري';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get phone => 'رقم الهاتف';

  @override
  String get pin => 'الرمز السري (4 أرقام)';

  @override
  String get loginButton => 'دخول';

  @override
  String get invalidCredentials => 'رقم الهاتف أو الرمز غير صحيح';

  @override
  String accountLocked(int minutes) {
    return 'محاولات كثيرة. حاول مجدداً بعد $minutes دقيقة';
  }

  @override
  String get networkError => 'تعذّر الاتصال بالخادم، تحقق من الإنترنت';

  @override
  String get genericError => 'حدث خطأ، حاول مجدداً';

  @override
  String get phoneRequired => 'أدخل رقم الهاتف';

  @override
  String get pinInvalid => 'الرمز يتكون من 4 أرقام';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabSell => 'البيع';

  @override
  String get tabProducts => 'المنتجات';

  @override
  String get tabStock => 'المخزون';

  @override
  String get tabMore => 'المزيد';

  @override
  String get language => 'اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get french => 'Français';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get loading => 'جارٍ التحميل…';
}
