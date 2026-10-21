import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:get/get.dart';

enum PlanType {
  free,
  individual,
  proTeam,
}

class PlanModel {
  PlanModel._();
  static final instance = PlanModel._();

  static const String kOptionPlanLicense = 'spl_plan_license_key';
  static const String kOptionPlanType = 'spl_plan_type';

  static const double individualPriceMonthly = 11.90;
  static const double proTeamPriceMonthly = 45.90;
  static const int freeSessionLimitMinutes = 5;

  final Rx<PlanType> planType = PlanType.free.obs;
  final RxString licenseKey = ''.obs;

  // ---- Free trial (7 days) ----
  static const String kOptionTrialStarts = 'spl_trial_starts';
  static const int trialDays = 7;
  static const List<String> trialKeys = [
    'SDTR-7K3M-9P2X-L4QW-H815',
    'SDTR-2B8V-5N6C-T9RZ-J472',
    'SDTR-4X7Q-1M3L-W8PK-D936',
    'SDTR-9H5T-6Z2V-B3NM-R584',
    'SDTR-5C2N-8W4K-M7ZP-Q163',
    'SDTR-3J9R-2V6T-X5LB-N748',
    'SDTR-8D4F-7H1Q-C9MK-W256',
    'SDTR-6L1P-3Y8N-V2XG-T591',
    'SDTR-1Z7W-9B5M-K4RD-F837',
    'SDTR-9N3X-4T6Q-H8LC-P102',
    'SDTR-2F8K-6R1V-D3WM-Y469',
    'SDTR-7Q5C-1L9Z-B6NT-K825',
    'SDTR-4V2M-8X7P-J5HR-C713',
    'SDTR-3T6B-5D9W-N1QL-Z984',
    'SDTR-8H1G-2K4X-R7VF-M356',
    'SDTR-5W9L-7C3Q-T2PB-D641',
    'SDTR-6Y4N-1M8Z-F5KX-H279',
    'SDTR-1R7D-3V5B-L9CW-Q518',
    'SDTR-9K2T-6P4H-X8NM-J837',
    'SDTR-4B8Q-9F1L-W3ZR-V462',
  ];

  /// Trial ends at the END of the 7th day after the registration day.
  static DateTime _expiryFor(int startMs) {
    final d = DateTime.fromMillisecondsSinceEpoch(startMs);
    return DateTime(d.year, d.month, d.day + trialDays, 23, 59, 59);
  }

  Timer? _trialTimer;

  void _startTrialWatcher() {
    _trialTimer ??= Timer.periodic(const Duration(minutes: 1), (_) {
      final exp = trialExpiresAt;
      if (isTrial.value && exp != null && DateTime.now().isAfter(exp)) {
        init();
        broadcastPlanUpdate();
      }
    });
  }

  /// e.g. "28/10/2026"
  String get trialExpiryLabel {
    final e = trialExpiresAt;
    if (e == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(e.day)}/${two(e.month)}/${e.year}';
  }

  /// "Te quedan 3 días" / "Último día"
  String get trialRemainingText {
    final d = trialDaysLeft;
    if (d <= 0) return 'Último día';
    return d == 1 ? 'Te queda 1 día' : 'Te quedan $d días';
  }

  /// True while the active license is a trial key.
  final RxBool isTrial = false.obs;
  /// Expiration of the running trial (null when not in trial).
  DateTime? trialExpiresAt;
  /// Human readable reason of the last failed activation.
  String lastActivationError = '';

