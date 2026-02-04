import 'package:flutter_riverpod/flutter_riverpod.dart';

// Passcode state provider
final passcodeProvider = StateProvider<String>((ref) => '');

// Username controller state provider
final usernameProvider = StateProvider<String>((ref) => '');

// Password controller state provider
final passwordProvider = StateProvider<String>((ref) => '');

// Helper to clear all login form states
void clearLoginStates(WidgetRef ref) {
  ref.read(passcodeProvider.notifier).state = '';
  ref.read(usernameProvider.notifier).state = '';
  ref.read(passwordProvider.notifier).state = '';
}
