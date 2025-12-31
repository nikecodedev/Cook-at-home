/// List of countries with common names and variations
/// Used for location autocomplete and autocorrect
class CountriesList {
  /// Lista de países en español (priorizando países hispanohablantes)
  static const List<String> countries = [
    // Países hispanohablantes (más comunes)
    'México',
    'España',
    'Argentina',
    'Colombia',
    'Chile',
    'Perú',
    'Venezuela',
    'Ecuador',
    'Guatemala',
    'Cuba',
    'Bolivia',
    'República Dominicana',
    'Honduras',
    'Paraguay',
    'El Salvador',
    'Nicaragua',
    'Costa Rica',
    'Panamá',
    'Uruguay',
    'Puerto Rico',

    // América del Norte
    'Estados Unidos',
    'Canadá',

    // América del Sur (no hispanohablantes)
    'Brasil',

    // Europa - Occidental
    'Reino Unido',
    'Francia',
    'Alemania',
    'Italia',
    'Portugal',
    'Países Bajos',
    'Bélgica',
    'Suiza',
    'Austria',
    'Irlanda',
    'Luxemburgo',

    // Europa - Norte
    'Suecia',
    'Noruega',
    'Dinamarca',
    'Finlandia',
    'Islandia',

    // Europa - Sur
    'Grecia',
    'Chipre',
    'Malta',

    // Europa - Este
    'Polonia',
    'República Checa',
    'Hungría',
    'Rumania',
    'Ucrania',
    'Croacia',
    'Rusia',

    // Asia - Este
    'China',
    'Japón',
    'Corea del Sur',
    'Taiwán',
    'Hong Kong',

    // Asia - Sudeste
    'Filipinas',
    'Indonesia',
    'Malasia',
    'Tailandia',
    'Vietnam',
    'Singapur',

    // Asia - Sur
    'India',
    'Pakistán',

    // Asia - Oeste / Medio Oriente
    'Turquía',
    'Arabia Saudita',
    'Emiratos Árabes Unidos',
    'Israel',
    'Líbano',

    // África
    'Egipto',
    'Marruecos',
    'Sudáfrica',
    'Nigeria',
    'Argelia',

    // Oceanía
    'Australia',
    'Nueva Zelanda',
  ];

  /// Common misspellings and corrections
  static const Map<String, String> corrections = {
    // México variations - including common typos (keyboard adjacency errors)
    'nexico': 'México',
    'Nexico': 'México',
    'NEXICO': 'México',
    'meico': 'México',
    'Meico': 'México',
    'mexco': 'México',
    'Mexco': 'México',
    'mxico': 'México',
    'Mxico': 'México',
    'mexico': 'México',
    'Mexico': 'México',
    'MEXICO': 'México',
    'mejico': 'México',
    'Mejico': 'México',
    'méjico': 'México',
    'Méjico': 'México',
    'mexiko': 'México',
    'Mexiko': 'México',
    'mecsico': 'México',
    'Mecsico': 'México',
    'méxcio': 'México',
    'Méxcio': 'México',

    // España variations
    'espana': 'España',
    'Espana': 'España',
    'ESPANA': 'España',
    'spain': 'España',
    'Spain': 'España',
    'SPAIN': 'España',
    'espania': 'España',
    'Espania': 'España',
    'espanha': 'España',
    'Espanha': 'España',

    // Estados Unidos variations
    'usa': 'Estados Unidos',
    'USA': 'Estados Unidos',
    'U.S.A.': 'Estados Unidos',
    'u.s.a.': 'Estados Unidos',
    'U.S.': 'Estados Unidos',
    'u.s.': 'Estados Unidos',
    'eeuu': 'Estados Unidos',
    'EEUU': 'Estados Unidos',
    'E.E.U.U.': 'Estados Unidos',
    'EE.UU.': 'Estados Unidos',
    'estados unidos': 'Estados Unidos',
    'Estados unidos': 'Estados Unidos',
    'ESTADOS UNIDOS': 'Estados Unidos',
    'united states': 'Estados Unidos',
    'United States': 'Estados Unidos',
    'UNITED STATES': 'Estados Unidos',
    'america': 'Estados Unidos',
    'America': 'Estados Unidos',

    // China variations
    'china': 'China',
    'CHINA': 'China',

    // Argentina variations
    'argentina': 'Argentina',
    'ARGENTINA': 'Argentina',
    'argnetina': 'Argentina',
    'Argnetina': 'Argentina',
    'argetina': 'Argentina',
    'Argetina': 'Argentina',

    // Colombia variations
    'colombia': 'Colombia',
    'COLOMBIA': 'Colombia',
    'columbia': 'Colombia',
    'Columbia': 'Colombia',
    'colmbia': 'Colombia',
    'Colmbia': 'Colombia',

    // Chile variations
    'chile': 'Chile',
    'CHILE': 'Chile',
    'chili': 'Chile',
    'Chili': 'Chile',

    // Perú variations
    'peru': 'Perú',
    'Peru': 'Perú',
    'PERU': 'Perú',
    'perú': 'Perú',

    // Venezuela variations
    'venezuela': 'Venezuela',
    'VENEZUELA': 'Venezuela',
    'venezuala': 'Venezuela',
    'Venezuala': 'Venezuela',
    'venuzuela': 'Venezuela',
    'Venuzuela': 'Venezuela',

    // Ecuador variations
    'ecuador': 'Ecuador',
    'ECUADOR': 'Ecuador',
    'equador': 'Ecuador',
    'Equador': 'Ecuador',

    // Brasil variations
    'brasil': 'Brasil',
    'Brazil': 'Brasil',
    'brazil': 'Brasil',
    'BRAZIL': 'Brasil',
    'BRASIL': 'Brasil',
    'brasul': 'Brasil',
    'Brasul': 'Brasil',

    // Canadá variations
    'canada': 'Canadá',
    'Canada': 'Canadá',
    'CANADA': 'Canadá',
    'canadá': 'Canadá',

    // Guatemala variations
    'guatemala': 'Guatemala',
    'GUATEMALA': 'Guatemala',
    'guatamala': 'Guatemala',
    'Guatamala': 'Guatemala',

    // Other Latin American countries
    'costa rica': 'Costa Rica',
    'Costa rica': 'Costa Rica',
    'costarica': 'Costa Rica',
    'panama': 'Panamá',
    'Panama': 'Panamá',
    'PANAMA': 'Panamá',
    'puerto rico': 'Puerto Rico',
    'Puerto rico': 'Puerto Rico',
    'puertorico': 'Puerto Rico',
    'honduras': 'Honduras',
    'HONDURAS': 'Honduras',
    'nicaragua': 'Nicaragua',
    'NICARAGUA': 'Nicaragua',
    'el salvador': 'El Salvador',
    'El salvador': 'El Salvador',
    'elsalvador': 'El Salvador',
    'cuba': 'Cuba',
    'CUBA': 'Cuba',
    'paraguay': 'Paraguay',
    'PARAGUAY': 'Paraguay',
    'uruguay': 'Uruguay',
    'URUGUAY': 'Uruguay',
    'bolivia': 'Bolivia',
    'BOLIVIA': 'Bolivia',

    // European countries
    'france': 'Francia',
    'France': 'Francia',
    'francia': 'Francia',
    'germany': 'Alemania',
    'Germany': 'Alemania',
    'alemania': 'Alemania',
    'italy': 'Italia',
    'Italy': 'Italia',
    'italia': 'Italia',
    'portugal': 'Portugal',
    'PORTUGAL': 'Portugal',
    'uk': 'Reino Unido',
    'UK': 'Reino Unido',
    'united kingdom': 'Reino Unido',
    'United Kingdom': 'Reino Unido',
    'england': 'Reino Unido',
    'England': 'Reino Unido',
    'reino unido': 'Reino Unido',

    // Asian countries
    'japan': 'Japón',
    'Japan': 'Japón',
    'japon': 'Japón',
    'india': 'India',
    'INDIA': 'India',
    'south korea': 'Corea del Sur',
    'South Korea': 'Corea del Sur',
    'korea': 'Corea del Sur',
    'Korea': 'Corea del Sur',

    // Common placeholder values that should be cleared
    'ubicación detectada': '',
    'Ubicación detectada': '',
    'UBICACIÓN DETECTADA': '',
    'location detected': '',
    'Location detected': '',
    'LOCATION DETECTED': '',
    'ubicacion detectada': '',
    'Ubicacion detectada': '',
    'detecting...': '',
    'detectando...': '',
    'Detectando...': '',
  };

