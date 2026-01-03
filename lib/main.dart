import 'package:flutter/material.dart';
import 'package:habit_tracker/habit_tracker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lljkeerrtanuoghevpvu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxsamtlZXJydGFudW9naGV2cHZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc0MTI1NzksImV4cCI6MjA4Mjk4ODU3OX0.GirklFipK6Ood8iCcI2sSaEr8D_FpvRZ15yib7cF1Kc',
  );

  runApp(HabitTrackerApp());
}
