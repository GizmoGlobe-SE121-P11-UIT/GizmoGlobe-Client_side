import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_text.dart';
import '../../../data/database/database.dart';
import '../../../enums/processing/order_option_enum.dart';
import '../../../widgets/general/invisible_gradient_button.dart';
import '../../../widgets/general/vertical_icon_button.dart';
import '../add_address_screen/add_address_screen_view.dart';
import '../address_screen/address_screen_view.dart';
import '../order_screen/order_screen_view.dart';
import 'user_screen_cubit.dart';
import 'user_screen_state.dart';
import '../../../data/firebase/firebase.dart'; // Import the Firebase file

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

  @override
  void initState() {
    super.initState();
    cubit.getUser();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Clean SliverAppBar
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              backgroundColor: Theme.of(context).colorScheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: Theme.of(context).colorScheme.primary,
                  child: BlocBuilder<UserScreenCubit, UserScreenState>(
                    builder: (context, state) {
                      return SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Luxurious Avatar
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.white.withOpacity(0.95),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person,
                                size: 75,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Enhanced Username
                            Text(
                              state.username,
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 2),
                                    blurRadius: 6,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Elegant Email Container
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Text(
                                state.email,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.95),
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
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Clean Orders Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
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
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'My Orders',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildEnhancedOrderStatus(
                                  context,
                                  FontAwesomeIcons.box,
                                  'To Ship',
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderScreen.newInstance(
                                          orderOption: OrderOption.toShip,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                _buildEnhancedOrderStatus(
                                  context,
                                  Icons.local_shipping_outlined,
                                  'To Receive',
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderScreen.newInstance(
                                          orderOption: OrderOption.toReceive,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                _buildEnhancedOrderStatus(
                                  context,
                                  FontAwesomeIcons.circleCheck,
                                  'Completed',
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderScreen.newInstance(
                                          orderOption: OrderOption.completed,
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

                  // Clean Account Settings
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                          _buildEnhancedSettingsItem(
                            context,
                            'Edit Profile',
                            Icons.person_outline,
                            'Update your personal information',
                                () async {
                              final newName = await showDialog<String>(
                                context: context,
                                builder: (context) {
                                  final TextEditingController nameController = TextEditingController();
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
                                        fillColor: Theme.of(context).colorScheme.surface,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
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
                                            color: Theme.of(context).colorScheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
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
                                          Navigator.of(context).pop(nameController.text);
                                        },
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (newName != null && newName.isNotEmpty) {
                                // Await the result of getCurrentUserID
                                final userId = await Database().getCurrentUserID();
                                if (userId != null) {
                                  await FirebaseFirestore.instance
                                      .collection('customers')
                                      .doc(userId)
                                      .update({'customerName': newName});

                                  // Update the local state
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
                                await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Password reset email sent to ${user.email}')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Clean Logout Button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: () => cubit.logOut(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.logout, size: 26),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                color: Theme.of(context).colorScheme.surfaceVariant,
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
        // if (showTopDivider) const Divider(height: 1),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
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
}