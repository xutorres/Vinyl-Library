import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'custom_lists.dart';

class AlbumDetailPage extends StatefulWidget {
  final int albumId;
  final String albumTitle;

  const AlbumDetailPage({
    Key? key,
    required this.albumId,
    required this.albumTitle,
  }) : super(key: key);

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  Map<String, dynamic>? _data;
  bool _loading = false;
  String? _error;
  final String _token = "BJkBPJwNBAYaeOkmoeOBgJimeJElBAzePUsWUDQJ";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final uri = Uri.parse(
        "https://api.discogs.com/releases/${widget.albumId}?token=$_token");
    try {
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        _data = jsonDecode(resp.body);
      } else {
        _error = "Error ${resp.statusCode}";
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 2.5,
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _infoCard(String title, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(items.join(', ')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      appBar: AppBar(title: Text(widget.albumTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : d == null
                  ? const Center(child: Text("No data"))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (d['images'] != null && d['images'].isNotEmpty)
                            Center(
                              child: GestureDetector(
                                onTap: () => _showImage(d['images'][0]['uri']),
                                child: Image.network(
                                  d['images'][0]['uri'],
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Text(d['title'] ?? 'Unknown Title',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text(
                            "${d['artists'][0]['name']} • ${d['year']}",
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          _infoCard('Genres', List<String>.from(d['genres'] ?? [])),
                          _infoCard('Styles', List<String>.from(d['styles'] ?? [])),
                          _infoCard('Labels',
                              (d['labels'] as List).map((l) => l['name'] as String).toList()),
                          _infoCard('Formats',
                              (d['formats'] as List).map((f) => f['name'] as String).toList()),
                          const Divider(),
                          ExpansionTile(
                            title: const Text('Tracklist'),
                            children: [
                              if ((d['tracklist'] as List?)?.isNotEmpty ?? false)
                                for (int i = 0; i < d['tracklist'].length; i++)
                                  ListTile(
                                    dense: true,
                                    leading: Text('${i + 1}.'),
                                    title: Text(d['tracklist'][i]['title'] ?? ''),
                                    subtitle: Text(d['tracklist'][i]['duration'] ?? ''),
                                  )
                              else
                                const ListTile(title: Text('No tracks')),
                            ],
                          ),
                        ],
                      ),
                    ),
      floatingActionButton: d == null
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.playlist_add),
              label: const Text('Add to List'),
              onPressed: () {
                final rd = {
                  'albumId': widget.albumId,
                  'title': d['title'],
                  'artist': d['artists'][0]['name'],
                  'year': d['year'],
                  'cover_image': (d['images'] as List?)?.isNotEmpty ?? false
                      ? d['images'][0]['uri']
                      : null,
                };
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomListsPage(recordData: rd),
                  ),
                );
              },
            ),
    );
  }
}
