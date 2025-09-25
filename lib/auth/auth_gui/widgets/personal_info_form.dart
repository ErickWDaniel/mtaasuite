import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:mtaasuite/auth/auth_gui/controllers/registration_controller.dart';
import 'package:mtaasuite/auth/auth_gui/widgets/form_decorations.dart';
import 'package:mtaasuite/auth/auth_gui/utils/form_validators.dart';
import 'package:mtaasuite/services/translation_service.dart';

class PersonalInfoForm extends StatelessWidget {
  final RegistrationController controller;

  const PersonalInfoForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.personalFormKey,
      child: SingleChildScrollView(
        child: Container(
          decoration: FormDecorations.cardDecoration(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('auth.register.personal_info'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.tealAccent,
                ),
              ),
              const SizedBox(height: 16),

              // Full Name
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: FormDecorations.textFieldDecoration(
                  labelKey: 'auth.register.full_name',
                  hintKey: 'auth.register.full_name_hint',
                  icon: Icons.person,
                ),
                validator: (value) => FormValidators.validateName(value),
                onSaved: (value) => controller.name = value?.trim() ?? '',
              ),
              const SizedBox(height: 16),

              // Phone Number
              IntlPhoneField(
                controller: controller.phoneController,
                decoration: FormDecorations.textFieldDecoration(
                  labelKey: 'auth.register.phone',
                  hintKey: 'auth.register.phone_hint',
                  icon: Icons.phone,
                ).copyWith(
                  // IntlPhoneField uses different structure, so we adapt
                  labelText: tr('auth.register.phone'),
                  hintText: tr('auth.register.phone_hint'),
                  labelStyle: const TextStyle(color: Colors.tealAccent),
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.phone, color: Colors.tealAccent),
                ),
                initialCountryCode: 'TZ',
                style: const TextStyle(color: Colors.white),
                dropdownTextStyle: const TextStyle(color: Colors.white),
                onChanged: (phone) => controller.updatePhoneNumber(phone.completeNumber),
                validator: (phone) => FormValidators.validatePhone(phone?.completeNumber),
              ),
              const SizedBox(height: 16),

              // User Type Selection
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.updateUserType('citizen'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: controller.userType == 'citizen'
                              ? Colors.tealAccent
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.tealAccent,
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people,
                              color: controller.userType == 'citizen'
                                  ? Colors.black
                                  : Colors.tealAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tr('auth.register.citizen'),
                              style: TextStyle(
                                color: controller.userType == 'citizen'
                                    ? Colors.black
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.updateUserType('ward'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: controller.userType == 'ward'
                              ? Colors.tealAccent
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.tealAccent,
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              color: controller.userType == 'ward'
                                  ? Colors.black
                                  : Colors.tealAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tr('auth.register.ward_officer'),
                              style: TextStyle(
                                color: controller.userType == 'ward'
                                    ? Colors.black
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Gender
              DropdownButtonFormField<String>(
                value: controller.gender,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                items: [
                  DropdownMenuItem(
                    value: 'male',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.male,
                          size: 20,
                          color: Colors.tealAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tr('auth.register.male'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'female',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.female,
                          size: 20,
                          color: Colors.tealAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tr('auth.register.female'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) => controller.updateGender(value!),
                decoration: FormDecorations.dropdownDecoration(
                  labelKey: 'auth.register.gender',
                  icon: Icons.wc,
                ),
              ),
              const SizedBox(height: 16),

              // Date of Birth
              TextFormField(
                controller: controller.dobController,
                style: const TextStyle(color: Colors.white),
                decoration: FormDecorations.textFieldDecoration(
                  labelKey: 'auth.register.date_of_birth',
                  hintKey: 'auth.register.dob_hint',
                  icon: Icons.calendar_today,
                ),
                readOnly: true,
                onTap: () => controller.selectDate(context),
                validator: (value) => FormValidators.validateDateOfBirth(value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}