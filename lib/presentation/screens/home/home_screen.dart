import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:task_veetech/cubits/auth_cubit.dart';
import 'package:task_veetech/cubits/wallet_cubit.dart';
import 'package:task_veetech/data/mock_data.dart';
import 'package:task_veetech/data/models/car_model.dart';
import 'package:task_veetech/presentation/screens/auth/login_screen.dart';
import 'package:task_veetech/presentation/screens/purchase/car_details_screen.dart';
import 'package:task_veetech/presentation/widgets/home/car_card.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:task_veetech/core/theme/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All'; // New, Used
  String? _selectedBrand;
  RangeValues _priceRange = const RangeValues(0, 10000000);
  RangeValues _installmentRange = const RangeValues(0, 100000);
  int? _selectedYear;
  String _sortBy = 'Recommended';

  final List<String> _filters = ['All', 'New', 'Used'];
  final List<String> _popularBrands = [
    'BMW',
    'Mercedes-Benz',
    'Audi',
    'Toyota',
    'Porsche',
    'Tesla',
    'Honda',
    'Land Rover',
    'Fiat',
    'Maruti',
  ];

  final Map<String, String> _brandLogos = MockData.getBrandLogos();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Car> get _filteredCars {
    var cars = MockData.getCars();

    // Type Filter
    if (_selectedFilter != 'All') {
      cars = cars
          .where((car) => car.type == _selectedFilter.toLowerCase())
          .toList();
    }

    // Brand Filter
    if (_selectedBrand != null) {
      cars = cars.where((car) => car.brand == _selectedBrand).toList();
    }

    // Search Query
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      cars = cars.where((car) {
        return car.name.toLowerCase().contains(query) ||
            car.brand.toLowerCase().contains(query) ||
            car.model.toLowerCase().contains(query);
      }).toList();
    }

    // Price Range
    cars = cars.where((car) {
      return car.price >= _priceRange.start && car.price <= _priceRange.end;
    }).toList();

    // Installment Range (EMI)
    cars = cars.where((car) {
      final minEMI = _calculateMinEMI(car);
      return minEMI >= _installmentRange.start &&
          minEMI <= _installmentRange.end;
    }).toList();

    // Year Filter
    if (_selectedYear != null) {
      cars = cars.where((car) => car.year >= _selectedYear!).toList();
    }

    // Sorting
    if (_sortBy == 'Price: Low to High') {
      cars.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'Price: High to Low') {
      cars.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'Newest First') {
      cars.sort((a, b) => b.year.compareTo(a.year));
    }

    return cars;
  }

  double _calculateMinEMI(Car car) {
    final banks = MockData.getBanks();
    double minEMI = double.infinity;

    for (final bank in banks) {
      // EMI Calculation Logic (Simplified for filtering)
      // min Down Payment
      final downPayment = car.price * (bank.minDownPaymentPercentage / 100);
      final loanAmount = car.price - downPayment;

      // Use max months for lowest EMI
      final months = bank.maxInstallmentMonths;
      double interestRate = bank.interestRate / 100;

      // Handle 0% Interest scenarios (e.g. from bank benefit or special financing)
      // For filtering purposes, we'll use the nominal rate
      bool hasZeroInterest = car.specialFinancingOffer?.contains('0%') ?? false;

      double monthlyInterest = interestRate / 12;
      double emi;

      if (hasZeroInterest || monthlyInterest == 0) {
        emi = loanAmount / months;
      } else {
        // Standard EMI Formula: P * r * (1 + r)^n / ((1 + r)^n - 1)
        emi =
            (loanAmount *
                monthlyInterest *
                math.pow(1 + monthlyInterest, months)) /
            (math.pow(1 + monthlyInterest, months) - 1);
      }

      if (emi < minEMI) minEMI = emi;
    }

    return minEMI == double.infinity ? 0 : minEMI;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(child: FadeInDown(child: _buildHeader(context))),

            // Wallet Balance Card
            SliverToBoxAdapter(
              child: FadeIn(
                delay: const Duration(milliseconds: 100),
                child: _buildWalletCard(),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _buildSearchBar(),
              ),
            ),

            // Popular Brands
            SliverToBoxAdapter(
              child: FadeInLeft(
                delay: const Duration(milliseconds: 300),
                child: _buildPopularBrands(),
              ),
            ),

            // Filter Chips and Sort
            SliverToBoxAdapter(
              child: FadeInLeft(
                delay: const Duration(milliseconds: 400),
                child: _buildFilterAndSort(),
              ),
            ),

            // Car List
            _buildSliverCarList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                "V",
                style: GoogleFonts.carroisGothic(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final userName = state is AuthAuthenticated
                        ? state.user.name
                        : 'User';
                    return Text(
                      'Hello, $userName 👋',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                        letterSpacing: -0.5,
                      ),
                    );
                  },
                ),
                Text(
                  'Find your dream car today',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, size: 20),
              onPressed: () => _showLogoutDialog(context),
              color: AppColors.error,
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthCubit>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withBlue(150)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.account_balance_wallet,
              size: 100,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Current Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BlocBuilder<WalletCubit, WalletState>(
                builder: (context, state) {
                  final balance = context.read<WalletCubit>().currentBalance;
                  return Text(
                    NumberFormat.currency(
                      symbol: 'EGP ',
                      decimalDigits: 0,
                    ).format(balance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Available for immediate purchase',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search brand, model, or car name...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.tune_rounded, color: Colors.white),
              onPressed: () => _showFilterBottomSheet(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularBrands() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            'Popular Brands',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _popularBrands.length,
            itemBuilder: (context, index) {
              final brand = _popularBrands[index];
              final isSelected = _selectedBrand == brand;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedBrand = isSelected ? null : brand;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 15),
                  width: 80,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _brandLogos.containsKey(brand)
                          ? CachedNetworkImage(
                              imageUrl: _brandLogos[brand]!,
                              height: 35,
                              width: 35,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Icon(
                                Icons.directions_car_rounded,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primary,
                                size: 30,
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.directions_car_rounded,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primary,
                                size: 30,
                              ),
                            )
                          : Icon(
                              Icons.directions_car_rounded,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primary,
                              size: 30,
                            ),
                      const SizedBox(height: 8),
                      Text(
                        brand,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF2C3E50),
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterAndSort() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          _buildFilterChips(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredCars.length} cars found',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox(),
                  icon: const Icon(
                    Icons.sort_rounded,
                    color: AppColors.primary,
                  ),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  items:
                      [
                        'Recommended',
                        'Price: Low to High',
                        'Price: High to Low',
                        'Newest First',
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _sortBy = newValue);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter);
                }
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey.shade200,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverCarList() {
    final cars = _filteredCars;

    if (cars.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No cars found',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final car = cars[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CarCard(
              car: car,
              index: index,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CarDetailsScreen(car: car)),
                );
              },
            ),
          );
        }, childCount: cars.length),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _selectedBrand = null;
                        _priceRange = const RangeValues(0, 10000000);
                        _installmentRange = const RangeValues(0, 100000);
                        _selectedYear = null;
                      });
                      setState(() {});
                    },
                    child: const Text('Reset All'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Price Range (EGP)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 10000000,
                divisions: 100,
                activeColor: AppColors.primary,
                inactiveColor: Colors.grey.shade200,
                labels: RangeLabels(
                  NumberFormat.compact().format(_priceRange.start),
                  NumberFormat.compact().format(_priceRange.end),
                ),
                onChanged: (values) {
                  setModalState(() => _priceRange = values);
                  setState(() {});
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Monthly Installment (EGP)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              RangeSlider(
                values: _installmentRange,
                min: 0,
                max: 100000,
                divisions: 100,
                activeColor: AppColors.primary,
                inactiveColor: Colors.grey.shade200,
                labels: RangeLabels(
                  NumberFormat.compact().format(_installmentRange.start),
                  NumberFormat.compact().format(_installmentRange.end),
                ),
                onChanged: (values) {
                  setModalState(() => _installmentRange = values);
                  setState(() {});
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Minimum Year',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [2020, 2021, 2022, 2023, 2024].map((year) {
                    final isSelected = _selectedYear == year;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(year.toString()),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedYear = selected ? year : null;
                          });
                          setState(() {});
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
