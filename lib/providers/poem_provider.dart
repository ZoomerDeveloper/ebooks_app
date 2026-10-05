import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../models/poem.dart';

class PoemProvider with ChangeNotifier {
  final ApiService _apiService;

  List<Poem> _poems = [];
  Poem? _currentPoem;
  // _poemsForLetter is _allPoemsForLetter narrowed by the meaning filter.
  List<Poem> _allPoemsForLetter = [];
  List<Poem> _poemsForLetter = [];
  Set<int> _meaningFilter = const {};
  int? _pinnedPoemId;
  bool _meaningFilterHasNoMatches = false;
  String _allPoemsLetter = '';
  // "All letters" mode: _poemsForLetter holds matching poems of every letter;
  // their text arrives lazily, ids without text yet are in _textPendingIds.
  bool _isAllLettersMode = false;
  final Set<int> _textPendingIds = {};
  final Set<int> _textRequestedIds = {};
  Map<int, int>? _catalogMeaningCounts;
  final Map<String, int> _poemCountsByLetter = {};
  final Map<String, int?> _firstPoemIdByLetter = {};
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
  int? firstPoemIdForLetter(String letter) =>
      _firstPoemIdByLetter[letter.toUpperCase()];
  int get currentLetterPoemIndex => _currentLetterPoemIndex;
  bool get isLoading => _isLoading;
  bool get isLoadingLetterCounts => _isLoadingLetterCounts;
  String? get error => _error;
  String? get currentLetter => _currentLetter;
  bool get hasLetterPoems =>
      _allPoemsForLetter.isNotEmpty && _allPoemsLetter == _currentLetter;
  Set<int> get meaningFilter => _meaningFilter;
  bool get meaningFilterHasNoMatches => _meaningFilterHasNoMatches;
  bool get isMeaningFilterActive =>
      _meaningFilter.isNotEmpty && !_meaningFilterHasNoMatches;
  bool get isAllLettersMode => _isAllLettersMode;
  bool isPoemTextPending(Poem poem) => _textPendingIds.contains(poem.id);
  bool get hasCatalogMeaningCounts => _catalogMeaningCounts != null;

  int countPoemsMatchingMeaningFilter(Set<int> filter) =>
      _allPoemsForLetter.where((p) => _matchesMeaningFilter(p, filter)).length;

  /// Meaning-count buckets that occur among the current letter's poems.
  Set<int> get availableMeaningBuckets => {
    for (final poem in _allPoemsForLetter)
      if (poem.meaningsCount > 0) _meaningBucket(poem.meaningsCount),
  };

  /// Meaning-count buckets that occur anywhere in the catalogue.
  Set<int> get catalogMeaningBuckets => {
    for (final count in (_catalogMeaningCounts ?? const <int, int>{}).keys)
      if (count > 0) _meaningBucket(count),
  };

  int countCatalogPoemsMatchingMeaningFilter(Set<int> filter) {
    var total = 0;
    (_catalogMeaningCounts ?? const <int, int>{}).forEach((count, poems) {
      if (filter.contains(_meaningBucket(count))) total += poems;
    });
    return total;
  }

  static int _meaningBucket(int meaningsCount) =>
      meaningsCount.clamp(0, AppConstants.meaningFilterMaxBucket);

  static bool _matchesMeaningFilter(Poem poem, Set<int> filter) {
    if (filter.isEmpty) return true;
    return filter.contains(_meaningBucket(poem.meaningsCount));
  }

  /// Server order of the "all letters" list: letter, then word, then id.
  static int _compareCatalogOrder(Poem a, Poem b) {
    final byLetter = a.letter.compareTo(b.letter);
    if (byLetter != 0) return byLetter;
    final byWord = a.word.toLowerCase().compareTo(b.word.toLowerCase());
    return byWord != 0 ? byWord : a.id.compareTo(b.id);
  }

