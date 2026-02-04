import '../../domain/entities/user.dart';

class DummyUsers {
  DummyUsers._();

  static final List<User> users = [
    User(
      id: 'user_001',
      name: 'John Captain',
      username: 'john',
      role: UserRole.captain,
      pin: '1234',
      passcode: '111111',
      assignedFloors: ['floor_1'],
      assignedSections: ['AC', 'Garden'],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    User(
      id: 'user_002',
      name: 'Sarah Captain',
      username: 'sarah',
      role: UserRole.captain,
      pin: '5678',
      passcode: '222222',
      assignedFloors: ['floor_1'],
      assignedSections: ['Non AC', 'Garden'],
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      updatedAt: DateTime.now(),
    ),
    User(
      id: 'user_003',
      name: 'Mike Cashier',
      username: 'mike',
      role: UserRole.cashier,
      pin: '9012',
      passcode: '333333',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now(),
    ),
    User(
      id: 'user_004',
      name: 'Emily Manager',
      username: 'emily',
      role: UserRole.manager,
      pin: '3456',
      passcode: '444444',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now(),
    ),
    User(
      id: 'user_005',
      name: 'Admin User',
      username: 'admin',
      role: UserRole.admin,
      pin: '0000',
      passcode: '000000',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now(),
    ),
  ];

  static User? findByPasscode(String passcode) {
    try {
      return users.firstWhere((user) => user.passcode == passcode);
    } catch (_) {
      return null;
    }
  }

  static User? findByPin(String pin) {
    try {
      return users.firstWhere((user) => user.pin == pin);
    } catch (_) {
      return null;
    }
  }

  static User? findByCredentials(String username, String password) {
    try {
      return users.firstWhere(
        (user) => user.username == username && user.pin == password,
      );
    } catch (_) {
      return null;
    }
  }

  static List<User> getCaptains() {
    return users.where((user) => user.role == UserRole.captain).toList();
  }
}
