import '../../domain/entities/user.dart';

class DummyUsers {
  DummyUsers._();

  static final List<User> users = [
    User(
      id: 1,
      uuid: '096963b5-c407-4521-b4ea-bfa68be43bf0',
      employeeCode: 'CAP0023',
      name: 'Tom Waiter',
      email: null,
      phone: null,
      avatarUrl: null,
      isActive: true,
      isVerified: false,
      lastLoginAt: DateTime.now(),
      roles: [
        Role(
          id: 4,
          name: 'Captain',
          slug: 'captain',
          outletId: 1,
          outletName: 'Main Restaurant',
        ),
      ],
      permissions: [
        'TABLE_VIEW',
        'TABLE_MERGE',
        'TABLE_TRANSFER',
        'ORDER_VIEW',
        'ORDER_CREATE',
        'ORDER_MODIFY',
        'KOT_SEND',
        'KOT_MODIFY',
        'KOT_REPRINT',
        'BILL_VIEW',
        'BILL_GENERATE',
        'BILL_REPRINT',
        'PAYMENT_COLLECT',
        'PAYMENT_SPLIT',
        'DISCOUNT_APPLY',
        'TIP_ADD',
        'ITEM_VIEW',
        'ITEM_CANCEL',
        'CATEGORY_VIEW',
        'REPORT_VIEW',
        'FLOOR_VIEW',
        'SECTION_VIEW',
      ],
      permissionsByModule: {
        'table': ['TABLE_VIEW', 'TABLE_MERGE', 'TABLE_TRANSFER'],
        'order': ['ORDER_VIEW', 'ORDER_CREATE', 'ORDER_MODIFY'],
        'kot': ['KOT_SEND', 'KOT_MODIFY', 'KOT_REPRINT'],
        'billing': ['BILL_VIEW', 'BILL_GENERATE', 'BILL_REPRINT'],
        'payment': ['PAYMENT_COLLECT', 'PAYMENT_SPLIT'],
        'discount': ['DISCOUNT_APPLY'],
        'tip': ['TIP_ADD'],
        'item': ['ITEM_VIEW', 'ITEM_CANCEL'],
        'category': ['CATEGORY_VIEW'],
        'report': ['REPORT_VIEW'],
        'floor': ['FLOOR_VIEW'],
        'section': ['SECTION_VIEW'],
      },
    ),
    User(
      id: 2,
      uuid: '096963b5-c407-4521-b4ea-bfa68be43bf1',
      employeeCode: 'CAP0024',
      name: 'Sarah Cashier',
      email: null,
      phone: null,
      avatarUrl: null,
      isActive: true,
      isVerified: false,
      lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)),
      roles: [
        Role(
          id: 5,
          name: 'Cashier',
          slug: 'cashier',
          outletId: 1,
          outletName: 'Main Restaurant',
        ),
      ],
      permissions: [
        'TABLE_VIEW',
        'ORDER_VIEW',
        'ORDER_CREATE',
        'ORDER_MODIFY',
        'BILL_VIEW',
        'BILL_GENERATE',
        'BILL_REPRINT',
        'PAYMENT_COLLECT',
        'PAYMENT_SPLIT',
        'ITEM_VIEW',
        'ITEM_CANCEL',
        'CATEGORY_VIEW',
        'REPORT_VIEW',
      ],
      permissionsByModule: {
        'table': ['TABLE_VIEW'],
        'order': ['ORDER_VIEW', 'ORDER_CREATE', 'ORDER_MODIFY'],
        'billing': ['BILL_VIEW', 'BILL_GENERATE', 'BILL_REPRINT'],
        'payment': ['PAYMENT_COLLECT', 'PAYMENT_SPLIT'],
        'item': ['ITEM_VIEW', 'ITEM_CANCEL'],
        'category': ['CATEGORY_VIEW'],
        'report': ['REPORT_VIEW'],
      },
    ),
    User(
      id: 3,
      uuid: '096963b5-c407-4521-b4ea-bfa68be43bf2',
      employeeCode: 'MGR0001',
      name: 'Mike Manager',
      email: null,
      phone: null,
      avatarUrl: null,
      isActive: true,
      isVerified: true,
      lastLoginAt: DateTime.now().subtract(const Duration(days: 1)),
      roles: [
        Role(
          id: 6,
          name: 'Manager',
          slug: 'manager',
          outletId: 1,
          outletName: 'Main Restaurant',
        ),
      ],
      permissions: [
        'TABLE_VIEW',
        'TABLE_MERGE',
        'TABLE_TRANSFER',
        'ORDER_VIEW',
        'ORDER_CREATE',
        'ORDER_MODIFY',
        'KOT_SEND',
        'KOT_MODIFY',
        'KOT_REPRINT',
        'BILL_VIEW',
        'BILL_GENERATE',
        'BILL_REPRINT',
        'PAYMENT_COLLECT',
        'PAYMENT_SPLIT',
        'DISCOUNT_APPLY',
        'TIP_ADD',
        'ITEM_VIEW',
        'ITEM_CANCEL',
        'CATEGORY_VIEW',
        'REPORT_VIEW',
        'FLOOR_VIEW',
        'SECTION_VIEW',
      ],
      permissionsByModule: {
        'table': ['TABLE_VIEW', 'TABLE_MERGE', 'TABLE_TRANSFER'],
        'order': ['ORDER_VIEW', 'ORDER_CREATE', 'ORDER_MODIFY'],
        'kot': ['KOT_SEND', 'KOT_MODIFY', 'KOT_REPRINT'],
        'billing': ['BILL_VIEW', 'BILL_GENERATE', 'BILL_REPRINT'],
        'payment': ['PAYMENT_COLLECT', 'PAYMENT_SPLIT'],
        'discount': ['DISCOUNT_APPLY'],
        'tip': ['TIP_ADD'],
        'item': ['ITEM_VIEW', 'ITEM_CANCEL'],
        'category': ['CATEGORY_VIEW'],
        'report': ['REPORT_VIEW'],
        'floor': ['FLOOR_VIEW'],
        'section': ['SECTION_VIEW'],
      },
    ),
  ];

  static User? findByPasscode(String passcode) {
    try {
      return users.firstWhere((user) => user.employeeCode == passcode);
    } catch (_) {
      return null;
    }
  }

  static User? findByPin(String pin) {
    try {
      return users.firstWhere((user) => user.employeeCode == pin);
    } catch (_) {
      return null;
    }
  }

  static User? findByCredentials(String username, String password) {
    try {
      return users.firstWhere(
        (user) => user.employeeCode == username,
      );
    } catch (_) {
      return null;
    }
  }

  static List<User> getCaptains() {
    return users.where((user) => user.primaryRole == 'Captain').toList();
  }
}
