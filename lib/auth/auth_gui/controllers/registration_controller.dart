import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mtaasuite/auth/model/user_mode.dart';
import 'package:mtaasuite/auth/model/location_models.dart';
import 'package:mtaasuite/services/phone_auth_service.dart';
import 'package:mtaasuite/auth/auth_gui/utils/location_utils.dart';
import 'package:mtaasuite/auth/auth_gui/utils/form_validators.dart';

class RegistrationController extends ChangeNotifier {
  // Form keys
  final GlobalKey<FormState> personalFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> locationFormKey = GlobalKey<FormState>();

  // Page controller
  final PageController pageController = PageController();
  int currentPage = 0;

  // Location state
  List<Region> regions = [];
  List<District> districts = [];
  List<Ward> wards = [];
  String selectedRegion = '';
  String selectedDistrict = '';
  String selectedWard = '';
  bool loadingRegions = false;
  bool loadingDistricts = false;
  bool loadingWards = false;

  // User data
  String name = '';
  String completePhoneNumber = '';
  String userType = 'citizen'; // citizen | ward
  String gender = 'male';
  DateTime? selectedDate;
  String address = '';
  String street = '';
  String houseNumber = '';
  String? checkNumber;

  // Controllers
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  // OTP state
  bool otpSent = false;
  Timer? resendTimer;
  int resendCountdown = 0;
  bool get canResendOTP => resendCountdown == 0;

  // Ward validation data
  Map<String, dynamic>? wardJsonData;

  // Callbacks for auth operations
  Future<bool> Function(String phone, UserModel user)? sendRegistrationOTP;
  Future<bool> Function(String otp)? verifyOTP;

  RegistrationController({
    this.sendRegistrationOTP,
    this.verifyOTP,
  }) {
    // Set initial fallback regions
    _setInitialRegions();
    // Then load from API
    initialize();
  }

  void _setInitialRegions() {
    // Fallback regions for immediate display
    regions = [
      Region(name: 'Arusha'),
      Region(name: 'Dar es Salaam'),
      Region(name: 'Dodoma'),
      Region(name: 'Geita'),
      Region(name: 'Iringa'),
      Region(name: 'Kagera'),
      Region(name: 'Katavi'),
      Region(name: 'Kigoma'),
      Region(name: 'Kilimanjaro'),
      Region(name: 'Lindi'),
      Region(name: 'Manyara'),
      Region(name: 'Mara'),
      Region(name: 'Mbeya'),
      Region(name: 'Mjini Magharibi'),
      Region(name: 'Morogoro'),
      Region(name: 'Mtwara'),
      Region(name: 'Mwanza'),
      Region(name: 'Njombe'),
      Region(name: 'Pemba North'),
      Region(name: 'Pemba South'),
      Region(name: 'Pwani'),
      Region(name: 'Rukwa'),
      Region(name: 'Ruvuma'),
      Region(name: 'Shinyanga'),
      Region(name: 'Simiyu'),
      Region(name: 'Singida'),
      Region(name: 'Songwe'),
      Region(name: 'Tabora'),
      Region(name: 'Tanga'),
      Region(name: 'Unguja North'),
      Region(name: 'Unguja South'),
    ];
  }

  // Add separate initialize method
  Future<void> initialize() async {
    await loadWardJson();
    await loadRegions();
  }

  Future<void> loadWardJson() async {
    try {
      wardJsonData = await LocationUtils.loadWardValidationData();
    } catch (e) {
      wardJsonData = {};
    }
    notifyListeners();
  }

  Future<void> loadRegions() async {
    loadingRegions = true;
    notifyListeners();
    
    try {
      regions = await LocationUtils.loadRegions();
      loadingRegions = false;
    } catch (e) {
      loadingRegions = false;
      // Handle error - could show snackbar
    }
    notifyListeners();
  }

  Future<void> loadDistricts(String regionName) async {
    loadingDistricts = true;
    districts = [];
    selectedDistrict = '';
    wards = [];
    selectedWard = '';
    notifyListeners();
    
    try {
      districts = await LocationUtils.loadDistricts(regionName);
      loadingDistricts = false;
    } catch (e) {
      loadingDistricts = false;
      // Handle error
    }
    notifyListeners();
  }

