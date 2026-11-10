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

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get add => 'إضافة';

  @override
  String get create => 'إنشاء';

  @override
  String get search => 'بحث';

  @override
  String get confirm => 'تأكيد';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get close => 'إغلاق';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get optional => 'اختياري';

  @override
  String get requiredField => 'هذا الحقل مطلوب';

  @override
  String get nameAr => 'الاسم بالعربية';

  @override
  String get nameFr => 'الاسم بالفرنسية';

  @override
  String get nameRequired => 'أدخل الاسم بإحدى اللغتين';

  @override
  String get amount => 'المبلغ';

  @override
  String get quantity => 'الكمية';

  @override
  String get price => 'السعر';

  @override
  String get total => 'المجموع';

  @override
  String get subtotal => 'المجموع الفرعي';

  @override
  String get discount => 'تخفيض';

  @override
  String get note => 'ملاحظة';

  @override
  String get address => 'العنوان';

  @override
  String get city => 'المدينة';

  @override
  String get whatsapp => 'واتساب';

  @override
  String get status => 'الحالة';

  @override
  String get date => 'التاريخ';

  @override
  String get actions => 'إجراءات';

  @override
  String get none => 'لا شيء';

  @override
  String get all => 'الكل';

  @override
  String get active => 'نشط';

  @override
  String get inactive => 'غير نشط';

  @override
  String get scan => 'مسح الباركود';

  @override
  String get saved => 'تم الحفظ';

  @override
  String get deleted => 'تم الحذف';

  @override
  String get emptyList => 'لا توجد عناصر بعد';

  @override
  String get permissionDenied => 'ليست لديك صلاحية لهذا الإجراء';

  @override
  String get connectionRequired => 'هذا الإجراء يتطلب اتصالاً بالإنترنت';

  @override
  String get offlineBanner =>
      'وضع غير متصل — ستُرسل العمليات تلقائياً عند عودة الاتصال';

  @override
  String syncPending(int count) {
    return '$count عملية في الانتظار';
  }

  @override
  String get syncNow => 'مزامنة الآن';

  @override
  String get syncIssuesTitle => 'عمليات تحتاج إلى قرارك';

  @override
  String get syncIssuesHint =>
      'رفض الخادم هذه العمليات. أعد المحاولة أو تخلّ عنها.';

  @override
  String get discard => 'تخلّي';

  @override
  String get readOnlyBanner =>
      'الاشتراك منتهٍ: التطبيق للقراءة فقط. تواصل مع الناشر للتجديد.';

  @override
  String get graceBanner => 'اشتراكك منتهٍ — فترة سماح محدودة. جدّد قريباً.';

  @override
  String get suspendedTitle => 'الحساب موقوف';

  @override
  String get suspendedText =>
      'تم إيقاف هذا المتجر بسبب انتهاء الاشتراك. بياناتك محفوظة ويمكنك الاطلاع عليها.';

  @override
  String get contactPublisher => 'تواصل مع الناشر';

  @override
  String get shop => 'المتجر';

  @override
  String get switchShop => 'تغيير المتجر';

  @override
  String get synced => 'تمت المزامنة';

  @override
  String lastSync(String date) {
    return 'آخر مزامنة: $date';
  }

  @override
  String get selectOption => 'اختر';

  @override
  String unknownError(String details) {
    return 'تعذّر تنفيذ العملية: $details';
  }

  @override
  String get stockInsufficient => 'المخزون غير كافٍ';

  @override
  String get serverError_stock_insuffisant => 'المخزون غير كافٍ لهذه العملية';

  @override
  String get serverError_client_requis => 'اختر زبونة لبيع بالآجل';

  @override
  String get serverError_plafond_credit_depasse => 'تجاوز سقف الائتمان للزبونة';

  @override
  String get serverError_prix_non_autorise => 'ليست لديك صلاحية تعديل الأسعار';

  @override
  String get serverError_boutique_inactive => 'المتجر في وضع القراءة فقط';

  @override
  String get serverError_quota_depasse => 'تجاوزت حد خطة اشتراكك';

  @override
  String get serverError_motif_obligatoire => 'السبب إلزامي لإخراج المخزون';

  @override
  String get bootLoading => 'جارٍ تحضير متجرك…';

  @override
  String get noShopTitle => 'لا يوجد متجر مرتبط بحسابك';

  @override
  String get noShopText => 'تواصل مع الناشر لإنشاء متجرك.';

  @override
  String get continueReadOnly => 'المتابعة بوضع القراءة فقط';

  @override
  String get dashboardToday => 'اليوم';

  @override
  String get dashboardWeek => '7 أيام';

  @override
  String get dashboardMonth => 'هذا الشهر';

  @override
  String get revenue => 'المبيعات';

  @override
  String get salesCount => 'عدد المبيعات';

  @override
  String get outOfStock => 'منتجات نفدت';

  @override
  String get lowStock => 'مخزون منخفض';

  @override
  String get ordersToProcess => 'طلبات للمعالجة';

  @override
  String get unpaidCustomers => 'ديون الزبائن';

  @override
  String get shortcuts => 'اختصارات';

  @override
  String get newSale => 'عملية بيع جديدة';

  @override
  String get newProduct => 'منتج جديد';

  @override
  String get stockEntry => 'إدخال مخزون';

  @override
  String get menuOrders => 'الطلبات الإلكترونية';

  @override
  String get menuDocuments => 'الفواتير';

  @override
  String get menuCustomers => 'الزبائن';

  @override
  String get menuReferentials => 'المراجع (ألوان، أصناف…)';

  @override
  String get menuSettings => 'إعدادات المتجر';

  @override
  String get menuNotifications => 'الإشعارات';

  @override
  String get menuSync => 'المزامنة';

  @override
  String get menuSubscription => 'الاشتراك';

  @override
  String get refCategories => 'الأصناف';

  @override
  String get refColors => 'الألوان';

  @override
  String get refModels => 'الموديلات';

  @override
  String get refSizes => 'المقاسات';

  @override
  String get refBrands => 'العلامات التجارية';

  @override
  String get refUnits => 'الوحدات';

  @override
  String get refPaymentModes => 'طرق الدفع';

  @override
  String get refDeliveryZones => 'مناطق التوصيل';

  @override
  String get refSuppliers => 'الموردون';

  @override
  String get colorHex => 'رمز اللون (Hex)';

  @override
  String get colorInvalid => 'رمز لون غير صالح (مثال: #00FF00)';

  @override
  String get parentCategory => 'الصنف الأب';

  @override
  String get visibleOnline => 'ظاهر في المتجر الإلكتروني';

  @override
  String get sizeType => 'نوع المقاس';

  @override
  String get sizeTypeSize => 'مقاس';

  @override
  String get sizeTypeShoe => 'مقاس حذاء';

  @override
  String get sizeTypeLength => 'طول';

  @override
  String get paymentTypeCash => 'نقداً';

  @override
  String get paymentTypeMobile => 'محفظة إلكترونية';

  @override
  String get paymentTypeBank => 'بنك';

  @override
  String get paymentTypeCard => 'بطاقة';

  @override
  String get paymentTypeCredit => 'آجل';

  @override
  String get isDefault => 'الافتراضية';

  @override
  String get deliveryFee => 'رسوم التوصيل';

  @override
  String get deliveryDays => 'المدة (أيام)';

  @override
  String get abbreviation => 'الاختصار';

  @override
  String get deactivate => 'تعطيل';

  @override
  String get activate => 'تفعيل';

  @override
  String get usedCannotDelete =>
      'العنصر مستعمل ولا يمكن حذفه. عطّله بدلاً من ذلك.';

  @override
  String get deleteConfirm => 'حذف هذا العنصر؟';

  @override
  String get reorderHint => 'اسحب لتغيير الترتيب';

  @override
  String get newItem => 'عنصر جديد';

  @override
  String get addOnTheFly => '+ إضافة جديد';

  @override
  String get productsTitle => 'المنتجات';

  @override
  String get searchProducts => 'ابحث عن منتج أو رمز…';

  @override
  String get noProducts => 'لا توجد منتجات. أضف أول منتج.';

  @override
  String get lowStockFilter => 'مخزون منخفض';

  @override
  String get allCategories => 'كل الأصناف';

  @override
  String get productNew => 'منتج جديد';

  @override
  String get productEdit => 'تعديل المنتج';

  @override
  String get descriptionAr => 'الوصف بالعربية';

  @override
  String get descriptionFr => 'الوصف بالفرنسية';

  @override
  String get category => 'الصنف';

  @override
  String get brand => 'العلامة';

  @override
  String get unit => 'الوحدة';

  @override
  String get tags => 'وسوم (مفصولة بفاصلة)';

  @override
  String get productActive => 'منتج نشط';

  @override
  String get photos => 'الصور';

  @override
  String get addPhotos => 'إضافة صور';

  @override
  String get photoMain => 'الرئيسية';

  @override
  String get variants => 'المتغيرات (موديل، لون، مقاس)';

  @override
  String get variantAdd => 'إضافة متغير';

  @override
  String get variantEdit => 'تعديل المتغير';

  @override
  String get variantsGenerate => 'توليد كل المتغيرات';

  @override
  String get variantsGenerateHint =>
      'اختر الموديلات والألوان والمقاسات: تُنشأ كل التركيبات.';

  @override
  String variantsToCreate(int count) {
    return '$count متغير سيُنشأ';
  }

  @override
  String get basePrice => 'سعر البيع';

  @override
  String get model => 'الموديل';

  @override
  String get color => 'اللون';

  @override
  String get size => 'المقاس';

  @override
  String get sku => 'المرجع (SKU)';

  @override
  String get barcode => 'الباركود';

  @override
  String get barcodeAutoHint => 'يُولَّد تلقائياً إن تُرك فارغاً';

  @override
  String get promoPrice => 'سعر العرض';

  @override
  String get promoStart => 'بداية العرض';

  @override
  String get promoEnd => 'نهاية العرض';

  @override
  String get stockMinimum => 'حد التنبيه';

  @override
  String get archiveProduct => 'أرشفة المنتج';

  @override
  String get archiveConfirm => 'أرشفة هذا المنتج؟ يبقى سجل مبيعاته محفوظاً.';

  @override
  String get duplicateProduct => 'نسخ المنتج';

  @override
  String priceFrom(String price) {
    return 'ابتداءً من $price';
  }

  @override
  String stockCount(String count) {
    return 'المخزون: $count';
  }

  @override
  String variantCount(int count) {
    return '$count متغير';
  }

  @override
  String get variantExists => 'هذه التركيبة موجودة مسبقاً';

  @override
  String get needOnline => 'إنشاء المنتجات يتطلب اتصالاً بالإنترنت';

  @override
  String get createQuick => 'إضافة سريعة';

  @override
  String get priceInvalid => 'سعر غير صالح';

  @override
  String get deleteVariantConfirm => 'تعطيل هذا المتغير؟';

  @override
  String get variantInactive => 'معطّل';

  @override
  String get stockTitle => 'المخزون';

  @override
  String get stockSearch => 'ابحث بالاسم أو الباركود…';

  @override
  String get stockInStock => 'المتوفر';

  @override
  String get stockReserved => 'محجوز';

  @override
  String get stockAvailable => 'المتاح';

  @override
  String get stockEntryTitle => 'إدخال مخزون';

  @override
  String get stockOutTitle => 'إخراج مخزون';

  @override
  String get inventoryTitle => 'جرد المخزون';

  @override
  String get stockActions => 'عمليات المخزون';

  @override
  String get supplier => 'المورد';

  @override
  String get reference => 'المرجع';

  @override
  String get unitCost => 'سعر الشراء للوحدة';

  @override
  String get expiryDate => 'تاريخ الانتهاء';

  @override
  String get newSalePrice => 'سعر البيع الجديد';

  @override
  String get amountPaid => 'المبلغ المدفوع';

  @override
  String get addLine => 'إضافة منتج';

  @override
  String get pickVariant => 'اختيار منتج';

  @override
  String get noLines => 'أضف منتجاً أو امسح باركوده';

  @override
  String get reason => 'السبب';

  @override
  String get reasonRequired => 'اختر سبباً';

  @override
  String get counted => 'الكمية المعدودة';

  @override
  String systemQty(String qty) {
    return 'في النظام: $qty';
  }

  @override
  String difference(String qty) {
    return 'الفرق: $qty';
  }

  @override
  String get applyInventory => 'تطبيق الجرد';

  @override
  String get stockHistory => 'سجل الحركات';

  @override
  String get lots => 'الدفعات';

  @override
  String lotRemaining(String qty, String initial) {
    return 'المتبقي $qty من $initial';
  }

  @override
  String expiresOn(String date) {
    return 'ينتهي في $date';
  }

  @override
  String costLabel(String cost) {
    return 'الشراء: $cost';
  }

  @override
  String get movement_entree => 'إدخال';

  @override
  String get movement_sortie_vente => 'بيع';

  @override
  String get movement_sortie_manuelle => 'إخراج يدوي';

  @override
  String get movement_retour_client => 'إرجاع زبونة';

  @override
  String get movement_retour_fournisseur => 'إرجاع للمورد';

  @override
  String get movement_ajustement => 'تعديل جرد';

  @override
  String get movement_reservation => 'حجز';

  @override
  String get movement_liberation => 'إلغاء حجز';

  @override
  String get movement_transfert_sortie => 'تحويل صادر';

  @override
  String get movement_transfert_entree => 'تحويل وارد';

  @override
  String get queuedOffline => 'تم الحفظ وسيُرسل عند عودة الاتصال';

  @override
  String get scanNotFound => 'لم يتم العثور على منتج بهذا الرمز';

  @override
  String get quantityInvalid => 'كمية غير صالحة';

  @override
  String get stockOutQty => 'الكمية المخرجة';

  @override
  String get cartTitle => 'السلة';

  @override
  String get cartEmpty => 'السلة فارغة';

  @override
  String cartItems(String count) {
    return '$count منتج';
  }

  @override
  String get viewCart => 'عرض السلة';

  @override
  String get pay => 'الدفع';

  @override
  String get editPrice => 'تعديل السعر';

  @override
  String get applyDiscount => 'تخفيض على الفاتورة';

  @override
  String get lineDiscount => 'تخفيض على السطر';

  @override
  String get discountAmount => 'مبلغ';

  @override
  String get discountPercent => 'نسبة %';

  @override
  String get walkInCustomer => 'زبونة عابرة';

  @override
  String get suspendSale => 'تعليق البيع';

  @override
  String get suspendedSales => 'المبيعات المعلّقة';

  @override
  String get noSuspended => 'لا توجد مبيعات معلّقة';

  @override
  String get paidSoFar => 'المدفوع';

  @override
  String get remainingDue => 'المتبقي';

  @override
  String get changeDue => 'الباقي للزبونة';

  @override
  String get receivedAmount => 'المبلغ المستلم';

  @override
  String get addPayment => 'إضافة دفعة';

  @override
  String get creditSale => 'بيع بالآجل';

  @override
  String get customerRequiredForDebt => 'اختر زبونة لتسجيل المبلغ المتبقي كدين';

  @override
  String get confirmSale => 'تأكيد البيع';

  @override
  String get receiptTitle => 'تم البيع';

  @override
  String get numberPending => 'الرقم قيد الإسناد';

  @override
  String get saleQueued => 'تم الحفظ وسيُزامَن تلقائياً';

  @override
  String get sharePdf => 'مشاركة PDF';

  @override
  String get whatsappMessage => 'رسالة واتساب';

  @override
  String get printInvoice => 'طباعة';

  @override
  String get newSaleAction => 'بيع جديد';

  @override
  String get cashSession => 'الصندوق';

  @override
  String get openCash => 'فتح الصندوق';

  @override
  String get closeCash => 'إغلاق الصندوق';

  @override
  String get cashFloat => 'مبلغ بداية الصندوق';

  @override
  String get cashCounted => 'المبلغ المعدود';

  @override
  String get cashExpected => 'المبلغ المنتظر';

  @override
  String get cashDifference => 'الفرق';

  @override
  String get zReport => 'تقرير Z';

  @override
  String get unpaidOnly => 'غير مدفوعة';

  @override
  String get searchCustomers => 'ابحث عن زبونة…';

  @override
  String get noCustomers => 'لا توجد زبائن';

  @override
  String get newCustomer => 'زبونة جديدة';

  @override
  String get editCustomer => 'تعديل الزبونة';

  @override
  String get creditLimit => 'سقف الدين';

  @override
  String get balanceDue => 'الدين المستحق';

  @override
  String get settleDebt => 'تسديد الدين';

  @override
  String get callCustomer => 'اتصال';

  @override
  String get whatsappReminder => 'تذكير واتساب';

  @override
  String reminderMessage(String name, String amount) {
    return 'مرحباً $name، نذكّرك بمبلغ مستحق: $amount. شكراً!';
  }

  @override
  String get purchaseHistory => 'سجل المشتريات';

  @override
  String get noPurchases => 'لا توجد مشتريات';

  @override
  String get orderNew => 'جديد';

  @override
  String get orderConfirmed => 'مؤكد';

  @override
  String get orderPreparing => 'قيد التجهيز';

  @override
  String get orderReady => 'جاهز';

  @override
  String get orderShipped => 'تم الشحن';

  @override
  String get orderDelivered => 'تم التسليم';

  @override
  String get orderCancelled => 'ملغى';

  @override
  String get orderReturned => 'مرتجع';

  @override
  String get orderDetail => 'تفاصيل الطلب';

  @override
  String get newOrderReceived => 'طلب جديد';

  @override
  String get pickup => 'استلام من المتجر';

  @override
  String get delivery => 'توصيل';

  @override
  String get paymentMode => 'طريقة الدفع';

  @override
  String get paymentProof => 'إثبات الدفع';

  @override
  String get cancelOrderConfirm => 'إلغاء هذا الطلب؟ سيُحرَّر المخزون المحجوز.';

  @override
  String get generateInvoice => 'إنشاء فاتورة';

  @override
  String get invoiceCreated => 'تم إنشاء الفاتورة';

  @override
  String get viewInvoice => 'عرض الفاتورة';

  @override
  String orderStatusMessage(String number, String status) {
    return 'طلبك رقم $number: $status';
  }

  @override
  String get shopProfile => 'ملف المتجر';

  @override
  String get onlineStore => 'المتجر الإلكتروني';

  @override
  String get employees => 'الموظفات';

  @override
  String get currency => 'العملة';

  @override
  String get documentFooterAr => 'تذييل الفواتير (عربي)';

  @override
  String get documentFooterFr => 'تذييل الفواتير (فرنسي)';

  @override
  String get defaultStockThreshold => 'حد تنبيه المخزون الافتراضي';

  @override
  String get allowNegativeStock => 'السماح بالمخزون السالب';

  @override
  String get subdomain => 'النطاق الفرعي';

  @override
  String get subdomainReadOnlyHint =>
      'يُمنح النطاق الفرعي عند إنشاء المتجر ولا يمكن تغييره من التطبيق. للتعديل تواصل مع الناشر.';

  @override
  String get customDomain => 'النطاق الخاص';

  @override
  String get shopCode => 'رمز المتجر';

  @override
  String get role => 'الدور';

  @override
  String get roleOwner => 'المالكة';

  @override
  String get roleManager => 'المسيّرة';

  @override
  String get roleCashier => 'بائعة';

  @override
  String get roleStockKeeper => 'أمينة المخزن';

  @override
  String get inviteEmployee => 'دعوة موظفة';

  @override
  String get initialCode => 'الرمز الأولي';

  @override
  String get initialCodeHint =>
      'سلّمها رقم الهاتف وهذا الرمز (يظهر مرة واحدة).';

  @override
  String get resetCode => 'إعادة تعيين الرمز';

  @override
  String get unlimited => 'غير محدود';

  @override
  String get renewalHint =>
      'لتجديد اشتراكك تواصل مع الناشر: يُسجَّل الدفع من لوحة الإدارة.';

  @override
  String get onboardingTitle => 'مرحباً بك!';

  @override
  String get onboardingShop => 'معلومات المتجر';

  @override
  String get onboardingCategories => 'أصناف البداية';

  @override
  String get onboardingCategoriesHint =>
      'احتفظ بالأصناف التي تبيعينها. يمكنك تعديلها لاحقاً.';

  @override
  String get onboardingPayment => 'طريقة الدفع الافتراضية';

  @override
  String get onboardingPaymentHint => 'ستُحدَّد تلقائياً عند البيع.';

  @override
  String get chooseLogo => 'اختيار شعار';

  @override
  String get back => 'رجوع';

  @override
  String get next => 'التالي';

  @override
  String get finish => 'إنهاء';

  @override
  String get appearance => 'المظهر';

  @override
  String get themeModeTitle => 'وضع العرض';

  @override
  String get themeSystem => 'تلقائي';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get appColor => 'لون التطبيق';

  @override
  String get appColorHint =>
      'اختاري لوناً بالسحب فوق المربع والشريط، أو اضغطي على لون جاهز.';

  @override
  String get resetColor => 'اللون الأصلي';

  @override
  String get shopLogo => 'شعار المتجر';

  @override
  String get shopLogoHint => 'يظهر في الفواتير وفي المتجر الإلكتروني.';

  @override
  String get changeLogo => 'تغيير الشعار';

  @override
  String get removeLogo => 'إزالة الشعار';

  @override
  String get shopIdentity => 'هوية المتجر';

  @override
  String productImageFailed(String details) {
    return 'تم حفظ المنتج لكن تعذّر رفع الصورة: $details';
  }

  @override
  String get docTypeInvoice => 'الفواتير';

  @override
  String get docTypeQuote => 'عروض الأسعار';

  @override
  String get docTypeDelivery => 'سندات التسليم';

  @override
  String get docTypeCredit => 'الإشعارات الدائنة';

  @override
  String get newQuote => 'عرض سعر جديد';

  @override
  String get newDeliveryNote => 'سند تسليم جديد';

  @override
  String get quoteTitle => 'عرض سعر';

  @override
  String get deliveryTitle => 'سند تسليم';

  @override
  String get creditTitle => 'إشعار دائن';

  @override
  String get ticketTitle => 'تذكرة';

  @override
  String get invoiceTitle => 'فاتورة';

  @override
  String get validUntil => 'صالح حتى';

  @override
  String get statusDraft => 'مسودة';

  @override
  String get statusSent => 'مرسل';

  @override
  String get statusAccepted => 'مقبول';

  @override
  String get statusRefused => 'مرفوض';

  @override
  String get statusExpired => 'منتهي';

  @override
  String get statusValidated => 'مؤكد';

  @override
  String get statusDelivered => 'مُسلَّم';

  @override
  String get statusInvoiced => 'مفوتر';

  @override
  String get statusIssued => 'صادرة';

  @override
  String get statusPartiallyPaid => 'مدفوعة جزئياً';

  @override
  String get statusPaid => 'مدفوعة';

  @override
  String get statusCancelled => 'ملغاة';

  @override
  String get actionSend => 'تعليم كمرسل';

  @override
  String get actionAccept => 'قبلته الزبونة';

  @override
  String get actionRefuse => 'رفضته الزبونة';

  @override
  String get actionValidate => 'تأكيد (إخراج من المخزون)';

  @override
  String get actionDeliver => 'تعليم كمُسلَّم';

  @override
  String get convertToDelivery => 'تحويل إلى سند تسليم';

  @override
  String get convertToInvoice => 'تحويل إلى فاتورة';

  @override
  String get invoiceSelected => 'فوترة المحدد';

  @override
  String get selectDeliveryNotes =>
      'اضغط مطولاً لتجميع عدة سندات تسليم في فاتورة واحدة';

  @override
  String get cancelDocument => 'إلغاء الوثيقة';

  @override
  String get cancelReason => 'سبب الإلغاء';

  @override
  String get createCreditNote => 'إنشاء إشعار دائن';

  @override
  String get creditNoteReturnStock => 'إرجاع المنتجات إلى المخزون';

  @override
  String get creditNoteHint =>
      'حدّد الكميات المراد ردّها. يُخصم المبلغ أولاً من المتبقي ثم يُسترجع أو يُسجَّل رصيداً للزبونة.';

  @override
  String get refundMode => 'طريقة الاسترجاع';

  @override
  String get refundAmount => 'المبلغ المسترجع';

  @override
  String alreadyCredited(String qty) {
    return 'سبق ردّه: $qty';
  }

  @override
  String get documentCreated => 'تم إنشاء الوثيقة';

  @override
  String get documentUpdated => 'تم تحديث الوثيقة';

  @override
  String get linesRequired => 'أضف منتجاً واحداً على الأقل';

  @override
  String get onlineOnly => 'هذه العملية تتطلب اتصالاً بالإنترنت';

  @override
  String get linkedDocuments => 'الوثائق المرتبطة';

  @override
  String get unitPriceLabel => 'سعر الوحدة';

  @override
  String get quantityLabel => 'الكمية';

  @override
  String get serverError_devis_expire => 'انتهت صلاحية عرض السعر';

  @override
  String get serverError_deja_converti => 'سبق تحويل هذه الوثيقة';

  @override
  String get serverError_bl_non_valide => 'أكّد سند التسليم قبل فوترته';

  @override
  String get serverError_transition_invalide => 'تغيير الحالة هذا غير مسموح';

  @override
  String get serverError_annulation_impossible =>
      'لا يمكن الإلغاء: استخدم إشعاراً دائناً لفاتورة محصّلة';

  @override
  String get serverError_quantite_avoir_excessive => 'الكمية أكبر من المفوترة';

  @override
  String get serverError_avoir_excessif => 'مجموع الإشعارات يتجاوز الفاتورة';

  @override
  String get serverError_remboursement_excessif =>
      'الاسترجاع يتجاوز المبلغ المستحق';

  @override
  String get serverError_document_non_modifiable => 'لا يمكن تعديل إلا المسودة';

  @override
  String get serverError_clients_differents =>
      'يجب أن تخص الوثائق المجمّعة الزبونة نفسها';

  @override
  String get serverError_motif_requis => 'السبب إلزامي';

  @override
  String get serverError_destinataire_introuvable => 'المتجر المستلم غير موجود';

  @override
  String get serverError_transfert_deja_traite =>
      'تمت معالجة هذا التحويل مسبقاً';

  @override
  String get serverError_correspondance_requise =>
      'اربط كل منتج مستلم بمنتج في متجرك';

  @override
  String get serverError_trop_de_requetes => 'طلبات كثيرة، حاول لاحقاً';

  @override
  String get dueDate => 'تاريخ الاستحقاق';

  @override
  String get chooseCustomer => 'اختر زبونة (اختياري)';

  @override
  String get menuTransfers => 'تحويلات المخزون';

  @override
  String get transfersReceived => 'الواردة';

  @override
  String get transfersSent => 'الصادرة';

  @override
  String get newTransfer => 'تحويل جديد';

  @override
  String get sendTransfer => 'إرسال التحويل';

  @override
  String get recipientHint => 'رمز المتجر أو هاتف المستلمة';

  @override
  String get transferHint =>
      'يخرج المخزون من متجرك فوراً. تقبل المستلمة (فيدخل مخزونها) أو ترفض (فيعود إليك).';

  @override
  String get transferPrice => 'سعر التحويل';

  @override
  String get transferPending => 'قيد الانتظار';

  @override
  String get transferCancelled => 'ملغى';

  @override
  String get transferFrom => 'من';

  @override
  String get transferTo => 'إلى';

  @override
  String get mapToProduct => 'ربط بمنتج';

  @override
  String get createProduct => 'إنشاء المنتج';

  @override
  String get salePriceLabel => 'سعر البيع';

  @override
  String get acceptTransfer => 'قبول';

  @override
  String get refuseTransfer => 'رفض التحويل';

  @override
  String get cancelTransfer => 'إلغاء التحويل';

  @override
  String get transferSent => 'تم إرسال التحويل';

  @override
  String get transferAnswered => 'تم تسجيل الرد';

  @override
  String get transferInvalid => 'حدّد المستلمة ومنتجاً واحداً على الأقل';

  @override
  String get transferExceedsStock =>
      'كمية تتجاوز المخزون المعروض. هل تريد الإرسال؟';

  @override
  String get menuReports => 'التقارير';

  @override
  String get menuExpenses => 'المصاريف';

  @override
  String get periodToday => 'اليوم';

  @override
  String get periodWeek => '7 أيام';

  @override
  String get periodMonth => 'هذا الشهر';

  @override
  String get periodCustom => 'فترة مخصصة';

  @override
  String get grossMargin => 'الهامش الإجمالي';

  @override
  String get expensesTotal => 'المصاريف';

  @override
  String get netResult => 'النتيجة';

  @override
  String get cashCollected => 'المحصّل';

  @override
  String get stockValue => 'قيمة المخزون';

  @override
  String get supplierDebts => 'ديون الموردين';

  @override
  String get reportByDay => 'حسب اليوم';

  @override
  String get reportByProduct => 'حسب المنتج';

  @override
  String get reportByCategory => 'حسب الفئة';

  @override
  String get reportBySeller => 'حسب البائعة';

  @override
  String get reportByPayment => 'حسب طريقة الدفع';

  @override
  String get reportByChannel => 'حسب القناة';

  @override
  String get reportBest => 'أفضل المنتجات';

  @override
  String get reportDormant => 'منتجات راكدة';

  @override
  String get reportStockValue => 'قيمة المخزون';

  @override
  String get reportUnpaid => 'المستحقات والديون';

  @override
  String get exportCsv => 'تصدير CSV';

  @override
  String get exportPdf => 'مشاركة PDF';

  @override
  String get colSales => 'المبيعات';

  @override
  String get colMargin => 'الهامش';

  @override
  String get colQuantity => 'الكمية';

  @override
  String get colLastSale => 'آخر بيع';

  @override
  String get colValue => 'القيمة';

  @override
  String get customersOwing => 'الزبونات المدينات';

  @override
  String get suppliersOwed => 'الموردون المستحقون';

  @override
  String oldestDue(String date) {
    return 'أقدم استحقاق: $date';
  }

  @override
  String get channelCashier => 'الصندوق';

  @override
  String get channelWeb => 'الموقع';

  @override
  String get channelWhatsapp => 'واتساب';

  @override
  String get channelInstagram => 'إنستغرام';

  @override
  String get channelFacebook => 'فيسبوك';

  @override
  String get channelPhone => 'الهاتف';

  @override
  String get channelOther => 'أخرى';

  @override
  String get newExpense => 'مصروف جديد';

  @override
  String get expenseCategory => 'الفئة';

  @override
  String get expenseReason => 'السبب';

  @override
  String get expenseSaved => 'تم تسجيل المصروف';

  @override
  String get expenseQueued => 'تم تسجيل المصروف وسيُرسل عند عودة الاتصال';

  @override
  String get expensePending => 'بانتظار الإرسال';

  @override
  String get stockDiscrepancies => 'فروقات المخزون للتأكيد';

  @override
  String get validateDiscrepancy => 'تأكيد الفرق';

  @override
  String get discrepancyHint =>
      'مبيعات تمت مزامنتها والمخزون غير كافٍ: أكّد لإعادة المخزون إلى الصفر.';

  @override
  String get menuSite => 'المتجر الإلكتروني';

  @override
  String get siteGeneral => 'عام والنطاق';

  @override
  String get siteAppearance => 'الهوية البصرية والقالب';

  @override
  String get siteBanners => 'اللافتات';

  @override
  String get siteSections => 'أقسام الصفحة الرئيسية';

  @override
  String get sitePages => 'الصفحات (من نحن، التوصيل…)';

  @override
  String get siteSales => 'إعدادات البيع';

  @override
  String get siteCatalog => 'الكتالوج على الإنترنت';

  @override
  String get sitePublished => 'الموقع منشور (ظاهر للزبونات)';

  @override
  String get siteUrl => 'عنوان الموقع';

  @override
  String get domainNotConfigured => 'غير مهيأ';

  @override
  String get domainPending => 'قيد الانتظار';

  @override
  String get domainVerified => 'تم التحقق';

  @override
  String get domainError => 'خطأ';

  @override
  String get verifyDomain => 'التحقق من النطاق';

  @override
  String get dnsInstructions => 'أضف سجل DNS هذا لدى مزوّد النطاق ثم تحقق:';

  @override
  String get domainInvalid => 'اسم نطاق غير صالح (مثال: maboutique.com)';

  @override
  String get socialLinks => 'الشبكات الاجتماعية (الروابط)';

  @override
  String get openingHours => 'أوقات العمل (مثال: الإثنين-السبت: 9-19)';

  @override
  String get primaryColor => 'اللون الأساسي';

  @override
  String get secondaryColor => 'اللون الثانوي';

  @override
  String get backgroundColor => 'لون الخلفية';

  @override
  String get textColor => 'لون النص';

  @override
  String get fontLabel => 'الخط';

  @override
  String get fontSystem => 'عادي';

  @override
  String get fontSerif => 'كلاسيكي';

  @override
  String get fontNaskh => 'نسخ';

  @override
  String get fontRounded => 'مستدير';

  @override
  String get radiusLabel => 'شكل الأزرار والزوايا';

  @override
  String get radiusNone => 'حاد';

  @override
  String get radiusSmall => 'صغير';

  @override
  String get radiusMedium => 'متوسط';

  @override
  String get radiusLarge => 'كبير';

  @override
  String get radiusPill => 'كبسولة';

  @override
  String get cardStyleLabel => 'نمط بطاقات المنتجات';

  @override
  String get cardBorder => 'إطار';

  @override
  String get cardShadow => 'ظل';

  @override
  String get cardMinimal => 'بسيط';

  @override
  String get headerLabel => 'الترويسة';

  @override
  String get headerCenter => 'وسط';

  @override
  String get headerLeft => 'جانبية';

  @override
  String get gridLabel => 'أعمدة المنتجات';

  @override
  String get themeLabel => 'القالب';

  @override
  String get previewLabel => 'معاينة';

  @override
  String get saveDraft => 'حفظ المسودة';

  @override
  String get publishChanges => 'نشر';

  @override
  String get draftSaved => 'تم حفظ المسودة';

  @override
  String get draftPublished => 'تم نشر التعديلات';

  @override
  String get unpublishedDraft => 'مسودة غير منشورة';

  @override
  String get faviconLabel => 'أيقونة الموقع';

  @override
  String get addBanner => 'إضافة لافتة';

  @override
  String get bannerLink => 'رابط (اختياري)';

  @override
  String get bannerTitle => 'عنوان اللافتة';

  @override
  String get sectionBanner => 'اللافتة';

  @override
  String get sectionFeaturedCategories => 'الفئات المميزة';

  @override
  String get sectionNew => 'الجديد';

  @override
  String get sectionPromotions => 'العروض';

  @override
  String get sectionPopular => 'الأكثر مبيعاً';

  @override
  String get sectionAbout => 'من نحن';

  @override
  String get sectionContact => 'اتصل بنا';

  @override
  String get sectionTitleFr => 'العنوان (بالفرنسية)';

  @override
  String get sectionTitleAr => 'العنوان (بالعربية)';

  @override
  String get contentFr => 'المحتوى (بالفرنسية)';

  @override
  String get contentAr => 'المحتوى (بالعربية)';

  @override
  String get addSection => 'إضافة قسم';

  @override
  String get addPage => 'صفحة جديدة';

  @override
  String get pageSlug => 'عنوان الصفحة (أحرف صغيرة وأرقام وشرطات)';

  @override
  String get pageSlugInvalid => 'عنوان غير صالح (مثال: about)';

  @override
  String get deliveryEnabled => 'التوصيل للمنزل';

  @override
  String get pickupEnabled => 'الاستلام من المتجر';

  @override
  String get cashOnDelivery => 'الدفع عند الاستلام';

  @override
  String get mobileMoneyEnabled => 'الدفع بالمحفظة الإلكترونية (مع إثبات)';

  @override
  String get paymentInstructionsAr => 'تعليمات الدفع (بالعربية)';

  @override
  String get paymentInstructionsFr => 'تعليمات الدفع (بالفرنسية)';

  @override
  String get minimumOrder => 'الحد الأدنى للطلب';

  @override
  String get showStockOnline => 'إظهار «متوفر» في الموقع';

  @override
  String get hideSoldOut => 'إخفاء المنتجات المنتهية';

  @override
  String get confirmationMessageFr => 'رسالة التأكيد (بالفرنسية)';

  @override
  String get confirmationMessageAr => 'رسالة التأكيد (بالعربية)';

  @override
  String get deliveryZones => 'مناطق التوصيل';

  @override
  String get addZone => 'إضافة منطقة';

  @override
  String get zoneFee => 'رسوم التوصيل';

  @override
  String get categoriesOrder => 'ترتيب الفئات (سحب وإفلات)';

  @override
  String get productsOnline => 'المنتجات المعروضة في الموقع';

  @override
  String get pinnedFirst => 'مثبّت في الأعلى';

  @override
  String get pinnedOrderHint =>
      'تظهر المنتجات المثبّتة في الأعلى بالترتيب أدناه.';

  @override
  String get printerSettings => 'طابعة حرارية بلوتوث';

  @override
  String get printerNotSelected => 'لم يتم اختيار طابعة';

  @override
  String get printerForget => 'إلغاء الطابعة';

  @override
  String get paperWidth => 'عرض الورق';

  @override
  String get printTest => 'طباعة تذكرة تجريبية';

  @override
  String get printerPaired => 'الطابعات المقترنة';

  @override
  String get printerPairHint =>
      'اقرن الطابعة أولاً من إعدادات البلوتوث في الهاتف ثم اخترها هنا.';

  @override
  String get printerNoneFound => 'لا توجد طابعة مقترنة';

  @override
  String get printerUnsupported => 'الطباعة عبر البلوتوث متاحة على أندرويد فقط';

  @override
  String get printerBluetoothOff => 'فعّل البلوتوث في الهاتف';

  @override
  String get printerPermission =>
      'اسمح للتطبيق باستخدام البلوتوث من إعدادات الهاتف';

  @override
  String get printerConnectionFailed =>
      'تعذّر الاتصال بالطابعة: تأكد من تشغيلها وقربها';

  @override
  String get printerWriteFailed => 'توقفت الطباعة';

  @override
  String get printSent => 'تم إرسال الطباعة';

  @override
  String get printThermal => 'طباعة (تذكرة بلوتوث)';
}
