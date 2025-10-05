// lib/widgets/common/loading_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingWidget({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SpinKitFadingCircle(
      color: color ?? Theme.of(context).primaryColor,
      size: size,
    );
  }
}