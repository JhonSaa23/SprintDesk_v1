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

  // Real product keys for each plan
  static const List<String> individualKeys = [
    'SD11-9F82-K47L-P93Q-M821',
    'SD11-3A8K-B74V-R82M-Z615',
    'SD11-7X9N-C35W-T61P-Y482',
    'SD11-4M2P-Q86V-L91X-K374',
  ];

  static const List<String> proTeamKeys = [
    'SD45-8K92-XM49-Q7LP-W381',
    'SD45-2B74-VQ19-L5XP-Z623',
    'SD45-6M31-TR85-N42K-H794',
    'SD45-5P98-QW34-Z71M-L826',
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
