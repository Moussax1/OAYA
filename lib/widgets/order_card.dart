import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme.dart';
import '../utils/currency.dart';

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderCard({super.key, required this.order});

  static const _statusColors = {
    'pending':    {'bg': Color(0xFFFEF9C3), 'text': Color(0xFF854D0E), 'label': 'En attente'},
    'processing': {'bg': Color(0xFFDBEAFE), 'text': Color(0xFF1D4ED8), 'label': 'En traitement'},
    'shipped':    {'bg': Color(0xFFE0F2FE), 'text': Color(0xFF0369A1), 'label': 'Expédié'},
    'delivered':  {'bg': Color(0xFFDCFCE7), 'text': Color(0xFF15803D), 'label': 'Livré'},
    'cancelled':  {'bg': Color(0xFFFEE2E2), 'text': Color(0xFFB91C1C), 'label': 'Annulé'},
  };

  @override
  Widget build(BuildContext context) {
    final status = _statusColors[order['status']] ?? _statusColors['pending']!;
    final items = order['order_items'] as List? ?? [];
    final date = DateTime.tryParse(order['created_at'] ?? '');
    final dateStr = date != null ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}' : '';
    final firstImage = items.isNotEmpty ? (items[0]['product']?['image_url'] as String?) : null;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), boxShadow: AppShadow.card),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(width: 52, height: 52,
            child: firstImage != null ? CachedNetworkImage(imageUrl: firstImage, fit: BoxFit.cover)
                : Container(color: AppColors.border, child: const Center(child: Icon(FeatherIcons.package, size: 20, color: AppColors.textMuted)))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Commande #${order['id'].toString().substring(0, 8).toUpperCase()}',
              style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text('$dateStr · ${items.length} article${items.length > 1 ? 's' : ''}',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
          Text(formatCurrency(order['total_amount'] ?? order['total']),
              style: GoogleFonts.inter(fontSize: AppFontSize.sm, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: status['bg'] as Color, borderRadius: BorderRadius.circular(AppRadius.full)),
          child: Text(status['label'] as String, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: status['text'] as Color)),
        ),
      ]),
    );
  }
}
