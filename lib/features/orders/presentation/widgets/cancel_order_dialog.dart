import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../data/models/order_models.dart';
import '../../data/repositories/order_repository.dart';

/// Provider for fetching order cancel reasons
final orderCancelReasonsProvider =
    FutureProvider.family<List<ApiCancelReason>, int>((ref, outletId) async {
      final repository = ref.watch(orderRepositoryProvider);
      final result = await repository.getOrderCancelReasons(outletId);
      return result.when(
        success: (data, _) => data,
        failure: (_, __, ___) => <ApiCancelReason>[],
      );
    });

/// Result of a cancel order dialog
class CancelOrderResult {
  final String reason;
  final int? reasonId;

  const CancelOrderResult({required this.reason, this.reasonId});
}

/// Shows cancel order dialog/bottom sheet based on device type.
/// Returns [CancelOrderResult] on confirm, null on dismiss.
Future<CancelOrderResult?> showCancelOrderDialog(
  BuildContext context, {
  required String orderNumber,
  required int outletId,
  required double orderTotal,
  required int itemCount,
}) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isMobile = screenWidth < 600;

  if (isMobile) {
    return showModalBottomSheet<CancelOrderResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CancelOrderSheet(
        orderNumber: orderNumber,
        outletId: outletId,
        orderTotal: orderTotal,
        itemCount: itemCount,
      ),
    );
  } else {
    return showDialog<CancelOrderResult>(
      context: context,
      builder: (context) => _CancelOrderDialog(
        orderNumber: orderNumber,
        outletId: outletId,
        orderTotal: orderTotal,
        itemCount: itemCount,
      ),
    );
  }
}

/// Cancel Order Bottom Sheet for mobile
class _CancelOrderSheet extends ConsumerWidget {
  final String orderNumber;
  final int outletId;
  final double orderTotal;
  final int itemCount;

  const _CancelOrderSheet({
    required this.orderNumber,
    required this.outletId,
    required this.orderTotal,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(
            child: _CancelOrderContent(
              orderNumber: orderNumber,
              outletId: outletId,
              orderTotal: orderTotal,
              itemCount: itemCount,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cancel Order Dialog for tablet/desktop
class _CancelOrderDialog extends ConsumerWidget {
  final String orderNumber;
  final int outletId;
  final double orderTotal;
  final int itemCount;

  const _CancelOrderDialog({
    required this.orderNumber,
    required this.outletId,
    required this.orderTotal,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Container(
        width: 480,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.error, Color(0xFFD32F2F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cancel_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Cancel Order',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child:
                            Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: _CancelOrderContent(
                orderNumber: orderNumber,
                outletId: outletId,
                orderTotal: orderTotal,
                itemCount: itemCount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Main content widget for cancel order
class _CancelOrderContent extends ConsumerStatefulWidget {
  final String orderNumber;
  final int outletId;
  final double orderTotal;
  final int itemCount;

  const _CancelOrderContent({
    required this.orderNumber,
    required this.outletId,
    required this.orderTotal,
    required this.itemCount,
  });

  @override
  ConsumerState<_CancelOrderContent> createState() =>
      _CancelOrderContentState();
}

class _CancelOrderContentState extends ConsumerState<_CancelOrderContent> {
  final _manualReasonController = TextEditingController();
  int? _selectedReasonId;
  String? _selectedReasonText;
  bool _useManualReason = false;

  @override
  void dispose() {
    _manualReasonController.dispose();
    super.dispose();
  }

  String? get _effectiveReason {
    if (_useManualReason) {
      final text = _manualReasonController.text.trim();
      return text.isEmpty ? null : text;
    }
    return _selectedReasonText;
  }

  bool get _canConfirm =>
      _effectiveReason != null && _effectiveReason!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final reasonsAsync =
        ref.watch(orderCancelReasonsProvider(widget.outletId));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order info
                _buildOrderInfo(),
                const SizedBox(height: 16),

                // Warning
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This will cancel the entire order including all items and KOTs. This action cannot be undone.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Cancel reasons
                const Text(
                  'Select Reason *',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),

                reasonsAsync.when(
                  data: (reasons) => _buildReasonsList(reasons),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: LoadingIndicator(size: LoadingSize.small),
                    ),
                  ),
                  error: (_, __) => _buildManualReasonOnly(),
                ),

                // Manual reason input
                if (_useManualReason) ...[
                  const SizedBox(height: 12),
                  _buildManualReasonInput(),
                ],
              ],
            ),
          ),
        ),
        // Confirm button
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top:
                  BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canConfirm
                  ? () {
                      Navigator.of(context).pop(
                        CancelOrderResult(
                          reason: _effectiveReason!,
                          reasonId:
                              _useManualReason ? null : _selectedReasonId,
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.cancel, size: 18),
              label: const Text('CANCEL ORDER'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.error.withValues(alpha: 0.3),
                disabledForegroundColor: Colors.white60,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.receipt_long,
                size: 22,
                color: AppColors.error,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${widget.orderNumber}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.itemCount} items',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${widget.orderTotal.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonsList(List<ApiCancelReason> reasons) {
    if (reasons.isEmpty) return _buildManualReasonOnly();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Predefined reasons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: reasons.map((reason) {
            final isSelected =
                !_useManualReason && _selectedReasonId == reason.id;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedReasonId = reason.id;
                  _selectedReasonText = reason.reason;
                  _useManualReason = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.error : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppColors.error,
                        ),
                      ),
                    Flexible(
                      child: Text(
                        reason.reason,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? AppColors.error
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Manual reason toggle
        GestureDetector(
          onTap: () {
            setState(() {
              _useManualReason = true;
              _selectedReasonId = null;
              _selectedReasonText = null;
            });
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _useManualReason
                  ? AppColors.info.withValues(alpha: 0.1)
                  : AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    _useManualReason ? AppColors.info : AppColors.border,
                width: _useManualReason ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_note,
                  size: 18,
                  color: _useManualReason
                      ? AppColors.info
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Write custom reason',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _useManualReason
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: _useManualReason
                        ? AppColors.info
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualReasonOnly() {
    // When no reasons from API, go directly to manual
    if (!_useManualReason) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _useManualReason = true);
      });
    }
    return const SizedBox.shrink();
  }

  Widget _buildManualReasonInput() {
    return TextField(
      controller: _manualReasonController,
      decoration: InputDecoration(
        labelText: 'Reason',
        hintText: 'Enter cancellation reason...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        prefixIcon: const Icon(Icons.notes, size: 20),
      ),
      maxLines: 2,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      onChanged: (_) => setState(() {}),
    );
  }
}
