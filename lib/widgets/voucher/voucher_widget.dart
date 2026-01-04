import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/functions/helper.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import '../../data/database/database.dart';
import '../../objects/voucher_related/end_time_interface.dart';
import '../../objects/voucher_related/limited_interface.dart';
import '../../objects/voucher_related/percentage_interface.dart';
import '../../objects/voucher_related/voucher.dart';

class VoucherWidget extends StatelessWidget {
  final Voucher voucher;
  final VoidCallback onPressed;

  const VoucherWidget({
    super.key,
    required this.voucher,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      voucher.voucherName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getDiscountText(context),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 16,
                          color: colorScheme.tertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${S.of(context).minimumPurchase}: ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          Helper.toCurrencyFormat(voucher.minimumPurchase),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.tertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Bottom row with expiry and usage info
                    Row(
                      children: [
                        Expanded(child: _buildExpiryInfo(context)),
                        if (voucher.isLimited) ...[
                          const SizedBox(width: 16),
                          _buildUsageInfo(context),
                        ],
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
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 16,
          color: isUrgent
              ? colorScheme.error
              : colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Text(
          daysLeft <= 0
              ? S.of(context).expired
              : S.of(context).expiresIn(daysLeft),
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
    try {
      final vid = (voucher.voucherID ?? '').trim();
      final ownedUses = Database().ownedVoucherUses[vid];
      if (ownedUses != null) {
        return Row(
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 16,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              '$ownedUses/${voucher.maxUsagePerPerson}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ),
          ],
        );
      }
    } catch (_) {}

    // Fallback to showing remaining/maximum when no owned record exists
    return Row(
      children: [
        Icon(
          Icons.people_outline,
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
}

// Custom clipper to create voucher-like shape with notches
class _VoucherClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const notchRadius = 8.0;
    const notchPosition = 0.7; // Position of notch from top (70%)
    // Start from top-left
    path.moveTo(0, 0);
    // Top edge
    path.lineTo(size.width, 0);
    // Right edge to notch
    path.lineTo(size.width, size.height * notchPosition - notchRadius);
    // Right notch
    path.arcToPoint(
      Offset(size.width, size.height * notchPosition + notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    // Right edge from notch to bottom
    path.lineTo(size.width, size.height);
    // Bottom edge
    path.lineTo(0, size.height);
    // Left edge from bottom to notch
    path.lineTo(0, size.height * notchPosition + notchRadius);
    // Left notch
    path.arcToPoint(
      Offset(0, size.height * notchPosition - notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    // Left edge from notch to top
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