  void _leaveAllLettersMode() {
    _isAllLettersMode = false;
    _textPendingIds.clear();
    _textRequestedIds.clear();
  }

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
      if (e is ApiException && e.statusCode != null) {
        _error = '${e.statusCode}: ${e.message}';
      } else {
        _error = e.toString();
      }
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
      final serverIndex = await _apiService.getPoemLetterIndex();

      for (final letter in requestedLetters) {
        final entry = serverIndex[letter];
        _poemCountsByLetter[letter] = entry?.count ?? 0;
        _firstPoemIdByLetter[letter] = entry?.firstPoemId;
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
      _allPoemsForLetter = [];
      _leaveAllLettersMode();
      if (_currentPoem != null) {
        _poemsForLetter = [_currentPoem!];
        _currentLetter = _currentPoem!.letter;
        _currentLetterPoemIndex = 0;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Poem [id] stays in the list even if it doesn't match [meaningFilter],
  /// unless [keepOpenedPoem] is false (then the nearest matching poem opens).
  Future<void> loadPoemWithLetterPoems(
    int id, {
    bool showLoading = true,
    Set<int> meaningFilter = const {},
    bool keepOpenedPoem = true,
  }) async {
    if (showLoading) {
      _isLoading = true;
    }
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getPoemWithLetterPoems(id);
      _currentPoem = response['poem'] as Poem?;
      _allPoemsForLetter =
          (response['poemsForLetter'] as List?)?.cast<Poem>() ?? [];
      _currentLetter = response['letter'] as String? ?? '';

      if (_currentPoem == null) {
        throw Exception('Failed to parse poem data');
      }

      if (_allPoemsForLetter.isEmpty) {
        _allPoemsForLetter = [_currentPoem!];
      }
      _allPoemsLetter = _currentLetter ?? '';
      _leaveAllLettersMode();
      _meaningFilter = {...meaningFilter};
      _pinnedPoemId = keepOpenedPoem ? id : null;
      _applyMeaningFilter(anchorPoemId: id);

      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    } catch (e) {
      if (e is ApiException && e.statusCode != null) {
        _error = '${e.statusCode}: ${e.message}';
      } else {
        _error = e.toString();
      }
      if (showLoading) {
        _currentPoem = null;
        _poemsForLetter = [];
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  /// Switches to paging through matching poems of all letters, positioned at
  /// [anchor] or the next matching poem after it. [anchor] is inserted into
  /// the list if [keepAnchor]. Returns false (list untouched) if nothing
  /// matches or the request fails.
  Future<bool> loadAllLettersPoems({
    required Poem anchor,
    required Set<int> meaningFilter,
    bool keepAnchor = false,
  }) async {
    const maxBucket = AppConstants.meaningFilterMaxBucket;
    final List<Poem> list;
    try {
      list = await _apiService.getPoemsByMeanings(
        counts: meaningFilter.where((bucket) => bucket < maxBucket).toSet(),
        atLeast: meaningFilter.contains(maxBucket) ? maxBucket : null,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
    if (list.isEmpty) return false;

    var index = list.indexWhere((p) => p.id == anchor.id);
    if (index >= 0) {
      list[index] = anchor;
    } else {
      final next = list.indexWhere((p) => _compareCatalogOrder(p, anchor) > 0);
      if (keepAnchor) {
        index = next < 0 ? list.length : next;
        list.insert(index, anchor);
      } else {
        index = next < 0 ? list.length - 1 : next;
      }
    }

    _isAllLettersMode = true;
    _meaningFilter = {...meaningFilter};
    _meaningFilterHasNoMatches = false;
    _pinnedPoemId = null;
    _poemsForLetter = list;
    _textRequestedIds.clear();
    _textPendingIds
      ..clear()
      ..addAll(list.where((p) => p.id != anchor.id).map((p) => p.id));
    _currentLetterPoemIndex = index;
    _currentPoem = list[index];
    _currentLetter = _currentPoem!.letter;
    notifyListeners();
    unawaited(ensurePoemTextsAround(index));
    return true;
  }

  /// Loads text for poems near [index] in "all letters" mode.
  Future<void> ensurePoemTextsAround(int index) async {
    if (_textPendingIds.isEmpty) return;
    final start = max(0, index - 2);
    final end = min(_poemsForLetter.length, index + 6);
    final ids = [
      for (var i = start; i < end; i++)
        if (_textPendingIds.contains(_poemsForLetter[i].id) &&
            !_textRequestedIds.contains(_poemsForLetter[i].id))
          _poemsForLetter[i].id,
    ];
    if (ids.isEmpty) return;

    _textRequestedIds.addAll(ids);
    try {
      final loaded = await _apiService.getPoemsByIds(ids);
      loaded.forEach(_replaceLoadedPoem);
      notifyListeners();
    } catch (_) {
      // Pending ids stay pending and are retried on the next page change.
    } finally {
      _textRequestedIds.removeAll(ids);
    }
  }

  void _replaceLoadedPoem(Poem poem) {
    final index = _poemsForLetter.indexWhere((p) => p.id == poem.id);
    if (index >= 0) _poemsForLetter[index] = poem;
    _textPendingIds.remove(poem.id);
    if (_currentPoem?.id == poem.id) _currentPoem = poem;
  }

  Future<void> loadCatalogMeaningCounts() async {
    if (_catalogMeaningCounts != null) return;
    try {
      _catalogMeaningCounts = await _apiService.getMeaningCounts();
      notifyListeners();
    } catch (_) {
      // The settings sheet falls back to showing every bucket.
    }
  }

  /// Returns true if the list of poems to page through changed.
  bool setMeaningFilter(Set<int> filter) {
    if (_allPoemsForLetter.isEmpty || setEquals(filter, _meaningFilter)) {
      return false;
    }
    final previousIds = _poemsForLetter.map((p) => p.id).toList();
    _meaningFilter = {...filter};
    _pinnedPoemId = null;
    _applyMeaningFilter(
      anchorPoemId: _currentPoem?.id ?? _allPoemsForLetter.first.id,
    );
    notifyListeners();
    return !listEquals(previousIds, _poemsForLetter.map((p) => p.id).toList());
  }

  /// If the anchor poem is filtered out, moves to the next matching poem
  /// in alphabetical order (or the last one if there is none after it).
  void _applyMeaningFilter({required int anchorPoemId}) {
    var filtered = _allPoemsForLetter
        .where(
          (p) =>
              p.id == _pinnedPoemId || _matchesMeaningFilter(p, _meaningFilter),
        )
        .toList();
    _meaningFilterHasNoMatches =
        _meaningFilter.isNotEmpty &&
        !filtered.any((p) => _matchesMeaningFilter(p, _meaningFilter));
    if (_meaningFilterHasNoMatches) {
      filtered = List.of(_allPoemsForLetter);
    }
    _poemsForLetter = filtered;

    var index = filtered.indexWhere((p) => p.id == anchorPoemId);
    if (index < 0) {
      final filteredIds = {for (final p in filtered) p.id};
      final anchorPos = _allPoemsForLetter.indexWhere(
        (p) => p.id == anchorPoemId,
      );
      final nextMatch = _allPoemsForLetter
          .skip(anchorPos + 1)
          .where((p) => filteredIds.contains(p.id));
      index = nextMatch.isEmpty
          ? filtered.length - 1
          : filtered.indexOf(nextMatch.first);
    }
    _currentLetterPoemIndex = index;
    if (_currentPoem?.id != filtered[index].id) {
      _currentPoem = filtered[index];
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
    if (_isAllLettersMode) {
      _currentLetter = _currentPoem!.letter;
      unawaited(ensurePoemTextsAround(index));
    }
    notifyListeners();

    try {
      // Load full poem data
      // Ignored if the user already swiped further while this was loading.
      _replaceLoadedPoem(
        await _apiService.getPoemById(_poemsForLetter[index].id),
      );
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
    _allPoemsForLetter = [];
    _poemsForLetter = [];
    _leaveAllLettersMode();
    _currentLetterPoemIndex = 0;
    notifyListeners();
  }

  void clearPoems() {
    _poems = [];
    _currentLetter = null;
    notifyListeners();
  }
}
