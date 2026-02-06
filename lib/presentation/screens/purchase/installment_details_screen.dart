import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:task_veetech/cubits/car_purchase_cubit.dart';
import 'package:task_veetech/cubits/wallet_cubit.dart';
import 'package:task_veetech/data/models/bank_model.dart';
import 'package:task_veetech/data/models/car_model.dart';
import 'package:task_veetech/presentation/screens/purchase/purchase_confirmation_screen.dart';
import 'package:animate_do/animate_do.dart';
import 'package:task_veetech/core/theme/colors.dart';

class InstallmentDetailsScreen extends StatefulWidget {
  final Car car;
  final Bank bank;

  const InstallmentDetailsScreen({
    super.key,
    required this.car,
    required this.bank,
  });

  @override
  State<InstallmentDetailsScreen> createState() =>
      _InstallmentDetailsScreenState();
}

class _InstallmentDetailsScreenState extends State<InstallmentDetailsScreen> {
  int _selectedMonths = 12;
  late List<int> _availableMonths;

  @override
  void initState() {
    super.initState();
    _availableMonths = [12, 24, 36, 48];
    if (widget.bank.maxInstallmentMonths >= 60) {
      _availableMonths.add(60);
    }
    _availableMonths = _availableMonths
        .where((m) => m <= widget.bank.maxInstallmentMonths)
        .toList();
  }

  double get downPayment =>
      widget.car.price * widget.bank.minDownPaymentPercentage / 100;

  double get loanAmount => widget.car.price - downPayment;

  double get monthlyPayment {
    final principal = loanAmount;
    final monthlyRate = widget.bank.interestRate / 100 / 12;
    final n = _selectedMonths.toDouble();

    if (monthlyRate == 0) return principal / n;

    return principal *
        (monthlyRate * math.pow(1 + monthlyRate, n)) /
        (math.pow(1 + monthlyRate, n) - 1);
  }

  double get totalAmount => downPayment + (monthlyPayment * _selectedMonths);

  double get totalInterest => totalAmount - widget.car.price;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'EGP ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Finance Details'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
      ),
      body: BlocBuilder<WalletCubit, WalletState>(
        builder: (context, walletState) {
          final walletBalance = context.read<WalletCubit>().currentBalance;
          final canAffordDownPayment = walletBalance >= downPayment;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bank Info
                FadeInDown(child: _buildBankInfo()),
                const SizedBox(height: 24),

                // Selection Header
                FadeInLeft(
                  delay: const Duration(milliseconds: 200),
                  child: const Text(
                    'Choose Finance Period',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2C3E50),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Period Selection
                _buildPeriodSelection(),
                const SizedBox(height: 32),

                // Payment Summary
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: _buildPaymentSummary(
                    canAffordDownPayment,
                    currencyFormat,
                  ),
                ),
                const SizedBox(height: 32),

                // Installment Table
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: _buildInstallmentTable(currencyFormat),
                ),

                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return BlocBuilder<WalletCubit, WalletState>(
      builder: (context, state) {
        final walletBalance = context.read<WalletCubit>().currentBalance;
        final canAffordDownPayment = walletBalance >= downPayment;

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
              onPressed: canAffordDownPayment ? _handleSubmit : null,
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
                'Submit Application',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleSubmit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Application'),
        content: Text(
          'Down payment of ${NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0).format(downPayment)} will be deducted from your wallet.\n\nYou will pay ${NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0).format(monthlyPayment)} monthly for $_selectedMonths months.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processInstallment();
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
  }

  void _processInstallment() {
    context.read<WalletCubit>().deductAmount(downPayment);
    context.read<CarPurchaseCubit>().submitPurchase(
      widget.car,
      'installment',
      bank: widget.bank,
      installmentMonths: _selectedMonths,
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => PurchaseConfirmationScreen(
          car: widget.car,
          paymentMethod: 'installment',
          bank: widget.bank,
          installmentMonths: _selectedMonths,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  Widget _buildBankInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                widget.bank.logoUrl,
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.bank.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Finance Rate: ${widget.bank.interestRate}%',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelection() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _availableMonths.map((months) {
        final isSelected = _selectedMonths == months;
        return GestureDetector(
          onTap: () => setState(() => _selectedMonths = months),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade200,
                width: 1.5,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Text(
              '$months mos',
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentSummary(bool canAfford, NumberFormat formatter) {
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
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Finance Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildSummaryRow('Down Payment', formatter.format(downPayment)),
          _buildSummaryRow('Loan Amount', formatter.format(loanAmount)),
          _buildSummaryRow('Monthly Payment', formatter.format(monthlyPayment)),
          _buildSummaryRow('Total Interest', formatter.format(totalInterest)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white12),
          ),
          _buildSummaryRow(
            'Total Commitment',
            formatter.format(totalAmount),
            isTotal: true,
          ),
          if (!canAfford) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Insufficient balance for down payment',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.white : Colors.white70,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTotal ? 20 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentTable(NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Proposed Schedule',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),

          ...List.generate(
            _selectedMonths > 4 ? 4 : _selectedMonths,
            (index) => _buildTableRow(index + 1, monthlyPayment, formatter),
          ),

          if (_selectedMonths > 4)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  '... plus ${_selectedMonths - 4} remaining payments',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableRow(int month, double amount, NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade50)),
      ),
      child: Row(
        children: [
          Text(
            'Month $month',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            formatter.format(amount),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }
}
