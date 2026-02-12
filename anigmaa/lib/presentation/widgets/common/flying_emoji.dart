import 'package:flutter/material.dart';

class FlyingEmoji extends StatefulWidget {
  final VoidCallback onAnimationComplete;
  final String emoji;
  final double size;
  final Offset startPosition;
  final Offset endPosition;

  const FlyingEmoji({
    super.key,
    required this.onAnimationComplete,
    required this.startPosition,
    required this.endPosition,
    this.emoji = '📌',
    this.size = 50,
  });

  @override
  State<FlyingEmoji> createState() => _FlyingEmojiState();
}

class _FlyingEmojiState extends State<FlyingEmoji>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Slightly longer flight
    );

    // Position Animation: Fly from start to end (relative to the Stack)
    // We will position this widget at (0,0) in the Stack and transform it
    _positionAnimation =
        Tween<Offset>(
          begin: widget.startPosition,
          end: widget.endPosition,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 1.0, curve: Curves.easeInOutCubic),
          ),
        );

    // Scale animation: Pop up (0->1.5), then shrink to target (1.5->0.5)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.5,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30, // First 300ms
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.5,
          end: 0.5,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 70, // Remaining 700ms flight
      ),
    ]).animate(_controller);

    // Opacity: Fade out near the very end
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.9, 1.0, curve: Curves.linear),
      ),
    );

    _controller.forward().then((_) {
      if (mounted) {
        widget.onAnimationComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Use Global position translation
        return Positioned(
          left: 0,
          top: 0,
          child: Transform.translate(
            offset: _positionAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Text(
                  widget.emoji,
                  style: TextStyle(
                    fontSize: widget.size,
                    decoration: TextDecoration.none, // Ensure no underline
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
