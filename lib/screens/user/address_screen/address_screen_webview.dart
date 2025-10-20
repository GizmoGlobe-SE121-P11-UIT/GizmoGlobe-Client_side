import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';
import 'package:gizmoglobe_client/screens/user/address_screen/address_screen_state.dart';
import 'package:gizmoglobe_client/widgets/general/app_text_style.dart';
import 'package:gizmoglobe_client/services/web_guest_service.dart';
import 'package:gizmoglobe_client/components/general/snackbar_service.dart';
import 'package:gizmoglobe_client/screens/authentication/sign_in_screen/sign_in_webview.dart';
import 'package:gizmoglobe_client/screens/authentication/sign_in_screen/sign_in_cubit.dart';

import '../../../objects/address_related/address.dart';
import '../add_address_screen/add_address_screen_view.dart';
import '../edit_address_screen/edit_address_screen_view.dart';
import '../edit_address_screen/edit_address_modal_webview.dart';
import 'address_screen_cubit.dart';

class AddressScreenWebView extends StatefulWidget {
  const AddressScreenWebView({super.key});

  static Widget newInstance() => BlocProvider(
        create: (context) => AddressScreenCubit(),
        child: const AddressScreenWebView(),
      );

  static Widget withCubit(AddressScreenCubit cubit) => BlocProvider.value(
        value: cubit,
        child: const AddressScreenWebView(),
      );

  @override
  State<AddressScreenWebView> createState() => _AddressScreenWebViewState();
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PinnedHeaderDelegate({
    required this.minExtentHeight,
    required this.maxExtentHeight,
    required this.builder,
  });

  final double minExtentHeight;
  final double maxExtentHeight;
  final Widget Function(BuildContext) builder;

  @override
  double get minExtent => minExtentHeight;

  @override
  double get maxExtent => maxExtentHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: overlapsContent ? 6 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Align(
          alignment: Alignment.center,
          child: builder(context),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return minExtentHeight != oldDelegate.minExtentHeight ||
        maxExtentHeight != oldDelegate.maxExtentHeight;
  }
}

class _AddressScreenWebViewState extends State<AddressScreenWebView> {
  AddressScreenCubit get cubit => context.read<AddressScreenCubit>();
  final WebGuestService _webGuestService = WebGuestService();

  @override
  void initState() {
    super.initState();
    cubit.reloadList();
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
            actionType: 'address',
          );
          final signInCubit = SignInCubit();
          await showSignInModalWithCubit(context, signInCubit);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildWebLayout();
  }

  Widget _buildWebLayout() {
    return BlocBuilder<AddressScreenCubit, AddressScreenState>(
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedHeaderDelegate(
                minExtentHeight: 64,
                maxExtentHeight: 72,
                builder: (context) => Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.only(bottom: 12, left: 0, right: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        S.of(context).myAddresses,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await openAddAddressFlow(context);
                          if (result != null) {
                            cubit.addAddress(result);
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: Text(S.of(context).addAddress),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (state.addressList.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildEmptyAddresses(),
                ),
              )
            else
              SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  final crossAxisCount = width > 1200
                      ? 3
                      : width > 800
                          ? 2
                          : 1;
                  final childAspectRatio = width > 1200
                      ? 5.5
                      : width > 800
                          ? 5.0
                          : 5.5;

                  return SliverPadding(
                    padding: const EdgeInsets.only(bottom: 16),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final address = state.addressList[index];
                          return _buildAddressCard(address);
                        },
                        childCount: state.addressList.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: childAspectRatio,
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyAddresses() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 80,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              S.of(context).noAddressFound,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              S.of(context).addYourFirstAddress,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await openAddAddressFlow(context);
                if (result != null) {
                  cubit.addAddress(result);
                }
              },
              icon: const Icon(Icons.add),
              label: Text(S.of(context).addAddress),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Removed old non-sticky header grid builder

  Widget _buildAddressCard(Address address) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Address Header
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  // Title
                  Expanded(
                    child: Text(
                      '${S.of(context).address} ${cubit.state.addressList.indexOf(address) + 1}',
                      style: AppTextStyle.boldText.copyWith(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        Address? result;
                        if (kIsWeb) {
                          result = await showEditAddressModal(context, address);
                        } else {
                          result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    EditAddressScreen.newInstance(address)),
                          );
                        }

                        if (result != null) {
                          cubit.editAddress(result);
                        }
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(address);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(S.of(context).edit),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              S.of(context).delete,
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Address Content
              Text(
                address.firstLine(),
                style: AppTextStyle.boldText.copyWith(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                address.secondLine(isEnglish: false),
                style: AppTextStyle.regularText.copyWith(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Address address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          S.of(context).deleteAddress,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          S.of(context).deleteAddressConfirmation,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              cubit.deleteAddress(address);
            },
            child: Text(
              S.of(context).delete,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
