import 'dart:math';
import 'package:flutter/material.dart';

/// Partícula de anacardo para el efecto confeti
class _CashuParticle {
  double x;
  double y;
  double vx; // velocidad horizontal
  double vy; // velocidad vertical
  double size;
  double rotation;
  double rotationSpeed;
  double opacity;

  _CashuParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  }) : opacity = 1.0;
}

/// Controller para disparar el efecto de confeti
class CashuConfettiController extends ChangeNotifier {
  bool _isActive = false;
  bool get isActive => _isActive;

  void fire() {
    _isActive = true;
    notifyListeners();
  }

  void reset() {
    _isActive = false;
    notifyListeners();
  }
}

/// Widget que muestra explosión de anacardos tipo confeti
/// Usa IgnorePointer para no bloquear interacciones
class CashuConfetti extends StatefulWidget {
  final CashuConfettiController controller;
  final Widget child;

  const CashuConfetti({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<CashuConfetti> createState() => _CashuConfettiState();
}

class _CashuConfettiState extends State<CashuConfetti>
    with SingleTickerProviderStateMixin {
  final List<_CashuParticle> _particles = [];
  late AnimationController _animController;
  final Random _random = Random();

  // Configuración de timing (en segundos)
  static const double _totalDuration = 4.0;
  static const double _explosionEnd = 0.08; // 0.3s de 4s
  static const double _fadeStart = 0.82; // fade en último 18%

  // Física
  static const double _gravity = 250.0; // caída suave
  static const int _particleCount = 220; // lluvia densa

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_totalDuration * 1000).toInt()),
    );

    _animController.addListener(_updateParticles);
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _particles.clear();
        });
        widget.controller.reset();
      }
    });

    widget.controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    if (widget.controller.isActive && !_animController.isAnimating) {
      _spawnParticles();
      _animController.forward(from: 0);
    }
  }

  void _spawnParticles() {
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    _particles.clear();

    for (int i = 0; i < _particleCount; i++) {
      // Ángulo aleatorio para explosión radial
      final angle = _random.nextDouble() * 2 * pi;
      // Velocidad inicial más moderada para lluvia más densa
      final speed = 250 + _random.nextDouble() * 400;

      _particles.add(_CashuParticle(
        x: centerX,
        y: centerY,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 150, // Bias hacia arriba
        size: 24 + _random.nextDouble() * 36, // 24-60px
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 6, // Rotación más suave
      ));
    }
    setState(() {});
  }

  void _updateParticles() {
    if (_particles.isEmpty) return;

    final progress = _animController.value;
    final dt = 1 / 60; // ~60fps

    // Calcular opacidad basada en fase
    double targetOpacity = 1.0;
    if (progress > _fadeStart) {
      // Fade out suave
      targetOpacity = 1.0 - ((progress - _fadeStart) / (1.0 - _fadeStart));
    }

    for (final p in _particles) {
      // Aplicar velocidad (con ease-out en la explosión)
      double speedMultiplier = 1.0;
      if (progress < _explosionEnd) {
        // Fase de explosión: rápida
        speedMultiplier = 1.0;
      } else {
        // Fase de caída: lenta y suave
        speedMultiplier = 0.5;
        p.vx *= 0.997; // Fricción horizontal muy suave
      }

      p.x += p.vx * dt * speedMultiplier;
      p.y += p.vy * dt * speedMultiplier;

      // Aplicar gravedad después de la explosión (suave)
      if (progress > _explosionEnd) {
        p.vy += _gravity * dt * 0.6;
      }

      // Rotación continua
      p.rotation += p.rotationSpeed * dt;

      // Actualizar opacidad
      p.opacity = targetOpacity.clamp(0.0, 1.0);
    }

    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Capa de confeti - IgnorePointer para no bloquear UI
        if (_particles.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(
                  particles: _particles,
                  image: _cashuImage,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        // Fallback con widgets si no hay imagen cargada
        if (_particles.isNotEmpty && _cashuImage == null)
          ..._buildParticleWidgets(),
      ],
    );
  }

  ImageInfo? _cashuImage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadImage();
  }

  void _loadImage() async {
    final imageProvider = const AssetImage('assets/img/cashu.png');
    final stream = imageProvider.resolve(ImageConfiguration.empty);
    stream.addListener(ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _cashuImage = info;
        });
      }
    }));
  }

  List<Widget> _buildParticleWidgets() {
    return _particles.map((p) {
      return Positioned(
        left: p.x - p.size / 2,
        top: p.y - p.size / 2,
        child: IgnorePointer(
          child: Transform.rotate(
            angle: p.rotation,
            child: Opacity(
              opacity: p.opacity,
              child: Image.asset(
                'assets/img/cashu.png',
                width: p.size,
                height: p.size,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

/// Painter para renderizar partículas con mejor rendimiento
class _ConfettiPainter extends CustomPainter {
  final List<_CashuParticle> particles;
  final ImageInfo? image;

  _ConfettiPainter({required this.particles, this.image});

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;

    for (final p in particles) {
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: p.opacity)
        ..filterQuality = FilterQuality.medium;

      final srcRect = Rect.fromLTWH(
        0,
        0,
        image!.image.width.toDouble(),
        image!.image.height.toDouble(),
      );
      final dstRect = Rect.fromCenter(
        center: Offset.zero,
        width: p.size,
        height: p.size,
      );

      canvas.drawImageRect(image!.image, srcRect, dstRect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
