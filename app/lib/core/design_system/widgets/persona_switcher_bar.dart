import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/mock_persona.dart';
import '../../providers/persona_provider.dart';
import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';

class PersonaSwitcherBar extends ConsumerWidget {
  const PersonaSwitcherBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePersona = ref.watch(currentPersonaProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              color: AppColors.defenseGreen.withValues(alpha: 0.15),
              borderRadius: AppSpacing.borderSm,
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 16.0,
              color: AppColors.defenseGreen,
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ACTIVE EVALUATION PERSONA',
                  style: AppTypography.labelUppercase.copyWith(
                    fontSize: 9.0,
                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                  ),
                ),
                Text(
                  '${activePersona.name} • ${activePersona.title}',
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 12.0,
                    color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6.0),
          PopupMenuButton<MockPersona>(
            initialValue: activePersona,
            onSelected: (persona) {
              ref.read(currentPersonaProvider.notifier).selectPersona(persona);
            },
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderMd,
              side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            itemBuilder: (context) {
              return MockPersona.all.map((p) {
                final isSelected = p.id == activePersona.id;
                return PopupMenuItem<MockPersona>(
                  value: p,
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 16.0,
                        color: isSelected ? AppColors.defenseGreen : AppColors.darkMutedText,
                      ),
                      const SizedBox(width: 8.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 12.5,
                              color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                            ),
                          ),
                          Text(
                            p.title,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 10.5,
                              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevated : AppColors.lightElevated,
                borderRadius: AppSpacing.borderSm,
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Switch Role',
                    style: AppTypography.labelBadge.copyWith(
                      fontSize: 11.0,
                      color: AppColors.defenseGreen,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 16.0,
                    color: AppColors.defenseGreen,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

