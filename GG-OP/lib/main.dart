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
  List<int> championIds = [];
  Map<String, dynamic> championData = {};
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
    String apiUrl =
        'https://euw1.api.riotgames.com/lol/platform/v3/champion-rotations?api_key=RGAPI-63e1fa95-be94-4029-8036-486c498a9800';

    var response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonDataMap = jsonDecode(response.body);
      championIds = jsonDataMap['freeChampionIds'].cast<int>();
      notifyListeners();
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

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 10),
            ],
          ),
        ],
      ),
    );
  }
}
