import 'package:equatable/equatable.dart';

class Car extends Equatable {
  final String id;
  final String name;
  final String brand;
  final String model;
  final int year;
  final double price;
  final String imageUrl;
  final String type; // new or used
  final int mileage;
  final String transmission;
  final String fuelType;
  final String color;
  final List<String> features;

  const Car({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.year,
    required this.price,
    required this.imageUrl,
    required this.type,
    required this.mileage,
    required this.transmission,
    required this.fuelType,
    required this.color,
    required this.features,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        brand,
        model,
        year,
        price,
        imageUrl,
        type,
        mileage,
        transmission,
        fuelType,
        color,
        features,
      ];
}