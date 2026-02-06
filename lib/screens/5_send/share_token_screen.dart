import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/primary_button.dart';

/// Pantalla para compartir el token Cashu generado
class ShareTokenScreen extends StatefulWidget {
  final String token;
  final int amount;
  final String unit;
  final String? memo;

  const ShareTokenScreen({
    super.key,
    required this.token,
    required this.amount,
    required this.unit,
    this.memo,
  });

  @override
  State<ShareTokenScreen> createState() => _ShareTokenScreenState();
}

class _ShareTokenScreenState extends State<ShareTokenScreen> {
  late PageController _pageController;
  late List<String> _qrParts;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _qrParts = _encodeTokenToQR();
    _startQRAnimation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  List<String> _encodeTokenToQR() {
    // TODO: Implementar con cdk-flutter cuando esté disponible
    // final qrParts = encodeQrToken(token: widget.token);

    // Por ahora, simulamos fragmentos UR para el token
    if (widget.token.length <= 200) {
      return [widget.token];
    }

    // Simular fragmentación para tokens largos
    final parts = <String>[];
    const chunkSize = 200;
    for (int i = 0; i < widget.token.length; i += chunkSize) {
      final end = (i + chunkSize < widget.token.length)
          ? i + chunkSize
          : widget.token.length;
      parts.add(widget.token.substring(i, end));
    }
    return parts;
  }

  void _startQRAnimation() {
    // Solo animar si hay múltiples fragmentos
    if (_qrParts.length <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        final nextPage = (_currentPage + 1) % _qrParts.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.x, color: Colors.white),
            onPressed: () => _goToHome(context),
          ),
          title: const Text(
            'Token creado',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              children: [
                const SizedBox(height: AppDimensions.paddingLarge),

                // Icono de exito
                _buildSuccessIcon(),

                const SizedBox(height: AppDimensions.paddingLarge),

                // Monto
                _buildAmountDisplay(),

                const SizedBox(height: AppDimensions.paddingLarge),

                // QR del token (dinámico si hay múltiples fragmentos)
                _buildQRDisplay(),

                const SizedBox(height: AppDimensions.paddingMedium),

                // Token truncado
                _buildTokenTextDisplay(),

                const SizedBox(height: AppDimensions.paddingSmall),

                // Indicador de página (si hay múltiples fragmentos)
                if (_qrParts.length > 1) _buildPageIndicator(),

                const SizedBox(height: AppDimensions.paddingMedium),

                // Botones copiar y compartir
                _buildActionButtons(context),

                const SizedBox(height: AppDimensions.paddingLarge),

                // Advertencia
                _buildWarning(),

                const Spacer(),

                // Boton volver al inicio
                PrimaryButton(
                  text: 'Volver al inicio',
                  onPressed: () => _goToHome(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(LucideIcons.check, color: AppColors.success, size: 40),
    );
  }

  Widget _buildAmountDisplay() {
    return Column(
      children: [
        Text(
          '${widget.amount} ${widget.unit}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (widget.memo != null && widget.memo!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '"${widget.memo}"',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQRDisplay() {
    final size = 220.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _qrParts.length > 1
            ? PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _qrParts.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: QrImageView(
                        data: _qrParts[index],
                        version: QrVersions.auto,
                        size: size - 40,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                  );
                },
              )
            : Padding(
                padding: const EdgeInsets.all(20),
                child: QrImageView(
                  data: _qrParts[0],
                  version: QrVersions.auto,
                  size: size - 40,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
      ),
    );
  }

  Widget _buildTokenTextDisplay() {
    final displayToken = widget.token.length > 50
        ? '${widget.token.substring(0, 25)}...${widget.token.substring(widget.token.length - 20)}'
        : widget.token;

    return GlassCard(
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.bean, color: AppColors.primaryAction, size: 16),
              const SizedBox(width: 6),
              Text(
                'Token Cashu (${_qrParts.length} ${_qrParts.length == 1 ? "parte" : "partes"})',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            displayToken,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _qrParts.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == _currentPage ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == _currentPage
                ? AppColors.primaryAction
                : AppColors.textSecondary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Copiar
        Expanded(
          child: GestureDetector(
            onTap: () => _copyToken(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.copy, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Copiar',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.paddingMedium),
        // Compartir
        Expanded(
          child: GestureDetector(
            onTap: () => _shareToken(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.buttonGradient,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.share2, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Compartir',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarning() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertTriangle, color: AppColors.warning, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Guarda este token hasta que el receptor lo reclame. Si lo pierdes, perderas los fondos.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToken(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.token));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Token copiado al portapapeles'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _shareToken(BuildContext context) async {
    final memo = widget.memo != null && widget.memo!.isNotEmpty
        ? '\n"${widget.memo}"'
        : '';

    await SharePlus.instance.share(
      ShareParams(
        text: '${widget.amount} ${widget.unit}$memo\n\n${widget.token}',
        subject: 'Token Cashu - ${widget.amount} ${widget.unit}',
      ),
    );
  }

  void _goToHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
