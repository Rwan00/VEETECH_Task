import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:task_veetech/data/models/user_model.dart';


// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Simple validation
      if (email.isEmpty || password.isEmpty) {
        emit(const AuthError('Please fill in all fields'));
        return;
      }

      if (!email.contains('@')) {
        emit(const AuthError('Please enter a valid email'));
        return;
      }

      if (password.length < 6) {
        emit(const AuthError('Password must be at least 6 characters'));
        return;
      }

      // Create user
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: email.split('@')[0].toUpperCase(),
        email: email,
        phone: '+20 100 000 0000',
      );

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> register(String name, String email, String password, String phone) async {
    emit(AuthLoading());
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Simple validation
      if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
        emit(const AuthError('Please fill in all fields'));
        return;
      }

      if (!email.contains('@')) {
        emit(const AuthError('Please enter a valid email'));
        return;
      }

      if (password.length < 6) {
        emit(const AuthError('Password must be at least 6 characters'));
        return;
      }

      // Create user
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        phone: phone,
      );

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void logout() {
    emit(AuthUnauthenticated());
  }
}