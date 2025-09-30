part of 'profile_page.dart';

class _FramePickerSheet extends StatefulWidget {
  const _FramePickerSheet({
    required this.allStyles,
    required this.current,
    required this.favs,
    required this.categories,
    required this.colorsFor,
    required this.onPreviewStart,
    required this.onPreviewEnd,
    required this.onToggleFav,
  });

  final List<String> allStyles;
  final String current;
  final Set<String> favs;
  final Map<String, List<String>> categories;
  final List<Color> Function(String) colorsFor;
  final ValueChanged<String> onPreviewStart;
  final VoidCallback onPreviewEnd;
  final Future<void> Function(String) onToggleFav;

  @override
  State<_FramePickerSheet> createState() => _FramePickerSheetState();
}

class _FramePickerSheetState extends State<_FramePickerSheet> {
  String _category = 'All';
  String _query = '';
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = _buildList();
  }

  List<String> _buildList() {
    Iterable<String> source = widget.allStyles;
    final prefixes = widget.categories[_category] ?? const <String>[];
    if (prefixes.isNotEmpty) {
      source = source.where(
        (style) => prefixes.any((prefix) => style.startsWith(prefix)) ||
            (prefixes.contains('rainbow') && style == 'rainbow'),
      );
    }
    if (_query.isNotEmpty) {
      source = source.where((style) => style.toLowerCase().contains(_query.toLowerCase()));
    }
    final favorites = source.where((style) => widget.favs.contains(style)).toList();
    final rest = source.where((style) => !widget.favs.contains(style)).toList();
    return [...favorites, ...rest];
  }

  void _applyFilters() {
    setState(() => _filtered = _buildList());
  }

  int _crossAxisCount(double width) {
    if (width < 340) return 3;
    if (width < 480) return 4;
    if (width < 680) return 5;
    return 6;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (ctx, scroll) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 24),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.brush_outlined),
                    const SizedBox(width: 8),
                    Text('Keretválasztó', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    if (widget.favs.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 16),
                            const SizedBox(width: 6),
                            Text('${widget.favs.length}')
                          ],
                        ),
                      ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  onChanged: (value) {
                    _query = value;
                    _applyFilters();
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Keresés (pl. neon, violet, gold)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, index) {
                    final name = widget.categories.keys.elementAt(index);
                    final selected = name == _category;
                    return ChoiceChip(
                      label: Text(name),
                      selected: selected,
                      onSelected: (_) {
                        _category = name;
                        _applyFilters();
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: widget.categories.length,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final cols = _crossAxisCount(constraints.maxWidth);
                    return GridView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        childAspectRatio: 0.88,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemCount: _filtered.length,
                      itemBuilder: (_, index) {
                        final style = _filtered[index];
                        final isFav = widget.favs.contains(style);
                        final isSelected = style == widget.current;
                        return GestureDetector(
                          onTap: () => Navigator.pop(context, style),
                          onLongPressStart: (_) => widget.onPreviewStart(style),
                          onLongPressEnd: (_) => widget.onPreviewEnd(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white.withOpacity(0.08),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Expanded(
                                  child: CustomPaint(
                                    painter: _SwatchPainter(colors: widget.colorsFor(style)),
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        style.replaceAll('-', '\u200B-'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        widget.onToggleFav(style);
                                      },
                                      child: Icon(isFav ? Icons.star : Icons.star_border, size: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter({required this.colors});

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2 - 4;
    final center = Offset(size.width / 2, size.height / 2);

    final background = Paint()..color = Colors.black.withOpacity(0.35);
    canvas.drawCircle(center, radius, background);

    final stroke = (radius * 0.32).clamp(6, 18).toDouble();
    final ringRect = Rect.fromCircle(center: center, radius: radius - stroke / 2);
    final shader = SweepGradient(
      colors: [...colors, colors.first],
      startAngle: 0,
      endAngle: math.pi * 2,
    ).createShader(ringRect);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..shader = shader
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawArc(ringRect, 0, math.pi * 2, false, ring);
  }

  @override
  bool shouldRepaint(covariant _SwatchPainter oldDelegate) => oldDelegate.colors != colors;
}
