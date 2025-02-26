import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AlbumDetailPage extends StatefulWidget {
  final int albumId;
  final String albumTitle;

  const AlbumDetailPage({super.key, required this.albumId, required this.albumTitle});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  Map<String, dynamic>? _albumData;
  bool _isLoading = false;
  String? _errorMessage;

  final String apiToken = "BJkBPJwNBAYaeOkmoeOBgJimeJElBAzePUsWUDQJ";

  @override
  void initState() {
    super.initState();
    fetchAlbumDetails();
  }

  Future<void> fetchAlbumDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse(
        "https://api.discogs.com/releases/${widget.albumId}?token=$apiToken");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _albumData = jsonDecode(response.body);
        });
      } else {
        setState(() {
          _errorMessage = "Error: ${response.statusCode} - ${response.reasonPhrase}";
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

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 2.5,
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.albumTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Text(
                    _errorMessage!,
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  )
                : _albumData != null
                    ? SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _albumData!['title'] ?? "Unknown Title",
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
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

                            // Album Cover (Small Clickable Image)
                            if (_albumData!['images'] != null &&
                                _albumData!['images'].isNotEmpty)
                              GestureDetector(
                                onTap: () => _showFullImage(
                                    _albumData!['images'][0]['uri']),
                                child: Center(
                                  child: Image.network(
                                    _albumData!['images'][0]['uri'],
                                    width: 120, // Small size
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 20),
                            _buildDetailsSection("Genres", _albumData!['genres']),
                            _buildDetailsSection("Styles", _albumData!['styles']),
                            _buildDetailsSection("Labels", _albumData!['labels']?.map((e) => e['name']).toList()),
                            _buildDetailsSection("Formats", _albumData!['formats']?.map((e) => e['name']).toList()),
                            _buildDetailsSection("Catalog Number", _albumData!['labels']?.map((e) => e['catno']).toList()),
                            _buildDetailsSection("Barcode", _albumData!['barcodes']),
                            
                            const SizedBox(height: 20),
                            Text(
                              "Tracklist:",
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),

                            // Display Tracklist
                            _albumData!['tracklist'] != null &&
                                    _albumData!['tracklist'].isNotEmpty
                                ? ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _albumData!['tracklist'].length,
                                    itemBuilder: (context, index) {
                                      final track =
                                          _albumData!['tracklist'][index];
                                      return ListTile(
                                        leading: Text(
                                          "${index + 1}.",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        title:
                                            Text(track['title'] ?? "Unknown Track"),
                                        subtitle: Text(
                                            "Duration: ${track['duration'] ?? 'N/A'}"),
                                      );
                                    },
                                  )
                                : const Center(
                                    child: Text(
                                      "No tracklist available.",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                          ],
                        ),
                      )
                    : const Center(child: Text("No data available")),
      ),
    );
  }

  // Helper function to display album details
  Widget _buildDetailsSection(String title, List<dynamic>? items) {
    if (items == null || items.isEmpty) {
      return const SizedBox.shrink(); // Hide if no data
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title:",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            items.join(", "),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}
