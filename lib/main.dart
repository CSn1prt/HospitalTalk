import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/conversation_provider.dart';
import 'providers/soap_note_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const HospitalTalkApp());
}

class HospitalTalkApp extends StatelessWidget {
  const HospitalTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ConversationProvider()),
        ChangeNotifierProvider(create: (context) => SoapNoteProvider()),
      ],
      child: MaterialApp(
        title: 'Hospital Talk',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
