import 'package:flutter/material.dart';

import '../../functions/converter.dart';
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
                  colorScheme.primaryContainer,
                  colorScheme.primaryContainer.withValues(alpha: 0.8),
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
                    // Header with voucher name and status
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
                        _buildStatusChip(context),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Discount information
                    Text(
                      _getDiscountText(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
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
                          'Min. purchase:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          Converter.formatDouble(voucher.minimumPurchase), 
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

  Widget _buildStatusChip(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    String statusText;
    Color backgroundColor;
    Color textColor;
    if (!voucher.isEnabled) {
      statusText = 'Disabled';
      backgroundColor = colorScheme.error.withValues(alpha: 0.2);
      textColor = colorScheme.error;
    } else if (voucher.isLimited &&
        (voucher as LimitedInterface).usageLeft <= 0) {
      statusText = 'Ran out';
      backgroundColor = colorScheme.error.withValues(alpha: 0.2);
      textColor = colorScheme.error;
    } else if (voucher.hasEndTime &&
        voucher is EndTimeInterface &&
        (voucher as EndTimeInterface).endTime.isBefore(DateTime.now())) {
      statusText = 'Expired';
      backgroundColor = colorScheme.error.withValues(alpha: 0.2);
      textColor = colorScheme.error;
    } else {
      statusText = 'Available';
      backgroundColor = colorScheme.tertiary.withValues(alpha: 0.2);
      textColor = colorScheme.tertiary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
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
            'No expiry',
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
              ? 'Expired'
              : 'Expires in $daysLeft day${daysLeft == 1 ? '' : 's'}',
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

  String _getDiscountText() {
    if (voucher.isPercentage && voucher is PercentageInterface) {
      final percentage = voucher as PercentageInterface;
      return 'Discount ${Converter.formatDouble(voucher.discountValue)}% maximum discount ${Converter.formatDouble(percentage.maximumDiscountValue)}';
    } else {
      return 'Discount ${Converter.formatDouble(voucher.discountValue)}';
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
