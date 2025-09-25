import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mtaasuite/auth/model/location_models.dart';
import 'package:flutter/services.dart' show rootBundle;

class GeodataService {
  static const String baseUrl = 'https://tzgeodata.vercel.app/api/v1';

  // Fallback data
  static const List<String> _fallbackRegions = [
    'Arusha',
    'Dar es Salaam',
    'Dodoma',
    'Geita',
    'Iringa',
    'Kagera',
    'Katavi',
    'Kigoma',
    'Kilimanjaro',
    'Lindi',
    'Manyara',
    'Mara',
    'Mbeya',
    'Mjini Magharibi',
    'Morogoro',
    'Mtwara',
    'Mwanza',
    'Njombe',
    'Pemba North',
    'Pemba South',
    'Pwani',
    'Rukwa',
    'Ruvuma',
    'Shinyanga',
    'Simiyu',
    'Singida',
    'Songwe',
    'Tabora',
    'Tanga',
    'Unguja North',
    'Unguja South',
  ];

  static const Map<String, List<String>> _fallbackDistricts = {
    'Dar es Salaam': ['Ilala', 'Kinondoni', 'Temeke', 'Kigamboni'],
    'Arusha': [
      'Arusha City',
      'Arusha District',
      'Karatu',
      'Longido',
      'Monduli',
      'Ngorongoro',
    ],
    'Dodoma': [
      'Bahi',
      'Chamwino',
      'Chemba',
      'Dodoma Municipal',
      'Kondoa',
      'Kongwa',
      'Mpwapwa',
    ],
    // Add more as needed
  };

  static const List<String> _fallbackWards = [
    'Kisukuru', 'Kimanga', 'Kimara', // Placeholder
  ];

  /// Fetch all regions from the API
  Future<List<Region>> fetchRegions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/regions/'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final regions = data['regions'] as List<String>;

        return regions
            .map((regionName) => Region.fromString(regionName))
            .toList();
      } else {
        throw Exception('Failed to load regions: ${response.statusCode}');
      }
    } catch (e) {
      // Return fallback data
      return _fallbackRegions
          .map((regionName) => Region.fromString(regionName))
          .toList();
    }
  }

  /// Fetch districts for a specific region
  Future<List<District>> fetchDistricts(String regionName) async {
    try {
      // Try the API first
      final encodedRegion = Uri.encodeComponent(regionName);
      final response = await http.get(
        Uri.parse('$baseUrl/districts/$encodedRegion'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final districts = data['districts'] as List<String>;

        return districts
            .map(
              (districtName) => District.fromString(districtName, regionName),
            )
            .toList();
      } else {
        // If API fails, return fallback districts
        final fallbackDistricts =
            _fallbackDistricts[regionName] ?? ['District not available'];
        return fallbackDistricts
            .map(
              (districtName) => District.fromString(districtName, regionName),
            )
            .toList();
      }
    } catch (e) {
      // Return fallback districts
      final fallbackDistricts =
          _fallbackDistricts[regionName] ?? ['District not available'];
      return fallbackDistricts
          .map((districtName) => District.fromString(districtName, regionName))
          .toList();
    }
  }

  /// Fetch all wards from the API
  Future<List<Ward>> fetchWards() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/wards/'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final wards = data['wards'] as List<String>;

        return wards.map((wardName) => Ward.fromString(wardName)).toList();
      } else {
        throw Exception('Failed to load wards: ${response.statusCode}');
      }
    } catch (e) {
      // Return fallback data
      return _fallbackWards
          .map((wardName) => Ward.fromString(wardName))
          .toList();
    }
  }

  /// Search wards by name (useful for filtering)
  Future<List<Ward>> searchWards(String query) async {
    try {
      final allWards = await fetchWards();
      final lowercaseQuery = query.toLowerCase();

      return allWards
          .where((ward) => ward.name.toLowerCase().contains(lowercaseQuery))
          .toList();
    } catch (e) {
      throw Exception('Error searching wards: $e');
    }
  }

  /// Fetch wards filtered by region and district (with robust fallbacks)
  Future<List<Ward>> fetchWardsByDistrict(
    String regionName,
    String districtName,
  ) async {
    final encodedDistrict = Uri.encodeComponent(districtName);

    // Use the new endpoint
    final uri = Uri.parse('$baseUrl/districts/$encodedDistrict/wards/');
    try {
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        List<String> wardNames = [];
        if (decoded is Map && decoded['wards'] is List) {
          wardNames = List<String>.from(decoded['wards']);
        }
        if (wardNames.isNotEmpty) {
          return wardNames.map((w) => Ward.fromString(w)).toList();
        }
      }
    } catch (_) {
      // Continue to fallback
    }

    // Local fallback derived from ward_officials.json
    try {
      final raw = await rootBundle.loadString(
        'assets/fallbackdata/ward/ward_officials.json',
      );
      final decoded = json.decode(raw);
      final list = decoded is List ? decoded : <dynamic>[];
      final lowerDistrict = districtName.toLowerCase();
      final Set<String> names = {};

      for (final item in list) {
        if (item is Map) {
          final dist = (item['district'] ?? '').toString().toLowerCase();
          final ward = (item['ward'] ?? '').toString();
          if (ward.isEmpty) continue;
          if (dist.isNotEmpty && dist == lowerDistrict) {
            names.add(ward);
          } else if (dist.isNotEmpty) {
            // Fall back to district-only match
            if (dist == lowerDistrict) {
              names.add(ward);
            }
          }
        }
      }

      if (names.isEmpty) {
        // Final fallback to generic placeholder wards
        return _fallbackWards.map((w) => Ward.fromString(w)).toList();
      }
      return names.map((w) => Ward.fromString(w)).toList();
    } catch (_) {
      return _fallbackWards.map((w) => Ward.fromString(w)).toList();
    }
  }
}
