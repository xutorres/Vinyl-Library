// album_search_page.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'album_detail.dart';

class AlbumSearchPage extends StatefulWidget {
  const AlbumSearchPage({super.key});

  @override
  State<AlbumSearchPage> createState() => _AlbumSearchPageState();
}

class _AlbumSearchPageState extends State<AlbumSearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  final String apiToken = "BJkBPJwNBAYaeOkmoeOBgJimeJElBAzePUsWUDQJ";

  Future<void> searchAlbums(String title) async {
    String searchTerm = _controller.text.trim();
    if (searchTerm.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchResults = [];
    });

    final String apiUrl =
        "https://api.discogs.com/database/search?q=${Uri.encodeComponent(searchTerm)}&type=release&token=$apiToken";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _searchResults = data['results'];
        });
      } else {
        setState(() {
          _errorMessage =
              "Error: ${response.statusCode} - ${response.reasonPhrase}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to fetch data: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToAlbumDetail(dynamic album) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlbumDetailPage(
          albumId: album['id'],
          albumTitle: album['title'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Album Search")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Enter search query",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => searchAlbums(value),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => searchAlbums(_controller.text),
              child: const Text("Search Albums"),
            ),
            const SizedBox(height: 20),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final album = _searchResults[index];
                  return ListTile(
                    leading: album['cover_image'] != null
                        ? Image.network(album['cover_image'],
                            width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.music_note, size: 50),
                    title: Text(album['title'] ?? "Unknown Title"),
                    subtitle: Text(album['year'] != null
                        ? "Year: ${album['year']}"
                        : "Unknown Year"),
                    onTap: () => _navigateToAlbumDetail(album),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
