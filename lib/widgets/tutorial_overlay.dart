import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final IconData icon;

  const TutorialStep({
    required this.targetKey,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class TutorialOverlay extends StatefulWidget {
  final String tutorialId;
  final List<TutorialStep> steps;
  final VoidCallback onComplete;

  const TutorialOverlay({
    super.key,
    required this.tutorialId,
    required this.steps,
    required this.onComplete,
  });

  static Future<bool> shouldShow(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('tutorial_$tutorialId') ?? false);
  }

  static Future<void> markComplete(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_$tutorialId', true);
  }

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() async {
    await _controller.reverse();
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
      _controller.forward();
    } else {
      await TutorialOverlay.markComplete(widget.tutorialId);
      widget.onComplete();
    }
  }

  void _skip() async {
    await TutorialOverlay.markComplete(widget.tutorialId);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Offset? targetCenter;
    Size? targetSize;
    final renderBox =
        step.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final position = renderBox.localToGlobal(Offset.zero);
      targetSize = renderBox.size;
      targetCenter = position + Offset(targetSize.width / 2, targetSize.height / 2);
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dimmed background
          GestureDetector(
            onTap: _next,
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Container(
                  color: Colors.black.withValues(alpha: 0.6 * _fadeAnimation.value),
                );
              },
            ),
          ),

          // Spotlight cutout around target
          if (targetCenter != null && targetSize != null)
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: CustomPaint(
                    size: MediaQuery.of(context).size,
                    painter: _SpotlightPainter(
                      center: targetCenter!,
                      radius: (targetSize!.longestSide / 2) + 16,
                    ),
                  ),
                );
              },
            ),

          // Tooltip card
          if (targetCenter != null)
            Positioned(
              left: 24,
              right: 24,
              top: targetCenter.dy + (targetSize?.height ?? 0) / 2 + 24,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(step.icon, color: colors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                step.title,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          step.description,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_currentStep + 1} of ${widget.steps.length}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            Row(
                              children: [
                                if (_currentStep < widget.steps.length - 1)
                                  TextButton(
                                    onPressed: _skip,
                                    child: const Text('Skip'),
                                  ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _next,
                                  child: Text(
                                    _currentStep < widget.steps.length - 1
                                        ? 'Next'
                                        : 'Got it!',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Offset center;
  final double radius;

  _SpotlightPainter({required this.center, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.transparent,
    );
    canvas.drawCircle(center, radius, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.center != center || oldDelegate.radius != radius;
  }
}
