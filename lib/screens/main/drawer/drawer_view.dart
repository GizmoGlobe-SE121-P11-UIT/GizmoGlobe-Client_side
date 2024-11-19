import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/widgets/app_logo.dart';
import 'package:gizmoglobe_client/widgets/invisible_gradient_button.dart';
import '../main_screen/main_screen_cubit.dart';
import 'drawer_cubit.dart';
import 'drawer_state.dart';

class DrawerView extends StatelessWidget {
  const DrawerView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DrawerCubit>();

    return BlocBuilder<DrawerCubit, DrawerState>(
      builder: (context, state) {
        if (state.isOpen) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Material(
              child: Container(
                width: 280,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Column(
                  children: <Widget>[
                    DrawerHeader(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      child: Row(
                        children: [
                          const AppLogo(height: 32),
                          const SizedBox(width: 8),
                          BlocBuilder<MainScreenCubit, MainScreenState>(
                            builder: (context, state) {
                              return Text(
                                'Hello! ${state.username}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 16,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: state.categories.map((category) {
                          return ListTile(
                            title: Text(
                              category,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                              ),
                            ),
                            onTap: () {
                              // Handle category tap
                            },
                            visualDensity: VisualDensity.compact,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                          );
                        }).toList(),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Us:',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'gizmoglobe@gg.com',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '0XXX-XXX-XXX',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InvisibleGradientButton(
                      onPress: () {
                        cubit.logOut(context);
                      },
                      suffixIcon: Icons.logout,
                      text: 'Log out',
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}