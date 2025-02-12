import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Information Pulling',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AlbumDetailPage(),
    );
  }
}

class AlbumDetailPage extends StatefulWidget {
  const AlbumDetailPage({super.key});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  Map<String, dynamic>? _albumData;
  bool _isLoading = true;
  String? _errorMessage;

  final String apiToken = "BJkBPJwNBAYaeOkmoeOBgJimeJElBAzePUsWUDQJ";
  final int thrillerAlbumId = 1203470; // american idiot discogs ID

  @override
  void initState() {
    super.initState();
    fetchAlbumDetails();
  }

  Future<void> fetchAlbumDetails() async {
    final url = Uri.parse("https://api.discogs.com/releases/$thrillerAlbumId?token=$apiToken");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _albumData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Error: ${response.statusCode} - ${response.reasonPhrase}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to fetch data: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Album Info")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  )
                : _albumData != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _albumData!['title'] ?? "Unknown Title",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Artist: ${_albumData!['artists'][0]['name'] ?? 'Unknown'}",
                            style: const TextStyle(fontSize: 18),
                          ),
                          Text(
                            "Year: ${_albumData!['year'] ?? 'Unknown'}",
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 10),
                          if (_albumData!['images'] != null && _albumData!['images'].isNotEmpty)
                            Image.network(_albumData!['images'][0]['uri']),
                          const SizedBox(height: 10),
                          Text(
                            "Tracklist:",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _albumData!['tracklist']?.length ?? 0,
                              itemBuilder: (context, index) {
                                final track = _albumData!['tracklist'][index];
                                return ListTile(
                                  title: Text(track['title'] ?? "Unknown Track"),
                                  subtitle: Text("Duration: ${track['duration'] ?? 'N/A'}"),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    : const Center(child: Text("No data available")),
      ),
    );
  }
}
