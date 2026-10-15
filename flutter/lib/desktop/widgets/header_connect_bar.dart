import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/formatter/id_formatter.dart';

class HeaderConnectBar extends StatefulWidget {
  const HeaderConnectBar({Key? key}) : super(key: key);

  @override
  State<HeaderConnectBar> createState() => _HeaderConnectBarState();
}

class _HeaderConnectBarState extends State<HeaderConnectBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _id => _controller.text.replaceAll(' ', '');

  void _connect(
      {bool isFileTransfer = false,
      bool isViewCamera = false,
      bool isTerminal = false,
      bool isTcpTunneling = false}) {
    if (_id.isEmpty) {
      _focus.requestFocus();
      return;
    }
    connect(context, _id,
        isFileTransfer: isFileTransfer,
        isViewCamera: isViewCamera,
        isTerminal: isTerminal,
        isTcpTunneling: isTcpTunneling);
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
    );
    return Container(
      constraints: const BoxConstraints(maxWidth: 420, minWidth: 180),
      height: 42,
      margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        autocorrect: false,
        enableSuggestions: false,
        maxLines: 1,
        inputFormatters: [IDTextInputFormatter()],
        cursorColor: MyTheme.accent,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        onSubmitted: (_) => _connect(),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white.withOpacity(0.06),
          hintText: translate('Enter Remote ID'),
          hintStyle: TextStyle(
              fontSize: 15, color: Colors.white.withOpacity(0.4)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
              borderSide: const BorderSide(color: MyTheme.accent, width: 1.2)),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _connect,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 18,
                      color: _id.isEmpty
                          ? Colors.white.withOpacity(0.35)
                          : MyTheme.accent),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: '',
                padding: EdgeInsets.zero,
                splashRadius: 14,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                onSelected: (v) {
                  switch (v) {
                    case 'file':
                      _connect(isFileTransfer: true);
                      break;
                    case 'camera':
                      _connect(isViewCamera: true);
                      break;
                    case 'terminal':
                      _connect(isTerminal: true);
                      break;
                    case 'tcp':
                      _connect(isTcpTunneling: true);
                      break;
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'file', child: Text(translate('Transfer file'))),
                  PopupMenuItem(
                      value: 'camera', child: Text(translate('View camera'))),
                  PopupMenuItem(
                      value: 'terminal',
                      child: Text('${translate('Terminal')} (beta)')),
                  if (isDesktop)
                    PopupMenuItem(
                        value: 'tcp', child: Text(translate('TCP tunneling'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
