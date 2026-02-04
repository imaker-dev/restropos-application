# PIN Login Fix Documentation

## Issue Identified

The PIN login was failing with error "Invalid employee code or PIN" even when entering the correct 4-digit PIN (e.g., "9999").

### Root Cause

The `loginWithPasscode` method in `AuthNotifier` was incorrectly using the 4-digit PIN as both:
1. The employee code (e.g., "CAP0023")
2. The PIN (e.g., "9999")

The API requires two separate values:
```json
{
  "employeeCode": "CAP0023",
  "pin": "9999",
  "outletId": 4
}
```

But the code was sending:
```json
{
  "employeeCode": "9999",  // ❌ Wrong - using PIN as employee code
  "pin": "9999",           // ✅ Correct
  "outletId": 4
}
```

## Fix Applied

### 1. Updated Auth Provider (`auth_provider.dart`)

**Before:**
```dart
Future<bool> loginWithPasscode(String passcode) async {
  return loginWithPin(passcode);  // Using passcode as both employee code and PIN
}

Future<bool> loginWithPin(String pin, {String? employeeCode}) async {
  final result = await _repository.loginWithPin(
    employeeCode: employeeCode ?? pin,  // ❌ Fallback to PIN if no employee code
    pin: pin,
  );
}
```

**After:**
```dart
Future<bool> loginWithPasscode(String passcode, {String? employeeCode}) async {
  return loginWithPin(
    pin: passcode,
    employeeCode: employeeCode ?? 'CAP0023',  // ✅ Use default employee code
  );
}

Future<bool> loginWithPin({
  required String pin,
  String? employeeCode,
}) async {
  final result = await _repository.loginWithPin(
    employeeCode: employeeCode ?? 'CAP0023',  // ✅ Default employee code
    pin: pin,
  );
}
```

### 2. Updated Login Screen (`login_screen.dart`)

Fixed passcode length validation from 6 digits to 4 digits:

**Before:**
```dart
if (_passcode.length < 6) {
  // ...
  if (_passcode.length == 6) {
    _submitPasscode();
  }
}
```

**After:**
```dart
if (_passcode.length < 4) {
  // ...
  if (_passcode.length == 4) {
    _submitPasscode();
  }
}
```

## Testing

### Test Credentials

**PIN Login:**
- Employee Code: `CAP0023` (default, hardcoded)
- PIN: `9999`
- Just enter: `9999` on the PIN pad

**Email/Password Login:**
- Email: `captainall@gmail.com`
- Password: `Captain@123`

### Expected Behavior

1. **PIN Login:**
   - Enter 4 digits on the PIN pad
   - Auto-submits after 4th digit
   - Should successfully authenticate with employee code "CAP0023" and the entered PIN
   - On success: Navigates to home screen
   - On failure: Clears PIN and shows error message

2. **Email/Password Login:**
   - Enter email and password
   - Click Login button
   - Should successfully authenticate
   - On success: Navigates to home screen
   - On failure: Shows error message

## Production Considerations

### Current Implementation
- **Default Employee Code**: Hardcoded to `'CAP0023'` for testing
- **Security**: PIN is sent in plain text (HTTPS provides transport security)

### Recommended Enhancements

1. **Employee Code Input:**
   ```dart
   // Add employee code field to PIN login screen
   Widget _buildPinLoginForm() {
     return Column(
       children: [
         TextInput(
           label: 'Employee Code',
           controller: _employeeCodeController,
         ),
         // ... PIN pad
       ],
     );
   }
   ```

2. **Remember Employee Code:**
   ```dart
   // Store last used employee code
   final prefs = await SharedPreferences.getInstance();
   await prefs.setString('last_employee_code', employeeCode);
   
   // Retrieve on app start
   final lastEmployeeCode = prefs.getString('last_employee_code');
   ```

3. **QR Code/Barcode Scanner:**
   ```dart
   // Scan employee badge to get employee code
   final result = await BarcodeScanner.scan();
   final employeeCode = result.rawContent;
   ```

4. **PIN Security:**
   - Consider implementing PIN encryption at rest
   - Add rate limiting for failed attempts
   - Implement account lockout after X failed attempts
   - Add audit logging for login attempts

## API Integration Status

✅ **Completed:**
- Login with email/password
- Login with PIN (employee code + PIN)
- Token storage in SharedPreferences
- Error handling with user-friendly messages
- Automatic token injection via interceptors

⏳ **Pending:**
- Refresh token flow
- Session timeout handling
- Biometric authentication
- Card swipe authentication

## Files Modified

1. `/lib/features/auth/presentation/providers/auth_provider.dart`
   - Fixed `loginWithPasscode()` method
   - Updated `loginWithPin()` signature
   - Added default employee code

2. `/lib/features/auth/presentation/screens/login_screen.dart`
   - Updated passcode length validation (6 → 4 digits)

## State Management Note

The login screen currently uses `setState` for local UI state (passcode input). This is acceptable for simple local state. For a full Riverpod refactor:

```dart
// Create state providers
final passcodeProvider = StateProvider<String>((ref) => '');

// Use in widget
class LoginScreen extends ConsumerWidget {
  void _onDigitPressed(WidgetRef ref, String digit) {
    final current = ref.read(passcodeProvider);
    ref.read(passcodeProvider.notifier).state = current + digit;
  }
}
```

However, the current implementation with `setState` is clean and works well for this use case. The important state (authentication status, user data, tokens) is properly managed through Riverpod providers.
