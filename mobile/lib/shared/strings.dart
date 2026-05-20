/// Pulse string catalog — single source of truth for all user-visible copy.
///
/// Usage: PulseStrings.get('key', locale)
/// Locale values: 'en' (default) or 'ur'
/// Falls back to English when a Urdu key is absent.
class PulseStrings {
  PulseStrings._();

  static const String en = 'en';
  static const String ur = 'ur';

  static const _catalog = <String, Map<String, String>>{
    // ── Auth ──────────────────────────────────────────────────────────────
    'auth.tagline': {
      'en': 'Urban Crisis Response · Islamabad operations',
      'ur': 'شہری بحران ردعمل · اسلام آباد آپریشنز',
    },
    'auth.demo_hint': {
      'en': 'Demo OTP is 654321 · phone is hashed before processing',
      'ur': 'ڈیمو OTP 654321 ہے · فون نمبر محفوظ طریقے سے پروسیس ہوتا ہے',
    },
    'auth.build_id': {
      'en': 'Antigravity build a215.7 · 2026-05-15',
      'ur': 'Antigravity بلڈ a215.7 · 2026-05-15',
    },

    // ── Citizen home ──────────────────────────────────────────────────────
    'citizen.home.title': {
      'en': 'Live incidents',
      'ur': 'براہ راست واقعات',
    },
    'citizen.home.empty': {
      'en': 'No active incidents in your area.',
      'ur': 'آپ کے علاقے میں کوئی فعال واقعہ نہیں۔',
    },
    'citizen.home.error_title': {
      'en': 'NETWORK ERROR',
      'ur': 'نیٹ ورک خرابی',
    },
    'citizen.home.retry': {
      'en': 'RETRY',
      'ur': 'دوبارہ کوشش',
    },

    // ── Citizen alerts ─────────────────────────────────────────────────────
    'citizen.alerts.title': {
      'en': 'Alerts',
      'ur': 'اطلاعات',
    },
    'citizen.alerts.empty': {
      'en': 'No alerts yet — run a scenario from Command.',
      'ur': 'ابھی تک کوئی اطلاع نہیں — کمانڈ سے منظرنامہ چلائیں۔',
    },
    'citizen.alerts.helpline': {
      'en': 'helpline 1122',
      'ur': 'ہیلپ لائن 1122',
    },
    'citizen.alerts.retraction.correction_label': {
      'en': 'CORRECTION',
      'ur': 'تصحیح',
    },
    'citizen.alerts.retraction.correction_en': {
      'en': 'The original classification has been retracted. Updated agencies are responding. Apologies for the alarm.',
      'ur': 'پہلی درجہ بندی واپس لی گئی ہے۔ متعلقہ ادارے جواب دے رہے ہیں۔ الارم کے لیے معذرت۔',
    },
    'citizen.alerts.retraction.correction_ur': {
      'en': 'The original alert has been retracted.',
      'ur': 'پہلی اطلاع واپس لی جا چکی ہے۔ متعلقہ ادارے کام کر رہے ہیں۔',
    },
    'citizen.alerts.approval_required': {
      'en': 'AWAITING APPROVAL',
      'ur': 'منظوری زیر التواء',
    },

    // ── Citizen report ─────────────────────────────────────────────────────
    'citizen.report.title': {
      'en': 'Report an incident',
      'ur': 'واقعہ رپورٹ کریں',
    },
    'citizen.report.subtitle': {
      'en': 'Your report routes to Pulse command in real time',
      'ur': 'آپ کی رپورٹ فوری طور پر Pulse کمانڈ کو جاتی ہے',
    },
    'citizen.report.privacy_hash': {
      'en': 'Your phone number is hashed before processing',
      'ur': 'آپ کا فون نمبر پروسیسنگ سے پہلے ہیش کیا جاتا ہے',
    },
    'citizen.report.privacy_trust': {
      'en': 'False reports degrade your trust score',
      'ur': 'غلط رپورٹیں آپ کا اعتماد سکور کم کرتی ہیں',
    },
    'citizen.report.submit': {
      'en': 'Submit report',
      'ur': 'رپورٹ جمع کریں',
    },
    'citizen.report.gps_label': {
      'en': 'CAPTURE GPS',
      'ur': 'جی پی ایس حاصل کریں',
    },
    'citizen.report.photo_label': {
      'en': 'ATTACH PHOTO',
      'ur': 'تصویر منسلک کریں',
    },
    'citizen.report.gps_denied': {
      'en': 'Location permission denied — please drop a pin manually.',
      'ur': 'مقام کی اجازت نہیں ملی — براہ کرم دستی طور پر پن ڈالیں۔',
    },
    'citizen.report.gps_error': {
      'en': 'Location error',
      'ur': 'مقام کی خرابی',
    },
    'citizen.report.gps_required': {
      'en': 'Please capture GPS coordinates first.',
      'ur': 'پہلے جی پی ایس کوآرڈینیٹ حاصل کریں۔',
    },
    'citizen.report.offline_queued': {
      'en': 'Offline — queued for retry.',
      'ur': 'آف لائن — دوبارہ کوشش کے لیے قطار میں ہے۔',
    },
    'citizen.report.accepted': {
      'en': 'ACCEPTED',
      'ur': 'قبول',
    },

    // ── Citizen verify ─────────────────────────────────────────────────────
    'citizen.verify.title': {
      'en': 'Verify nearby',
      'ur': 'قریبی تصدیق',
    },
    'citizen.verify.subtitle': {
      'en': 'Confirm or dispute incidents near you to improve accuracy',
      'ur': 'درستگی بہتر کرنے کے لیے قریبی واقعات کی تصدیق یا اختلاف کریں',
    },
    'citizen.verify.empty': {
      'en': 'No incidents nearby to verify.',
      'ur': 'قریب تصدیق کے لیے کوئی واقعہ نہیں۔',
    },
    'citizen.verify.confirm': {
      'en': 'CONFIRM — I can see this',
      'ur': 'تصدیق — میں یہ دیکھ سکتا ہوں',
    },
    'citizen.verify.dispute': {
      'en': 'DISPUTE — This looks wrong',
      'ur': 'اختلاف — یہ غلط لگتا ہے',
    },
    'citizen.verify.submitted': {
      'en': 'Verification submitted',
      'ur': 'تصدیق جمع کر دی گئی',
    },

    // ── Responder queue ────────────────────────────────────────────────────
    'responder.queue.title': {
      'en': 'Dispatch queue',
      'ur': 'ڈسپیچ قطار',
    },
    'responder.queue.empty': {
      'en': 'No active dispatches for this asset.',
      'ur': 'اس اثاثے کے لیے کوئی فعال ڈسپیچ نہیں۔',
    },
    'responder.queue.asset_hint': {
      'en': 'asset id (e.g. rescue-3)',
      'ur': 'اثاثہ آئی ڈی (مثلاً rescue-3)',
    },
    'responder.queue.destination': {
      'en': 'destination',
      'ur': 'منزل',
    },
    'responder.queue.eta': {
      'en': 'eta',
      'ur': 'متوقع وقت',
    },
    'responder.queue.instructions': {
      'en': 'INSTRUCTIONS',
      'ur': 'ہدایات',
    },

    // ── Responder status ───────────────────────────────────────────────────
    'responder.status.title': {
      'en': 'Asset status',
      'ur': 'اثاثہ کی حالت',
    },
    'responder.status.subtitle': {
      'en': 'Report your current availability to command',
      'ur': 'اپنی موجودہ دستیابی کمانڈ کو رپورٹ کریں',
    },
    'responder.status.on_duty': {
      'en': 'ON DUTY',
      'ur': 'ڈیوٹی پر',
    },
    'responder.status.standby': {
      'en': 'STANDBY',
      'ur': 'اسٹینڈ بائی',
    },
    'responder.status.off_duty': {
      'en': 'OFF DUTY',
      'ur': 'ڈیوٹی سے باہر',
    },
    'responder.status.submit': {
      'en': 'UPDATE STATUS',
      'ur': 'حالت اپ ڈیٹ کریں',
    },

    // ── Command dashboard ──────────────────────────────────────────────────
    'command.dashboard.title': {
      'en': 'Islamabad operations',
      'ur': 'اسلام آباد آپریشنز',
    },
    'command.trace.title': {
      'en': 'Antigravity trace',
      'ur': 'Antigravity ٹریس',
    },
    'command.trace.empty': {
      'en': 'Awaiting agent events.\nTap RUN ▾ in the top bar to fire a scenario.',
      'ur': 'ایجنٹ ایونٹس کا انتظار ہے۔\nمنظرنامہ چلانے کے لیے اوپر RUN ▾ دبائیں۔',
    },
    'command.trace.disconnected': {
      'en': 'DISCONNECTED',
      'ur': 'منقطع',
    },
    'command.trace.reconnecting': {
      'en': 'RECONNECTING…',
      'ur': 'دوبارہ جڑ رہا ہے…',
    },
    'command.dashboard.empty': {
      'en': 'No incidents — run a scenario from above.',
      'ur': 'کوئی واقعہ نہیں — اوپر سے منظرنامہ چلائیں۔',
    },

    // ── Degraded mode ──────────────────────────────────────────────────────
    'degraded.banner.title': {
      'en': 'DEGRADED',
      'ur': 'کم معیار',
    },
    'degraded.banner.stale': {
      'en': 'stale',
      'ur': 'پرانا',
    },
    'degraded.banner.minutes': {
      'en': 'min',
      'ur': 'منٹ',
    },
    'degraded.banner.sensor_silent': {
      'en': 'SENSOR SILENT',
      'ur': 'سینسر خاموش',
    },

    // ── Audit chain ────────────────────────────────────────────────────────
    'audit.title': {
      'en': 'AUDIT CHAIN',
      'ur': 'آڈٹ سلسلہ',
    },
    'audit.original': {
      'en': 'original',
      'ur': 'اصل',
    },
    'audit.revised': {
      'en': 'revised',
      'ur': 'نظرثانی شدہ',
    },
    'audit.recipients': {
      'en': 'recipients notified',
      'ur': 'وصول کنندگان مطلع',
    },
    'audit.responders_recalled': {
      'en': 'responders recalled',
      'ur': 'جوابدہ واپس بلائے',
    },
    'audit.no_flips': {
      'en': 'No classification changes recorded.',
      'ur': 'کوئی درجہ بندی تبدیلی ریکارڈ نہیں۔',
    },

    // ── Forecast bands ─────────────────────────────────────────────────────
    'forecast.population': {
      'en': 'pop affected',
      'ur': 'متاثرہ آبادی',
    },
    'forecast.p10': {
      'en': 'P10',
      'ur': 'P10',
    },
    'forecast.p50': {
      'en': 'P50',
      'ur': 'P50',
    },
    'forecast.p90': {
      'en': 'P90',
      'ur': 'P90',
    },

    // ── Common ─────────────────────────────────────────────────────────────
    'common.retry': {
      'en': 'RETRY',
      'ur': 'دوبارہ کوشش',
    },
    'common.load': {
      'en': 'LOAD',
      'ur': 'لوڈ',
    },
    'common.network_error': {
      'en': 'NETWORK ERROR',
      'ur': 'نیٹ ورک خرابی',
    },
    'common.live': {
      'en': 'LIVE',
      'ur': 'براہ راست',
    },
    'common.active': {
      'en': 'ACTIVE',
      'ur': 'فعال',
    },
    'common.retracted': {
      'en': 'RETRACTED',
      'ur': 'واپس لی گئی',
    },
  };

  /// Returns the string for [key] in [locale], falling back to English.
  static String get(String key, [String locale = en]) {
    final entry = _catalog[key];
    if (entry == null) return key;
    return entry[locale] ?? entry[en] ?? key;
  }
}
