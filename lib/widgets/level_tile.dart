import 'package:flutter/material.dart';

/// A gradient card representing one CEFR level with its word count.
class LevelTile extends StatelessWidget {
  const LevelTile({
    super.key,
    required this.level,
    required this.wordCount,
    required this.countLabel,
    this.onTap,
  });

  final String level;
  final int wordCount;

  /// Localised "N words" label.
  final String countLabel;

  final VoidCallback? onTap;

  static const List<List<Color>> _palettes = <List<Color>>[
    <Color>[Color(0xFF4356D6), Color(0xFF7C4DFF)],
    <Color>[Color(0xFF667EEA), Color(0xFF764BA2)],
    <Color>[Color(0xFF11998E), Color(0xFF38EF7D)],
    <Color>[Color(0xFF2193B0), Color(0xFF6DD5ED)],
  ];

  static const List<String> _levelOrder = <String>['A1', 'A2', 'B1', 'B2'];

  List<Color> get _palette {
    final index = _levelOrder.indexOf(level);
    return _palettes[index < 0 ? 0 : index];
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _palette,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    level,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$wordCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  countLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
