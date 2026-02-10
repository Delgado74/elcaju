import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../core/services/lnurl_service.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/numpad_widget.dart';
import '../../providers/wallet_provider.dart';

/// Pantalla para elegir monto en pagos LNURL/Lightning Address
class AmountScreen extends StatefulWidget {
  /// Destino (LNURL o Lightning Address)
  final String destination;

  /// Tipo de destino
  final LnInputType destinationType;

  /// Parámetros LNURL ya resueltos
  final LnurlPayParams params;

  const AmountScreen({
    super.key,
    required this.destination,
    required this.destinationType,
    required this.params,
  });

  @override
  State<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  String _amount = '';
  bool _isProcessing = false;
  String? _errorMessage;
  BigInt _availableBalance = BigInt.zero;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final walletProvider = context.read<WalletProvider>();
    final balance = await walletProvider.getBalance();
    if (mounted) {
      setState(() => _availableBalance = balance);
    }
  }

  BigInt get _amountSats {
    if (_amount.isEmpty) return BigInt.zero;
    return BigInt.tryParse(_amount) ?? BigInt.zero;
  }

  bool get _isAmountValid {
    if (_amountSats <= BigInt.zero) return false;
    return widget.params.isAmountValid(_amountSats);
  }

  bool get _canPay {
    return _isAmountValid && !_isProcessing && _amountSats <= _availableBalance;
  }

  String get _destinationLabel {
    return widget.destinationType == LnInputType.lightningAddress
        ? 'Lightning Address'
        : 'LNURL';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            l10n.send,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Column(
                    children: [
                      // Destino
                      _buildDestinationCard(),
                      const SizedBox(height: AppDimensions.paddingLarge),

                      // Display del monto
                      _buildAmountDisplay(),
                      const SizedBox(height: AppDimensions.paddingSmall),

                      // Rango permitido
                      _buildRangeInfo(),
                      const SizedBox(height: AppDimensions.paddingLarge),

                      // Teclado numérico
                      _buildNumpad(),

                      // Error message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppDimensions.paddingMedium),
                        _buildErrorMessage(),
                      ],
                    ],
                  ),
                ),
              ),

              // Balance y botón pagar
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Column(
                  children: [
                    _buildBalanceInfo(),
                    const SizedBox(height: AppDimensions.paddingMedium),
                    _buildPayButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationCard() {
    return GlassCard(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryAction.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.destinationType == LnInputType.lightningAddress
                  ? LucideIcons.atSign
                  : LucideIcons.link,
              color: AppColors.primaryAction,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _destinationLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.params.description ?? widget.destination,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    final displayAmount = _amount.isEmpty ? '0' : _amount;

    return Column(
      children: [
        Text(
          displayAmount,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: _isAmountValid || _amount.isEmpty
                ? Colors.white
                : AppColors.error,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'sats',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRangeInfo() {
    final min = widget.params.minSats;
    final max = widget.params.maxSats;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Min: $min  •  Max: $max sats',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textSecondary.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return NumpadWidget(
      value: _amount,
      onChanged: (newValue) {
        setState(() {
          _errorMessage = null;
          _amount = newValue;
        });
      },
    );
  }

  Widget _buildBalanceInfo() {
    final activeUnit = context.read<WalletProvider>().activeUnit;
    final unitLabel = UnitFormatter.getUnitLabel(activeUnit);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${L10n.of(context)!.available} ',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
        ),
        Text(
          '${UnitFormatter.formatBalance(_availableBalance, activeUnit)} $unitLabel',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryAction,
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    final l10n = L10n.of(context)!;

    return PrimaryButton(
      text: _isProcessing ? l10n.paying : l10n.payInvoice,
      onPressed: _canPay ? _processPayment : null,
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!_canPay) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // 1. Obtener invoice desde LNURL callback
      final invoiceResult = await LnurlService.fetchInvoice(
        widget.params.callback,
        _amountSats,
      );

      if (!mounted) return;

      // 2. Obtener quote del mint
      final walletProvider = context.read<WalletProvider>();
      final quote = await walletProvider.getMeltQuote(invoiceResult.invoice);

      if (!mounted) return;

      final total = quote.amount + quote.feeReserve;

      // 3. Verificar balance suficiente
      if (total > _availableBalance) {
        setState(() {
          _isProcessing = false;
          _errorMessage = L10n.of(context)!.insufficientBalance;
        });
        return;
      }

      // 4. Mostrar confirmación
      final confirmed = await _showConfirmation(quote.amount, quote.feeReserve, total);

      if (!confirmed || !mounted) {
        setState(() => _isProcessing = false);
        return;
      }

      // 5. Ejecutar pago
      final totalPaid = await walletProvider.melt(quote);

      if (!mounted) return;

      // 6. Mostrar éxito y volver
      final l10n = L10n.of(context)!;
      final activeUnit = walletProvider.activeUnit;
      final unitLabel = UnitFormatter.getUnitLabel(activeUnit);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.sent('-${UnitFormatter.formatBalance(totalPaid, activeUnit)}', unitLabel)),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );

      // Volver a home (pop dos veces: AmountScreen y MeltScreen)
      Navigator.pop(context);
      Navigator.pop(context);

    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = _parseError(e.toString());
        });
      }
    }
  }

  String _parseError(String error) {
    final lower = error.toLowerCase();
    final l10n = L10n.of(context)!;

    if (lower.contains('insufficient') || lower.contains('not enough')) {
      return l10n.insufficientBalance;
    } else if (lower.contains('expired')) {
      return l10n.invoiceExpired;
    } else if (lower.contains('min') || lower.contains('max')) {
      return 'Monto fuera del rango permitido';
    }

    return error.replaceFirst('Exception: ', '');
  }

  Future<bool> _showConfirmation(BigInt amount, BigInt fee, BigInt total) async {
    final activeUnit = context.read<WalletProvider>().activeUnit;
    final unitLabel = UnitFormatter.getUnitLabel(activeUnit);

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.deepVoidPurple,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Icono
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryAction.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.zap,
                color: AppColors.primaryAction,
                size: 32,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            // Título
            Text(
              L10n.of(context)!.confirmPayment,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),

            // Monto
            Text(
              '${UnitFormatter.formatBalance(amount, activeUnit)} $unitLabel',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '+ ~${UnitFormatter.formatBalance(fee, activeUnit)} $unitLabel fee',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              'Total: ${UnitFormatter.formatBalance(total, activeUnit)} $unitLabel',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryAction,
              ),
            ),

            const SizedBox(height: AppDimensions.paddingLarge),

            // Botones
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          L10n.of(context)!.cancel,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                Expanded(
                  child: PrimaryButton(
                    text: L10n.of(context)!.pay,
                    onPressed: () => Navigator.pop(context, true),
                    height: 52,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.paddingSmall),
          ],
        ),
      ),
    );

    return result ?? false;
  }
}
