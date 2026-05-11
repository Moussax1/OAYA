import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/theme.dart';
import '../../services/order_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await OrderService.getOrders();
      if (!mounted) return;
      setState(() {
        _orders = data;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(String orderId, String status) async {
    try {
      await OrderService.updateOrderStatus(orderId, status);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const statuses = ['pending', 'paid', 'shipped', 'delivered', 'cancelled'];
    final pendingCount = _orders.where((order) => (order['status']?.toString() ?? 'pending') == 'pending').length;
    final shippedCount = _orders.where((order) => order['status']?.toString() == 'shipped').length;
    final deliveredCount = _orders.where((order) => order['status']?.toString() == 'delivered').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(AppSpacing.base),
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primarySoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadow.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: const Icon(FeatherIcons.arrowLeft, size: 18, color: Colors.white),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _load,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(FeatherIcons.refreshCw, size: 18, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Gestion des Commandes', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Suivez les ventes et ajustez le statut des commandes avec une interface sobre et premium.', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: Colors.white70, height: 1.4)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statTile(label: 'En attente', value: '$pendingCount'),
                      const SizedBox(width: 12),
                      _statTile(label: 'Expédiées', value: '$shippedCount'),
                      const SizedBox(width: 12),
                      _statTile(label: 'Livrées', value: '$deliveredCount'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
                          ),
                        )
                      : _orders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(FeatherIcons.package, size: 48, color: AppColors.textMuted),
                                  const SizedBox(height: 12),
                                  Text('Aucune commande trouvée', style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.xl, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.xl),
                              itemCount: _orders.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (_, index) {
                                final order = _orders[index];
                                final currentStatus = order['status']?.toString() ?? 'pending';
                                final statusColor = _statusColor(currentStatus);

                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(AppRadius.xl),
                                    boxShadow: AppShadow.card,
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 62,
                                            height: 62,
                                            decoration: BoxDecoration(
                                              color: AppColors.accentLight,
                                              borderRadius: BorderRadius.circular(AppRadius.lg),
                                            ),
                                            child: const Icon(FeatherIcons.package, color: AppColors.primary),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text('Commande #${order['id'].toString().substring(0, 8)}', style: GoogleFonts.inter(fontSize: AppFontSize.base, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                                    ),
                                                    _statusChip(currentStatus, statusColor),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text('Client: ${order['user_id']?.toString() ?? 'N/A'}', style: GoogleFonts.inter(fontSize: AppFontSize.sm, color: AppColors.textMuted)),
                                                const SizedBox(height: 10),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    _metaPill('Total', '${order['total_amount'] ?? 0}'),
                                                    _metaPill('Livraison', '${order['shipping'] ?? 0}'),
                                                    _metaPill('Paiement', order['payment_method']?.toString() ?? 'cod'),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      DropdownButtonFormField<String>(
                                        value: currentStatus,
                                        decoration: const InputDecoration(labelText: 'Statut de la commande'),
                                        items: statuses
                                            .map((status) => DropdownMenuItem(value: status, child: Text(status.toUpperCase())))
                                            .toList(),
                                        onChanged: (value) {
                                          if (value != null && value != currentStatus) {
                                            _updateStatus(order['id'].toString(), value);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile({required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.playfairDisplay(fontSize: AppFontSize.lg, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _metaPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text('$label: $value', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.success;
      case 'shipped':
        return const Color(0xFF0EA5E9);
      case 'delivered':
        return const Color(0xFF16A34A);
      case 'cancelled':
        return AppColors.error;
      case 'pending':
      default:
        return AppColors.warning;
    }
  }
}
