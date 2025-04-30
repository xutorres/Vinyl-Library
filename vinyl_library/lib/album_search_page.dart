import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'album_detail.dart';

class AlbumSearchPage extends StatefulWidget {
  const AlbumSearchPage({Key? key}) : super(key: key);
  @override
  State<AlbumSearchPage> createState() => _AlbumSearchPageState();
}

class _AlbumSearchPageState extends State<AlbumSearchPage> {
  final _controller = TextEditingController();
  List<dynamic> _results = [];
  bool _loading = false;
  String? _error;
  final String _token = "BJkBPJwNBAYaeOkmoeOBgJimeJElBAzePUsWUDQJ";

  Future<void> searchAlbums(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; _results = []; });
    final uri = Uri.https('api.discogs.com', '/database/search', {
      'q': query,
      'type': 'release',
      'token': _token,
    });
    try {
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body)['results'] as List<dynamic>;
        final Map<int, dynamic> unique = {};
        for (var r in data) {
          final key = (r['master_id'] ?? r['id']) as int;
          if (!unique.containsKey(key)) unique[key] = r;
        }
        _results = unique.values.toList();
      } else {
        _error = "Error ${resp.statusCode}: ${resp.reasonPhrase}";
      }
    } catch (e) {
      _error = "Failed to search: $e";
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openDetail(dynamic album) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlbumDetailPage(
          albumId: album['id'] as int,
          albumTitle: album['title'] as String,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Albums')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Album title',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: searchAlbums,
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (ctx, i) {
                  final a = _results[i] as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: a['cover_image'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                a['cover_image'] as String,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.album),
                      title: Text(a['title'] ?? 'Unknown'),
                      subtitle: Text(a['year']?.toString() ?? ''),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openDetail(a),
                    ),
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
