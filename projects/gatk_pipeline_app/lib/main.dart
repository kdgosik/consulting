// lib/main.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'bindings/app_binding.dart';
import 'views/home_view.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GatkPipelineApp());
}

class GatkPipelineApp extends StatelessWidget {
  const GatkPipelineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'GATK Pipeline Builder',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      initialBinding: AppBinding(),
      home: const HomeView(),
    );
  }
}