  static String _norm(String k) => k
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'[-\s_.]'), '');

  static bool isTrialKey(String key) {
    final n = _norm(key);
    return trialKeys.any((k) => _norm(k) == n);
  }

  Map<String, int> _readTrialStarts() {
    final raw = bind.mainGetLocalOption(key: kOptionTrialStarts);
    final map = <String, int>{};
    for (final part in raw.split(';')) {
      final i = part.indexOf('=');
      if (i <= 0) continue;
      final ms = int.tryParse(part.substring(i + 1));
      if (ms != null) map[part.substring(0, i)] = ms;
    }
    return map;
  }

  Future<void> _writeTrialStarts(Map<String, int> m) async {
    await bind.mainSetLocalOption(
        key: kOptionTrialStarts,
        value: m.entries.map((e) => '${e.key}=${e.value}').join(';'));
  }

  /// Calendar days left after today (0 = expires today).
  int get trialDaysLeft {
    final exp = trialExpiresAt;
    if (!isTrial.value || exp == null) return 0;
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final last = DateTime(exp.year, exp.month, exp.day);
    final diff = last.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  // Real product keys for each plan
  static const List<String> individualKeys = [
    'SD11-9F82-K47L-P93Q-M821',
    'SD11-3A8K-B74V-R82M-Z615',
    'SD11-7X9N-C35W-T61P-Y482',
    'SD11-4M2P-Q86V-L91X-K374',
    'SD11-6T2W-N58H-L47C-X193',
    'SD11-8R5K-D31P-V96M-B247',
    'SD11-2L9Q-Z74X-T53F-H861',
    'SD11-5V3M-C82W-K19R-P704',
    'SD11-1N7B-Q46D-Y85L-T352',
    'SD11-9H4X-F27K-M63V-C518',
  ];

  static const List<String> proTeamKeys = [
    'SD45-8K92-XM49-Q7LP-W381',
    'SD45-2B74-VQ19-L5XP-Z623',
    'SD45-6M31-TR85-N42K-H794',
    'SD45-5P98-QW34-Z71M-L826',
    'SD45-3W7P-LK82-N49X-Q165',
    'SD45-7D1R-VT56-B93M-Y248',
    'SD45-4Q8L-ZX37-H62K-F579',
    'SD45-9M2C-PW41-T85N-L336',
    'SD45-1K6V-RB93-X27Q-D802',
    'SD45-5T4H-NF68-W91L-Z417',
  ];

  static PlanType? detectPlanFromKey(String key) {
    final clean = key.trim().toUpperCase();
    if (clean.isEmpty) return null;

    if (individualKeys.contains(clean)) return PlanType.individual;
    if (proTeamKeys.contains(clean)) return PlanType.proTeam;

    final normalized = clean
        .replaceAll('-', '')
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('.', '');

    final normalizedIndKeys = individualKeys
        .map((k) => k
            .replaceAll('-', '')
            .replaceAll(' ', '')
            .replaceAll('_', '')
            .replaceAll('.', ''))
        .toSet();
    final normalizedProKeys = proTeamKeys
        .map((k) => k
            .replaceAll('-', '')
            .replaceAll(' ', '')
            .replaceAll('_', '')
            .replaceAll('.', ''))
        .toSet();

    if (normalizedIndKeys.contains(normalized)) return PlanType.individual;
    if (normalizedProKeys.contains(normalized)) return PlanType.proTeam;

    if (normalized.startsWith('SD11') ||
        normalized.startsWith('IND') ||
        normalized == 'IND' ||
        normalized == 'INDIVIDUAL') {
      return PlanType.individual;
    }

    if (normalized.startsWith('SD45') ||
        normalized.startsWith('PRO') ||
        normalized.startsWith('TEAM') ||
        normalized.startsWith('EQUIPO') ||
        normalized == 'PRO' ||
        normalized == 'EQUIPO' ||
        normalized == 'TEAM') {
      return PlanType.proTeam;
    }

    return null;
  }

  void init() {
    final savedKey = bind.mainGetLocalOption(key: kOptionPlanLicense);
    final savedType = bind.mainGetLocalOption(key: kOptionPlanType);

    isTrial.value = false;
    trialExpiresAt = null;
    if (savedKey.isNotEmpty && isTrialKey(savedKey)) {
      final starts = _readTrialStarts();
      final start = starts[_norm(savedKey)];
      final exp = start == null
          ? null
          : _expiryFor(start);
      if (exp != null && DateTime.now().isBefore(exp)) {
        planType.value = PlanType.individual;
        licenseKey.value = savedKey;
        isTrial.value = true;
        trialExpiresAt = exp;
        _startTrialWatcher();
      } else {
        // Trial finished: back to free. The key stays registered as used.
        planType.value = PlanType.free;
        licenseKey.value = '';
        bind.mainSetLocalOption(key: kOptionPlanLicense, value: '');
        bind.mainSetLocalOption(key: kOptionPlanType, value: 'free');
      }
      return;
    }

    if (savedKey.isNotEmpty) {
      final detected = detectPlanFromKey(savedKey);
      if (detected != null) {
        planType.value = detected;
        licenseKey.value = savedKey;
        return;
      }
    }

    if (savedType == 'individual' || savedType == 'PlanType.individual') {
      planType.value = PlanType.individual;
      licenseKey.value = savedKey;
    } else if (savedType == 'proTeam' || savedType == 'PlanType.proTeam') {
      planType.value = PlanType.proTeam;
      licenseKey.value = savedKey;
    } else {
      planType.value = PlanType.free;
      licenseKey.value = '';
    }
  }

  // Compatibility getter
  RxBool get isPro => (planType.value != PlanType.free).obs;

  bool get isProPlan => planType.value != PlanType.free;
  bool get isPaidPlan => planType.value != PlanType.free;

  int get maxConcurrentSessions {
    switch (planType.value) {
      case PlanType.individual:
        return 3;
      case PlanType.proTeam:
        return 10;
      case PlanType.free:
        return 1;
    }
  }

  int get maxSeats {
    switch (planType.value) {
      case PlanType.proTeam:
        return 5;
      case PlanType.individual:
      case PlanType.free:
        return 1;
    }
  }

  bool get hasTimeLimit => planType.value == PlanType.free;

  String get planName {
    if (isTrial.value) return "Licencia gratuita";
    switch (planType.value) {
      case PlanType.individual:
        return "Plan Individual";
      case PlanType.proTeam:
        return "Plan Pro Equipo";
      case PlanType.free:
        return "Plan Gratuito";
    }
  }

  Future<void> broadcastPlanUpdate() async {
    if (!isDesktop) return;
    try {
      await DesktopMultiWindow.invokeMethod(
          kMainWindowId, kWindowPlanUpdated, '');
    } catch (_) {}

    try {
      final subWindowIds = await DesktopMultiWindow.getAllSubWindowIds();
      for (final id in subWindowIds) {
        try {
          await DesktopMultiWindow.invokeMethod(id, kWindowPlanUpdated, '');
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<bool> activateLicense(String key) async {
    final clean = key.trim().toUpperCase();
    lastActivationError = '';

    if (isTrialKey(clean)) {
      final starts = _readTrialStarts();
      final id = _norm(clean);
      final now = DateTime.now();
      final existing = starts[id];
      if (existing != null && !now.isBefore(_expiryFor(existing))) {
        lastActivationError =
            'La credencial de prueba gratuita ha finalizado. Adquiere un plan para continuar.';
        return false;
      }
      final start = existing ?? now.millisecondsSinceEpoch;
      if (existing == null) {
        starts[id] = start;
        await _writeTrialStarts(starts);
      }
      planType.value = PlanType.individual;
      licenseKey.value = clean;
      isTrial.value = true;
      trialExpiresAt = _expiryFor(start);
      _startTrialWatcher();
      await bind.mainSetLocalOption(key: kOptionPlanLicense, value: clean);
      await bind.mainSetLocalOption(key: kOptionPlanType, value: 'individual');
      await broadcastPlanUpdate();
      return true;
    }

    isTrial.value = false;
    trialExpiresAt = null;
    final detected = detectPlanFromKey(clean);
    if (detected != null) {
      planType.value = detected;
      licenseKey.value = clean;
      final typeString =
          detected == PlanType.individual ? 'individual' : 'proTeam';
      await bind.mainSetLocalOption(key: kOptionPlanLicense, value: clean);
      await bind.mainSetLocalOption(key: kOptionPlanType, value: typeString);
      await broadcastPlanUpdate();
      return true;
    }
    return false;
  }

  Future<void> deactivateLicense() async {
    planType.value = PlanType.free;
    licenseKey.value = '';
    await bind.mainSetLocalOption(key: kOptionPlanLicense, value: '');
    await bind.mainSetLocalOption(key: kOptionPlanType, value: 'free');
    await broadcastPlanUpdate();
  }
}
