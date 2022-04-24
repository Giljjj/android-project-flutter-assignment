import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/foundation.dart';
import 'auth_repository.dart';

class FavoritesRepository with ChangeNotifier {
  static final FavoritesRepository _singleton = FavoritesRepository._internal();

  factory FavoritesRepository() {
    _singleton.onChange();
    return _singleton;
  }

  FavoritesRepository._internal();

  final Set<WordPair> _favorites = <WordPair>{}; // NEW
  StreamSubscription? _subscription;

  Set<WordPair> get favorites => _favorites;

  // Upsert user to make sure it exists
  Future upsertUser() async {
    var _auth = AuthRepository.instance();
    if (_auth.isAuthenticated) {
      FirebaseFirestore db = FirebaseFirestore.instance;
      String userId = _auth.user!.uid;

      await db
          .collection('users')
          .doc(userId)
          .get()
          .then((DocumentSnapshot documentSnapshot) async {
        if (!documentSnapshot.exists) {
          await db
              .collection('users')
              .doc(userId)
              .set({'favorites': [], 'created_at': Timestamp.now()});
        }
      });
    }
  }

  // Add
  Future add(WordPair pair) async {
    var _auth = AuthRepository.instance();
    if (_auth.isAuthenticated) {
      FirebaseFirestore db = FirebaseFirestore.instance;
      String userId = _auth.user!.uid;
      await upsertUser();
      db.collection('users').doc(userId).update({
        'favorites': FieldValue.arrayUnion([
          {'first': pair.first, 'second': pair.second}
        ])
      });
    } else {
      _favorites.add(pair);
      notifyListeners();
    }
    return Future.delayed(Duration.zero);
  }

// Remove
  Future remove(WordPair pair) async {
    var _auth = AuthRepository.instance();
    if (_auth.isAuthenticated) {
      FirebaseFirestore db = FirebaseFirestore.instance;
      String userId = _auth.user!.uid;
      await upsertUser();
      db.collection('users').doc(userId).update({
        'favorites': FieldValue.arrayRemove([
          {'first': pair.first, 'second': pair.second}
        ])
      });
    } else {
      _favorites.remove(pair);
      notifyListeners();
    }
    return Future.delayed(Duration.zero);
  }

  Future mergeLogin() async {
    var _auth = AuthRepository.instance();
    if (_auth.isAuthenticated) {
      FirebaseFirestore db = FirebaseFirestore.instance;
      String userId = _auth.user!.uid;

      var _processedFavorites = [];
      for (var fav in _favorites) {
        _processedFavorites.add({'first': fav.first, 'second': fav.second});
      }

      await upsertUser();
      db
          .collection('users')
          .doc(userId)
          .update({'favorites': FieldValue.arrayUnion(_processedFavorites)});

      onChange();
    }
  }

  Future cleanLogout() async {
    _subscription?.cancel();
    _favorites.clear();
    notifyListeners();
  }

// OnChange
  Future onChange() async {
    var _auth = AuthRepository.instance();
    if (_auth.isAuthenticated) {
      FirebaseFirestore db = FirebaseFirestore.instance;
      String userId = _auth.user!.uid;
      var stream = db.collection('users').doc(userId).snapshots();
      _subscription = stream.listen((value) {
        _favorites.clear();
        List<dynamic> userFavorites = value.get('favorites');
        for (var userFav in userFavorites) {
          WordPair cur = WordPair(userFav['first'], userFav['second']);
          _favorites.add(cur);
        }
        notifyListeners();
      });
    }
  }
}
