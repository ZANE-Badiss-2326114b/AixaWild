import 'package:flutter/material.dart';

PreferredSizeWidget intranetAppBar({
  required String title,
  List<Widget>? actions,
}) {
  return AppBar(
    title: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    centerTitle: true,
    backgroundColor: const Color(0xFF1F6FB2),
    actions: actions,
  );
}
