import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'album_detail.dart';

class CollectionDetailPage extends StatelessWidget {
  final String listId;
  final String listName;
  const CollectionDetailPage({Key? key, required this.listId, required this.listName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Sign in first")));
    }
    return Scaffold(
      appBar: AppBar(title: Text(listName)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users').doc(user.uid)
            .collection('lists').doc(listId)
            .collection('records')
            .orderBy('title')
            .snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final recs = snap.data!.docs;
          if (recs.isEmpty) return const Center(child: Text('Empty'));
          return ListView(
            children: recs.map((r) {
              final data = r.data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: data['cover_image'] != null
                      ? Image.network(data['cover_image'], width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.album),
                  title: Text(data['title']),
                  subtitle: Text(data['artist']),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlbumDetailPage(
                          albumId: data['albumId'] as int,
                          albumTitle: data['title'] as String,
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
