import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'album_detail.dart'; // Import your album_detail page

class CollectionDetailPage extends StatelessWidget {
  final String listId;
  final String listName;

  const CollectionDetailPage({
    Key? key,
    required this.listId,
    required this.listName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not authenticated.")),
      );
    }

    // Query the records subcollection in this collection.
    final Stream<QuerySnapshot> recordsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('lists')
        .doc(listId)
        .collection('records')
        .orderBy('title')
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: Text(listName)),
      body: StreamBuilder<QuerySnapshot>(
        stream: recordsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data!.docs;
          if (records.isEmpty) {
            return const Center(child: Text("No records found in this collection."));
          }

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final String title = record['title'] ?? "Unknown Title";
              final String artist = record['artist'] ?? "Unknown Artist";
              final String year = record['year']?.toString() ?? "";
              final String? coverImage = record['cover_image'];
              // For navigation, we expect an 'albumId' in the record data.
              final dynamic albumId = record['albumId'];

              return ListTile(
                leading: coverImage != null
                    ? Image.network(
                        coverImage,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.album, size: 50),
                title: Text(title),
                subtitle: Text("$artist${year.isNotEmpty ? ', $year' : ''}"),
                onTap: () {
                  if (albumId != null) {
                    // Navigate to the album detail page, passing the albumId and title.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlbumDetailPage(
                          albumId: albumId,
                          albumTitle: title,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Album ID not found")),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