  /// Get suggestions based on user input
  static List<String> getSuggestions(String query) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase().trim();
    final suggestions = <String>[];
    
    // First check for exact misspelling matches
    if (corrections.containsKey(lowerQuery)) {
      suggestions.add(corrections[lowerQuery]!);
    }
    
    // Then search for countries that contain the query
    for (final country in countries) {
      final lowerCountry = country.toLowerCase();
      if (lowerCountry.contains(lowerQuery) && 
          !suggestions.contains(country)) {
        suggestions.add(country);
      }
    }
    
    // Limit to top 10 suggestions
    return suggestions.take(10).toList();
  }

  /// Auto-correct common misspellings
  static String autocorrect(String input) {
    if (input.isEmpty) return input;
    
    final trimmed = input.trim();
    final lowerInput = trimmed.toLowerCase();
    
    // Check for exact match in corrections (highest priority)
    if (corrections.containsKey(lowerInput)) {
      return corrections[lowerInput]!;
    }
    
    // Check if input contains a misspelled country name
    // Handle cases like "Ciudad, Nexico" or "Nexico" or "Ciudad Nexico"
    String corrected = trimmed;
    
    // Sort corrections by length (longest first) to avoid partial replacements
    final sortedCorrections = corrections.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    
    for (final entry in sortedCorrections) {
      // Use word boundaries to avoid replacing parts of words
      final pattern = RegExp(
        '\\b${RegExp.escape(entry.key)}\\b',
        caseSensitive: false,
      );
      if (pattern.hasMatch(lowerInput)) {
        // Find the actual case in the original string
        final match = pattern.firstMatch(lowerInput);
        if (match != null) {
          final start = match.start;
          final end = match.end;
          corrected = corrected.substring(0, start) +
              entry.value +
              corrected.substring(end);
          // Update lowerInput for next iteration
          final updatedLower = corrected.toLowerCase();
          if (updatedLower != lowerInput) {
            // Continue with updated string
            return autocorrect(corrected);
          }
        }
      }
    }
    
    // Also check for common patterns without word boundaries
    for (final entry in sortedCorrections) {
      if (lowerInput.contains(entry.key)) {
        // Replace the first occurrence
        final index = lowerInput.indexOf(entry.key);
        if (index != -1) {
          corrected = corrected.substring(0, index) +
              entry.value +
              corrected.substring(index + entry.key.length);
          break;
        }
      }
    }
    
    return corrected;
  }

  /// Check if input looks like a country name
  static bool looksLikeCountry(String input) {
    if (input.isEmpty) return false;
    final lowerInput = input.toLowerCase().trim();
    
    // Check if it's a known country or correction
    return countries.any((c) => c.toLowerCase() == lowerInput) ||
           corrections.containsKey(lowerInput);
  }
}

