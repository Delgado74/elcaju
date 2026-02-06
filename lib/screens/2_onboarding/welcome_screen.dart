import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/secondary_button.dart';
import 'create_wallet_screen.dart';
import 'restore_wallet_screen.dart';

/// Pantalla de bienvenida - Onboarding
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Logo / Mascota
                Image.asset(
                  'assets/img/elcajucubano.png',
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: AppDimensions.paddingLarge),

                // Título
                Text(
                  l10n.welcomeTitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.paddingSmall),

                // Subtítulo
                Text(
                  l10n.welcomeSubtitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 2),

                // Botón crear wallet
                PrimaryButton(
                  text: l10n.createWallet,
                  icon: Icons.add_circle_outline,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateWalletScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.paddingMedium),

                // Botón restaurar wallet
                SecondaryButton(
                  text: l10n.restoreWallet,
                  icon: Icons.restore,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RestoreWalletScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppDimensions.paddingXLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
