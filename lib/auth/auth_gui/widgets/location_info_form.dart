import 'package:flutter/material.dart';
import 'package:mtaasuite/auth/auth_gui/controllers/registration_controller.dart';
import 'package:mtaasuite/auth/auth_gui/widgets/form_decorations.dart';
import 'package:mtaasuite/auth/auth_gui/utils/form_validators.dart';
import 'package:mtaasuite/auth/model/location_models.dart';
import 'package:mtaasuite/services/translation_service.dart';

class LocationInfoForm extends StatelessWidget {
  final RegistrationController controller;

  const LocationInfoForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.locationFormKey,
      child: SingleChildScrollView(
        child: Container(
          decoration: FormDecorations.cardDecoration(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('auth.register.location_info'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.tealAccent,
                ),
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: FormDecorations.textFieldDecoration(
                  labelKey: 'auth.register.address',
                  hintKey: 'auth.register.address_hint',
                  icon: Icons.location_on,
                ),
                onSaved: (value) => controller.address = value?.trim() ?? '',
              ),
              const SizedBox(height: 16),

              // Street/Village
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: FormDecorations.textFieldDecoration(
                  labelKey: 'auth.register.street',
                  hintKey: 'auth.register.street_hint',
                  icon: Icons.streetview,
                ),
                onSaved: (value) => controller.street = value?.trim() ?? '',
              ),
              const SizedBox(height: 16),

              // House Number
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: FormDecorations.textFieldDecoration(
                  labelKey: 'auth.register.house_number',
                  hintKey: 'auth.register.house_number_hint',
                  icon: Icons.home,
                ),
                onSaved: (value) => controller.houseNumber = value?.trim() ?? '',
              ),
              const SizedBox(height: 16),

              // Region
              DropdownButtonFormField<String>(
                value: controller.selectedRegion.isEmpty ? null : controller.selectedRegion,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                decoration: FormDecorations.dropdownDecoration(
                  labelKey: 'auth.register.region',
                  hintKey: controller.loadingRegions
                      ? 'auth.register.loading_regions'
                      : 'auth.register.select_region',
                  icon: Icons.map,
                ),
                items: controller.regions
                    .map(
                      (region) => DropdownMenuItem(
                        value: region.name,
                        child: Text(
                          region.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: controller.loadingRegions
                    ? null
                    : (value) => controller.updateRegion(value ?? ''),
                validator: (value) => FormValidators.validateRegion(value),
              ),
              if (controller.loadingRegions)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: LinearProgressIndicator(color: Colors.tealAccent),
                ),
              const SizedBox(height: 16),

              // District
              if (controller.selectedRegion.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: controller.selectedDistrict.isEmpty ? null : controller.selectedDistrict,
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                  decoration: FormDecorations.dropdownDecoration(
                    labelKey: 'auth.register.district',
                    hintKey: controller.loadingDistricts
                        ? 'auth.register.loading_districts'
                        : 'auth.register.select_district',
                    icon: Icons.location_city,
                  ),
                  items: controller.districts
                      .map(
                        (district) => DropdownMenuItem(
                          value: district.name,
                          child: Text(
                            district.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: controller.loadingDistricts
                      ? null
                      : (value) => controller.updateDistrict(value ?? ''),
                  validator: (value) => FormValidators.validateDistrict(value),
                ),
              if (controller.selectedRegion.isNotEmpty && controller.loadingDistricts)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: LinearProgressIndicator(color: Colors.tealAccent),
                ),
              if (controller.selectedDistrict.isNotEmpty) const SizedBox(height: 16),

              // Ward
              if (controller.selectedDistrict.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: controller.selectedWard.isEmpty ? null : controller.selectedWard,
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                  decoration: FormDecorations.dropdownDecoration(
                    labelKey: 'auth.register.ward',
                    hintKey: controller.loadingWards
                        ? 'auth.register.loading_wards'
                        : 'auth.register.select_ward',
                    icon: Icons.home_work,
                  ),
                  items: controller.wards
                      .map(
                        (ward) => DropdownMenuItem(
                          value: ward.name,
                          child: Text(
                            ward.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: controller.loadingWards
                      ? null
                      : (value) => controller.updateWard(value ?? ''),
                  validator: (value) => FormValidators.validateWard(value),
                ),
              if (controller.selectedDistrict.isNotEmpty && controller.loadingWards)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: LinearProgressIndicator(color: Colors.tealAccent),
                ),

              // Check Number (Ward Officers only)
              if (controller.userType == 'ward') ...[
                const SizedBox(height: 16),
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  decoration: FormDecorations.textFieldDecoration(
                    labelKey: 'auth.register.check_number',
                    hintKey: 'auth.register.check_number_hint',
                    icon: Icons.verified,
                  ),
                  validator: (value) => FormValidators.validateCheckNumber(value, true),
                  onSaved: (value) => controller.checkNumber = value?.trim(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}