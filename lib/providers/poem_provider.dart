import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/poem.dart';

class PoemProvider with ChangeNotifier {
  final ApiService _apiService;

  List<Poem> _poems = [];
  Poem? _currentPoem;
  List<Poem> _poemsForLetter = [];
  final Map<String, int> _poemCountsByLetter = {};
  int _currentLetterPoemIndex = 0;
  bool _isLoading = false;
  bool _isLoadingLetterCounts = false;
  String? _error;
  String? _currentLetter;

  PoemProvider(this._apiService);

  List<Poem> get poems => _poems;
  Poem? get currentPoem => _currentPoem;
  List<Poem> get poemsForLetter => _poemsForLetter;
  Map<String, int> get poemCountsByLetter => _poemCountsByLetter;
  int? poemCountForLetter(String letter) => _poemCountsByLetter[letter];
  int get currentLetterPoemIndex => _currentLetterPoemIndex;
  bool get isLoading => _isLoading;
  bool get isLoadingLetterCounts => _isLoadingLetterCounts;
  String? get error => _error;
  String? get currentLetter => _currentLetter;

  bool get hasNextPoem =>
      _poemsForLetter.isNotEmpty &&
      _currentLetterPoemIndex < _poemsForLetter.length - 1;
  bool get hasPreviousPoem =>
      _poemsForLetter.isNotEmpty && _currentLetterPoemIndex > 0;

  Poem? get nextPoem =>
      hasNextPoem ? _poemsForLetter[_currentLetterPoemIndex + 1] : null;
  Poem? get previousPoem =>
      hasPreviousPoem ? _poemsForLetter[_currentLetterPoemIndex - 1] : null;

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

  Future<void> preloadLetterPoemCounts(
    Iterable<String> letters, {
    bool forceRefresh = false,
  }) async {
    final requestedLetters = letters
        .map((letter) => letter.toUpperCase())
        .toSet();
    final needsLoad =
        forceRefresh ||
        requestedLetters.any(
          (letter) => !_poemCountsByLetter.containsKey(letter),
        );

    if (!needsLoad) return;

    _isLoadingLetterCounts = true;
    notifyListeners();

    try {
      final serverCounts = await _apiService.getPoemCountsByLetter();

      for (final letter in requestedLetters) {
        _poemCountsByLetter[letter] = serverCounts[letter] ?? 0;
      }
    } catch (_) {
      // Keep previous values on failure.
    } finally {
      _isLoadingLetterCounts = false;
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

  Future<void> loadPoemWithLetterPoems(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getPoemWithLetterPoems(id);
      _currentPoem = response['poem'] as Poem?;
      _poemsForLetter =
          (response['poemsForLetter'] as List?)?.cast<Poem>() ?? [];
      _currentLetter = response['letter'] as String? ?? '';

      if (_currentPoem == null) {
        throw Exception('Failed to parse poem data');
      }

      // Find current poem index in the list
      _currentLetterPoemIndex = _poemsForLetter.indexWhere(
        (poem) => poem.id == id,
      );
      if (_currentLetterPoemIndex < 0) {
        _currentLetterPoemIndex = 0;
        if (_poemsForLetter.isEmpty && _currentPoem != null) {
          _poemsForLetter = [_currentPoem!];
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _currentPoem = null;
      _poemsForLetter = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> moveToNextPoem() async {
    if (!hasNextPoem) return;

    final nextPoem = _poemsForLetter[_currentLetterPoemIndex + 1];
    _currentLetterPoemIndex++;
    _currentPoem = nextPoem;
    notifyListeners();

    try {
      // Load full poem data
      _currentPoem = await _apiService.getPoemById(nextPoem.id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> moveToPreviousPoem() async {
    if (!hasPreviousPoem) return;

    final previousPoem = _poemsForLetter[_currentLetterPoemIndex - 1];
    _currentLetterPoemIndex--;
    _currentPoem = previousPoem;
    notifyListeners();

    try {
      // Load full poem data
      _currentPoem = await _apiService.getPoemById(previousPoem.id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
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

  Future<void> moveToPoem(int index) async {
    if (index < 0 || index >= _poemsForLetter.length) return;

    _currentLetterPoemIndex = index;
    _currentPoem = _poemsForLetter[index];
    notifyListeners();

    try {
      // Load full poem data
      _currentPoem = await _apiService.getPoemById(_poemsForLetter[index].id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrentPoem() {
    _currentPoem = null;
    _poemsForLetter = [];
    _currentLetterPoemIndex = 0;
    notifyListeners();
  }

  void clearPoems() {
    _poems = [];
    _currentLetter = null;
    notifyListeners();
  }
}
