import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kokrhel_app/providers/timer_provider.dart'; // Will be created
import 'package:kokrhel_app/screens/timer_list_page.dart'; // Will be created

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => TimerProvider(), // TimerProvider will be created
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kokrhel',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue, // A common primary color for dark themes
        scaffoldBackgroundColor: const Color(0xFF121212), // Standard dark background
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F), // Slightly lighter dark for AppBar
          elevation: 0, // Flat design
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue[600],
        ),
        // You can customize other theme properties here like text themes, card themes etc.
        // For example, to make digits blue as requested for timers:
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ).copyWith(
          // Example: A specific style that could be used for timer digits
          headlineMedium: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.blue[300]),
        ),
        colorScheme: ColorScheme.fromSwatch(
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
        ).copyWith(
          secondary: Colors.blueAccent, // Accent color
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'), // Old home
      home: const TimerListPage(), // TimerListPage will be created
    );
  }
}

// Placeholder for TimerProvider until it's created
// class TimerProvider extends ChangeNotifier {}

// Placeholder for TimerListPage until it's created
// class TimerListPage extends StatelessWidget {
//   const TimerListPage({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('kokrhel - Loading...')),
//       body: const Center(child: Text('Timer List Page - Coming Soon!')),
//     );
//   }
// }
