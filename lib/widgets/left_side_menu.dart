import 'package:flutter/material.dart';
import '../models/menu_item_data.dart';

class LeftSideMenu extends StatelessWidget {
  const LeftSideMenu({
    super.key,
    required this.items,
    required this.selectedIndex,
    this.onItemSelected,
    this.width = 240,
    this.collapsed = false,
    this.onCollapseToggle,
    this.footer,
  });

  final List<MenuItemData> items;
  final int selectedIndex;
  final ValueChanged<int>? onItemSelected;
  final double width;
  final bool collapsed;
  final ValueChanged<bool>? onCollapseToggle;
  final Widget? footer;

  double get _effectiveWidth => collapsed ? 88 : width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final textColor = theme.textTheme.bodyMedium?.color;

    Widget titleFor(MenuItemData item, bool selected) {
      if (collapsed) {
        return const SizedBox.shrink();
      }
      return Expanded(
        child: Text(
          item.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: selected ? accent : textColor,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      );
    }

    return Container(
      width: _effectiveWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface.withOpacity(0.96),
            theme.colorScheme.surface.withOpacity(0.88),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          right: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
        ),
      ),
      child: SafeArea(
        left: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: collapsed
                  ? const EdgeInsets.symmetric(vertical: 18)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                mainAxisAlignment:
                    collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.flutter_dash, color: accent),
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aplicatie',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                  if (onCollapseToggle != null)
                    IconButton(
                      icon: Icon(collapsed ? Icons.unfold_more : Icons.unfold_less),
                      tooltip: collapsed ? 'Deschide meniul' : 'Restrânge meniul',
                      onPressed: () => onCollapseToggle!(!collapsed),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = index == selectedIndex;

                  return Material(
                    color: selected ? accent.withOpacity(0.08) : Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        item.onTap?.call();
                        onItemSelected?.call(index);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: collapsed ? 16 : 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 4,
                              height: 32,
                              decoration: BoxDecoration(
                                color: selected ? accent : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(item.icon, color: selected ? accent : theme.iconTheme.color),
                            if (!collapsed) const SizedBox(width: 14),
                            titleFor(item, selected),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (footer != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 12, vertical: 12),
                child: footer!,
              )
            else
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Versiune 1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  textAlign: collapsed ? TextAlign.center : TextAlign.start,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
