import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/desktop_home_page.dart';
import 'package:flutter_hbb/common/widgets/login.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/desktop/widgets/header_connect_bar.dart';
import 'package:flutter_hbb/desktop/widgets/tabbar_widget.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:flutter_hbb/models/plan_model.dart';
import 'package:flutter_hbb/desktop/widgets/plans_dialog.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';
// import 'package:flutter/services.dart';

import '../../common/shared_state.dart';

class DesktopTabPage extends StatefulWidget {
  const DesktopTabPage({Key? key}) : super(key: key);

  @override
  State<DesktopTabPage> createState() => _DesktopTabPageState();

  static void onAddSetting(
      {SettingsTabKey initialPage = SettingsTabKey.general}) {
    try {
      DesktopTabController tabController = Get.find<DesktopTabController>();
      tabController.add(TabInfo(
          key: kTabLabelSettingPage,
          label: kTabLabelSettingPage,
          selectedIcon: Icons.build_sharp,
          unselectedIcon: Icons.build_outlined,
          page: DesktopSettingPage(
            key: const ValueKey(kTabLabelSettingPage),
            initialTabkey: initialPage,
          )));
    } catch (e) {
      debugPrintStack(label: '$e');
    }
  }
}

class _DesktopTabPageState extends State<DesktopTabPage> {
  final tabController = DesktopTabController(tabType: DesktopTabType.main);

  _DesktopTabPageState() {
    RemoteCountState.init();
    Get.put<DesktopTabController>(tabController);
    tabController.add(TabInfo(
        key: kTabLabelHomePage,
        label: kTabLabelHomePage,
        selectedIcon: Icons.home_sharp,
        unselectedIcon: Icons.home_outlined,
        closable: false,
        page: DesktopHomePage(
          key: const ValueKey(kTabLabelHomePage),
        )));
    if (bind.isIncomingOnly()) {
      tabController.onSelected = (key) {
        if (key == kTabLabelHomePage) {
          windowManager.setSize(getIncomingOnlyHomeSize());
          setResizable(false);
        } else {
          windowManager.setSize(getIncomingOnlySettingsSize());
          setResizable(true);
        }
      };
    }
  }

  @override
  void initState() {
    super.initState();
    // HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  /*
  bool _handleKeyEvent(KeyEvent event) {
    if (!mouseIn && event is KeyDownEvent) {
      print('key down: ${event.logicalKey}');
      shouldBeBlocked(_block, canBeBlocked);
    }
    return false; // allow it to propagate
  }
  */

  @override
  void dispose() {
    // HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    Get.delete<DesktopTabController>();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabWidget = Container(
        child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            body: DesktopTab(
              controller: tabController,
              leading:
                  bind.isIncomingOnly() ? null : const HeaderConnectBar(),
              tail: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const UpgradePlanHeaderChip(),
                    Obx(() {
                      final user = gFFI.userModel;
                      if (user.userName.value.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SizedBox(
                            height: 34,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MyTheme.accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(17)),
                              ),
                              onPressed: () => loginDialog(),
                              icon: const Icon(
                                  Icons.account_circle_outlined,
                                  size: 18),
                              label: Text(translate('Login'),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            DesktopTabPage.onAddSetting(
                                initialPage: SettingsTabKey.account);
                            Future.delayed(const Duration(milliseconds: 100),
                                () {
                              DesktopSettingPage.switch2page(
                                  SettingsTabKey.account);
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.account_circle_outlined,
                                    size: 22, color: MyTheme.accent),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 180),
                                  child: Text(
                                    user.userName.value,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    Offstage(
                      offstage:
                          bind.isIncomingOnly() || bind.isDisableSettings(),
                      child: ActionIcon(
                        message: 'Settings',
                        icon: IconFont.menu,
                        onTap: DesktopTabPage.onAddSetting,
                        isClose: false,
                      ),
                    ),
                  ],
                ),
              ),
            )));
    return isMacOS || kUseCompatibleUiMode
        ? tabWidget
        : Obx(
            () => DragToResizeArea(
              resizeEdgeSize: stateGlobal.resizeEdgeSize.value,
              enableResizeEdges: windowManagerEnableResizeEdges,
              child: tabWidget,
            ),
          );
  }
}

class UpgradePlanHeaderChip extends StatelessWidget {
  const UpgradePlanHeaderChip({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final plan = PlanModel.instance;
      final isPaid = plan.isPaidPlan;
      final isTeam = plan.planType.value == PlanType.proTeam;
      final label = isPaid
          ? (isTeam ? "Plan Pro Equipo" : "Plan Individual")
          : "Actualizar planes";
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () => showPlansDialog(context),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isPaid
                  ? const Color(0xFF10B981).withOpacity(0.16)
                  : const Color(0xFFF59E0B).withOpacity(0.18),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: isPaid
                    ? const Color(0xFF10B981).withOpacity(0.4)
                    : const Color(0xFFF59E0B).withOpacity(0.45),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPaid ? Icons.verified_user_rounded : Icons.star_rounded,
                  size: 16,
                  color: isPaid
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isPaid
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
