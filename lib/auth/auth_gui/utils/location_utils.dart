import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:mtaasuite/services/geodata_service.dart';
import 'package:mtaasuite/auth/model/location_models.dart';

class LocationUtils {
  static final GeodataService _geo = GeodataService();

  static Future<List<Region>> loadRegions() async {
    try {
      return await _geo.fetchRegions();
    } catch (e) {
      throw Exception('Failed to load regions: $e');
    }
  }

  static Future<List<District>> loadDistricts(String regionName) async {
    try {
      return await _geo.fetchDistricts(regionName);
    } catch (e) {
      throw Exception('Failed to load districts: $e');
    }
  }

  static Future<List<Ward>> loadWards(String regionName, String districtName) async {
    try {
      return await _geo.fetchWardsByDistrict(regionName, districtName);
    } catch (e) {
      throw Exception('Failed to load wards: $e');
    }
  }

  static Future<Map<String, dynamic>?> loadWardValidationData() async {
    try {
      final String officials = await rootBundle.loadString(
        'assets/fallbackdata/ward/ward_officials.json',
      );

      Map<String, dynamic>? parsed;
      if (officials.trim().isNotEmpty) {
        final dynamic listDecoded = json.decode(officials);
        if (listDecoded is List) {
          parsed = {
            for (final e in listDecoded)
              if (e is Map && e['checkNumber'] is String)
                e['checkNumber'] as String: e,
          };
        } else if (listDecoded is Map<String, dynamic>) {
          parsed = listDecoded;
        }
      }
      return parsed;
    } catch (e) {
      // Return empty map on error
      return {};
    }
  }

  static Future<bool> validateCheckNumber(String checkNumber, Map<String, dynamic>? wardData) async {
    // Try API validation first (mock for now)
    bool apiValid = await _checkNumberApi(checkNumber);
    if (apiValid) return true;

    // Fallback to JSON
    return wardData?.containsKey(checkNumber) ?? false;
  }

  static Future<bool> _checkNumberApi(String checkNumber) async {
    // TODO: Implement actual API call
    // For now, return false to use JSON fallback
    return false;
  }
}