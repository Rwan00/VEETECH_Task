import 'package:equatable/equatable.dart';

class Bank extends Equatable {
  final String id;
  final String name;
  final String logoUrl;
  final double interestRate;
  final int maxInstallmentMonths;
  final double minDownPaymentPercentage;

  const Bank({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.interestRate,
    required this.maxInstallmentMonths,
    required this.minDownPaymentPercentage,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        logoUrl,
        interestRate,
        maxInstallmentMonths,
        minDownPaymentPercentage,
      ];
}