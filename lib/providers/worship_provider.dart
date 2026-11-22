import 'package:flutter/material.dart';
import '../models/worship_item.dart';
import '../services/data_service.dart';
import '../services/storage_service.dart';

class WorshipProvider extends ChangeNotifier {
  String _selectedCategoryKey = 'generalPrayers';
  String _searchQuery = '';
  List<String> _favorites = [];

  String get selectedCategoryKey => _selectedCategoryKey;
  String get searchQuery => _searchQuery;
  List<String> get favorites => _favorites;

  WorshipProvider() {
    _loadFavorites();
  }

  void _loadFavorites() {
    _favorites = StorageService().getFavorites();
    notifyListeners();
  }

  void selectCategory(String key) {
    _selectedCategoryKey = key;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  Future<void> toggleFavorite(String title) async {
    await StorageService().toggleFavorite(title);
    _favorites = StorageService().getFavorites();
    notifyListeners();
  }

  bool isFavorite(String title) => _favorites.contains(title);

  List<WorshipItem> get currentCategoryItems {
    if (_selectedCategoryKey == 'favorites') {
      final allItems = <WorshipItem>[];
      DataService().worshipData.values.forEach(allItems.addAll);
      return allItems.where((item) => _favorites.contains(item.title)).toList();
    }
    return DataService().getItemsByCategory(_selectedCategoryKey);
  }

  List<WorshipItem> get searchResults {
    return DataService().searchWorship(_searchQuery);
  }
}
