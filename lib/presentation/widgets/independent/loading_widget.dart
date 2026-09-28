import 'package:flutter/material.dart';
import '../../../app_setting/app_setting.dart';

/// Visible loading feedback shared by routes that have no content skeleton.
class LoadingWidget extends StatelessWidget {
  final Color backgroundColor;
  const LoadingWidget({super.key, this.backgroundColor = colorBackground});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: backgroundColor,
    child: Center(
      child: Semantics(
        liveRegion: true,
        label: 'Loading',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: mainColor,
              ),
            ),
            const SizedBox(height: AppDesign.spaceLg),
            Text('Loading…', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    ),
  );
}
