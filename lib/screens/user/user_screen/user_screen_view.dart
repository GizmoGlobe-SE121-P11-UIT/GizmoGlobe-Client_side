import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/screens/user/user_screen/user_screen_state.dart';

import '../../../widgets/gradient_text.dart';
import 'user_screen_cubit.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  static Widget newInstance() =>
      BlocProvider(
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
    cubit.getUserName();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<UserScreenCubit, UserScreenState>(
            builder: (context, state) {
              return GradientText(
                text: 'Welcome, ${state.username}',
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                cubit.logOut(context);
              },
            ),
          ],
        ),
        body: Center(
          child: Text(
            'User Screen Content',
            style: TextStyle(
              fontSize: 24.0,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}