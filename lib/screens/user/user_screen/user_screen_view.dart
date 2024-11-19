import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/widgets/gradient_text.dart';
import 'package:gizmoglobe_client/widgets/invisible_gradient_button.dart';
import 'user_screen_cubit.dart';
import 'user_screen_state.dart';

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
        ),
        body: Center(
          child: Column(
            children: [
              Text(
                '[User Screen Content]',
                style: TextStyle(
                  fontSize: 24.0,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20.0),
              InvisibleGradientButton(
                onPress: () {
                  cubit.logOut(context);
                },
                suffixIcon: Icons.logout,
                text: 'Log out',
              ),
            ],
          ),
        ),
      ),
    );
  }
}