  Future<void> loadWards() async {
    if (selectedRegion.isEmpty || selectedDistrict.isEmpty) {
      wards = [];
      selectedWard = '';
      notifyListeners();
      return;
    }
    
    loadingWards = true;
    wards = [];
    selectedWard = '';
    notifyListeners();
    
    try {
      wards = await LocationUtils.loadWards(selectedRegion, selectedDistrict);
      loadingWards = false;
    } catch (e) {
      loadingWards = false;
      // Handle error
    }
    notifyListeners();
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.tealAccent,
              onPrimary: Colors.black,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.tealAccent),
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != selectedDate) {
      selectedDate = picked;
      dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      notifyListeners();
    }
  }

  void updateUserType(String type) {
    userType = type;
    if (type != 'ward') {
      checkNumber = null;
    }
    notifyListeners();
  }

  void updateGender(String newGender) {
    gender = newGender;
    notifyListeners();
  }

  void updateRegion(String region) {
    selectedRegion = region;
    if (selectedRegion.isNotEmpty) {
      loadDistricts(selectedRegion);
    }
    notifyListeners();
  }

  void updateDistrict(String district) {
    selectedDistrict = district;
    if (selectedDistrict.isNotEmpty) {
      loadWards();
    }
    notifyListeners();
  }

  void updateWard(String ward) {
    selectedWard = ward;
    notifyListeners();
  }

  void updatePhoneNumber(String phone) {
    completePhoneNumber = phone;
    notifyListeners();
  }

  void nextPage() {
    if (currentPage < 2) {
      if (validateCurrentPage()) {
        saveCurrentPageData();
        pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      sendOTP();
    }
  }

  void previousPage() {
    if (currentPage > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void onPageChanged(int page) {
    currentPage = page;
    notifyListeners();
  }

  bool validateCurrentPage() {
    switch (currentPage) {
      case 0:
        return personalFormKey.currentState?.validate() ?? false;
      case 1:
        return locationFormKey.currentState?.validate() ?? false;
      case 2:
        return true; // Verification page
      default:
        return false;
    }
  }

  void saveCurrentPageData() {
    switch (currentPage) {
      case 0:
        personalFormKey.currentState?.save();
        break;
      case 1:
        locationFormKey.currentState?.save();
        break;
    }
  }

  Future<void> sendOTP() async {
    // Validate all forms
    bool personalValid = personalFormKey.currentState?.validate() ?? false;
    if (!personalValid) {
      // Navigate to personal info page
      pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      return;
    }

    bool locationValid = locationFormKey.currentState?.validate() ?? false;
    if (!locationValid) {
      // Navigate to location info page
      pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      return;
    }

    // Save form data
    personalFormKey.currentState!.save();
    locationFormKey.currentState!.save();

    // Validate ward check number if needed
    if (userType == 'ward') {
      if (checkNumber?.trim().isEmpty ?? true) {
        // Show error - this should be handled by the UI
        return;
      }
      final isValid = await LocationUtils.validateCheckNumber(checkNumber!.trim(), wardJsonData);
      if (!isValid) {
        // Show error - this should be handled by the UI
        return;
      }
    }

    // Create user data
    final userData = UserModel(
      uid: 'temp',
      type: userType,
      phone: completePhoneNumber,
      name: name,
      gender: gender,
      dob: dobController.text,
      address: address,
      region: selectedRegion,
      district: selectedDistrict,
      ward: selectedWard,
      street: street,
      houseNumber: houseNumber,
      checkNumber: userType == 'ward' ? checkNumber : null,
      profilePicUrl: null,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    // Send OTP using callback
    if (sendRegistrationOTP != null) {
      final success = await sendRegistrationOTP!(completePhoneNumber, userData);
      if (success) {
        otpSent = true;
        startResendTimer();
        // Navigate to verification page
        pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }
    notifyListeners();
  }

  void startResendTimer() {
    resendCountdown = 60;
    resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      resendCountdown--;
      if (resendCountdown <= 0) {
        timer.cancel();
        resendTimer = null;
      }
      notifyListeners();
    });
  }

  void stopResendTimer() {
    resendTimer?.cancel();
    resendTimer = null;
    resendCountdown = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    phoneController.dispose();
    dobController.dispose();
    pageController.dispose();
    stopResendTimer();
    super.dispose();
  }
}