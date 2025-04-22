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
import '../../authentication/sign_in_screen/sign_in_view.dart';
import '../../authentication/sign_up_screen/sign_up_view.dart';
import '../../../providers/language_provider.dart';
import 'package:gizmoglobe_client/generated/l10n.dart';


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
                      S.of(context).accountSettings,
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
                        S.of(context).editProfile,
                        Icons.person_outline,
                        S.of(context).editProfileDescription,
                        () async {
                          final newName = await showDialog<String>(
                            context: context,
                            builder: (context) {
                              final TextEditingController nameController =
                                  TextEditingController();
                              return Dialog(
                                insetPadding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.85,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.1),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(24)),
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
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Icon(
                                                Icons.person_outline,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              S.of(context).editProfile,
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
                                        padding: const EdgeInsets.fromLTRB(
                                            24, 32, 24, 32),
                                        child: TextField(
                                          controller: nameController,
                                          decoration: InputDecoration(
                                            hintText:
                                                S.of(context).enterNewUsername,
                                            hintStyle: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 16,
                                            ),
                                            filled: true,
                                            fillColor: Theme.of(context)
                                                .colorScheme
                                                .surface,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 20,
                                                    horizontal: 24),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color: Colors.grey[300]!,
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
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
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(
                                            24, 0, 24, 24),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 24,
                                                        vertical: 16),
                                                foregroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .error,
                                              ),
                                              child: Text(
                                                S.of(context).cancel,
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .error,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(nameController.text);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                foregroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .onPrimary,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 32,
                                                        vertical: 16),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: Text(
                                                S.of(context).save,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                        S.of(context).myAddresses,
                        Icons.location_on_outlined,
                        S.of(context).manageAddressDescription,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddressScreen.newInstance(),
                          ),
                        ),
                      ),
                      _buildEnhancedSettingsItem(
                        context,
                        S.of(context).changePassword,
                        Icons.lock_outline,
                        S.of(context).changePasswordDescription,
                        () async {
                          final User? user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            await FirebaseAuth.instance
                                .sendPasswordResetEmail(email: user.email!);
                            if (mounted) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    S.of(context).passwordResetEmailSent,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Text(
                                    S
                                        .of(context)
                                        .passwordResetEmailContent(user.email!),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        S.of(context).ok,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                  ],
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

  void _showSignUpOptions() {
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
                        Icons.person_add_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      S.of(context).accountSettings,
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
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    _buildEnhancedSettingsItem(
                      context,
                      S.of(context).signUpWithEmail,
                      Icons.email_outlined,
                      S.of(context).createAccountUsingEmail,
                      () {
                        Navigator.pop(context);
                        // Đăng xuất tài khoản guest
                        FirebaseAuth.instance.signOut();
                        // Chuyển hướng đến màn hình đăng ký
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignUpScreen.newInstance(),
                          ),
                          (Route<dynamic> route) => false,
                        );
                      },
                      showTopDivider: false,
                    ),
                    _buildEnhancedSettingsItem(
                      context,
                      S.of(context).signIn,
                      Icons.login,
                      S.of(context).alreadyHaveAccountQuestion,
                      () {
                        Navigator.pop(context);
                        // Đăng xuất tài khoản guest
                        FirebaseAuth.instance.signOut();
                        // Chuyển hướng đến màn hình đăng nhập
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignInScreen.newInstance(),
                          ),
                          (Route<dynamic> route) => false,
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
                    expandedHeight: MediaQuery.of(context).size.height * 0.32,
                    pinned: true,
                    stretch: true,
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
                                          width: 32,
                                          height: 32,
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
                                                  size: 20, color: Colors.white)
                                              : null,
                                        ),
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                state.isGuest
                                                    ? S.of(context).guestAccount
                                                    : state.username,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.light
                                                      ? const Color(0xFF2C3E50)
                                                      : Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                state.isGuest
                                                    ? S.of(context).guestAccount
                                                    : state.email,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.light
                                                      ? const Color(0xFF2C3E50)
                                                          .withOpacity(0.7)
                                                      : Colors.white70,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
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
                                      const SizedBox(height: 16),
                                      AvatarPicker(
                                        userId: FirebaseAuth
                                                .instance.currentUser?.uid ??
                                            '',
                                        currentAvatarUrl: state.avatarUrl,
                                        onAvatarChanged: (String newAvatarUrl) {
                                          cubit.updateAvatar(newAvatarUrl);
                                        },
                                        isGuest: state.isGuest,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        state.isGuest
                                            ? S.of(context).guestAccount
                                            : state.username,
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          state.isGuest
                                              ? S.of(context).guestAccount
                                              : state.email,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            letterSpacing: 0.3,
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
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
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
                                        S.of(context).myOrders,
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
                                        S.of(context).toShip,
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
                                        S.of(context).toReceive,
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
                                        S.of(context).completed,
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
                        BlocBuilder<UserScreenCubit, UserScreenState>(
                            builder: (context, state) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            child: Card(
                              elevation: 4,
                              shadowColor: Colors.black12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: InkWell(
                                onTap: state.isGuest
                                    ? _showSignUpOptions
                                    : _showAccountSettingsModal,
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        state.isGuest
                                            ? S.of(context).createAccount
                                            : S.of(context).accountSettings,
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        // App Settings Card
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
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
                                                    Icons.settings,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                    size: 28,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Text(
                                                  S.of(context).appSettings,
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
                                                  S.of(context).language,
                                                  Icons.language,
                                                  S.of(context).changeLanguageDescription,
                                                  () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        return AlertDialog(
                                                          title: Text(
                                                            S
                                                                .of(context)
                                                                .language,
                                                            style: TextStyle(
                                                              fontSize: 24,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary,
                                                            ),
                                                          ),
                                                          content: Consumer<
                                                              LanguageProvider>(
                                                            builder: (context,
                                                                languageProvider,
                                                                child) {
                                                              return Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  ListTile(
                                                                    title: Text(S
                                                                        .of(context)
                                                                        .languageEn),
                                                                    leading:
                                                                        Text(
                                                                            S.of(context).languageEn
                                                                            ),
                                                                    onTap: () {
                                                                      languageProvider
                                                                          .setLanguage(
                                                                              'en');
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                    selected: languageProvider
                                                                            .currentLocale
                                                                            .languageCode ==
                                                                        'en',
                                                                  ),
                                                                  ListTile(
                                                                    title: Text(S
                                                                        .of(context)
                                                                        .languageVi),
                                                                    leading:
                                                                        Text(
                                                                            S.of(context).languageVi
                                                                        ),
                                                                    onTap: () {
                                                                      languageProvider
                                                                          .setLanguage(
                                                                              'vi');
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                    selected: languageProvider
                                                                            .currentLocale
                                                                            .languageCode ==
                                                                        'vi',
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                  showTopDivider: false,
                                                ),
                                                _buildEnhancedSettingsItem(
                                                  context,
                                                  S.of(context).changeTheme,
                                                  Icons.dark_mode_outlined,
                                                  S.of(context).changeThemeDescription,
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
                                                                    S
                                                                        .of(context)
                                                                        .themeSettings,
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
                                                                      S
                                                                          .of(context)
                                                                          .lightMode,
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
                                                                      S
                                                                          .of(context)
                                                                          .darkMode,
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
                                      .primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.settings,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      S.of(context).appSettings,
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
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
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
                                                  S.of(context).about,
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
                                                  S.of(context).developers,
                                                  Icons.people_outline,
                                                  S.of(context).meetDevelopmentTeam,
                                                  () {
                                                    Navigator.pop(context);
                                                    _showDevelopersInfo(
                                                        context);
                                                  },
                                                ),
                                                _buildEnhancedSettingsItem(
                                                  context,
                                                  S
                                                      .of(context)
                                                      .termsAndConditions,
                                                  Icons.description_outlined,
                                                  S.of(context).termsAndConditionsDescription,
                                                  () {
                                                    Navigator.pop(context);
                                                    _showTermsInfo(context);
                                                  },
                                                ),
                                                _buildEnhancedSettingsItem(
                                                  context,
                                                  S.of(context).privacyPolicy,
                                                  Icons.privacy_tip_outlined,
                                                  S.of(context).privacyPolicyDescription,
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
                                      .primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      S.of(context).about,
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

                        // Add spacing before Log Out Card
                        const SizedBox(height: 16),

                        // Log Out Card
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
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
                                    Icon(
                                      Icons.logout,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      S.of(context).logOut,
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
    VoidCallback? onTap, {
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
          trailing: onTap != null
              ? Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                )
              : null,
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
                      S.of(context).developers,
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
                      'To Vinh Tien - Terry',
                      Icons.person_outline,
                      S.of(context).developer,
                      null,
                      showTopDivider: false,
                    ),
                    _buildEnhancedSettingsItem(
                      context,
                      'Do Hong Quan',
                      Icons.groups_outlined,
                      S.of(context).developer,
                      null,
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
                    S.of(context).termsAndConditions,
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
                    S.of(context).acceptanceOfTerms,
                    S.of(context).termsAndConditionsContent,
                  ),
                  const SizedBox(height: 16),
                  _buildTermsSection(
                    S.of(context).useLicense,
                    S.of(context).useLicenseContent,
                  ),
                  const SizedBox(height: 16),
                  _buildTermsSection(
                    S.of(context).disclaimer,
                    S.of(context).disclaimerContent,
                  ),
                  const SizedBox(height: 16),
                  _buildTermsSection(
                    S.of(context).limitations,
                    S.of(context).limitationsContent,
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
                    S.of(context).privacyPolicy,
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
                    S.of(context).informationWeCollect,
                    S.of(context).informationWeCollectContent,
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacySection(
                    S.of(context).howWeUseYourInformation,
                    S.of(context).howWeUseYourInformationContent,
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacySection(
                    S.of(context).informationSharing,
                    S.of(context).informationSharingContent,
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacySection(
                    S.of(context).dataSecurity,
                    S.of(context).dataSecurityContent,
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