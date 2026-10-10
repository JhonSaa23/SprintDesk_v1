import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common.dart';

Widget getConnectionPageTitle(BuildContext context, bool isWeb) {
  final textColor = Theme.of(context).textTheme.titleLarge?.color;
  return Row(
    children: [
      Expanded(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: MyTheme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.desktop_windows_outlined,
                size: 16,
                color: MyTheme.accent,
              ),
            ),
            const SizedBox(width: 8),
            AutoSizeText(
              translate('Control Remote Desktop'),
              maxLines: 1,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: textColor,
              ),
            ).marginOnly(right: 6),
            Tooltip(
              waitDuration: const Duration(milliseconds: 300),
              message: translate(isWeb ? "web_id_input_tip" : "id_input_tip"),
              child: Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: textColor?.withOpacity(0.45),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
