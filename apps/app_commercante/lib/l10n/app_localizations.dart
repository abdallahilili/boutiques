import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'متجري'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get login;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phone;

  /// No description provided for @pin.
  ///
  /// In ar, this message translates to:
  /// **'الرمز السري (4 أرقام)'**
  String get pin;

  /// No description provided for @loginButton.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get loginButton;

  /// No description provided for @invalidCredentials.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف أو الرمز غير صحيح'**
  String get invalidCredentials;

  /// No description provided for @accountLocked.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كثيرة. حاول مجدداً بعد {minutes} دقيقة'**
  String accountLocked(int minutes);

  /// No description provided for @networkError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال بالخادم، تحقق من الإنترنت'**
  String get networkError;

  /// No description provided for @genericError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ، حاول مجدداً'**
  String get genericError;

  /// No description provided for @phoneRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم الهاتف'**
  String get phoneRequired;

  /// No description provided for @pinInvalid.
  ///
  /// In ar, this message translates to:
  /// **'الرمز يتكون من 4 أرقام'**
  String get pinInvalid;

  /// No description provided for @tabHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get tabHome;

  /// No description provided for @tabSell.
  ///
  /// In ar, this message translates to:
  /// **'البيع'**
  String get tabSell;

  /// No description provided for @tabProducts.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات'**
  String get tabProducts;

  /// No description provided for @tabStock.
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get tabStock;

  /// No description provided for @tabMore.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get tabMore;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @french.
  ///
  /// In ar, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل…'**
  String get loading;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get add;

  /// No description provided for @create.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء'**
  String get create;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In ar, this message translates to:
  /// **'نعم'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ar, this message translates to:
  /// **'لا'**
  String get no;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @optional.
  ///
  /// In ar, this message translates to:
  /// **'اختياري'**
  String get optional;

  /// No description provided for @requiredField.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get requiredField;

  /// No description provided for @nameAr.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالعربية'**
  String get nameAr;

  /// No description provided for @nameFr.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالفرنسية'**
  String get nameFr;

  /// No description provided for @nameRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الاسم بإحدى اللغتين'**
  String get nameRequired;

  /// No description provided for @amount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get amount;

  /// No description provided for @quantity.
  ///
  /// In ar, this message translates to:
  /// **'الكمية'**
  String get quantity;

  /// No description provided for @price.
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get price;

  /// No description provided for @total.
  ///
  /// In ar, this message translates to:
  /// **'المجموع'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In ar, this message translates to:
  /// **'المجموع الفرعي'**
  String get subtotal;

  /// No description provided for @discount.
  ///
  /// In ar, this message translates to:
  /// **'تخفيض'**
  String get discount;

  /// No description provided for @note.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة'**
  String get note;

  /// No description provided for @address.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get address;

  /// No description provided for @city.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get city;

  /// No description provided for @whatsapp.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get whatsapp;

  /// No description provided for @status.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get status;

  /// No description provided for @date.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get date;

  /// No description provided for @actions.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات'**
  String get actions;

  /// No description provided for @none.
  ///
  /// In ar, this message translates to:
  /// **'لا شيء'**
  String get none;

  /// No description provided for @all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get all;

  /// No description provided for @active.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In ar, this message translates to:
  /// **'غير نشط'**
  String get inactive;

  /// No description provided for @scan.
  ///
  /// In ar, this message translates to:
  /// **'مسح الباركود'**
  String get scan;

  /// No description provided for @saved.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ'**
  String get saved;

  /// No description provided for @deleted.
  ///
  /// In ar, this message translates to:
  /// **'تم الحذف'**
  String get deleted;

  /// No description provided for @emptyList.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عناصر بعد'**
  String get emptyList;

  /// No description provided for @permissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'ليست لديك صلاحية لهذا الإجراء'**
  String get permissionDenied;

  /// No description provided for @connectionRequired.
  ///
  /// In ar, this message translates to:
  /// **'هذا الإجراء يتطلب اتصالاً بالإنترنت'**
  String get connectionRequired;

  /// No description provided for @offlineBanner.
  ///
  /// In ar, this message translates to:
  /// **'وضع غير متصل — ستُرسل العمليات تلقائياً عند عودة الاتصال'**
  String get offlineBanner;

  /// No description provided for @syncPending.
  ///
  /// In ar, this message translates to:
  /// **'{count} عملية في الانتظار'**
  String syncPending(int count);

  /// No description provided for @syncNow.
  ///
  /// In ar, this message translates to:
  /// **'مزامنة الآن'**
  String get syncNow;

  /// No description provided for @syncIssuesTitle.
  ///
  /// In ar, this message translates to:
  /// **'عمليات تحتاج إلى قرارك'**
  String get syncIssuesTitle;

  /// No description provided for @syncIssuesHint.
  ///
  /// In ar, this message translates to:
  /// **'رفض الخادم هذه العمليات. أعد المحاولة أو تخلّ عنها.'**
  String get syncIssuesHint;

  /// No description provided for @discard.
  ///
  /// In ar, this message translates to:
  /// **'تخلّي'**
  String get discard;

  /// No description provided for @readOnlyBanner.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك منتهٍ: التطبيق للقراءة فقط. تواصل مع الناشر للتجديد.'**
  String get readOnlyBanner;

  /// No description provided for @graceBanner.
  ///
  /// In ar, this message translates to:
  /// **'اشتراكك منتهٍ — فترة سماح محدودة. جدّد قريباً.'**
  String get graceBanner;

  /// No description provided for @suspendedTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحساب موقوف'**
  String get suspendedTitle;

  /// No description provided for @suspendedText.
  ///
  /// In ar, this message translates to:
  /// **'تم إيقاف هذا المتجر بسبب انتهاء الاشتراك. بياناتك محفوظة ويمكنك الاطلاع عليها.'**
  String get suspendedText;

  /// No description provided for @contactPublisher.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع الناشر'**
  String get contactPublisher;

  /// No description provided for @shop.
  ///
  /// In ar, this message translates to:
  /// **'المتجر'**
  String get shop;

  /// No description provided for @switchShop.
  ///
  /// In ar, this message translates to:
  /// **'تغيير المتجر'**
  String get switchShop;

  /// No description provided for @synced.
  ///
  /// In ar, this message translates to:
  /// **'تمت المزامنة'**
  String get synced;

  /// No description provided for @lastSync.
  ///
  /// In ar, this message translates to:
  /// **'آخر مزامنة: {date}'**
  String lastSync(String date);

  /// No description provided for @selectOption.
  ///
  /// In ar, this message translates to:
  /// **'اختر'**
  String get selectOption;

  /// No description provided for @unknownError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تنفيذ العملية: {details}'**
  String unknownError(String details);

  /// No description provided for @stockInsufficient.
  ///
  /// In ar, this message translates to:
  /// **'المخزون غير كافٍ'**
  String get stockInsufficient;

  /// No description provided for @serverError_stock_insuffisant.
  ///
  /// In ar, this message translates to:
  /// **'المخزون غير كافٍ لهذه العملية'**
  String get serverError_stock_insuffisant;

  /// No description provided for @serverError_client_requis.
  ///
  /// In ar, this message translates to:
  /// **'اختر زبونة لبيع بالآجل'**
  String get serverError_client_requis;

  /// No description provided for @serverError_plafond_credit_depasse.
  ///
  /// In ar, this message translates to:
  /// **'تجاوز سقف الائتمان للزبونة'**
  String get serverError_plafond_credit_depasse;

  /// No description provided for @serverError_prix_non_autorise.
  ///
  /// In ar, this message translates to:
  /// **'ليست لديك صلاحية تعديل الأسعار'**
  String get serverError_prix_non_autorise;

  /// No description provided for @serverError_boutique_inactive.
  ///
  /// In ar, this message translates to:
  /// **'المتجر في وضع القراءة فقط'**
  String get serverError_boutique_inactive;

  /// No description provided for @serverError_quota_depasse.
  ///
  /// In ar, this message translates to:
  /// **'تجاوزت حد خطة اشتراكك'**
  String get serverError_quota_depasse;

  /// No description provided for @serverError_motif_obligatoire.
  ///
  /// In ar, this message translates to:
  /// **'السبب إلزامي لإخراج المخزون'**
  String get serverError_motif_obligatoire;

  /// No description provided for @bootLoading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحضير متجرك…'**
  String get bootLoading;

  /// No description provided for @noShopTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد متجر مرتبط بحسابك'**
  String get noShopTitle;

  /// No description provided for @noShopText.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع الناشر لإنشاء متجرك.'**
  String get noShopText;

  /// No description provided for @continueReadOnly.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة بوضع القراءة فقط'**
  String get continueReadOnly;

  /// No description provided for @dashboardToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get dashboardToday;

  /// No description provided for @dashboardWeek.
  ///
  /// In ar, this message translates to:
  /// **'7 أيام'**
  String get dashboardWeek;

  /// No description provided for @dashboardMonth.
  ///
  /// In ar, this message translates to:
  /// **'هذا الشهر'**
  String get dashboardMonth;

  /// No description provided for @revenue.
  ///
  /// In ar, this message translates to:
  /// **'المبيعات'**
  String get revenue;

  /// No description provided for @salesCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد المبيعات'**
  String get salesCount;

  /// No description provided for @outOfStock.
  ///
  /// In ar, this message translates to:
  /// **'منتجات نفدت'**
  String get outOfStock;

  /// No description provided for @lowStock.
  ///
  /// In ar, this message translates to:
  /// **'مخزون منخفض'**
  String get lowStock;

  /// No description provided for @ordersToProcess.
  ///
  /// In ar, this message translates to:
  /// **'طلبات للمعالجة'**
  String get ordersToProcess;

  /// No description provided for @unpaidCustomers.
  ///
  /// In ar, this message translates to:
  /// **'ديون الزبائن'**
  String get unpaidCustomers;

  /// No description provided for @shortcuts.
  ///
  /// In ar, this message translates to:
  /// **'اختصارات'**
  String get shortcuts;

  /// No description provided for @newSale.
  ///
  /// In ar, this message translates to:
  /// **'عملية بيع جديدة'**
  String get newSale;

  /// No description provided for @newProduct.
  ///
  /// In ar, this message translates to:
  /// **'منتج جديد'**
  String get newProduct;

  /// No description provided for @stockEntry.
  ///
  /// In ar, this message translates to:
  /// **'إدخال مخزون'**
  String get stockEntry;

  /// No description provided for @menuOrders.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات الإلكترونية'**
  String get menuOrders;

  /// No description provided for @menuDocuments.
  ///
  /// In ar, this message translates to:
  /// **'الفواتير'**
  String get menuDocuments;

  /// No description provided for @menuCustomers.
  ///
  /// In ar, this message translates to:
  /// **'الزبائن'**
  String get menuCustomers;

  /// No description provided for @menuReferentials.
  ///
  /// In ar, this message translates to:
  /// **'المراجع (ألوان، أصناف…)'**
  String get menuReferentials;

  /// No description provided for @menuSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات المتجر'**
  String get menuSettings;

  /// No description provided for @menuNotifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get menuNotifications;

  /// No description provided for @menuSync.
  ///
  /// In ar, this message translates to:
  /// **'المزامنة'**
  String get menuSync;

  /// No description provided for @menuSubscription.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك'**
  String get menuSubscription;

  /// No description provided for @refCategories.
  ///
  /// In ar, this message translates to:
  /// **'الأصناف'**
  String get refCategories;

  /// No description provided for @refColors.
  ///
  /// In ar, this message translates to:
  /// **'الألوان'**
  String get refColors;

  /// No description provided for @refModels.
  ///
  /// In ar, this message translates to:
  /// **'الموديلات'**
  String get refModels;

  /// No description provided for @refSizes.
  ///
  /// In ar, this message translates to:
  /// **'المقاسات'**
  String get refSizes;

  /// No description provided for @refBrands.
  ///
  /// In ar, this message translates to:
  /// **'العلامات التجارية'**
  String get refBrands;

  /// No description provided for @refUnits.
  ///
  /// In ar, this message translates to:
  /// **'الوحدات'**
  String get refUnits;

  /// No description provided for @refPaymentModes.
  ///
  /// In ar, this message translates to:
  /// **'طرق الدفع'**
  String get refPaymentModes;

  /// No description provided for @refDeliveryZones.
  ///
  /// In ar, this message translates to:
  /// **'مناطق التوصيل'**
  String get refDeliveryZones;

  /// No description provided for @refSuppliers.
  ///
  /// In ar, this message translates to:
  /// **'الموردون'**
  String get refSuppliers;

  /// No description provided for @colorHex.
  ///
  /// In ar, this message translates to:
  /// **'رمز اللون (Hex)'**
  String get colorHex;

  /// No description provided for @colorInvalid.
  ///
  /// In ar, this message translates to:
  /// **'رمز لون غير صالح (مثال: #00FF00)'**
  String get colorInvalid;

  /// No description provided for @parentCategory.
  ///
  /// In ar, this message translates to:
  /// **'الصنف الأب'**
  String get parentCategory;

  /// No description provided for @visibleOnline.
  ///
  /// In ar, this message translates to:
  /// **'ظاهر في المتجر الإلكتروني'**
  String get visibleOnline;

  /// No description provided for @sizeType.
  ///
  /// In ar, this message translates to:
  /// **'نوع المقاس'**
  String get sizeType;

  /// No description provided for @sizeTypeSize.
  ///
  /// In ar, this message translates to:
  /// **'مقاس'**
  String get sizeTypeSize;

  /// No description provided for @sizeTypeShoe.
  ///
  /// In ar, this message translates to:
  /// **'مقاس حذاء'**
  String get sizeTypeShoe;

  /// No description provided for @sizeTypeLength.
  ///
  /// In ar, this message translates to:
  /// **'طول'**
  String get sizeTypeLength;

  /// No description provided for @paymentTypeCash.
  ///
  /// In ar, this message translates to:
  /// **'نقداً'**
  String get paymentTypeCash;

  /// No description provided for @paymentTypeMobile.
  ///
  /// In ar, this message translates to:
  /// **'محفظة إلكترونية'**
  String get paymentTypeMobile;

  /// No description provided for @paymentTypeBank.
  ///
  /// In ar, this message translates to:
  /// **'بنك'**
  String get paymentTypeBank;

  /// No description provided for @paymentTypeCard.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة'**
  String get paymentTypeCard;

  /// No description provided for @paymentTypeCredit.
  ///
  /// In ar, this message translates to:
  /// **'آجل'**
  String get paymentTypeCredit;

  /// No description provided for @isDefault.
  ///
  /// In ar, this message translates to:
  /// **'الافتراضية'**
  String get isDefault;

  /// No description provided for @deliveryFee.
  ///
  /// In ar, this message translates to:
  /// **'رسوم التوصيل'**
  String get deliveryFee;

  /// No description provided for @deliveryDays.
  ///
  /// In ar, this message translates to:
  /// **'المدة (أيام)'**
  String get deliveryDays;

  /// No description provided for @abbreviation.
  ///
  /// In ar, this message translates to:
  /// **'الاختصار'**
  String get abbreviation;

  /// No description provided for @deactivate.
  ///
  /// In ar, this message translates to:
  /// **'تعطيل'**
  String get deactivate;

  /// No description provided for @activate.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get activate;

  /// No description provided for @usedCannotDelete.
  ///
  /// In ar, this message translates to:
  /// **'العنصر مستعمل ولا يمكن حذفه. عطّله بدلاً من ذلك.'**
  String get usedCannotDelete;

  /// No description provided for @deleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'حذف هذا العنصر؟'**
  String get deleteConfirm;

  /// No description provided for @reorderHint.
  ///
  /// In ar, this message translates to:
  /// **'اسحب لتغيير الترتيب'**
  String get reorderHint;

  /// No description provided for @newItem.
  ///
  /// In ar, this message translates to:
  /// **'عنصر جديد'**
  String get newItem;

  /// No description provided for @addOnTheFly.
  ///
  /// In ar, this message translates to:
  /// **'+ إضافة جديد'**
  String get addOnTheFly;

  /// No description provided for @productsTitle.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات'**
  String get productsTitle;

  /// No description provided for @searchProducts.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن منتج أو رمز…'**
  String get searchProducts;

  /// No description provided for @noProducts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات. أضف أول منتج.'**
  String get noProducts;

  /// No description provided for @lowStockFilter.
  ///
  /// In ar, this message translates to:
  /// **'مخزون منخفض'**
  String get lowStockFilter;

  /// No description provided for @allCategories.
  ///
  /// In ar, this message translates to:
  /// **'كل الأصناف'**
  String get allCategories;

  /// No description provided for @productNew.
  ///
  /// In ar, this message translates to:
  /// **'منتج جديد'**
  String get productNew;

  /// No description provided for @productEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المنتج'**
  String get productEdit;

  /// No description provided for @descriptionAr.
  ///
  /// In ar, this message translates to:
  /// **'الوصف بالعربية'**
  String get descriptionAr;

  /// No description provided for @descriptionFr.
  ///
  /// In ar, this message translates to:
  /// **'الوصف بالفرنسية'**
  String get descriptionFr;

  /// No description provided for @category.
  ///
  /// In ar, this message translates to:
  /// **'الصنف'**
  String get category;

  /// No description provided for @brand.
  ///
  /// In ar, this message translates to:
  /// **'العلامة'**
  String get brand;

  /// No description provided for @unit.
  ///
  /// In ar, this message translates to:
  /// **'الوحدة'**
  String get unit;

  /// No description provided for @tags.
  ///
  /// In ar, this message translates to:
  /// **'وسوم (مفصولة بفاصلة)'**
  String get tags;

  /// No description provided for @productActive.
  ///
  /// In ar, this message translates to:
  /// **'منتج نشط'**
  String get productActive;

  /// No description provided for @photos.
  ///
  /// In ar, this message translates to:
  /// **'الصور'**
  String get photos;

  /// No description provided for @addPhotos.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صور'**
  String get addPhotos;

  /// No description provided for @photoMain.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get photoMain;

  /// No description provided for @variants.
  ///
  /// In ar, this message translates to:
  /// **'المتغيرات (موديل، لون، مقاس)'**
  String get variants;

  /// No description provided for @variantAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة متغير'**
  String get variantAdd;

  /// No description provided for @variantEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المتغير'**
  String get variantEdit;

  /// No description provided for @variantsGenerate.
  ///
  /// In ar, this message translates to:
  /// **'توليد كل المتغيرات'**
  String get variantsGenerate;

  /// No description provided for @variantsGenerateHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر الموديلات والألوان والمقاسات: تُنشأ كل التركيبات.'**
  String get variantsGenerateHint;

  /// No description provided for @variantsToCreate.
  ///
  /// In ar, this message translates to:
  /// **'{count} متغير سيُنشأ'**
  String variantsToCreate(int count);

  /// No description provided for @basePrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر البيع'**
  String get basePrice;

  /// No description provided for @model.
  ///
  /// In ar, this message translates to:
  /// **'الموديل'**
  String get model;

  /// No description provided for @color.
  ///
  /// In ar, this message translates to:
  /// **'اللون'**
  String get color;

  /// No description provided for @size.
  ///
  /// In ar, this message translates to:
  /// **'المقاس'**
  String get size;

  /// No description provided for @sku.
  ///
  /// In ar, this message translates to:
  /// **'المرجع (SKU)'**
  String get sku;

  /// No description provided for @barcode.
  ///
  /// In ar, this message translates to:
  /// **'الباركود'**
  String get barcode;

  /// No description provided for @barcodeAutoHint.
  ///
  /// In ar, this message translates to:
  /// **'يُولَّد تلقائياً إن تُرك فارغاً'**
  String get barcodeAutoHint;

  /// No description provided for @promoPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر العرض'**
  String get promoPrice;

  /// No description provided for @promoStart.
  ///
  /// In ar, this message translates to:
  /// **'بداية العرض'**
  String get promoStart;

  /// No description provided for @promoEnd.
  ///
  /// In ar, this message translates to:
  /// **'نهاية العرض'**
  String get promoEnd;

  /// No description provided for @stockMinimum.
  ///
  /// In ar, this message translates to:
  /// **'حد التنبيه'**
  String get stockMinimum;

  /// No description provided for @archiveProduct.
  ///
  /// In ar, this message translates to:
  /// **'أرشفة المنتج'**
  String get archiveProduct;

  /// No description provided for @archiveConfirm.
  ///
  /// In ar, this message translates to:
  /// **'أرشفة هذا المنتج؟ يبقى سجل مبيعاته محفوظاً.'**
  String get archiveConfirm;

  /// No description provided for @duplicateProduct.
  ///
  /// In ar, this message translates to:
  /// **'نسخ المنتج'**
  String get duplicateProduct;

  /// No description provided for @priceFrom.
  ///
  /// In ar, this message translates to:
  /// **'ابتداءً من {price}'**
  String priceFrom(String price);

  /// No description provided for @stockCount.
  ///
  /// In ar, this message translates to:
  /// **'المخزون: {count}'**
  String stockCount(String count);

  /// No description provided for @variantCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} متغير'**
  String variantCount(int count);

  /// No description provided for @variantExists.
  ///
  /// In ar, this message translates to:
  /// **'هذه التركيبة موجودة مسبقاً'**
  String get variantExists;

  /// No description provided for @needOnline.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء المنتجات يتطلب اتصالاً بالإنترنت'**
  String get needOnline;

  /// No description provided for @createQuick.
  ///
  /// In ar, this message translates to:
  /// **'إضافة سريعة'**
  String get createQuick;

  /// No description provided for @priceInvalid.
  ///
  /// In ar, this message translates to:
  /// **'سعر غير صالح'**
  String get priceInvalid;

  /// No description provided for @deleteVariantConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تعطيل هذا المتغير؟'**
  String get deleteVariantConfirm;

  /// No description provided for @variantInactive.
  ///
  /// In ar, this message translates to:
  /// **'معطّل'**
  String get variantInactive;

  /// No description provided for @stockTitle.
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get stockTitle;

  /// No description provided for @stockSearch.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بالاسم أو الباركود…'**
  String get stockSearch;

  /// No description provided for @stockInStock.
  ///
  /// In ar, this message translates to:
  /// **'المتوفر'**
  String get stockInStock;

  /// No description provided for @stockReserved.
  ///
  /// In ar, this message translates to:
  /// **'محجوز'**
  String get stockReserved;

  /// No description provided for @stockAvailable.
  ///
  /// In ar, this message translates to:
  /// **'المتاح'**
  String get stockAvailable;

  /// No description provided for @stockEntryTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدخال مخزون'**
  String get stockEntryTitle;

  /// No description provided for @stockOutTitle.
  ///
  /// In ar, this message translates to:
  /// **'إخراج مخزون'**
  String get stockOutTitle;

  /// No description provided for @inventoryTitle.
  ///
  /// In ar, this message translates to:
  /// **'جرد المخزون'**
  String get inventoryTitle;

  /// No description provided for @stockActions.
  ///
  /// In ar, this message translates to:
  /// **'عمليات المخزون'**
  String get stockActions;

  /// No description provided for @supplier.
  ///
  /// In ar, this message translates to:
  /// **'المورد'**
  String get supplier;

  /// No description provided for @reference.
  ///
  /// In ar, this message translates to:
  /// **'المرجع'**
  String get reference;

  /// No description provided for @unitCost.
  ///
  /// In ar, this message translates to:
  /// **'سعر الشراء للوحدة'**
  String get unitCost;

  /// No description provided for @expiryDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الانتهاء'**
  String get expiryDate;

  /// No description provided for @newSalePrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر البيع الجديد'**
  String get newSalePrice;

  /// No description provided for @amountPaid.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المدفوع'**
  String get amountPaid;

  /// No description provided for @addLine.
  ///
  /// In ar, this message translates to:
  /// **'إضافة منتج'**
  String get addLine;

  /// No description provided for @pickVariant.
  ///
  /// In ar, this message translates to:
  /// **'اختيار منتج'**
  String get pickVariant;

  /// No description provided for @noLines.
  ///
  /// In ar, this message translates to:
  /// **'أضف منتجاً أو امسح باركوده'**
  String get noLines;

  /// No description provided for @reason.
  ///
  /// In ar, this message translates to:
  /// **'السبب'**
  String get reason;

  /// No description provided for @reasonRequired.
  ///
  /// In ar, this message translates to:
  /// **'اختر سبباً'**
  String get reasonRequired;

  /// No description provided for @counted.
  ///
  /// In ar, this message translates to:
  /// **'الكمية المعدودة'**
  String get counted;

  /// No description provided for @systemQty.
  ///
  /// In ar, this message translates to:
  /// **'في النظام: {qty}'**
  String systemQty(String qty);

  /// No description provided for @difference.
  ///
  /// In ar, this message translates to:
  /// **'الفرق: {qty}'**
  String difference(String qty);

  /// No description provided for @applyInventory.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق الجرد'**
  String get applyInventory;

  /// No description provided for @stockHistory.
  ///
  /// In ar, this message translates to:
  /// **'سجل الحركات'**
  String get stockHistory;

  /// No description provided for @lots.
  ///
  /// In ar, this message translates to:
  /// **'الدفعات'**
  String get lots;

  /// No description provided for @lotRemaining.
  ///
  /// In ar, this message translates to:
  /// **'المتبقي {qty} من {initial}'**
  String lotRemaining(String qty, String initial);

  /// No description provided for @expiresOn.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي في {date}'**
  String expiresOn(String date);

  /// No description provided for @costLabel.
  ///
  /// In ar, this message translates to:
  /// **'الشراء: {cost}'**
  String costLabel(String cost);

  /// No description provided for @movement_entree.
  ///
  /// In ar, this message translates to:
  /// **'إدخال'**
  String get movement_entree;

  /// No description provided for @movement_sortie_vente.
  ///
  /// In ar, this message translates to:
  /// **'بيع'**
  String get movement_sortie_vente;

  /// No description provided for @movement_sortie_manuelle.
  ///
  /// In ar, this message translates to:
  /// **'إخراج يدوي'**
  String get movement_sortie_manuelle;

  /// No description provided for @movement_retour_client.
  ///
  /// In ar, this message translates to:
  /// **'إرجاع زبونة'**
  String get movement_retour_client;

  /// No description provided for @movement_retour_fournisseur.
  ///
  /// In ar, this message translates to:
  /// **'إرجاع للمورد'**
  String get movement_retour_fournisseur;

  /// No description provided for @movement_ajustement.
  ///
  /// In ar, this message translates to:
  /// **'تعديل جرد'**
  String get movement_ajustement;

  /// No description provided for @movement_reservation.
  ///
  /// In ar, this message translates to:
  /// **'حجز'**
  String get movement_reservation;

  /// No description provided for @movement_liberation.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء حجز'**
  String get movement_liberation;

  /// No description provided for @movement_transfert_sortie.
  ///
  /// In ar, this message translates to:
  /// **'تحويل صادر'**
  String get movement_transfert_sortie;

  /// No description provided for @movement_transfert_entree.
  ///
  /// In ar, this message translates to:
  /// **'تحويل وارد'**
  String get movement_transfert_entree;

  /// No description provided for @queuedOffline.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ وسيُرسل عند عودة الاتصال'**
  String get queuedOffline;

  /// No description provided for @scanNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على منتج بهذا الرمز'**
  String get scanNotFound;

  /// No description provided for @quantityInvalid.
  ///
  /// In ar, this message translates to:
  /// **'كمية غير صالحة'**
  String get quantityInvalid;

  /// No description provided for @stockOutQty.
  ///
  /// In ar, this message translates to:
  /// **'الكمية المخرجة'**
  String get stockOutQty;

  /// No description provided for @cartTitle.
  ///
  /// In ar, this message translates to:
  /// **'السلة'**
  String get cartTitle;

  /// No description provided for @cartEmpty.
  ///
  /// In ar, this message translates to:
  /// **'السلة فارغة'**
  String get cartEmpty;

  /// No description provided for @cartItems.
  ///
  /// In ar, this message translates to:
  /// **'{count} منتج'**
  String cartItems(String count);

  /// No description provided for @viewCart.
  ///
  /// In ar, this message translates to:
  /// **'عرض السلة'**
  String get viewCart;

  /// No description provided for @pay.
  ///
  /// In ar, this message translates to:
  /// **'الدفع'**
  String get pay;

  /// No description provided for @editPrice.
  ///
  /// In ar, this message translates to:
  /// **'تعديل السعر'**
  String get editPrice;

  /// No description provided for @applyDiscount.
  ///
  /// In ar, this message translates to:
  /// **'تخفيض على الفاتورة'**
  String get applyDiscount;

  /// No description provided for @lineDiscount.
  ///
  /// In ar, this message translates to:
  /// **'تخفيض على السطر'**
  String get lineDiscount;

  /// No description provided for @discountAmount.
  ///
  /// In ar, this message translates to:
  /// **'مبلغ'**
  String get discountAmount;

  /// No description provided for @discountPercent.
  ///
  /// In ar, this message translates to:
  /// **'نسبة %'**
  String get discountPercent;

  /// No description provided for @walkInCustomer.
  ///
  /// In ar, this message translates to:
  /// **'زبونة عابرة'**
  String get walkInCustomer;

  /// No description provided for @suspendSale.
  ///
  /// In ar, this message translates to:
  /// **'تعليق البيع'**
  String get suspendSale;

  /// No description provided for @suspendedSales.
  ///
  /// In ar, this message translates to:
  /// **'المبيعات المعلّقة'**
  String get suspendedSales;

  /// No description provided for @noSuspended.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مبيعات معلّقة'**
  String get noSuspended;

  /// No description provided for @paidSoFar.
  ///
  /// In ar, this message translates to:
  /// **'المدفوع'**
  String get paidSoFar;

  /// No description provided for @remainingDue.
  ///
  /// In ar, this message translates to:
  /// **'المتبقي'**
  String get remainingDue;

  /// No description provided for @changeDue.
  ///
  /// In ar, this message translates to:
  /// **'الباقي للزبونة'**
  String get changeDue;

  /// No description provided for @receivedAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المستلم'**
  String get receivedAmount;

  /// No description provided for @addPayment.
  ///
  /// In ar, this message translates to:
  /// **'إضافة دفعة'**
  String get addPayment;

  /// No description provided for @creditSale.
  ///
  /// In ar, this message translates to:
  /// **'بيع بالآجل'**
  String get creditSale;

  /// No description provided for @customerRequiredForDebt.
  ///
  /// In ar, this message translates to:
  /// **'اختر زبونة لتسجيل المبلغ المتبقي كدين'**
  String get customerRequiredForDebt;

  /// No description provided for @confirmSale.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد البيع'**
  String get confirmSale;

  /// No description provided for @receiptTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم البيع'**
  String get receiptTitle;

  /// No description provided for @numberPending.
  ///
  /// In ar, this message translates to:
  /// **'الرقم قيد الإسناد'**
  String get numberPending;

  /// No description provided for @saleQueued.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ وسيُزامَن تلقائياً'**
  String get saleQueued;

  /// No description provided for @sharePdf.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة PDF'**
  String get sharePdf;

  /// No description provided for @whatsappMessage.
  ///
  /// In ar, this message translates to:
  /// **'رسالة واتساب'**
  String get whatsappMessage;

  /// No description provided for @printInvoice.
  ///
  /// In ar, this message translates to:
  /// **'طباعة'**
  String get printInvoice;

  /// No description provided for @newSaleAction.
  ///
  /// In ar, this message translates to:
  /// **'بيع جديد'**
  String get newSaleAction;

  /// No description provided for @cashSession.
  ///
  /// In ar, this message translates to:
  /// **'الصندوق'**
  String get cashSession;

  /// No description provided for @openCash.
  ///
  /// In ar, this message translates to:
  /// **'فتح الصندوق'**
  String get openCash;

  /// No description provided for @closeCash.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق الصندوق'**
  String get closeCash;

  /// No description provided for @cashFloat.
  ///
  /// In ar, this message translates to:
  /// **'مبلغ بداية الصندوق'**
  String get cashFloat;

  /// No description provided for @cashCounted.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المعدود'**
  String get cashCounted;

  /// No description provided for @cashExpected.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المنتظر'**
  String get cashExpected;

  /// No description provided for @cashDifference.
  ///
  /// In ar, this message translates to:
  /// **'الفرق'**
  String get cashDifference;

  /// No description provided for @zReport.
  ///
  /// In ar, this message translates to:
  /// **'تقرير Z'**
  String get zReport;

  /// No description provided for @unpaidOnly.
  ///
  /// In ar, this message translates to:
  /// **'غير مدفوعة'**
  String get unpaidOnly;

  /// No description provided for @searchCustomers.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن زبونة…'**
  String get searchCustomers;

  /// No description provided for @noCustomers.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد زبائن'**
  String get noCustomers;

  /// No description provided for @newCustomer.
  ///
  /// In ar, this message translates to:
  /// **'زبونة جديدة'**
  String get newCustomer;

  /// No description provided for @editCustomer.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الزبونة'**
  String get editCustomer;

  /// No description provided for @creditLimit.
  ///
  /// In ar, this message translates to:
  /// **'سقف الدين'**
  String get creditLimit;

  /// No description provided for @balanceDue.
  ///
  /// In ar, this message translates to:
  /// **'الدين المستحق'**
  String get balanceDue;

  /// No description provided for @settleDebt.
  ///
  /// In ar, this message translates to:
  /// **'تسديد الدين'**
  String get settleDebt;

  /// No description provided for @callCustomer.
  ///
  /// In ar, this message translates to:
  /// **'اتصال'**
  String get callCustomer;

  /// No description provided for @whatsappReminder.
  ///
  /// In ar, this message translates to:
  /// **'تذكير واتساب'**
  String get whatsappReminder;

  /// No description provided for @reminderMessage.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً {name}، نذكّرك بمبلغ مستحق: {amount}. شكراً!'**
  String reminderMessage(String name, String amount);

  /// No description provided for @purchaseHistory.
  ///
  /// In ar, this message translates to:
  /// **'سجل المشتريات'**
  String get purchaseHistory;

  /// No description provided for @noPurchases.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مشتريات'**
  String get noPurchases;

  /// No description provided for @orderNew.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get orderNew;

  /// No description provided for @orderConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'مؤكد'**
  String get orderConfirmed;

  /// No description provided for @orderPreparing.
  ///
  /// In ar, this message translates to:
  /// **'قيد التجهيز'**
  String get orderPreparing;

  /// No description provided for @orderReady.
  ///
  /// In ar, this message translates to:
  /// **'جاهز'**
  String get orderReady;

  /// No description provided for @orderShipped.
  ///
  /// In ar, this message translates to:
  /// **'تم الشحن'**
  String get orderShipped;

  /// No description provided for @orderDelivered.
  ///
  /// In ar, this message translates to:
  /// **'تم التسليم'**
  String get orderDelivered;

  /// No description provided for @orderCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغى'**
  String get orderCancelled;

  /// No description provided for @orderReturned.
  ///
  /// In ar, this message translates to:
  /// **'مرتجع'**
  String get orderReturned;

  /// No description provided for @orderDetail.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الطلب'**
  String get orderDetail;

  /// No description provided for @newOrderReceived.
  ///
  /// In ar, this message translates to:
  /// **'طلب جديد'**
  String get newOrderReceived;

  /// No description provided for @pickup.
  ///
  /// In ar, this message translates to:
  /// **'استلام من المتجر'**
  String get pickup;

  /// No description provided for @delivery.
  ///
  /// In ar, this message translates to:
  /// **'توصيل'**
  String get delivery;

  /// No description provided for @paymentMode.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get paymentMode;

  /// No description provided for @paymentProof.
  ///
  /// In ar, this message translates to:
  /// **'إثبات الدفع'**
  String get paymentProof;

  /// No description provided for @cancelOrderConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء هذا الطلب؟ سيُحرَّر المخزون المحجوز.'**
  String get cancelOrderConfirm;

  /// No description provided for @generateInvoice.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء فاتورة'**
  String get generateInvoice;

  /// No description provided for @invoiceCreated.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء الفاتورة'**
  String get invoiceCreated;

  /// No description provided for @viewInvoice.
  ///
  /// In ar, this message translates to:
  /// **'عرض الفاتورة'**
  String get viewInvoice;

  /// No description provided for @orderStatusMessage.
  ///
  /// In ar, this message translates to:
  /// **'طلبك رقم {number}: {status}'**
  String orderStatusMessage(String number, String status);

  /// No description provided for @shopProfile.
  ///
  /// In ar, this message translates to:
  /// **'ملف المتجر'**
  String get shopProfile;

  /// No description provided for @onlineStore.
  ///
  /// In ar, this message translates to:
  /// **'المتجر الإلكتروني'**
  String get onlineStore;

  /// No description provided for @employees.
  ///
  /// In ar, this message translates to:
  /// **'الموظفات'**
  String get employees;

  /// No description provided for @currency.
  ///
  /// In ar, this message translates to:
  /// **'العملة'**
  String get currency;

  /// No description provided for @documentFooterAr.
  ///
  /// In ar, this message translates to:
  /// **'تذييل الفواتير (عربي)'**
  String get documentFooterAr;

  /// No description provided for @documentFooterFr.
  ///
  /// In ar, this message translates to:
  /// **'تذييل الفواتير (فرنسي)'**
  String get documentFooterFr;

  /// No description provided for @defaultStockThreshold.
  ///
  /// In ar, this message translates to:
  /// **'حد تنبيه المخزون الافتراضي'**
  String get defaultStockThreshold;

  /// No description provided for @allowNegativeStock.
  ///
  /// In ar, this message translates to:
  /// **'السماح بالمخزون السالب'**
  String get allowNegativeStock;

  /// No description provided for @subdomain.
  ///
  /// In ar, this message translates to:
  /// **'النطاق الفرعي'**
  String get subdomain;

  /// No description provided for @subdomainReadOnlyHint.
  ///
  /// In ar, this message translates to:
  /// **'يُمنح النطاق الفرعي عند إنشاء المتجر ولا يمكن تغييره من التطبيق. للتعديل تواصل مع الناشر.'**
  String get subdomainReadOnlyHint;

  /// No description provided for @customDomain.
  ///
  /// In ar, this message translates to:
  /// **'النطاق الخاص'**
  String get customDomain;

  /// No description provided for @shopCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز المتجر'**
  String get shopCode;

  /// No description provided for @role.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get role;

  /// No description provided for @roleOwner.
  ///
  /// In ar, this message translates to:
  /// **'المالكة'**
  String get roleOwner;

  /// No description provided for @roleManager.
  ///
  /// In ar, this message translates to:
  /// **'المسيّرة'**
  String get roleManager;

  /// No description provided for @roleCashier.
  ///
  /// In ar, this message translates to:
  /// **'بائعة'**
  String get roleCashier;

  /// No description provided for @roleStockKeeper.
  ///
  /// In ar, this message translates to:
  /// **'أمينة المخزن'**
  String get roleStockKeeper;

  /// No description provided for @inviteEmployee.
  ///
  /// In ar, this message translates to:
  /// **'دعوة موظفة'**
  String get inviteEmployee;

  /// No description provided for @initialCode.
  ///
  /// In ar, this message translates to:
  /// **'الرمز الأولي'**
  String get initialCode;

  /// No description provided for @initialCodeHint.
  ///
  /// In ar, this message translates to:
  /// **'سلّمها رقم الهاتف وهذا الرمز (يظهر مرة واحدة).'**
  String get initialCodeHint;

  /// No description provided for @resetCode.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين الرمز'**
  String get resetCode;

  /// No description provided for @unlimited.
  ///
  /// In ar, this message translates to:
  /// **'غير محدود'**
  String get unlimited;

  /// No description provided for @renewalHint.
  ///
  /// In ar, this message translates to:
  /// **'لتجديد اشتراكك تواصل مع الناشر: يُسجَّل الدفع من لوحة الإدارة.'**
  String get renewalHint;

  /// No description provided for @onboardingTitle.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك!'**
  String get onboardingTitle;

  /// No description provided for @onboardingShop.
  ///
  /// In ar, this message translates to:
  /// **'معلومات المتجر'**
  String get onboardingShop;

  /// No description provided for @onboardingCategories.
  ///
  /// In ar, this message translates to:
  /// **'أصناف البداية'**
  String get onboardingCategories;

  /// No description provided for @onboardingCategoriesHint.
  ///
  /// In ar, this message translates to:
  /// **'احتفظ بالأصناف التي تبيعينها. يمكنك تعديلها لاحقاً.'**
  String get onboardingCategoriesHint;

  /// No description provided for @onboardingPayment.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع الافتراضية'**
  String get onboardingPayment;

  /// No description provided for @onboardingPaymentHint.
  ///
  /// In ar, this message translates to:
  /// **'ستُحدَّد تلقائياً عند البيع.'**
  String get onboardingPaymentHint;

  /// No description provided for @chooseLogo.
  ///
  /// In ar, this message translates to:
  /// **'اختيار شعار'**
  String get chooseLogo;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// No description provided for @finish.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء'**
  String get finish;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
