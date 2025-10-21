import 'package:flutter/material.dart';

class TypingIndicatorWidget extends StatefulWidget {
  const TypingIndicatorWidget({
    super.key,
    this.dotColor,
    this.bubbleColor,
    this.text = 'AI is typing',
  });

  final Color? dotColor;
  final Color? bubbleColor;
  final String text;

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();

    _animation1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _animation2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeInOut),
      ),
    );

    _animation3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: IntrinsicWidth(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.bubbleColor ??
                  theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Text
                Text(
                  widget.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(width: 12),

                // Animated dots
                SizedBox(
                  width: 20,
                  height: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _AnimatedDot(
                        animation: _animation1,
                        color: widget.dotColor ?? theme.colorScheme.primary,
                      ),
                      _AnimatedDot(
                        animation: _animation2,
                        color: widget.dotColor ?? theme.colorScheme.primary,
                      ),
                      _AnimatedDot(
                        animation: _animation3,
                        color: widget.dotColor ?? theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedDot extends StatelessWidget {
  const _AnimatedDot({
    required this.animation,
    required this.color,
  });

  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: color.withOpacity(animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
