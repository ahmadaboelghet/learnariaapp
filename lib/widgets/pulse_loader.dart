import 'package:flutter/material.dart';

class PulseLoader extends StatefulWidget {
  final double size;
  const PulseLoader({super.key, this.size = 100.0});

  @override
  State<PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<PulseLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Image.asset(
          'assets/images/logo_bg.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
