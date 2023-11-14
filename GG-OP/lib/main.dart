import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var key = 'RGAPI-1acaa51c-c50d-42ca-8478-dabd1e7e7f96';
  List<int> championIds = [];
  Map<String, dynamic> championData = {};
  Future<String> fetchPuuid(name) async {
    var puuidResponse = await http.get(Uri.parse(
        'https://euw1.api.riotgames.com/lol/summoner/v4/summoners/by-name/$name?api_key=$key'));
    Map<String, dynamic> puuid = jsonDecode(puuidResponse.body);
    return puuid['puuid'].toString();
  }

  Future<Map<String, dynamic>> fetchGame(String gameId) async {
    try {
      final response = await http.get(Uri.parse(
          'https://europe.api.riotgames.com/lol/match/v5/matches/$gameId?api_key=$key'));

      if (response.statusCode == 200) {
        // Parse the JSON response into a Map<String, dynamic>
        Map<String, dynamic> gameData = jsonDecode(response.body);
        return gameData;
      } else {
        // Handle the case where the request fails with a status code other than 200
        throw Exception(
            'Failed to fetch game data. Status code: ${response.statusCode}');
      }
    } catch (error) {
      // Handle any exceptions that occur during the HTTP request
      throw Exception('Error during the request: $error');
    }
  }

  Future<void> fetchGamesInParallel(gameIds) async {
    var results = <Map<String, dynamic>>[];

    // Créez une future pour chaque ID de jeu
    for (String gameId in gameIds) {
      try {
        // Utilisez Future.wait pour attendre l'achèvement de toutes les futures en parallèle
        Map<String, dynamic> result = await fetchGame(gameId);
        results.add(result);
      } catch (error) {
        print(
            'Une erreur s\'est produite lors de la récupération des jeux : $error');
      }
    }

    print(results);
  }

  Future<List> fetchGames(puuid) async {
    var GameResponse = await http.get(Uri.parse(
        'https://europe.api.riotgames.com/lol/match/v5/matches/by-puuid/$puuid/ids?start=0&count=20&api_key=$key'));
    var game = jsonDecode(GameResponse.body) as List;
    print(game);
    return game;
  }

  Future<void> fetchChampionData() async {
    // Récupérer la liste des versions
    var versionsResponse = await http.get(
        Uri.parse('https://ddragon.leagueoflegends.com/api/versions.json'));
    var versions = jsonDecode(versionsResponse.body) as List;
    var latest = versions[0];

    // Récupérer la liste des champions pour en_US pour la dernière version
    var championDataResponse = await http.get(Uri.parse(
        'https://ddragon.leagueoflegends.com/cdn/$latest/data/en_US/champion.json'));
    championData = jsonDecode(championDataResponse.body)['data'];
    print(championData);
  }

  String getChampionInfo(Map<String, dynamic> championData, int id) {
    var list = championData.values.toList();
    for (var champion in list) {
      if (champion['key'] == id.toString()) {
        return champion['name'];
      }
    }
    return "";
  }

  Future<void> fetchChampions() async {
    print('fetch');
    String apiUrl =
        'https://euw1.api.riotgames.com/lol/platform/v3/champion-rotations?api_key=$key';

    var response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonDataMap = jsonDecode(response.body);
      championIds = jsonDataMap['freeChampionIds'].cast<int>();
      notifyListeners();
      print("reussi");
    } else {
      print('Failed to load champions: ${response.statusCode}');
    }
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Accueil'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text('Rotation des champions'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    context.read<MyAppState>().fetchChampions();
    context.read<MyAppState>().fetchChampionData();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var champions = appState.championIds;
    var championData = appState.championData;
    return Center(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                for (var id in champions)
                  ListTile(
                    title: Text(appState.getChampionInfo(championData, id)),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GeneratorPage extends StatefulWidget {
  @override
  _GeneratorPageState createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: 'Entrez du texte',
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              String enteredText = _textController.text;
              appState.fetchPuuid(enteredText).then((puuid) {
                print(puuid);
                appState.fetchGames(puuid).then((game) {
                  print(game);
                  appState.fetchGamesInParallel(game);
                });
              }).catchError((error) {
                print(
                    'Une erreur s\'est produite lors de la récupération du puuid : $error');
              });
            },
            icon: Icon(Icons.search),
            label: Text('Search'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController
        .dispose(); // N'oubliez pas de libérer le contrôleur lorsqu'il n'est plus nécessaire.
    super.dispose();
  }
}
