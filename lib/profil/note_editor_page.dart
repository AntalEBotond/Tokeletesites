import 'package:flutter/material.dart';
import 'framed_avatar.dart';
import 'note_editor.dart' show NoteEditResult;

class NoteEditorPage extends StatefulWidget {
  final String initialText;
  final Color textColor;
  final Color bgColor;
  final String? emoji;
  final ImageProvider? avatarImage;
  final String avatarName;
  final String frameStyle;

  const NoteEditorPage({
    super.key,
    required this.initialText,
    required this.textColor,
    required this.bgColor,
    required this.emoji,
    required this.avatarImage,
    required this.avatarName,
    required this.frameStyle,
  });

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _text;
  late FocusNode _focus;
  late Color _bg;
  late Color _fg;
  final PageController _page = PageController();
  int _pageIndex = 0;

  // 6/oldal, sok oldal: kibővített színpaletta
  static const List<Color> _palette = [
    // Purples / Violets
    Color(0xFFB388FF), Color(0xFF9575CD), Color(0xFF7E57C2), Color(0xFF673AB7), Color(0xFF5E35B1), Color(0xFF512DA8),
    Color(0xFF7C4DFF), Color(0xFF651FFF), Color(0xFF6200EA), Color(0xFF8E24AA), Color(0xFF9C27B0), Color(0xFFAA00FF),
    // Pinks / Magentas
    Color(0xFFF8BBD0), Color(0xFFF48FB1), Color(0xFFF06292), Color(0xFFEC407A), Color(0xFFE91E63), Color(0xFFD81B60),
    Color(0xFFC2185B), Color(0xFFAD1457), Color(0xFFF50057), Color(0xFFFF4081), Color(0xFFE040FB), Color(0xFFD500F9),
    // Reds
    Color(0xFFFFCDD2), Color(0xFFEF9A9A), Color(0xFFE57373), Color(0xFFEF5350), Color(0xFFF44336), Color(0xFFD32F2F),
    // Oranges
    Color(0xFFFFCC80), Color(0xFFFFB74D), Color(0xFFFFA726), Color(0xFFFF9800), Color(0xFFFB8C00), Color(0xFFF57C00),
    // Yellows
    Color(0xFFFFF59D), Color(0xFFFFEE58), Color(0xFFFFEB3B), Color(0xFFFDD835), Color(0xFFFBC02D), Color(0xFFF9A825),
    // Greens
    Color(0xFFC8E6C9), Color(0xFFA5D6A7), Color(0xFF81C784), Color(0xFF66BB6A), Color(0xFF4CAF50), Color(0xFF388E3C),
    // Teals
    Color(0xFFB2DFDB), Color(0xFF80CBC4), Color(0xFF4DB6AC), Color(0xFF26A69A), Color(0xFF009688), Color(0xFF00796B),
    // Cyans / Blues
    Color(0xFFB3E5FC), Color(0xFF81D4FA), Color(0xFF4FC3F7), Color(0xFF29B6F6), Color(0xFF03A9F4), Color(0xFF0288D1),
    Color(0xFF90CAF9), Color(0xFF64B5F6), Color(0xFF42A5F5), Color(0xFF2196F3), Color(0xFF1E88E5), Color(0xFF1976D2),
    // Greys
    Color(0xFFFAFAFA), Color(0xFFF0F0F0), Color(0xFFE0E0E0), Color(0xFFBDBDBD), Color(0xFF9E9E9E), Color(0xFF616161),
  ];

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.initialText);
    _focus = FocusNode();
    _bg = widget.bgColor;
    _fg = widget.textColor;
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Editor bulă'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Középen a buborék + avatar
            SizedBox(
              height: 240,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Avatar in bottom center
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FramedAvatar(
                      image: widget.avatarImage,
                      name: widget.avatarName,
                      radius: 64,
                      frameStyle: widget.frameStyle,
                    ),
                  ),
                  // Bubble aligned relative to avatar top (2*radius) with small gap
                  Positioned(
                    bottom: 64 * 2 - 2,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Transform.translate(
                          offset: const Offset(-15.0, 0.0),
                          child: _editableBubble(theme),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Színválasztó 6/oldal PageView-ben
            SizedBox(
              height: 70,
              child: PageView.builder(
                controller: _page,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) => setState(() => _pageIndex = i),
                itemCount: (_palette.length / 6).ceil(),
                itemBuilder: (ctx, page) {
                  final start = page * 6;
                  final end = (start + 6) > _palette.length ? _palette.length : start + 6;
                  final colors = _palette.sublist(start, end);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final c in colors)
                        GestureDetector(
                          onTap: () => setState(() { _bg = c; _fg = _bestText(c); }),
                          child: Container(
                            width: 36,
                            height: 36,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                              boxShadow: [BoxShadow(color: c.withOpacity(0.25), blurRadius: 12)],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Oldal pöttyök
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < (_palette.length / 6).ceil(); i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _pageIndex ? Colors.white70 : Colors.white24,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B2F5E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pop(
                      context,
                      NoteEditResult(text: _text.text.trim(), textColor: _fg, bgColor: _bg, deleted: false),
                    );
                  },
                  child: const Text('Aplică'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Törlés
            TextButton(
              onPressed: () {
                Navigator.pop(context, const NoteEditResult(text: null, textColor: Colors.white, bgColor: Colors.black54, deleted: true));
              },
              child: const Text('Șterge'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _editableBubble(ThemeData theme) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_focus),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 160),
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.25)),
            ),
            child: TextField(
              controller: _text,
              focusNode: _focus,
              maxLines: 2,
              decoration: const InputDecoration.collapsed(hintText: 'Ce îți trece prin minte?'),
              style: TextStyle(color: _fg, fontSize: 14, height: 1.15),
            ),
          ),
          if (widget.emoji != null && widget.emoji!.isNotEmpty)
            Positioned(
              top: -12,
              left: -12,
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFFF58529), Color(0xFFDD2A7B)]),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(widget.emoji!, style: const TextStyle(fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }

  Color _bestText(Color bg) => bg.computeLuminance() > 0.4 ? Colors.black : Colors.white;
}
