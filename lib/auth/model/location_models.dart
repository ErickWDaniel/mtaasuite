/// Location models for Tanzanian geographical data
library;

class Region {
  final String name;

  Region({required this.name});

  factory Region.fromString(String name) {
    return Region(name: name);
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Region && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}

class District {
  final String name;
  final String region;

  District({required this.name, required this.region});

  factory District.fromString(String name, String region) {
    return District(name: name, region: region);
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is District && other.name == name && other.region == region;
  }

  @override
  int get hashCode => name.hashCode ^ region.hashCode;
}

class Ward {
  final String name;

  Ward({required this.name});

  factory Ward.fromString(String name) {
    return Ward(name: name);
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ward && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
