import 'package:flutter/material.dart';

class NoteEditResult {
  final String? text;
  final Color textColor;
  final Color bgColor;
  final bool deleted;
  const NoteEditResult({this.text, required this.textColor, required this.bgColor, this.deleted = false});
}

Future<NoteEditResult?> showNoteEditor(
  BuildContext context, {
  required String initialText,
  required Color textColor,
  required Color bgColor,
}) async {
  String localText = initialText;
  Color localTextColor = textColor;
  Color localBgColor = bgColor;
  final textCtrl = TextEditingController(text: localText);

  final textPalette = <Color>[
    Colors.white, Colors.black, const Color(0xFFFFC107), const Color(0xFFFF5252),
    const Color(0xFF40C4FF), const Color(0xFF66BB6A), const Color(0xFF7E57C2), const Color(0xFFFF7043),
  ];
  final bgPalette = <Color>[
    const Color(0xDD000000), const Color(0xFF263238), const Color(0xFF37474F), const Color(0xFF424242),
    const Color(0xFF1E88E5), const Color(0xFF6A1B9A), const Color(0xFFD81B60), const Color(0xFF2E7D32),
  ];

  return showModalBottomSheet<NoteEditResult>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) {
      final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Status / Nota (24h)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 280),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                      decoration: BoxDecoration(
                        color: localBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.35)),
                      ),
                      child: Text(
                        localText.isEmpty ? 'Írj egy jegyzetet…' : localText,
                        style: TextStyle(color: localTextColor),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textCtrl,
                    maxLength: 140,
                    decoration: const InputDecoration(
                      hintText: 'Mi jár a fejedben?',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.chat_bubble_outline),
                    ),
                    onChanged: (v) => setSheetState(() => localText = v),
                  ),
                  const SizedBox(height: 10),
                  const Text('Szín (szöveg)', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final c in textPalette)
                        GestureDetector(
                          onTap: () => setSheetState(() => localTextColor = c),
                          child: Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: localTextColor.value == c.value ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Szín (háttér)', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final c in bgPalette)
                        GestureDetector(
                          onTap: () => setSheetState(() => localBgColor = c),
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: localBgColor.value == c.value ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Gyors kombinációk', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      for (final combo in const [
                        ['#FFFFFF','#263238'], ['#000000','#FFD54F'], ['#FFFFFF','#D81B60'], ['#000000','#80DEEA'],
                        ['#FFFFFF','#2E7D32'], ['#FFFFFF','#7E57C2'], ['#000000','#FF7043'], ['#FFFFFF','#1E88E5']
                      ])
                        GestureDetector(
                          onTap: () => setSheetState(() {
                            localTextColor = _hexToColor(combo[0]);
                            localBgColor = _hexToColor(combo[1]);
                          }),
                          child: Container(
                            width: 56, height: 28,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                              gradient: LinearGradient(colors: [_hexToColor(combo[1]).withOpacity(0.9), _hexToColor(combo[1])]),
                            ),
                            alignment: Alignment.center,
                            child: Text('Aa', style: TextStyle(color: localTextColor)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx, NoteEditResult(text: null, textColor: localTextColor, bgColor: localBgColor, deleted: true));
                        },
                        child: const Text('Törlés'),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('Mentés'),
                        onPressed: () {
                          Navigator.pop(
                            ctx,
                            NoteEditResult(
                              text: textCtrl.text.trim(),
                              textColor: localTextColor,
                              bgColor: localBgColor,
                              deleted: false,
                            ),
                          );
                        },
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

Color _hexToColor(String hex) {
  String v = hex.replaceAll('#', '');
  if (v.length == 6) v = 'FF$v';
  return Color(int.parse(v, radix: 16));
}

Future<String?> showEmojiPickerSheet(BuildContext context, {String? initialEmoji}) {
  final emojis = <String>[
    '\u{1F600}', '\u{1F60E}', '\u{1F914}', '\u{1F680}', '\u{2764}\u{FE0F}',
    '\u{1F525}', '\u{1F31F}', '\u{1F3AF}', '\u{1F4A1}', '\u{1F602}',
    '\u{1F634}', '\u{1F622}', '\u{1F9E0}', '\u{1F6E0}\u{FE0F}', '\u{1F440}',
    '\u{1F44D}', '\u{1F44E}', '\u{1F389}', '\u{1F916}', '\u{1F973}',
  ];
  return showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Válassz emojit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final e in emojis)
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, e),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, ''),
                  child: const Text('Törlés'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Mégse'),
                ),
              ],
            )
          ],
        ),
      );
    },
  );
}
