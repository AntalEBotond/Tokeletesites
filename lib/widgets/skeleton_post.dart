import 'dart:ui';

import 'package:flutter/material.dart';

class SkeletonPostCard extends StatelessWidget {
  const SkeletonPostCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget box({double h = 14, double w = double.infinity, double r = 8}) => Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(r),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface.withOpacity(0.9),
                  theme.colorScheme.surfaceVariant.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const CircleAvatar(radius: 18),
                  const SizedBox(width: 10),
                  Expanded(child: box(w: double.infinity, h: 16, r: 6)),
                  const SizedBox(width: 10),
                  box(w: 24, h: 24, r: 6),
                ]),
                const SizedBox(height: 14),
                box(h: 14, w: 200),
                const SizedBox(height: 10),
                box(h: 140, r: 16),
                const SizedBox(height: 12),
                box(h: 12, w: 140),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    box(h: 12, w: 80),
                    box(h: 12, w: 80),
                    box(h: 12, w: 80),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
