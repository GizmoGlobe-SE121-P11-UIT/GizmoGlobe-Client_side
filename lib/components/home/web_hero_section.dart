import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

class WebHeroSection extends StatefulWidget {
  const WebHeroSection({super.key});

  @override
  State<WebHeroSection> createState() => _WebHeroSectionState();
}

class _WebHeroSectionState extends State<WebHeroSection>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceContainerLowest,
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 20
            : isTablet
                ? 40
                : 80,
        vertical: isMobile
            ? 40
            : isTablet
                ? 60
                : 80,
      ),
      child: Column(
        children: [
          // Main Hero Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Content
              Expanded(
                flex: 3,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // Sale Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primaryContainer,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flash_on,
                                size: 16,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                S.of(context).limitedTimeOffer,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          S.of(context).buildYourDreamPc,
                          style: TextStyle(
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.onSurface,
                                  Theme.of(context).colorScheme.primary,
                                ],
                              ).createShader(
                                  const Rect.fromLTWH(0, 0, 300, 100)),
                            fontSize: isMobile
                                ? 36
                                : isTablet
                                    ? 48
                                    : 72,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                            letterSpacing: isMobile ? -1 : -2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          S.of(context).premiumComponentsForPc,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                            fontSize: isMobile ? 14 : 18,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/products');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 24 : 40,
                                    vertical: isMobile ? 16 : 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      S.of(context).shopNow,
                                      style: TextStyle(
                                        fontSize: isMobile ? 14 : 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: isMobile ? 16 : 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(isMobile ? 10 : 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_shipping,
                                    size: isMobile ? 18 : 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    S.of(context).freeShipping,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: isMobile ? 12 : 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Only show stats on larger screens (>=900px)
              if (MediaQuery.of(context).size.width >= 900) ...[
                const SizedBox(width: 60),
                // Right Stats Cards
                Expanded(
                  flex: 2,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.3, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _slideController,
                        curve: Curves.easeOutCubic,
                      )),
                      child: Column(
                        children: [
                          _buildEnhancedStatCard(
                            context,
                            '100+',
                            S.of(context).productsTab,
                            S.of(context).latestPcComponents,
                            Icons.inventory_2_outlined,
                            0,
                          ),
                          const SizedBox(height: 20),
                          _buildEnhancedStatCard(
                            context,
                            '24/7',
                            S.of(context).support,
                            S.of(context).expertAssistance,
                            Icons.support_agent_outlined,
                            100,
                          ),
                          const SizedBox(height: 20),
                          _buildEnhancedStatCard(
                            context,
                            '2-Day',
                            S.of(context).shippingLabel,
                            S.of(context).fastAndReliable,
                            Icons.local_shipping_outlined,
                            200,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatCard(BuildContext context, String value,
      String label, String description, IconData icon, int delay) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ??
                    Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .shadow
                        .withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
