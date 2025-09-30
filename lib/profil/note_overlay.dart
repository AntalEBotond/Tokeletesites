import 'package:flutter/material.dart';

class NoteOverlay extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color bgColor;
  final VoidCallback onEdit;
  final double maxWidth;
  final String? emoji;
  final VoidCallback? onPickEmoji;

  const NoteOverlay({
    super.key,
    required this.text,
    required this.textColor,
    required this.bgColor,
    required this.onEdit,
    this.maxWidth = 220,
    this.emoji,
    this.onPickEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onEdit,
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: EdgeInsets.fromLTRB(emoji == null ? 12 : 34, 10, 34, 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
              border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.35)),
            ),
            child: Text(
              text,
              style: TextStyle(color: textColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ),
        // Emoji badge (selected or placeholder) at bubble's top-left, outside
        Positioned(
          top: -10,
          left: -10,
          child: GestureDetector(
            onTap: onPickEmoji,
            child: _EmojiBadge(
              emoji: emoji,
              placeholder: '🙂',
            ),
          ),
        ),
        // Edit pencil removed: tap bubble to edit; emoji badge handles emoji
      ],
    );
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _EditButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Icon(Icons.edit, size: 14, color: Colors.grey.shade400),
    );
  }
}

class _EmojiBadge extends StatelessWidget {
  final String? emoji;
  final String placeholder;
  const _EmojiBadge({required this.emoji, required this.placeholder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasEmoji = emoji != null && emoji!.isNotEmpty;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hasEmoji ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.06),
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.primary.withOpacity(hasEmoji ? 0.5 : 0.25)),
          ),
          child: Text(hasEmoji ? emoji! : placeholder,
              style: TextStyle(fontSize: 16, color: hasEmoji ? null : Colors.white54)),
        ),
        if (!hasEmoji)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 14,
              height: 14,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: theme.colorScheme.primary.withOpacity(0.4), blurRadius: 4),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 10),
            ),
          )
      ],
    );
  }
}
