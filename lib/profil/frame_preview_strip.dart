import 'package:flutter/material.dart';
import 'framed_avatar.dart';

class FramePreviewStrip extends StatefulWidget {
  final List<String> styles;
  final String selected;
  final ImageProvider? image;
  final String name;
  final ValueChanged<String> onSelected;
  final int windowSize;

  const FramePreviewStrip({
    super.key,
    required this.styles,
    required this.selected,
    required this.image,
    required this.name,
    required this.onSelected,
    this.windowSize = 5,
  });

  @override
  State<FramePreviewStrip> createState() => _FramePreviewStripState();
}

class _FramePreviewStripState extends State<FramePreviewStrip> {
  late int _start;

  @override
  void initState() {
    super.initState();
    final idx = widget.styles.indexOf(widget.selected);
    _start = (idx <= 0) ? 0 : (idx ~/ widget.windowSize) * widget.windowSize;
  }

  @override
  void didUpdateWidget(covariant FramePreviewStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected || oldWidget.styles != widget.styles) {
      final idx = widget.styles.indexOf(widget.selected);
      setState(() {
        _start = (idx <= 0) ? 0 : (idx ~/ widget.windowSize) * widget.windowSize;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final end = (_start + widget.windowSize).clamp(0, widget.styles.length);
    final visible = widget.styles.sublist(_start, end);
    final canPrev = _start > 0;
    final canNext = end < widget.styles.length;

    return SizedBox(
      height: 120,
      child: Row(
        children: [
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: canPrev
                ? () => setState(() {
                      _start = _start - widget.windowSize;
                      if (_start < 0) _start = 0;
                    })
                : null,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: visible.length,
              itemBuilder: (context, i) {
                final style = visible[i];
                return GestureDetector(
                  onTap: () => widget.onSelected(style),
                  child: Container(
                    width: 96,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            Center(
                              child: FramedAvatar(
                                image: widget.image,
                                name: widget.name,
                                radius: 32,
                                frameStyle: style,
                              ),
                            ),
                            if (widget.selected == style)
                              const Positioned(
                                right: 6,
                                bottom: 6,
                                child: Icon(Icons.check_circle, color: Colors.lightGreenAccent, size: 18),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(_displayName(style), style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: canNext
                ? () => setState(() {
                      _start = _start + widget.windowSize;
                      final maxStart = ((widget.styles.length - 1) ~/ widget.windowSize) * widget.windowSize;
                      if (_start > maxStart) _start = maxStart;
                    })
                : null,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  String _displayName(String style) {
    if (!style.contains('-')) return style;
    final head = style.split('-').first;
    final tail = style.split('-').last;
    switch (head) {
      case 'gradient':
        return tail;
      case 'ring':
      case 'outline':
      case 'glow':
      case 'neon':
        return head;
      default:
        return style;
    }
  }
}
