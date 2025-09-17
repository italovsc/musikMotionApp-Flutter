abstract class AuthEvent {}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String lastName;
  final String address;
  final String city;
  final String state;

  AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.lastName,
    required this.address,
    required this.city,
    required this.state,
  });
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  AuthLoginRequested({required this.email, required this.password});
}

class AuthLogoutRequested extends AuthEvent {}
