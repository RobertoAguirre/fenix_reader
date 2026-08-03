import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio para gestionar favoritos persistentes
class FavoritesService {
  static const String _favoritesKey = 'fenix_favorites';
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true, resetOnError: true),
  );

  /// Obtener lista de IDs de favoritos
  Future<List<int>> getFavorites() async {
    try {
      final favoritesJson = await _storage.read(key: _favoritesKey);
      if (favoritesJson != null) {
        final decoded = jsonDecode(favoritesJson) as List<dynamic>;
        return decoded.map((id) => id as int).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo favoritos: $e');
      return [];
    }
  }

  /// Guardar lista de IDs de favoritos
  Future<void> saveFavorites(List<int> favoriteIds) async {
    try {
      final favoritesJson = jsonEncode(favoriteIds);
      await _storage.write(key: _favoritesKey, value: favoritesJson);
    } catch (e) {
      debugPrint('❌ Error guardando favoritos: $e');
    }
  }

  /// Agregar o quitar un favorito
  Future<void> toggleFavorite(int itemId) async {
    try {
      final favorites = await getFavorites();
      if (favorites.contains(itemId)) {
        favorites.remove(itemId);
      } else {
        favorites.add(itemId);
      }
      await saveFavorites(favorites);
    } catch (e) {
      debugPrint('❌ Error cambiando favorito: $e');
    }
  }

  /// Verificar si un item es favorito
  Future<bool> isFavorite(int itemId) async {
    try {
      final favorites = await getFavorites();
      return favorites.contains(itemId);
    } catch (e) {
      debugPrint('❌ Error verificando favorito: $e');
      return false;
    }
  }

  /// Limpiar todos los favoritos
  Future<void> clearFavorites() async {
    try {
      await _storage.delete(key: _favoritesKey);
    } catch (e) {
      debugPrint('❌ Error limpiando favoritos: $e');
    }
  }
}

