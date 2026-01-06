import 'package:flutter/material.dart';
import '../../generated/l10n.dart';

class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive padding: smaller on mobile, larger on desktop
    final horizontalPadding = screenWidth < 600
        ? 16.0
        : screenWidth < 900
            ? 32.0
            : 80.0;

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Horizontal layout: Logo/tagline on left, features on right
          LayoutBuilder(
            builder: (context, constraints) {
              // Use Column layout for mobile, Row for larger screens
              if (screenWidth < 600) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo and tagline
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.computer,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 24),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            s.appTitle,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.footerTagline,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              }

              // Desktop layout
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Logo and tagline
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.computer,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  size: 24),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                s.appTitle,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.footerTagline,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right: Features in horizontal row (only on larger screens)
                  if (screenWidth >= 900) ...[
                    const SizedBox(width: 48),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          _buildFeatureBadge(
                            context,
                            Icons.local_shipping_outlined,
                            s.freeShipping,
                            s.onAllOrders,
                          ),
                          const SizedBox(width: 12),
                          _buildFeatureBadge(
                            context,
                            Icons.verified_user_outlined,
                            s.oneYearWarranty,
                            s.onAllProducts,
                          ),
                          const SizedBox(width: 12),
                          _buildFeatureBadge(
                            context,
                            Icons.support_agent_outlined,
                            s.support247,
                            s.expertAssistance,
                          ),
                          const SizedBox(width: 12),
                          _buildFeatureBadge(
                            context,
                            Icons.lock_outline,
                            s.securePayment,
                            s.sslEncrypted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Divider(color: Theme.of(context).dividerColor),
          const SizedBox(height: 16),
          Text(
            s.copyrightText,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ??
              Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
