import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/utils/logger.dart';

/// Service for handling user location detection and geocoding
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Map of English country names to Spanish
  static const Map<String, String> _countryTranslations = {
    // Americas - North America
    'United States': 'Estados Unidos',
    'United States of America': 'Estados Unidos',
    'USA': 'Estados Unidos',
    'U.S.A.': 'Estados Unidos',
    'U.S.': 'Estados Unidos',
    'America': 'Estados Unidos',
    'Canada': 'Canadá',
    'Mexico': 'México',
    'Mexiko': 'México',

    // Americas - Central America
    'Guatemala': 'Guatemala',
    'Belize': 'Belice',
    'Honduras': 'Honduras',
    'El Salvador': 'El Salvador',
    'Nicaragua': 'Nicaragua',
    'Costa Rica': 'Costa Rica',
    'Panama': 'Panamá',

    // Americas - Caribbean
    'Cuba': 'Cuba',
    'Dominican Republic': 'República Dominicana',
    'Haiti': 'Haití',
    'Jamaica': 'Jamaica',
    'Puerto Rico': 'Puerto Rico',
    'Trinidad and Tobago': 'Trinidad y Tobago',
    'Bahamas': 'Bahamas',

    // Americas - South America
    'Argentina': 'Argentina',
    'Bolivia': 'Bolivia',
    'Brazil': 'Brasil',
    'Chile': 'Chile',
    'Colombia': 'Colombia',
    'Ecuador': 'Ecuador',
    'Guyana': 'Guyana',
    'Paraguay': 'Paraguay',
    'Peru': 'Perú',
    'Suriname': 'Surinam',
    'Uruguay': 'Uruguay',
    'Venezuela': 'Venezuela',

    // Europe - Western
    'United Kingdom': 'Reino Unido',
    'UK': 'Reino Unido',
    'Great Britain': 'Reino Unido',
    'England': 'Reino Unido',
    'Scotland': 'Escocia',
    'Wales': 'Gales',
    'Northern Ireland': 'Irlanda del Norte',
    'Ireland': 'Irlanda',
    'France': 'Francia',
    'Germany': 'Alemania',
    'Netherlands': 'Países Bajos',
    'Holland': 'Países Bajos',
    'Belgium': 'Bélgica',
    'Luxembourg': 'Luxemburgo',
    'Switzerland': 'Suiza',
    'Austria': 'Austria',
    'Liechtenstein': 'Liechtenstein',
    'Monaco': 'Mónaco',

    // Europe - Southern
    'Spain': 'España',
    'Portugal': 'Portugal',
    'Italy': 'Italia',
    'Greece': 'Grecia',
    'Malta': 'Malta',
    'Cyprus': 'Chipre',
    'Andorra': 'Andorra',
    'San Marino': 'San Marino',
    'Vatican City': 'Ciudad del Vaticano',

    // Europe - Northern
    'Sweden': 'Suecia',
    'Norway': 'Noruega',
    'Denmark': 'Dinamarca',
    'Finland': 'Finlandia',
    'Iceland': 'Islandia',

    // Europe - Eastern
    'Russia': 'Rusia',
    'Russian Federation': 'Rusia',
    'Poland': 'Polonia',
    'Czech Republic': 'República Checa',
    'Czechia': 'República Checa',
    'Slovakia': 'Eslovaquia',
    'Hungary': 'Hungría',
    'Romania': 'Rumania',
    'Bulgaria': 'Bulgaria',
    'Ukraine': 'Ucrania',
    'Belarus': 'Bielorrusia',
    'Moldova': 'Moldavia',
    'Croatia': 'Croacia',
    'Slovenia': 'Eslovenia',
    'Serbia': 'Serbia',
    'Bosnia and Herzegovina': 'Bosnia y Herzegovina',
    'Montenegro': 'Montenegro',
    'North Macedonia': 'Macedonia del Norte',
    'Albania': 'Albania',
    'Kosovo': 'Kosovo',
    'Estonia': 'Estonia',
    'Latvia': 'Letonia',
    'Lithuania': 'Lituania',

    // Asia - East
    'China': 'China',
    "People's Republic of China": 'China',
    'Japan': 'Japón',
    'South Korea': 'Corea del Sur',
    'Republic of Korea': 'Corea del Sur',
    'Korea': 'Corea del Sur',
    'North Korea': 'Corea del Norte',
    'Taiwan': 'Taiwán',
    'Hong Kong': 'Hong Kong',
    'Macau': 'Macao',
    'Mongolia': 'Mongolia',

    // Asia - Southeast
    'Philippines': 'Filipinas',
    'Indonesia': 'Indonesia',
    'Malaysia': 'Malasia',
    'Thailand': 'Tailandia',
    'Vietnam': 'Vietnam',
    'Viet Nam': 'Vietnam',
    'Singapore': 'Singapur',
    'Myanmar': 'Myanmar',
    'Burma': 'Myanmar',
    'Cambodia': 'Camboya',
    'Laos': 'Laos',
    'Brunei': 'Brunéi',

    // Asia - South
    'India': 'India',
    'Pakistan': 'Pakistán',
    'Bangladesh': 'Bangladesh',
    'Sri Lanka': 'Sri Lanka',
    'Nepal': 'Nepal',
    'Bhutan': 'Bután',
    'Maldives': 'Maldivas',

    // Asia - Central & West
    'Turkey': 'Turquía',
    'Iran': 'Irán',
    'Iraq': 'Irak',
    'Saudi Arabia': 'Arabia Saudita',
    'United Arab Emirates': 'Emiratos Árabes Unidos',
    'UAE': 'Emiratos Árabes Unidos',
    'Qatar': 'Catar',
    'Kuwait': 'Kuwait',
    'Bahrain': 'Baréin',
    'Oman': 'Omán',
    'Yemen': 'Yemen',
    'Jordan': 'Jordania',
    'Lebanon': 'Líbano',
    'Syria': 'Siria',
    'Israel': 'Israel',
    'Palestine': 'Palestina',
    'Afghanistan': 'Afganistán',
    'Kazakhstan': 'Kazajistán',
    'Uzbekistan': 'Uzbekistán',
    'Turkmenistan': 'Turkmenistán',
    'Tajikistan': 'Tayikistán',
    'Kyrgyzstan': 'Kirguistán',
    'Azerbaijan': 'Azerbaiyán',
    'Georgia': 'Georgia',
    'Armenia': 'Armenia',

    // Africa - North
    'Egypt': 'Egipto',
    'Morocco': 'Marruecos',
    'Algeria': 'Argelia',
    'Tunisia': 'Túnez',
    'Libya': 'Libia',
    'Sudan': 'Sudán',

    // Africa - Sub-Saharan
    'South Africa': 'Sudáfrica',
    'Nigeria': 'Nigeria',
    'Kenya': 'Kenia',
    'Ethiopia': 'Etiopía',
    'Ghana': 'Ghana',
    'Tanzania': 'Tanzania',
    'Uganda': 'Uganda',
    'Senegal': 'Senegal',
    'Ivory Coast': 'Costa de Marfil',
    "Côte d'Ivoire": 'Costa de Marfil',
    'Cameroon': 'Camerún',
    'Zimbabwe': 'Zimbabue',
    'Zambia': 'Zambia',
    'Botswana': 'Botsuana',
    'Namibia': 'Namibia',
    'Mozambique': 'Mozambique',
    'Madagascar': 'Madagascar',
    'Angola': 'Angola',
    'Democratic Republic of the Congo': 'República Democrática del Congo',
    'Congo': 'Congo',
    'Rwanda': 'Ruanda',

    // Oceania
    'Australia': 'Australia',
    'New Zealand': 'Nueva Zelanda',
    'Fiji': 'Fiyi',
    'Papua New Guinea': 'Papúa Nueva Guinea',
  };

  /// Translate country name to Spanish
  String _translateCountryToSpanish(String country) {
    // Check if already in Spanish or in our translation map
    final translated = _countryTranslations[country];
    if (translated != null) {
      return translated;
    }
    // Return original if no translation found
    return country;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      Logger.error('Error checking location service status', e, null, 'LocationService');
      return false;
    }
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      Logger.error('Error checking location permission', e, null, 'LocationService');
      return LocationPermission.denied;
    }
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    try {
      Logger.info('Requesting location permission', 'LocationService');
      
      // First check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        Logger.warning('Location services are disabled', 'LocationService');
        throw Exception('Los servicios de ubicación están deshabilitados. Por favor habilítalos en la configuración de tu dispositivo.');
      }

      // Check current permission status
      LocationPermission permission = await checkPermission();
      
      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        Logger.info('Permission request result: $permission', 'LocationService');
      }

      if (permission == LocationPermission.deniedForever) {
        Logger.warning('Location permission denied forever', 'LocationService');
        throw Exception('El permiso de ubicación fue denegado permanentemente. Por favor habilítalo en la configuración de la aplicación.');
      }

      if (permission == LocationPermission.denied) {
        Logger.warning('Location permission denied', 'LocationService');
        throw Exception('El permiso de ubicación fue denegado. Por favor permite el acceso a la ubicación para usar esta función.');
      }

      return permission;
    } catch (e) {
      Logger.error('Error requesting location permission', e, null, 'LocationService');
      rethrow;
    }
  }

  /// Get current location coordinates
  Future<Position> getCurrentPosition() async {
    try {
      Logger.info('Getting current position', 'LocationService');
      
      // Check and request permission
      LocationPermission permission = await requestPermission();
      
      if (permission != LocationPermission.whileInUse && 
          permission != LocationPermission.always) {
        throw Exception('No se pudo obtener el permiso de ubicación');
      }

      // Get position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      Logger.success('Position obtained: ${position.latitude}, ${position.longitude}', 'LocationService');
      return position;
    } catch (e) {
      Logger.error('Error getting current position', e, null, 'LocationService');
      rethrow;
    }
  }

  /// Convert coordinates to address (reverse geocoding)
  /// Returns the country name in Spanish
  Future<String> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      Logger.info('Getting address for coordinates: $latitude, $longitude', 'LocationService');

      // Try to get placemarks with Spanish locale first
      List<Placemark> placemarks = [];

      try {
        // Set locale to Spanish for geocoding
        await setLocaleIdentifier('es_ES');
        placemarks = await placemarkFromCoordinates(
          latitude,
          longitude,
        );
        Logger.info('Placemarks received: ${placemarks.length}', 'LocationService');
        if (placemarks.isNotEmpty) {
          Logger.info('First placemark: country=${placemarks[0].country}, locality=${placemarks[0].locality}, administrativeArea=${placemarks[0].administrativeArea}', 'LocationService');
        }
      } catch (localeError) {
        Logger.warning('Failed with Spanish locale, trying default: $localeError', 'LocationService');
        // Try without locale setting
        try {
          placemarks = await placemarkFromCoordinates(latitude, longitude);
        } catch (defaultError) {
          Logger.error('Default geocoding also failed: $defaultError', null, null, 'LocationService');
        }
      }

      if (placemarks.isEmpty) {
        Logger.warning('No placemarks found for coordinates', 'LocationService');
        // Try to determine country from coordinates using a simple approach
        return _getCountryFromCoordinates(latitude, longitude);
      }

      Placemark place = placemarks[0];

      // For location field, we want a simple format: City, Country
      // Build a concise address string
      List<String> addressParts = [];

      // Add city/locality
      if (place.locality != null && place.locality!.isNotEmpty) {
        addressParts.add(place.locality!);
      } else if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
        addressParts.add(place.administrativeArea!);
      }

      // Add country (translated to Spanish)
      if (place.country != null && place.country!.isNotEmpty) {
        String country = _translateCountryToSpanish(place.country!);
        addressParts.add(country);
      }

      String address = addressParts.join(', ');

      if (address.isEmpty) {
        // Fallback: try to get just the country
        if (place.country != null && place.country!.isNotEmpty) {
          address = _translateCountryToSpanish(place.country!);
        } else if (place.name != null && place.name!.isNotEmpty) {
          address = place.name!;
        } else {
          // Last resort: use coordinate-based country detection
          address = _getCountryFromCoordinates(latitude, longitude);
        }
      }

      Logger.success('Address obtained: $address', 'LocationService');
      return address;
    } catch (e) {
      Logger.error('Error getting address from coordinates', e, null, 'LocationService');
      // Return country based on coordinates as fallback
      return _getCountryFromCoordinates(latitude, longitude);
    }
  }

  /// Get approximate country from coordinates (fallback method)
  /// Uses simple bounding box checks for common regions
  String _getCountryFromCoordinates(double latitude, double longitude) {
    // China: roughly 18°N to 54°N, 73°E to 135°E
    if (latitude >= 18 && latitude <= 54 && longitude >= 73 && longitude <= 135) {
      // More specific check for China mainland
      if (latitude >= 20 && latitude <= 50 && longitude >= 100 && longitude <= 130) {
        return 'China';
      }
    }

    // United States (continental): roughly 25°N to 49°N, 125°W to 67°W
    if (latitude >= 25 && latitude <= 49 && longitude >= -125 && longitude <= -67) {
      return 'Estados Unidos';
    }

    // Mexico: roughly 14°N to 33°N, 118°W to 86°W
    if (latitude >= 14 && latitude <= 33 && longitude >= -118 && longitude <= -86) {
      return 'México';
    }

    // Spain: roughly 36°N to 44°N, 10°W to 5°E
    if (latitude >= 36 && latitude <= 44 && longitude >= -10 && longitude <= 5) {
      return 'España';
    }

    // Argentina: roughly 55°S to 22°S, 74°W to 53°W
    if (latitude >= -55 && latitude <= -22 && longitude >= -74 && longitude <= -53) {
      return 'Argentina';
    }

    // Colombia: roughly 4°S to 12°N, 79°W to 67°W
    if (latitude >= -4 && latitude <= 12 && longitude >= -79 && longitude <= -67) {
      return 'Colombia';
    }

    // Brazil: roughly 34°S to 5°N, 74°W to 35°W
    if (latitude >= -34 && latitude <= 5 && longitude >= -74 && longitude <= -35) {
      return 'Brasil';
    }

    // If we can't determine, return a message indicating unknown location
    Logger.warning('Could not determine country from coordinates: $latitude, $longitude', 'LocationService');
    return 'Ubicación detectada';
  }

  /// Get current location as address string
  /// This is the main method to use - it handles everything
  Future<String> getCurrentLocationAddress() async {
    try {
      Logger.info('Getting current location address', 'LocationService');
      
      // Get position
      Position position = await getCurrentPosition();
      
      // Convert to address
      String address = await getAddressFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      return address;
    } catch (e) {
      Logger.error('Error getting current location address', e, null, 'LocationService');
      rethrow;
    }
  }

  /// Open app settings (for permission denied forever)
  /// Note: This should be called from UI layer using permission_handler's openAppSettings()
  Future<void> openAppSettings() async {
    try {
      // This method is a placeholder - actual implementation should use permission_handler
      // from the UI layer: await openAppSettings();
      Logger.info('Permission denied forever, user should open settings manually', 'LocationService');
    } catch (e) {
      Logger.error('Error in openAppSettings placeholder', e, null, 'LocationService');
    }
  }
}

