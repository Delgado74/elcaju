import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:elcaju/generated/app_localizations.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/secondary_button.dart';
import 'create_wallet_screen.dart';
import 'restore_wallet_screen.dart';
import '../8_settings/language_screen.dart';

/// Pantalla de bienvenida - Onboarding
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // Mapa de códigos de idioma a banderas
  static const Map<String, String> _languageFlags = {
    'es': '🇪🇸',
    'en': '🇬🇧',
    'pt': '🇵🇹',
    'fr': '🇫🇷',
    'it': '🇮🇹',
    'de': '🇩🇪',
    'ru': '🇷🇺',
    'zh': '🇨🇳',
    'ja': '🇯🇵',
    'ko': '🇰🇷',
    'sw': '🇰🇪',
  };

  String _getFlag(String locale) {
    return _languageFlags[locale] ?? '🇪🇸';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;

    final settingsProvider = context.watch<SettingsProvider>();
    final currentLocale = settingsProvider.locale;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              children: [
                // Selector de idioma en esquina superior derecha
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LanguageScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getFlag(currentLocale),
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            currentLocale.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            LucideIcons.chevronRight,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

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
                  icon: LucideIcons.plusCircle,
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
                  icon: LucideIcons.rotateCcw,
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
