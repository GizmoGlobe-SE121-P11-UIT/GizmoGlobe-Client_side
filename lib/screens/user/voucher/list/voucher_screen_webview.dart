import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/screens/user/voucher/voucher_detail/voucher_detail_webview.dart';
import 'package:gizmoglobe_client/services/web_guest_service.dart';
import 'package:gizmoglobe_client/components/general/snackbar_service.dart';
import 'package:gizmoglobe_client/screens/authentication/sign_in_screen/sign_in_webview.dart';
import 'package:gizmoglobe_client/screens/authentication/sign_in_screen/sign_in_cubit.dart';
import 'package:gizmoglobe_client/components/general/web_header.dart';

import '../../../../enums/processing/process_state_enum.dart';
import '../../../../functions/helper.dart';
import '../../../../objects/voucher_related/voucher.dart';
import '../../../../widgets/dialog/information_dialog.dart';
import 'voucher_screen_cubit.dart';
import 'voucher_screen_state.dart';

class VoucherScreenWebView extends StatefulWidget {
  const VoucherScreenWebView({super.key});

  static Widget newInstance() => BlocProvider(
        create: (context) => VoucherScreenCubit(),
        child: const VoucherScreenWebView(),
      );

  static Widget withCubit(VoucherScreenCubit cubit) => BlocProvider.value(
        value: cubit,
        child: const VoucherScreenWebView(),
      );

  @override
  State<VoucherScreenWebView> createState() => _VoucherScreenWebViewState();
}

class _VoucherScreenWebViewState extends State<VoucherScreenWebView>
    with SingleTickerProviderStateMixin {
  VoucherScreenCubit get cubit => context.read<VoucherScreenCubit>();
  final WebGuestService _webGuestService = WebGuestService();
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    cubit.toLoading();
    Future.microtask(() async {
      await cubit.initialize();
    });
    tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: 0,
    );
    _checkGuestUser();
  }

  Future<void> _checkGuestUser() async {
    if (kIsWeb) {
      final isGuest = await _webGuestService.isCurrentUserGuest();
      if (isGuest) {
        // Show snackbar and sign-in modal for guest users
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final overlayState = Navigator.of(context).overlay!;
          SnackbarService.showGuestRestrictionAboveOverlay(
            overlayState,
            context: context,
            actionType: 'vouchers',
          );
          final signInCubit = SignInCubit();
          await showSignInModalWithCubit(context, signInCubit);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Web Header (only on web)
          if (kIsWeb) const WebHeader(),
          // Main Content
          Expanded(
            child: BlocConsumer<VoucherScreenCubit, VoucherScreenState>(
              listener: (context, state) {
                if (state.processState == ProcessState.success) {
                  // Only show dialog if there's a dialog message and name
                  if (state.dialogMessage.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (context) => InformationDialog(
                        title: state.dialogName.description,
                        content: state.dialogMessage,
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      VoucherScreenWebView.newInstance()));
                        },
                      ),
                    );
                  }
                }
              },
              builder: (context, state) {
                // Show loading indicator while data is being fetched
                if (state.processState == ProcessState.loading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Show error message if the initialization failed
                if (state.processState == ProcessState.failure) {
                  return _buildErrorState(state);
                }

                // Show the content when data is loaded
                return _buildWebLayout(state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(VoucherScreenState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).error,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              state.dialogMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                cubit.toLoading();
                Future.microtask(() async {
                  await cubit.initialize();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                S.of(context).retry,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebLayout(VoucherScreenState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header Section
          _buildHeader(),
          const SizedBox(height: 24),
          // Tab Bar
          _buildTabBar(),
          const SizedBox(height: 16),
          // Tab Content
          Expanded(
            child: _buildTabContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Text(
        S.of(context).voucher,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTabBar() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: TabBar(
        controller: tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: Theme.of(context).colorScheme.primary,
        indicatorWeight: 3,
        labelPadding: EdgeInsets.zero,
        tabAlignment: TabAlignment.fill,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Center(
              child: Text(
                S.of(context).ongoing,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Tab(
            child: Center(
              child: Text(
                S.of(context).upcoming,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(VoucherScreenState state) {
    return TabBarView(
      controller: tabController,
      children: [
        // Tab 1: Ongoing voucher list
        _buildVoucherList(
          state.ongoingList,
          S.of(context).noVouchersAvailable,
          Icons.play_circle_outline,
        ),
        // Tab 2: Upcoming voucher list
        _buildVoucherList(
          state.upcomingList,
          S.of(context).noVouchersAvailable,
          Icons.schedule,
        ),
      ],
    );
  }

  Widget _buildVoucherList(
      List<Voucher> vouchers, String emptyMessage, IconData emptyIcon) {
    if (vouchers.isEmpty) {
      return _buildEmptyState(emptyMessage, emptyIcon);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid layout
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
        final childAspectRatio = _getChildAspectRatio(constraints.maxWidth);

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: vouchers.length,
          itemBuilder: (context, index) {
            final voucher = vouchers[index];
            return _buildVoucherCard(voucher);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(Voucher voucher) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _onVoucherTap(context, voucher),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Voucher Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.local_offer,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .tertiary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      voucher.isPercentage
                          ? '${voucher.discountValue}%'
                          : Helper.toCurrencyFormat(voucher.discountValue),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Voucher Name
              Text(
                voucher.voucherName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Minimum Purchase
              Text(
                '${S.of(context).minimumPurchase}: ${Helper.toCurrencyFormat(voucher.minimumPurchase)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              const Spacer(),
              // Usage Info
              if (voucher.isLimited) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    S.of(context).usage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // Card tap will navigate to details; no explicit button needed
            ],
          ),
        ),
      ),
    );
  }

  int _getCrossAxisCount(double width) {
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  double _getChildAspectRatio(double width) {
    if (width > 1200) return 1.2;
    if (width > 900) return 1.1;
    if (width > 600) return 1.0;
    return 0.9;
  }

  void _onVoucherTap(BuildContext context, Voucher voucher) {
    showVoucherDetailModal(context, voucher);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }
}
