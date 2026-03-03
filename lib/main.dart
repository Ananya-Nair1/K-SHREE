import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void>  main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yqxelrqdbfhjmvjzblyg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlxeGVscnFkYmZoam12anpibHlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1MDg1MzIsImV4cCI6MjA4ODA4NDUzMn0._UYc2l2HYpHjZPW9pvQre3jBMkHdjJdoIZPCF-qQ0qk',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
