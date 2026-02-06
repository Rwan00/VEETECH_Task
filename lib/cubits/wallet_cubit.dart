import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// States
abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {
  final double balance;

  const WalletInitial({this.balance = 30000.0});

  @override
  List<Object?> get props => [balance];
}

class WalletUpdated extends WalletState {
  final double balance;

  const WalletUpdated(this.balance);

  @override
  List<Object?> get props => [balance];
}

// Cubit
class WalletCubit extends Cubit<WalletState> {
  WalletCubit() : super(const WalletInitial());

  double get currentBalance {
    if (state is WalletInitial) {
      return (state as WalletInitial).balance;
    } else if (state is WalletUpdated) {
      return (state as WalletUpdated).balance;
    }
    return 30000.0;
  }

  void deductAmount(double amount) {
    final newBalance = currentBalance - amount;
    emit(WalletUpdated(newBalance));
  }

  void addAmount(double amount) {
    final newBalance = currentBalance + amount;
    emit(WalletUpdated(newBalance));
  }

  void resetBalance() {
    emit(const WalletInitial());
  }
}