import 'package:equatable/equatable.dart';

import '../data/auth_repository.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class SignUpSuccess extends AuthState {
  final String message;
  const SignUpSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class SignInSuccess extends AuthState {
  final LoginResult result;
  const SignInSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}
