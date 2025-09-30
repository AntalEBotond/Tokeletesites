import 'package:flutter/material.dart';
import 'framed_avatar.dart';
import 'note_editor.dart' show NoteEditResult;

Future<NoteEditResult?> showNoteEditorEnhanced(
  BuildContext context, {
  required String initialText,
  required Color textColor,
  required Color bgColor,
  required String? emoji,
  required ImageProvider? avatarImage,
  required String avatarName,
  required String frameStyle,
}) async {
  String localText = initialText;
  Color localTextColor = textColor;
  Color localBgColor = bgColor;

  final textCtrl = TextEditingController(text: localText);
  final focus = FocusNode();

  final textPalette = <Color>[
    Colors.white, Colors.black, const Color(0xFFFFC107), const Color(0xFFFF5252),
    const Color(0xFF40C4FF), const Color(0xFF66BB6A), const Color(0xFF7E57C2), const Color(0xFFFF7043),
    const Color(0xFFAED581), const Color(0xFF80CBC4), const Color(0xFF90CAF9), const Color(0xFFFFAB91),
  ];
  final bgPalette = <Color>[
    const Color(0xDD000000), const Color(0xFF263238), const Color(0xFF37474F), const Color(0xFF424242),
    const Color(0xFF1E88E5), const Color(0xFF6A1B9A), const Color(0xFFD81B60), const Color(0xFF2E7D32),
    const Color(0xFFFF7043), const Color(0xFFFFD54F), const Color(0xFF80DEEA), const Color(0xFF7E57C2),
  ];
  int startText = 0;
  int startBg = 0;

  return showModalBottomSheet<NoteEditResult>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) {
      final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: StatefulBuilder(
          builder: (ctx, setState) {
            List<Widget> colorRow({required String title, required List<Color> colors, required bool isText}) {
              final start = isText ? startText : startBg;
              final end = (start + 6).clamp(0, colors.length);
              final visible = colors.sublist(start, end);
              final canPrev = start > 0;
              final canNext = end < colors.length;
              final selected = isText ? localTextColor : localBgColor;
              final totalPages = ((colors.length + 5) ~/ 6);
              final currentPage = (start ~/ 6);
              return [
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: canPrev
                          ? () => setState(() {
                                if (isText) {
                                  startText = (startText - 6).clamp(0, colors.length);
                                } else {
                                  startBg = (startBg - 6).clamp(0, colors.length);
                                }
                              })
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: canNext
                          ? () => setState(() {
                                if (isText) {
                                  startText = startText + 6;
                                  final maxStart = ((colors.length - 1) ~/ 6) * 6;
                                  if (startText > maxStart) startText = maxStart;
                                } else {
                                  startBg = startBg + 6;
                                  final maxStart = ((colors.length - 1) ~/ 6) * 6;
                                  if (startBg > maxStart) startBg = maxStart;
                                }
                              })
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final c in visible)
                      GestureDetector(
                        onTap: () => setState(() {
                          if (isText) {
                            localTextColor = c;
                          } else {
                            localBgColor = c;
                          }
                        }),
                        child: Container(
                          width: 40,
                          height: 28,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: (selected.value == c.value)
                              ? const Icon(Icons.check, size: 16, color: Colors.black)
                              : null,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < totalPages; i++)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == currentPage ? Colors.white70 : Colors.white24,
                        ),
                      ),
                  ],
                ),
              ];
            }

            Widget editableBubble() {
              final theme = Theme.of(context);
              return GestureDetector(
                onTap: () => FocusScope.of(ctx).requestFocus(focus),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 260),
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                      decoration: BoxDecoration(
                        color: localBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.35)),
                      ),
                      child: TextField(
                        controller: textCtrl,
                        focusNode: focus,
                        maxLines: 2,
                        decoration: const InputDecoration.collapsed(hintText: 'Scrie ce ai în minte…'),
                        style: TextStyle(color: localTextColor, fontSize: 16),
                        onChanged: (v) => setState(() => localText = v),
                      ),
                    ),
                    if (emoji != null && emoji.isNotEmpty)
                      Positioned(
                        top: -10,
                        left: -10,
                        child: Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.4)),
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Editează notița (24h)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      height: 220,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: FramedAvatar(
                              image: avatarImage,
                              name: avatarName,
                              radius: 60,
                              frameStyle: frameStyle,
                            ),
                          ),
                          Positioned(
                            bottom: 120,
                            left: 0,
                            right: 0,
                            child: Center(child: editableBubble()),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...colorRow(title: 'Culoare text', colors: textPalette, isText: true),
                  const SizedBox(height: 10),
                  ...colorRow(title: 'Fundal', colors: bgPalette, isText: false),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx, const NoteEditResult(text: null, textColor: Colors.white, bgColor: Colors.black54, deleted: true));
                        },
                        child: const Text('Șterge'),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('Aplică'),
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
                      const SizedBox(width: 8),
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulează')),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

