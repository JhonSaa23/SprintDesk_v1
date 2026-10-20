import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/formatter/id_formatter.dart';
import 'package:flutter_hbb/common/widgets/autocomplete.dart';
import 'package:flutter_hbb/models/peer_model.dart';

class HeaderConnectBar extends StatefulWidget {
  const HeaderConnectBar({Key? key}) : super(key: key);

  @override
  State<HeaderConnectBar> createState() => _HeaderConnectBarState();
}

class _HeaderConnectBarState extends State<HeaderConnectBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final AllPeersLoader _allPeersLoader = AllPeersLoader();
  Iterable<Peer> _opts = const [];

  @override
  void initState() {
    super.initState();
    _allPeersLoader.init(setState);
    _allPeersLoader.getAllPeers(force: true);
    _focus.addListener(() {
      if (_focus.hasFocus) {
        _allPeersLoader.getAllPeers(force: true);
      }
    });
  }

  @override
  void dispose() {
    _allPeersLoader.clear();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _id => _controller.text.replaceAll(' ', '');

  bool _matches(Peer p, String q) =>
      p.id.toLowerCase().contains(q) ||
      p.alias.toLowerCase().contains(q) ||
      p.hostname.toLowerCase().contains(q) ||
      p.username.toLowerCase().contains(q);

  /// Turns what the user typed into a remote ID. Numbers are used as-is;
  /// text is resolved against saved machines (alias/hostname/user).
  String _resolveId() {
    final raw = _controller.text.trim();
    final compact = raw.replaceAll(' ', '');
    if (compact.isEmpty || int.tryParse(compact) != null) return compact;
    final q = raw.toLowerCase();
    final peers = _allPeersLoader.peers;
    for (final p in peers) {
      if (p.alias.toLowerCase() == q || p.hostname.toLowerCase() == q) return p.id;
    }
    for (final p in peers) {
      if (_matches(p, q)) return p.id;
    }
    return compact;
  }

  void _connect(
      {bool isFileTransfer = false,
      bool isViewCamera = false,
      bool isTerminal = false,
      bool isTcpTunneling = false}) {
    final id = _resolveId();
    if (id.isEmpty) {
      _focus.requestFocus();
      return;
    }
    connect(context, id,
        isFileTransfer: isFileTransfer,
        isViewCamera: isViewCamera,
        isTerminal: isTerminal,
        isTcpTunneling: isTcpTunneling);
  }

  Iterable<Peer> _buildOptions(TextEditingValue value) {
    final peers = _allPeersLoader.peers;
    final text = value.text.trim().toLowerCase();
    if (text.isEmpty) {
      final all = List<Peer>.from(peers);
      all.sort((a, b) {
        final aHasName = a.alias.isNotEmpty || a.hostname.isNotEmpty;
        final bHasName = b.alias.isNotEmpty || b.hostname.isNotEmpty;
        return (aHasName ? 0 : 1).compareTo(bHasName ? 0 : 1);
      });
      _opts = all.take(50).toList();
    } else {
      final compact = text.replaceAll(' ', '');
      final q = int.tryParse(compact) != null ? compact : text;
      _opts = peers.where((p) => _matches(p, q)).take(50).toList();
    }
    if (_opts.isNotEmpty) _allPeersLoader.queryOnlines(_opts);
    return _opts;
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
    );
    return Container(
      constraints: const BoxConstraints(maxWidth: 420, minWidth: 100),
      height: 42,
      margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
      child: RawAutocomplete<Peer>(
        focusNode: _focus,
        textEditingController: _controller,
        optionsBuilder: _buildOptions,
        displayStringForOption: (p) => formatID(p.id),
        onSelected: (p) {
          _controller.text = formatID(p.id);
          setState(() {});
        },
        optionsViewBuilder: (context, onSelected, options) {
          final list = options.toList();
          return Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Material(
                elevation: 6,
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 380,
                    maxHeight: (list.length * 48.0).clamp(0.0, 260.0),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.only(top: 5),
                    shrinkWrap: true,
                    children: list
                        .map((p) => AutocompletePeerTile(
                            onSelect: () => onSelected(p), peer: p))
                        .toList(),
                  ),
                ),
              ),
            ),
          );
        },
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
          return _buildField(border, controller, focusNode);
        },
      ),
    );
  }

  Widget _buildField(OutlineInputBorder border, TextEditingController controller,
      FocusNode focusNode) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
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
