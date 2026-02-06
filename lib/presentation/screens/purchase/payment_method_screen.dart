import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:task_veetech/cubits/car_purchase_cubit.dart';
import 'package:task_veetech/cubits/wallet_cubit.dart';
import 'package:task_veetech/data/models/car_model.dart';
import 'package:task_veetech/presentation/screens/purchase/bank_selection_screen.dart';
import 'package:task_veetech/presentation/screens/purchase/purchase_confirmation_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import 'package:task_veetech/core/theme/colors.dart';

class PaymentMethodScreen extends StatefulWidget {
  final Car car;

  const PaymentMethodScreen({super.key, required this.car});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Payment Method'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
      ),
      body: BlocBuilder<WalletCubit, WalletState>(
        builder: (context, walletState) {
          final walletBalance = context.read<WalletCubit>().currentBalance;
          final canPayCash = walletBalance >= widget.car.price;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Car Summary
                FadeInDown(child: _buildCarSummary()),
                const SizedBox(height: 24),

                // Wallet Balance
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _buildWalletBalance(walletBalance),
                ),
                const SizedBox(height: 32),

                // Title
                FadeInLeft(
                  delay: const Duration(milliseconds: 400),
                  child: const Text(
                    'Choose Payment Method',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2C3E50),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Cash Payment Option
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: _buildPaymentOption(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Direct Cash Payment',
                    description: 'One-time payment from your wallet',
                    value: 'cash',
                    isEnabled: canPayCash,
                    insufficientFunds: !canPayCash,
                  ),
                ),
                const SizedBox(height: 16),

                // Installment Payment Option
                FadeInUp(
                  delay: const Duration(milliseconds: 800),
                  child: _buildPaymentOption(
                    icon: Icons.credit_card_rounded,
                    title: 'Financed Installments',
                    description: 'Flexible monthly payment plans',
                    value: 'installment',
                    isEnabled: true,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _selectedMethod == null ? null : _handleContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 0,
            disabledBackgroundColor: Colors.grey.shade200,
          ),
          child: const Text(
            'Proceed to Checkout',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _handleContinue() {
    if (_selectedMethod == 'cash') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Confirm Purchase'),
          content: Text(
            'Complete purchase for ${widget.car.name}?\n\n${NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0).format(widget.car.price)} will be deducted from your wallet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processCashPayment();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    } else if (_selectedMethod == 'installment') {
      context.read<CarPurchaseCubit>().selectPaymentMethod(
        widget.car,
        'installment',
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BankSelectionScreen(car: widget.car)),
      );
    }
  }

  void _processCashPayment() {
    context.read<WalletCubit>().deductAmount(widget.car.price);
    context.read<CarPurchaseCubit>().submitPurchase(widget.car, 'cash');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PurchaseConfirmationScreen(car: widget.car, paymentMethod: 'cash'),
      ),
      (route) => route.isFirst,
    );
  }

  Widget _buildCarSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: CachedNetworkImage(
              imageUrl: widget.car.imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.car.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.car.year} • ${widget.car.transmission}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Text(
                  NumberFormat.currency(
                    symbol: 'EGP ',
                    decimalDigits: 0,
                  ).format(widget.car.price),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletBalance(double balance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C3E50).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wallet Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                NumberFormat.currency(
                  symbol: 'EGP ',
                  decimalDigits: 0,
                ).format(balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String description,
    required String value,
    required bool isEnabled,
    bool insufficientFunds = false,
  }) {
    final isSelected = _selectedMethod == value;

    return GestureDetector(
      onTap: isEnabled
          ? () {
              setState(() {
                _selectedMethod = value;
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isEnabled
                ? Colors.grey.shade200
                : Colors.grey.shade100,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEnabled
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isEnabled ? AppColors.primary : Colors.grey[400],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isEnabled
                          ? const Color(0xFF2C3E50)
                          : Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isEnabled ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                  if (insufficientFunds) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Insufficient Funds',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IgnorePointer(
              child: Radio<String>(
                value: value,
                groupValue: _selectedMethod,
                onChanged: (_) {},
                activeColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
