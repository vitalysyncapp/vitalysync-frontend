class EnvironmentSnapshot {
  const EnvironmentSnapshot({
    required this.location,
    required this.coordinates,
    required this.weather,
    required this.airQuality,
    required this.fetchedAt,
  });

  final String location;
  final EnvironmentCoordinates coordinates;
  final EnvironmentWeather weather;
  final EnvironmentAirQuality airQuality;
  final DateTime fetchedAt;

  factory EnvironmentSnapshot.fromJson(Map<String, dynamic> json) {
    return EnvironmentSnapshot(
      location: (json['location'] ?? 'Unknown location').toString(),
      coordinates: EnvironmentCoordinates.fromJson(
        Map<String, dynamic>.from(json['coordinates'] as Map? ?? const {}),
      ),
      weather: EnvironmentWeather.fromJson(
        Map<String, dynamic>.from(json['weather'] as Map? ?? const {}),
      ),
      airQuality: EnvironmentAirQuality.fromJson(
        Map<String, dynamic>.from(json['air_quality'] as Map? ?? const {}),
      ),
      fetchedAt:
          DateTime.tryParse((json['fetched_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'coordinates': coordinates.toJson(),
      'weather': weather.toJson(),
      'air_quality': airQuality.toJson(),
      'fetched_at': fetchedAt.toIso8601String(),
    };
  }
}

class EnvironmentCoordinates {
  const EnvironmentCoordinates({required this.lat, required this.lon});

  final double lat;
  final double lon;

  factory EnvironmentCoordinates.fromJson(Map<String, dynamic> json) {
    return EnvironmentCoordinates(
      lat: _readDouble(json['lat']),
      lon: _readDouble(json['lon']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'lat': lat, 'lon': lon};
  }
}

class EnvironmentWeather {
  const EnvironmentWeather({
    required this.main,
    required this.description,
    required this.icon,
    required this.temperatureC,
    required this.feelsLikeC,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
  });

  final String main;
  final String description;
  final String icon;
  final double temperatureC;
  final double feelsLikeC;
  final int humidity;
  final int pressure;
  final double windSpeed;

  factory EnvironmentWeather.fromJson(Map<String, dynamic> json) {
    return EnvironmentWeather(
      main: (json['main'] ?? 'Unknown').toString(),
      description: (json['description'] ?? 'No description available')
          .toString(),
      icon: (json['icon'] ?? '').toString(),
      temperatureC: _readDouble(json['temperature_c']),
      feelsLikeC: _readDouble(json['feels_like_c']),
      humidity: _readInt(json['humidity']),
      pressure: _readInt(json['pressure']),
      windSpeed: _readDouble(json['wind_speed']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'main': main,
      'description': description,
      'icon': icon,
      'temperature_c': temperatureC,
      'feels_like_c': feelsLikeC,
      'humidity': humidity,
      'pressure': pressure,
      'wind_speed': windSpeed,
    };
  }
}

class EnvironmentAirQuality {
  const EnvironmentAirQuality({
    required this.aqi,
    required this.aqiLabel,
    required this.components,
  });

  final int aqi;
  final String aqiLabel;
  final EnvironmentAirComponents components;

  factory EnvironmentAirQuality.fromJson(Map<String, dynamic> json) {
    return EnvironmentAirQuality(
      aqi: _readInt(json['aqi']),
      aqiLabel: (json['aqi_label'] ?? 'Unknown').toString(),
      components: EnvironmentAirComponents.fromJson(
        Map<String, dynamic>.from(json['components'] as Map? ?? const {}),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aqi': aqi,
      'aqi_label': aqiLabel,
      'components': components.toJson(),
    };
  }
}

class EnvironmentAirComponents {
  const EnvironmentAirComponents({
    required this.pm25,
    required this.pm10,
    required this.o3,
    required this.no2,
    required this.so2,
    required this.co,
  });

  final double pm25;
  final double pm10;
  final double o3;
  final double no2;
  final double so2;
  final double co;

  factory EnvironmentAirComponents.fromJson(Map<String, dynamic> json) {
    return EnvironmentAirComponents(
      pm25: _readDouble(json['pm2_5']),
      pm10: _readDouble(json['pm10']),
      o3: _readDouble(json['o3']),
      no2: _readDouble(json['no2']),
      so2: _readDouble(json['so2']),
      co: _readDouble(json['co']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pm2_5': pm25,
      'pm10': pm10,
      'o3': o3,
      'no2': no2,
      'so2': so2,
      'co': co,
    };
  }
}

double _readDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
