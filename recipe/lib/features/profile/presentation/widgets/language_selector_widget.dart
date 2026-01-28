import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../providers/locale_provider.dart';
import '../../../../providers/profile_provider.dart';

/// Widget for selecting app language
class LanguageSelectorWidget extends ConsumerWidget {
  final bool enabled;

  const LanguageSelectorWidget({
    super.key,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(appLocaleProvider);
    final profileAsync = ref.watch(profileStreamProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.language_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n?.language ?? 'Language',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!enabled)
              Text(
                l10n?.languageDescription ?? 'Select your preferred language for the app interface',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            if (enabled) ...[
              _buildLanguageOption(
                context,
                ref,
                'en',
                'English',
                'Inglés',
                currentLocale,
                Icons.language,
              ),
              const SizedBox(height: 12),
              _buildLanguageOption(
                context,
                ref,
                'es',
                'Español',
                'Español',
                currentLocale,
                Icons.language,
              ),
              const SizedBox(height: 8),
              Text(
                l10n?.languageNote ?? 'Note: User-generated content (recipes, ingredients) will not be translated.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref,
    String languageCode,
    String englishName,
    String spanishName,
    Locale currentLocale,
    IconData icon,
  ) {
    final l10n = AppLocalizations.of(context);
    final isSelected = currentLocale.languageCode == languageCode;
    final displayName = languageCode == 'en' ? englishName : spanishName;

    return InkWell(
      onTap: enabled
          ? () async {
              try {
                final localeNotifier = ref.read(appLocaleProvider.notifier);
                await localeNotifier.setLocalePreference(languageCode);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n?.languageChanged ?? 'Language changed to $displayName',
                      ),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n?.languageChangeError ?? 'Error changing language: ${e.toString()}',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.gray200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
