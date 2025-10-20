import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';

import '../../../widgets/avatar_picker.dart';
import '../../../components/general/web_header.dart';
import '../../../components/general/snackbar_service.dart';
import '../address_screen/address_screen_webview.dart';
import 'user_screen_cubit.dart';
import 'user_screen_state.dart';

class UserScreenWebView extends StatefulWidget {
  const UserScreenWebView({super.key});

  static Widget newInstance() => BlocProvider(
        create: (context) => UserScreenCubit(),
        child: const UserScreenWebView(),
      );

  static Widget withCubit(UserScreenCubit cubit) => BlocProvider.value(
        value: cubit,
        child: const UserScreenWebView(),
      );

  @override
  State<UserScreenWebView> createState() => _UserScreenWebViewState();
}

class _UserScreenWebViewState extends State<UserScreenWebView> {
  UserScreenCubit get cubit => context.read<UserScreenCubit>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedSection = 'profile';
  final TextEditingController _usernameController = TextEditingController();
  bool _isUsernameChanged = false;

  @override
  void initState() {
    super.initState();
    cubit.getUser();
    // Sync selected section with incoming route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncSectionWithRoute();
      setState(() {});
    });
  }

  void _updateUsernameController(UserScreenState state) {
    // Only update if the state username is different and we're not currently editing
    if (_usernameController.text != state.username && !_isUsernameChanged) {
      _usernameController.text = state.username;
    }
  }

  void _saveUsername() {
    if (_usernameController.text.isNotEmpty) {
      // Call the cubit method which handles both database update and state emission
      cubit.updateUsername(_usernameController.text);
      setState(() {
        _isUsernameChanged = false;
      });
      // Clear focus after saving
      FocusScope.of(context).unfocus();
    }
  }

  void _cancelUsername() {
    _usernameController.text = cubit.state.username;
    setState(() {
      _isUsernameChanged = false;
    });
    // Clear focus after canceling
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
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
            child: BlocBuilder<UserScreenCubit, UserScreenState>(
              builder: (context, state) {
                _updateUsernameController(state);
                return _buildWebLayout(state);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _syncSectionWithRoute() {
    final name = ModalRoute.of(context)?.settings.name ?? '';
    if (name.endsWith('/addresses')) {
      _selectedSection = 'addresses';
    } else if (name.endsWith('/personal-information')) {
      _selectedSection = 'profile';
    }
  }

  Widget _buildWebLayout(UserScreenState state) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return _buildMobileLayout(state);
    }

    return _buildDesktopLayout(state);
  }

  Widget _buildDesktopLayout(UserScreenState state) {
    return Row(
      children: [
        // Sidebar Navigation
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(4, 0),
              ),
            ],
          ),
          child: _buildSidebar(state),
        ),
        // Main Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _buildContent(_selectedSection, state),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(UserScreenState state) {
    return Column(
      children: [
        // Profile Header
        _buildProfileHeader(state),
        // Content
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildContent(_selectedSection, state),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(UserScreenState state) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            AvatarPicker(
              userId: _auth.currentUser?.uid ?? '',
              currentAvatarUrl: state.avatarUrl,
              onAvatarChanged: (String newAvatarUrl) {
                cubit.updateAvatar(newAvatarUrl);
              },
              isGuest: state.isGuest,
            ),
            const SizedBox(height: 16),
            Text(
              state.isGuest ? S.of(context).guestAccount : state.username,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                state.isGuest ? S.of(context).guestAccount : state.email,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(UserScreenState state) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            S.of(context).accountSettings,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        // Navigation Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildNavItem(
                context,
                S.of(context).userTab,
                Icons.person_outline,
                'profile',
              ),
              _buildNavItem(
                context,
                S.of(context).address,
                Icons.location_on_outlined,
                'addresses',
              ),
            ],
          ),
        ),
        // Logout Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => cubit.logOut(context),
              icon: const Icon(Icons.logout),
              label: Text(S.of(context).logOut),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String title,
    IconData icon,
    String section,
  ) {
    final isSelected = _selectedSection == section;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      onTap: () {
        setState(() => _selectedSection = section);
        final target = section == 'addresses'
            ? '/user/addresses'
            : '/user/personal-information';
        final current = ModalRoute.of(context)?.settings.name;
        if (current != target) {
          Navigator.of(context).pushReplacementNamed(target);
        }
      },
      tileColor: isSelected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildContent(String section, UserScreenState state) {
    switch (section) {
      case 'profile':
        return SingleChildScrollView(
          child: _buildProfileSection(state),
        );
      case 'addresses':
        return _buildAddressesSection();
      default:
        return SingleChildScrollView(
          child: _buildProfileSection(state),
        );
    }
  }

  Widget _buildProfileSection(UserScreenState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).editProfile,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 32),
        // Avatar Section
        Card(
          elevation: 16,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).pickAvatar,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    AvatarPicker(
                      userId: _auth.currentUser?.uid ?? '',
                      currentAvatarUrl: state.avatarUrl,
                      onAvatarChanged: (String newAvatarUrl) {
                        cubit.updateAvatar(newAvatarUrl);
                      },
                      isGuest: state.isGuest,
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.of(context).pickAvatar,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          S.of(context).tapAvatarToChange,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          S.of(context).imageFormatHint,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Username Section
        Card(
          elevation: 16,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).fullName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  enabled: true,
                  decoration: InputDecoration(
                    hintText: S.of(context).enterNewUsername,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isUsernameChanged = value != state.username;
                    });
                  },
                  onTap: () {
                    // Ensure the text field is focused when tapped
                    _usernameController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _usernameController.text.length),
                    );
                  },
                  onSubmitted: (value) {
                    // Handle Enter key press
                    if (value.isNotEmpty && _isUsernameChanged) {
                      _saveUsername();
                    }
                  },
                ),
                if (_isUsernameChanged) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveUsername,
                          icon: const Icon(Icons.save),
                          label: Text(S.of(context).save),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _cancelUsername,
                          icon: const Icon(Icons.cancel),
                          label: Text(S.of(context).cancel),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.onSurface,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Email Section (Read-only)
        Card(
          elevation: 16,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).email,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  enabled: false,
                  controller: TextEditingController(text: state.email),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  S.of(context).emailCannotBeChanged,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Change Password Section
        Card(
          elevation: 16,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).changePassword,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  S.of(context).changePasswordDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final User? user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await FirebaseAuth.instance
                            .sendPasswordResetEmail(email: user.email!);
                        if (mounted) {
                          SnackbarService.showSuccess(
                            context,
                            title: S.of(context).success,
                            message: S.of(context).passwordResetEmailSent,
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.email_outlined),
                    label: Text(S.of(context).sendPasswordResetEmail),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressesSection() {
    // Use the existing AddressScreenWebView but without the web header
    // since we're already inside a section with web header
    return AddressScreenWebView.newInstance();
  }
}
