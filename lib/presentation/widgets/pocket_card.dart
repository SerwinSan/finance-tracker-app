/// Widget reusable untuk menampilkan satu pocket/dompet.
/// Menampilkan nama, tipe, saldo, dan ikon warna.
library;

import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../data/models/pocket_model.dart';
import '../../utils/formatters.dart';

class PocketCard extends StatelessWidget {
  final Pocket pocket;
  final VoidCallback? on_edit;
  final VoidCallback? on_delete;

  const PocketCard({
    super.key,
    required this.pocket,
    this.on_edit,
    this.on_delete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pocket_color = _parse_color(pocket.color);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: on_edit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // === Ikon Pocket ===
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: pocket_color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _get_icon(pocket.icon),
                  color: pocket_color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // === Info Pocket ===
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama pocket
                    Text(
                      pocket.name,
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Label tipe
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: pocket.is_entrusted
                                ? AppColors.warning.withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            pocket.is_entrusted ? 'Titipan' : 'Pribadi',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: pocket.is_entrusted
                                  ? AppColors.warning
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                        if (pocket.sync_status == 'pending') ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 14,
                            color: AppColors.warning,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // === Saldo ===
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.format_currency(pocket.balance, pocket.currency),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    pocket.currency,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 4),

              // === Menu ===
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') on_edit?.call();
                  if (value == 'delete') on_delete?.call();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded,
                            size: 18, color: AppColors.expense),
                        SizedBox(width: 8),
                        Text('Hapus',
                            style: TextStyle(color: AppColors.expense)),
                      ],
                    ),
                  ),
                ],
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Parse hex color string ke Color object.
  Color _parse_color(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  /// Map string icon ke IconData Material.
  IconData _get_icon(String icon_name) {
    const icon_map = {
      'wallet': Icons.account_balance_wallet_rounded,
      'savings': Icons.savings_rounded,
      'credit_card': Icons.credit_card_rounded,
      'attach_money': Icons.attach_money_rounded,
      'money': Icons.money_rounded,
      'people': Icons.people_rounded,
      'person': Icons.person_rounded,
      'handshake': Icons.handshake_rounded,
      'shopping_bag': Icons.shopping_bag_rounded,
      'business': Icons.business_rounded,
    };
    return icon_map[icon_name] ?? Icons.account_balance_wallet_rounded;
  }
}
