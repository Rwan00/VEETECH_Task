import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_veetech/cubits/car_purchase_cubit.dart';
import 'package:task_veetech/data/mock_data.dart';
import 'package:task_veetech/data/models/bank_model.dart';
import 'package:task_veetech/data/models/car_model.dart';
import 'package:task_veetech/presentation/screens/purchase/installment_details_screen.dart';
import 'package:animate_do/animate_do.dart';
import 'package:task_veetech/core/theme/colors.dart';

class BankSelectionScreen extends StatefulWidget {
  final Car car;

  const BankSelectionScreen({super.key, required this.car});

  @override
  State<BankSelectionScreen> createState() => _BankSelectionScreenState();
}

class _BankSelectionScreenState extends State<BankSelectionScreen> {
  Bank? _selectedBank;
  final List<Bank> _banks = MockData.getBanks();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Select Bank'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Choose a bank to finance your ${widget.car.name}',
                        style: const TextStyle(
                          color: Color(0xFF2C3E50),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            FadeInLeft(
              delay: const Duration(milliseconds: 200),
              child: const Text(
                'Available Banks',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2C3E50),
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Bank List
            ..._banks.asMap().entries.map((entry) {
              final index = entry.key;
              final bank = entry.value;
              return FadeInUp(
                delay: Duration(milliseconds: 300 + (index * 100)),
                child: _buildBankCard(bank),
              );
            }).toList(),
          ],
        ),
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
          onPressed: _selectedBank == null ? null : _handleContinue,
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
            'Continue to Plan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _handleContinue() {
    if (_selectedBank != null) {
      context.read<CarPurchaseCubit>().selectBank(
        widget.car,
        'installment',
        _selectedBank!,
        12,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              InstallmentDetailsScreen(car: widget.car, bank: _selectedBank!),
        ),
      );
    }
  }

  Widget _buildBankCard(Bank bank) {
    final isSelected = _selectedBank?.id == bank.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBank = bank;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                      bank.logoUrl,
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
                        bank.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Licensed Finance Partner',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Radio<String>(
                  value: bank.id,
                  groupValue: _selectedBank?.id,
                  onChanged: (val) {
                    setState(() {
                      _selectedBank = bank;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBankDetail(
                    'Interest Rate',
                    '${bank.interestRate}%',
                    Icons.percent_rounded,
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.grey.shade200),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBankDetail(
                    'Max Period',
                    '${bank.maxInstallmentMonths} mos',
                    Icons.calendar_today_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
