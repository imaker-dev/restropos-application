import 'package:equatable/equatable.dart';

class LoginWithEmailRequest extends Equatable {
  final String email;
  final String password;

  const LoginWithEmailRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };

  @override
  List<Object?> get props => [email, password];
}

class LoginWithPinRequest extends Equatable {
  final String employeeCode;
  final String pin;
  final int outletId;

  const LoginWithPinRequest({
    required this.employeeCode,
    required this.pin,
    required this.outletId,
  });

  Map<String, dynamic> toJson() => {
        'employeeCode': employeeCode,
        'pin': pin,
        'outletId': outletId,
      };

  @override
  List<Object?> get props => [employeeCode, pin, outletId];
}
