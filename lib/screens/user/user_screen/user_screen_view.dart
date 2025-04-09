import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../data/database/database.dart';
import '../../../enums/processing/order_option_enum.dart';
import '../../../widgets/avatar_picker.dart';
import '../address_screen/address_screen_view.dart';
import '../order_screen/order_screen_view.dart';
import 'user_screen_cubit.dart';
import 'user_screen_state.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
// Import the Firebase file

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  static Widget newInstance() => BlocProvider(
        create: (context) => UserScreenCubit(),
        child: const UserScreen(),
      );

  @override
  State<UserScreen> createState() => _UserScreen();
}

class _UserScreen extends State<UserScreen> {
  UserScreenCubit get cubit => context.read<UserScreenCubit>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    cubit.getUser();
  }

  void _showAccountSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.settings,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "Account Settings",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      _buildEnhancedSettingsItem(
                        context,
                        'Edit Profile',
                        Icons.person_outline,
                        'Update your personal information',
                        () async {
                          final newName = await showDialog<String>(
                            context: context,
                            builder: (context) {
                              final TextEditingController nameController =
                                  TextEditingController();
                              return AlertDialog(
                                title: const Text('Edit Profile'),
                                content: TextField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter new username',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 16,
                                    ),
                                    filled: true,
                                    fillColor:
                                        Theme.of(context).colorScheme.surface,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 15, horizontal: 20),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(nameController.text);
                                    },
                                    child: const Text('Save'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (newName != null && newName.isNotEmpty) {
                            final userId = await Database().getCurrentUserID();
                            if (userId != null) {
                              await FirebaseFirestore.instance
                                  .collection('customers')
                                  .doc(userId)
                                  .update({'customerName': newName});
                              cubit.updateUsername(newName);
                            }
                          }
                        },
                        showTopDivider: false,
                      ),
                      _buildEnhancedSettingsItem(
                        context,
                        'My Addresses',
                        Icons.location_on_outlined,
                        'Manage your delivery addresses',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddressScreen.newInstance(),
                          ),
                        ),
                      ),
                      _buildEnhancedSettingsItem(
                        context,
                        'Change Password',
                        Icons.lock_outline,
                        'Update your account security',
                        () async {
                          final User? user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            await FirebaseAuth.instance
                                .sendPasswordResetEmail(email: user.email!);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Password reset email sent to ${user.email}'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 260,
                    pinned: true,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    flexibleSpace: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        final bool isCollapsed =
                            constraints.maxHeight <= kToolbarHeight + 30;

                        return FlexibleSpaceBar(
                          centerTitle: false,
                          titlePadding:
                              const EdgeInsets.only(left: 16, bottom: 16),
                          title: isCollapsed
                              ? BlocBuilder<UserScreenCubit, UserScreenState>(
                                  builder: (context, state) {
                                    return Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          margin:
                                              const EdgeInsets.only(right: 12),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: state.avatarUrl != null
                                                ? DecorationImage(
                                                    image: NetworkImage(
                                                        state.avatarUrl!),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                          ),
                                          child: state.avatarUrl == null
                                              ? const Icon(Icons.person,
                                                  size: 24, color: Colors.white)
                                              : null,
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              state.username,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                            Text(
                                              state.email,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                )
                              : null,
                          background: Container(
                            color: Theme.of(context).colorScheme.primary,
                            child:
                                BlocBuilder<UserScreenCubit, UserScreenState>(
                              builder: (context, state) {
                                return SafeArea(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AvatarPicker(
                                        userId: FirebaseAuth
                                                .instance.currentUser?.uid ??
                                            '',
                                        currentAvatarUrl: state.avatarUrl,
                                        onAvatarChanged: (String newAvatarUrl) {
                                          cubit.updateAvatar(newAvatarUrl);
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        state.username,
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          letterSpacing: 0.5,
                                          shadows: [
                                            Shadow(
                                              offset: const Offset(0, 2),
                                              blurRadius: 6,
                                              color: Colors.black26,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(25),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          state.email,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.95),
                                            letterSpacing: 0.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // Clean Orders Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                          child: Card(
                            elevation: 4,
                            shadowColor: Colors.black12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 28,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'My Orders', // 'Đơn hàng của tôi'
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildEnhancedOrderStatus(
                                        context,
                                        FontAwesomeIcons.box,
                                        'To Ship', // 'Chờ vận chuyển'
                                        () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  OrderScreen.newInstance(
                                                orderOption: OrderOption.toShip,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      _buildEnhancedOrderStatus(
                                        context,
                                        Icons.local_shipping_outlined,
                                        'To Receive', // 'Chờ nhận hàng'
                                        () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  OrderScreen.newInstance(
                                                orderOption:
                                                    OrderOption.toReceive,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      _buildEnhancedOrderStatus(
                                        context,
                                        FontAwesomeIcons.circleCheck,
                                        'Completed', // 'Đã hoàn thành'
                                        () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  OrderScreen.newInstance(
                                                orderOption:
                                                    OrderOption.completed,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Account Settings Card
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: Card(
                            elevation: 4,
                            shadowColor: Colors.black12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: InkWell(
                              onTap: _showAccountSettingsModal,
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.settings,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      "Account Settings",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // App Settings Card
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: Card(
                            elevation: 4,
                            shadowColor: Colors.black12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (context) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(context)
                                              .viewInsets
                                              .bottom +
                                          MediaQuery.of(context).padding.bottom,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(24)),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            margin:
                                                const EdgeInsets.only(top: 12),
                                            width: 40,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[600],
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(24),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surface
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                      top: Radius.circular(24)),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  child: Icon(
                                                    Icons.settings_applications,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                    size: 28,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Text(
                                                  "App Settings",
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 24),
                                            child: Column(
                                              children: [
                                                _buildEnhancedSettingsItem(
                                                  context,
                                                  'Language',
                                                  Icons.language,
                                                  'Change app language',
                                                  () {
                                                    // TODO: Implement language change
                                                  },
                                                  showTopDivider: false,
                                                ),
                                                _buildEnhancedSettingsItem(
                                                  context,
                                                  'Theme',
                                                  Icons.dark_mode_outlined,
                                                  'Change app theme',
                                                  () {
                                                    showModalBottomSheet(
                                                      context: context,
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      builder: (context) =>
                                                          Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Theme.of(
                                                                  context)
                                                              .scaffoldBackgroundColor,
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .vertical(
                                                                  top: Radius
                                                                      .circular(
                                                                          24)),
                                                        ),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Container(
                                                              margin:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      top: 12),
                                                              width: 40,
                                                              height: 4,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .grey[600],
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            2),
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(24),
                                                              child: Row(
                                                                children: [
                                                                  Container(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            12),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .primary
                                                                          .withOpacity(
                                                                              0.1),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              16),
                                                                    ),
                                                                    child: Icon(
                                                                      Icons
                                                                          .dark_mode_outlined,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .primary,
                                                                      size: 28,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      width:
                                                                          16),
                                                                  Text(
                                                                    "Theme Settings",
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          24,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .primary,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Consumer<
                                                                ThemeProvider>(
                                                              builder: (context,
                                                                  themeProvider,
                                                                  child) {
                                                                return Column(
                                                                  children: [
                                                                    _buildThemeOption(
                                                                      context,
                                                                      'Light Mode',
                                                                      Icons
                                                                          .light_mode_outlined,
                                                                      themeProvider
                                                                              .themeMode ==
                                                                          ThemeMode
                                                                              .light,
                                                                      () => themeProvider
                                                                          .setTheme(
                                                                              ThemeMode.light),
                                                                    ),
                                                                    _buildThemeOption(
                                                                      context,
                                                                      'Dark Mode',
                                                                      Icons
                                                                          .dark_mode_outlined,
                                                                      themeProvider
                                                                              .themeMode ==
                                                                          ThemeMode
                                                                              .dark,
                                                                      () => themeProvider
                                                                          .setTheme(
                                                                              ThemeMode.dark),
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                            ),
                                                            const SizedBox(
                                                                height: 24),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
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
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.settings_applications,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      "App Settings",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // About Card
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: Card(
                            elevation: 4,
                            shadowColor: Colors.black12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (context) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(context)
                                              .viewInsets
                                              .bottom +
                                          MediaQuery.of(context).padding.bottom,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(24)),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            margin:
                                                const EdgeInsets.only(top: 12),
                                            width: 40,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[600],
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(24),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surface
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                      top: Radius.circular(24)),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  child: Icon(
                                                    Icons.info_outline,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                    size: 28,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Text(
                                                  "About",
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 24),
                                            child: Column(
                                              children: [
                                                _buildEnhancedSettingsItem(
                                                  context,
                                                  'Version',
                                                  Icons.new_releases_outlined,
                                                  'App version 1.0.0',
                                                  () {},
                                                  showTopDivider: false,
                                                ),
                                                _buildEnhancedSettingsItem(
                                                  context,
                                                  'Developers',
                                                  Icons.people_outline,
                                                  'Meet our development team',
                                                  () {
                                                    Navigator.pop(context);
                                                    _showDevelopersInfo(
                                                        context);
                                                  },
                                                ),
                                                _buildEnhancedSettingsItem(
                                                  context,
                                                  'Terms & Conditions',
                                                  Icons.description_outlined,
                                                  'Read our terms and conditions',
                                                  () {
                                                    Navigator.pop(context);
                                                    _showTermsInfo(context);
                                                  },
                                                ),
                                                _buildEnhancedSettingsItem(
                                                  context,
                                                  'Privacy Policy',
                                                  Icons.privacy_tip_outlined,
                                                  'Read our privacy policy',
                                                  () {
                                                    Navigator.pop(context);
                                                    _showPrivacyInfo(context);
                                                  },
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
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.info_outline,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      "About",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Log Out Card
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: Card(
                            elevation: 4,
                            shadowColor: Colors.black12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: InkWell(
                              onTap: () => cubit.logOut(context),
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.logout,
                                        color:
                                            Theme.of(context).colorScheme.error,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      "Log Out",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedOrderStatus(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSettingsItem(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
    VoidCallback onTap, {
    bool showTopDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Theme.of(context).colorScheme.primary,
            size: 16,
          ),
          onTap: onTap,
        ),
      ],
    );
  }

  void _showDevelopersInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.people_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "Developers",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    _buildEnhancedSettingsItem(
                      context,
                      'Terry',
                      Icons.person_outline,
                      'Lead Developer',
                      () {},
                      showTopDivider: false,
                    ),
                    _buildEnhancedSettingsItem(
                      context,
                      'GizmoGlobe Team',
                      Icons.groups_outlined,
                      'Development & Design',
                      () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTermsInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 20,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Terms & Conditions",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTermsSection(
                    '1. Acceptance of Terms',
                    'By accessing and using GizmoGlobe, you accept and agree to be bound by the terms and provision of this agreement.',
                  ),
                  const SizedBox(height: 16),
                  _buildTermsSection(
                    '2. Use License',
                    'Permission is granted to temporarily download one copy of the materials (information or software) on GizmoGlobe for personal, non-commercial transitory viewing only.',
                  ),
                  const SizedBox(height: 16),
                  _buildTermsSection(
                    '3. Disclaimer',
                    'The materials on GizmoGlobe are provided on an \'as is\' basis. GizmoGlobe makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.',
                  ),
                  const SizedBox(height: 16),
                  _buildTermsSection(
                    '4. Limitations',
                    'In no event shall GizmoGlobe or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on GizmoGlobe.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  void _showPrivacyInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 20,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.privacy_tip_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Privacy Policy",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrivacySection(
                    '1. Information We Collect',
                    'We collect information that you provide directly to us, including when you create an account, make a purchase, or contact us for support.',
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacySection(
                    '2. How We Use Your Information',
                    'We use the information we collect to provide, maintain, and improve our services, process your transactions, and communicate with you.',
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacySection(
                    '3. Information Sharing',
                    'We do not sell or share your personal information with third parties except as described in this policy or with your consent.',
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacySection(
                    '4. Data Security',
                    'We take reasonable measures to help protect your personal information from loss, theft, misuse, unauthorized access, disclosure, alteration, and destruction.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            )
          : null,
      onTap: onTap,
    );
  }
}
