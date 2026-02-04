# Auth API Integration Documentation

## Overview
This document describes the authentication API integration implemented following Clean Architecture principles.

## Architecture

```
Presentation Layer (UI)
    ↓
Auth Provider (State Management - Riverpod)
    ↓
Auth Repository (Domain Interface)
    ↓
Auth Repository Implementation (Data Layer)
    ↓
Auth Remote Data Source
    ↓
API (Dio HTTP Client)
```

## API Endpoints

### Base URL
```
https://sequences-diana-wholesale-adds.trycloudflare.com/api/v1/
```

### Login with Email/Password
**Endpoint:** `POST /auth/login`

**Request:**
```json
{
  "email": "captainall@gmail.com",
  "password": "Captain@123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 97,
      "uuid": "d904b77c-5737-4917-b4a1-65012e726257",
      "employeeCode": "CPT009",
      "name": "Captain All Access",
      "email": "captainall@gmail.com",
      "roles": ["captain"]
    },
    "accessToken": "eyJhbGci...",
    "refreshToken": "aba6aaa7f423...",
    "expiresIn": "30d",
    "tokenType": "Bearer"
  }
}
```

### Login with PIN
**Endpoint:** `POST /auth/login/pin`

**Request:**
```json
{
  "employeeCode": "CAP0023",
  "pin": "9999",
  "outletId": 4
}
```

**Response:** Same as login with email/password

## Implementation Details

### 1. Data Layer

#### Models (`/data/models/`)
- **LoginWithEmailRequest**: DTO for email/password login
- **LoginWithPinRequest**: DTO for PIN login with outlet ID
- **LoginResponse**: Response DTO with success/message/data
- **UserDto**: User data transfer object with mapping to domain entity

#### Data Source (`/data/datasources/`)
- **AuthRemoteDataSource**: Interface for authentication API calls
- **AuthRemoteDataSourceImpl**: Implementation using Dio client
  - Handles API requests
  - Error handling for different DioException types
  - Converts API responses to DTOs

#### Repository Implementation (`/data/repositories/`)
- **AuthRepositoryImpl**: Implements domain repository interface
  - Manages API calls through data source
  - Handles token storage via SharedPreferences
  - Converts DTOs to domain entities
  - Returns `AuthResult` with success/failure state

### 2. Domain Layer

#### Repository Interface (`/domain/repositories/`)
- **AuthRepository**: Contract for authentication operations
  - `loginWithEmail()`: Login with credentials
  - `loginWithPin()`: Login with employee code and PIN
  - `logout()`: Logout user
  - Token management methods

#### Entities (`/domain/entities/`)
- **User**: Core user entity with role-based permissions
- **AuthState**: Authentication state with status management
- **AuthResult**: Result wrapper for repository operations

### 3. Presentation Layer

#### Providers (`/presentation/providers/`)
- **authProvider**: StateNotifierProvider managing auth state
- **AuthNotifier**: State notifier using repository
  - `loginWithCredentials()`: Login with email/password
  - `loginWithPin()`: Login with employee code and PIN
  - `loginWithPasscode()`: Alias for PIN login
  - `logout()`: Logout and clear tokens
  - `restoreSession()`: Check for stored tokens

#### Screens (`/presentation/screens/`)
- **LoginScreen**: Multi-mode login UI
  - Credentials mode: Email/password form
  - Passcode mode: 6-digit keypad
  - Responsive design for mobile/tablet/desktop

## Configuration

### Outlet ID
Default outlet ID is configured in `/core/constants/app_constants.dart`:
```dart
static const int defaultOutletId = 4;
```

### Token Storage
Tokens are stored using SharedPreferences:
- **authTokenKey**: Access token storage key
- **refreshTokenKey**: Refresh token storage key

### API Client
Dio client is configured in `/core/network/api_client.dart` with:
- Base URL from ApiEndPoints
- Connection/receive timeouts (30s)
- Auth interceptor for token injection
- Retry interceptor for failed requests
- Logging interceptor for debugging

## Error Handling

### API Errors
- **401**: Invalid credentials or unauthorized
- **403**: Access denied
- **404**: Service not found
- **500**: Server error
- **Timeout**: Connection/send/receive timeout
- **Connection Error**: No internet connection

### Error Flow
1. DioException caught in data source
2. Converted to user-friendly Exception message
3. Caught in repository, wrapped in AuthResult.failure
4. Displayed in UI via auth state error message

## Usage Example

### Login with Email
```dart
final success = await ref.read(authProvider.notifier).loginWithCredentials(
  'captainall@gmail.com',
  'Captain@123',
);
```

### Login with PIN
```dart
final success = await ref.read(authProvider.notifier).loginWithPin(
  '9999',
  employeeCode: 'CAP0023',
);
```

### Check Auth State
```dart
final authState = ref.watch(authProvider);
if (authState.isAuthenticated) {
  // User is logged in
  final user = authState.user;
}
```

## Testing

### Test Credentials
**Email/Password:**
- Email: `captainall@gmail.com`
- Password: `Captain@123`

**PIN:**
- Employee Code: `CAP0023`
- PIN: `9999`
- Outlet ID: `4` (auto-included)

## Dependency Injection

All dependencies are managed through Riverpod providers:

```dart
// Core providers
sharedPreferencesProvider → Initialized in main.dart
dioProvider → HTTP client

// Auth providers
authRemoteDataSourceProvider → API calls
authRepositoryProvider → Business logic
authProvider → State management
```

## Security Considerations

1. **Token Storage**: Tokens stored in SharedPreferences (consider encrypted storage for production)
2. **HTTPS**: All API calls use HTTPS
3. **Token Expiry**: Handle token refresh (implement refresh token flow)
4. **Sensitive Data**: Passwords never stored locally
5. **Auth Interceptor**: Automatically adds Bearer token to requests

## Future Enhancements

1. Implement refresh token flow
2. Add biometric authentication
3. Implement card swipe authentication
4. Add session timeout handling
5. Implement remember me functionality
6. Add password reset flow
7. Implement multi-factor authentication
