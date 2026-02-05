import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/poem.dart';

class PoemProvider with ChangeNotifier {
  final ApiService _apiService;

  List<Poem> _poems = [];
  Poem? _currentPoem;
  bool _isLoading = false;
  String? _error;
  String? _currentLetter;

  PoemProvider(this._apiService);

  List<Poem> get poems => _poems;
  Poem? get currentPoem => _currentPoem;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentLetter => _currentLetter;

  Future<void> loadPoemsByLetter(String letter) async {
    _isLoading = true;
    _error = null;
    _currentLetter = letter;
    notifyListeners();

    try {
      _poems = await _apiService.getPoemsByLetter(letter);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPoemById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentPoem = await _apiService.getPoemById(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchPoems(String query) async {
    if (query.isEmpty) {
      _poems = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _currentLetter = null;
    notifyListeners();

    try {
      _poems = await _apiService.searchPoems(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrentPoem() {
    _currentPoem = null;
    notifyListeners();
  }

  void clearPoems() {
    _poems = [];
    _currentLetter = null;
    notifyListeners();
  }
}
