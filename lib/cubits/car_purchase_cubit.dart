import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:task_veetech/data/models/bank_model.dart';
import 'package:task_veetech/data/models/car_model.dart';


// States
abstract class CarPurchaseState extends Equatable {
  const CarPurchaseState();

  @override
  List<Object?> get props => [];
}

class CarPurchaseInitial extends CarPurchaseState {}

class CarSelected extends CarPurchaseState {
  final Car car;

  const CarSelected(this.car);

  @override
  List<Object?> get props => [car];
}

class PaymentMethodSelected extends CarPurchaseState {
  final Car car;
  final String paymentMethod; // cash or installment

  const PaymentMethodSelected(this.car, this.paymentMethod);

  @override
  List<Object?> get props => [car, paymentMethod];
}

class BankSelected extends CarPurchaseState {
  final Car car;
  final String paymentMethod;
  final Bank bank;
  final int installmentMonths;

  const BankSelected(this.car, this.paymentMethod, this.bank, this.installmentMonths);

  @override
  List<Object?> get props => [car, paymentMethod, bank, installmentMonths];
}

class PurchaseSubmitting extends CarPurchaseState {
  final Car car;

  const PurchaseSubmitting(this.car);

  @override
  List<Object?> get props => [car];
}

class PurchaseSuccess extends CarPurchaseState {
  final Car car;
  final String confirmationNumber;

  const PurchaseSuccess(this.car, this.confirmationNumber);

  @override
  List<Object?> get props => [car, confirmationNumber];
}

class PurchaseError extends CarPurchaseState {
  final String message;

  const PurchaseError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class CarPurchaseCubit extends Cubit<CarPurchaseState> {
  CarPurchaseCubit() : super(CarPurchaseInitial());

  void selectCar(Car car) {
    emit(CarSelected(car));
  }

  void selectPaymentMethod(Car car, String paymentMethod) {
    emit(PaymentMethodSelected(car, paymentMethod));
  }

  void selectBank(Car car, String paymentMethod, Bank bank, int installmentMonths) {
    emit(BankSelected(car, paymentMethod, bank, installmentMonths));
  }

  Future<void> submitPurchase(Car car, String paymentMethod, {Bank? bank, int? installmentMonths}) async {
    emit(PurchaseSubmitting(car));

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Generate confirmation number
      final confirmationNumber = 'CAR${DateTime.now().millisecondsSinceEpoch}';

      emit(PurchaseSuccess(car, confirmationNumber));
    } catch (e) {
      emit(PurchaseError(e.toString()));
    }
  }

  void reset() {
    emit(CarPurchaseInitial());
  }
}