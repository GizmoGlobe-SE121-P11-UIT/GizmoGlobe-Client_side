import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/enums/product_related/category_enum.dart';

class WebSidebar extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onToggle;

  const WebSidebar({
    super.key,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  State<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends State<WebSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _widthAnimation = Tween<double>(begin: 0, end: 280).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isOpen) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(WebSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(CategoryEnum category) {
    switch (category) {
      case CategoryEnum.ram:
        return Icons.memory;
      case CategoryEnum.cpu:
        return Icons.developer_board;
      case CategoryEnum.psu:
        return Icons.power;
      case CategoryEnum.gpu:
        return Icons.videocam;
      case CategoryEnum.drive:
        return Icons.storage;
      case CategoryEnum.mainboard:
        return Icons.dashboard;
      default:
        return Icons.devices;
    }
  }

  String _getCategoryLabel(BuildContext context, CategoryEnum category) {
    switch (category) {
      case CategoryEnum.ram:
        return S.of(context).ram;
      case CategoryEnum.cpu:
        return S.of(context).cpu;
      case CategoryEnum.psu:
        return S.of(context).psu;
      case CategoryEnum.gpu:
        return S.of(context).gpu;
      case CategoryEnum.drive:
        return S.of(context).drive;
      case CategoryEnum.mainboard:
        return S.of(context).mainboard;
      default:
        return S.of(context).all;
    }
  }

  String _getCategoryRoute(CategoryEnum category) {
    if (category == CategoryEnum.empty) {
      return '/products';
    }
    return '/products/${category.name.toLowerCase()}';
  }

  void _navigateToCategory(BuildContext context, CategoryEnum category) {
    final route = _getCategoryRoute(category);
    widget.onToggle(); // Close sidebar
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return SizedBox(
          width: _widthAnimation.value,
          child: Container(
            height: screenHeight,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: _widthAnimation.value > 100
                ? ClipRect(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: ClipRect(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.category,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      S.of(context).productsTab,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    iconSize: 20,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: widget.onToggle,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Navigation items
                          _buildNavItem(
                            context,
                            icon: Icons.apps,
                            label: S.of(context).all,
                            onTap: () => _navigateToCategory(
                                context, CategoryEnum.empty),
                            isAll: true,
                          ),
                          _buildNavItem(
                            context,
                            icon: Icons.build,
                            label: 'Build PC',
                            onTap: () {
                              widget.onToggle();
                              Navigator.pushNamed(context, '/builder');
                            },
                          ),
                          ...CategoryEnum.getValues().map((category) {
                            return _buildNavItem(
                              context,
                              icon: _getCategoryIcon(category),
                              label: _getCategoryLabel(context, category),
                              onTap: () =>
                                  _navigateToCategory(context, category),
                            );
                          }),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isAll = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ClipRect(
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isAll ? FontWeight.w600 : FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
