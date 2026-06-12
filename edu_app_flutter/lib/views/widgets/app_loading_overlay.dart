import 'dart:ui';

import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/models/app_loading_model.dart';
import 'package:flutter/material.dart';

class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLoadingModel.instance,
      builder: (context, _) {
        final visible = AppLoadingModel.instance.isLoading;

        return Stack(
          children: [
            child,
            IgnorePointer(
              ignoring: !visible,
              child: AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                    child: ColoredBox(
                      color: const Color(0x66101B3B),
                      child: const Center(
                        child: _LoadingCard(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A132A63),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              color: Color.fromARGB(255, 217, 222, 248),
            ),
          ),
        ],
      ),
    );
  }
}
