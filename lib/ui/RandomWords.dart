import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:hello_me/ui/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hello_me/data/auth_repository.dart';
import 'package:hello_me/data/favorites_repository.dart';
import 'package:provider/provider.dart';

class RandomWords extends StatefulWidget {
  const RandomWords({Key? key}) : super(key: key);

  @override
  State<RandomWords> createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[]; // NEW

  final _biggerFont = const TextStyle(fontSize: 18); // NEW

  Widget? deleteBackground(MainAxisAlignment maa) {
    return Row(mainAxisAlignment: maa, children: [
      const Icon(
        Icons.delete,
        color: Colors.white,
      ),
      Text("Delete Suggestion",
          style: const TextStyle(fontSize: 18, color: Colors.white))
    ]);
  }

  void _pushSaved() {
    Navigator.of(context).push(
        // Add lines from here...
        MaterialPageRoute<void>(builder: (context) {
      return Consumer<FavoritesRepository>(
        builder: (context, fav, _) {
          final tiles = fav.favorites.map(
            (pair) {
              return Dismissible(
                child: ListTile(
                  title: Text(
                    pair.asPascalCase,
                    style: _biggerFont,
                  ),
                ),
                background: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    alignment: Alignment.centerLeft,
                    child: deleteBackground(MainAxisAlignment.start),
                    color: Theme.of(context).colorScheme.primary),
                secondaryBackground: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    alignment: Alignment.centerRight,
                    child: deleteBackground(MainAxisAlignment.end),
                    color: Theme.of(context).colorScheme.primary),
                key: ValueKey<String>(pair.asPascalCase),
                confirmDismiss: (DismissDirection direction) async {
                  bool? result = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: Text('Delete Suggestion'),
                      content: Text(
                          'Are you sure you want to delete ${pair.asPascalCase} from your saved suggestions?'),
                      actions: <Widget>[
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Yes'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('No'),
                        ),
                      ],
                    ),
                  );
                  if (result == true) {
                    fav.remove(pair);
                  }
                  return result;
                },
              );
            },
          );
          final divided = tiles.isNotEmpty
              ? ListTile.divideTiles(
                  context: context,
                  tiles: tiles,
                ).toList()
              : <Widget>[];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Saved Suggestions'),
            ),
            body: ListView(children: divided),
          );
        },
      );
    }));
  }

  void _pushLogin() {
    Navigator.of(context).push(
      // Add lines from here...
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
              appBar: AppBar(
                title: const Text('Saved Suggestions'),
              ),
              // body: _loginPage(context),
              body: LoginPage());
        },
      ), // ...to here.
    );
  }

  void _logOut(AuthRepository auth) {
    auth.signOut();
    const snackBar = SnackBar(
      content: Text('Successfuly logged out'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    // return ChangeNotifierProvider(
    //     create: (_) => AuthRepository.instance(),
    print("Gilj ${this.widget.key}");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Startup Name Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: _pushSaved,
            tooltip: 'Saved Suggestions',
          ),
          Consumer<AuthRepository>(
              builder: (context, auth, _) => auth.isAuthenticated
                  ? IconButton(
                      icon: const Icon(Icons.exit_to_app),
                      onPressed: () => _logOut(auth),
                      tooltip: "Logout",
                    )
                  : IconButton(
                      icon: const Icon(Icons.login),
                      onPressed: _pushLogin,
                      tooltip: "Login",
                    ))
        ],
        // ... to here
      ),
      body: _buildSuggestions(),
    );
  }

  Widget _buildRow(WordPair pair) {
    return Consumer<FavoritesRepository>(builder: (context, fav, _) {
      final alreadySaved = fav.favorites.contains(pair);
      return ListTile(
        title: Text(
          pair.asPascalCase,
          style: _biggerFont,
        ),
        trailing: Icon(
          alreadySaved ? Icons.star : Icons.star_border,
          color: alreadySaved ? Theme.of(context).colorScheme.primary : null,
          semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
        ), // ... to here.
        onTap: () {
          if (alreadySaved) {
            fav.remove(pair);
          } else {
            fav.add(pair);
          }
          // });
        }, // ... to here.
      );
    });
  }

  Widget _buildSuggestions() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      // The itemBuilder callback is called once per suggested
      // word pairing, and places each suggestion into a ListTile
      // row. For even rows, the function adds a ListTile row for
      // the word pairing. For odd rows, the function adds a
      // Divider widget to visually separate the entries. Note that
      // the divider may be difficult to see on smaller devices.
      itemBuilder: (context, i) {
        // Add a one-pixel-high divider widget before each row
        // in the ListView.
        if (i.isOdd) {
          return const Divider();
        }

        // The syntax "i ~/ 2" divides i by 2 and returns an
        // integer result.
        // For example: 1, 2, 3, 4, 5 becomes 0, 1, 1, 2, 2.
        // This calculates the actual number of word pairings
        // in the ListView,minus the divider widgets.
        final index = i ~/ 2;
        // If you've reached the end of the available word
        // pairings...

        if (index >= _suggestions.length) {
          _suggestions.addAll(generateWordPairs().take(10));
        }

        return _buildRow(_suggestions[index]);
      },
    );
  }
}
