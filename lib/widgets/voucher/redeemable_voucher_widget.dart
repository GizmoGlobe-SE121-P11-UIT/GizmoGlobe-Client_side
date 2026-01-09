import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/functions/helper.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/enums/voucher_related/distribution_type.dart';
import '../../objects/voucher_related/end_time_interface.dart';
import '../../objects/voucher_related/limited_interface.dart';
import '../../objects/voucher_related/percentage_interface.dart';
import '../../objects/voucher_related/voucher.dart';
import '../../data/database/database.dart';

class RedeemableVoucherWidget extends StatelessWidget {
  final Voucher voucher;
  final VoidCallback onPressed;
  final VoidCallback? onRedeem;

  const RedeemableVoucherWidget({
    super.key,
    required this.voucher,
    required this.onPressed,
    this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final int? redeemPrice = voucher.redeemPrice;
    final bool canRedeem =
        redeemPrice == null || Database().loyalPoint >= redeemPrice;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipPath(
              clipper: _VoucherClipper(),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                voucher.voucherName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            // status badge removed per request; keep layout stable
                            const SizedBox.shrink(),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Discount information
                        Text(
                          _getDiscountText(context),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Minimum purchase
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 16,
                              color: colorScheme.tertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${S.of(context).minimumPurchase}:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              Helper.toCurrencyFormat(voucher.minimumPurchase),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.tertiary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildExpiryInfo(context)),
                            if (voucher.isLimited) ...[
                              const SizedBox(width: 16),
                              _buildUsageInfo(context),
                            ],
                            if (voucher.distributionType ==
                                    DistributionType.rewards &&
                                (voucher.redeemPrice != null)) ...[
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed:
                                    canRedeem ? (onRedeem ?? onPressed) : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.surface,
                                  foregroundColor: colorScheme.onSurface,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      S.of(context).redeemWithPoints(
                                          voucher.redeemPrice!),
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 18,
                                      color: colorScheme.onSurface,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpiryInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (!voucher.hasEndTime) {
      return Row(
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: colorScheme.tertiary,
          ),
          const SizedBox(width: 4),
          Text(
            S.of(context).noExpiry,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.tertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    if (voucher is! EndTimeInterface) return const SizedBox();
    final endTime = (voucher as EndTimeInterface).endTime;
    final now = DateTime.now();
    final daysLeft = endTime.isBefore(now) ? 0 : endTime.difference(now).inDays;
    final isUrgent = daysLeft <= 3;

    if (daysLeft <= 0) {
      return Row(
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: colorScheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            S.of(context).expired,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final start = voucher.startTime;
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 16,
          color: isUrgent
              ? colorScheme.error
              : colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 6),
        Text(
          '${_formatDate(start)} — ${_formatDate(endTime)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isUrgent
                ? colorScheme.error
                : colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            fontWeight: isUrgent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildUsageInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final limited = voucher as LimitedInterface;
    return Row(
      children: [
        Icon(
          Icons.card_giftcard_outlined,
          size: 16,
          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Text(
          '${limited.usageLeft}/${limited.maximumUsage}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  String _getDiscountText(BuildContext context) {
    if (voucher.isPercentage && voucher is PercentageInterface) {
      final percentage = voucher as PercentageInterface;
      return '${S.of(context).discount} ${voucher.discountValue}% ${S.of(context).maximumDiscount} ${Helper.toCurrencyFormat(percentage.maximumDiscountValue)}';
    } else {
      return '${S.of(context).discount} ${Helper.toCurrencyFormat(voucher.discountValue)}';
    }
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}

// Custom clipper unchanged
class _VoucherClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const notchRadius = 8.0;
    const notchPosition = 0.7;
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * notchPosition - notchRadius);
    path.arcToPoint(
      Offset(size.width, size.height * notchPosition + notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, size.height * notchPosition + notchRadius);
    path.arcToPoint(
      Offset(0, size.height * notchPosition - notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
