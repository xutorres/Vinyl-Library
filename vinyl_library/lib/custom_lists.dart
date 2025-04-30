import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'collection_detail_page.dart';

class CustomListsPage extends StatelessWidget {
  final Map<String, dynamic>? recordData;

  const CustomListsPage({Key? key, this.recordData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Sign in to view collections")),
      );
    }

    final listsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('lists');

    return Scaffold(
      appBar: AppBar(title: const Text('Your Collections')),
      floatingActionButton: recordData == null
          ? FloatingActionButton(
              onPressed: () async {
                final ctrl = TextEditingController();
                await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('New Collection'),
                    content: TextField(controller: ctrl),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final name = ctrl.text.trim();
                          if (name.isNotEmpty) {
                            await listsRef.add({
                              'name': name,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: listsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No collections yet'));
          }
          return ListView(
            children: docs.map((doc) {
              final name = doc['name'] as String;
              return Card(
                child: ListTile(
                  title: Text(name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: Theme.of(context).colorScheme.error,
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Collection'),
                              content: Text('Are you sure you want to delete "$name"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await listsRef.doc(doc.id).delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Deleted "$name"')),
                            );
                          }
                        },
                      ),
                      // Just an icon now — ListTile.onTap handles the action
                      const Icon(Icons.chevron_right),
                    ],
                  ),

                  // Make the entire tile tappable
                  onTap: () async {
                    if (recordData != null) {
                      // Add recordData into this list
                      await listsRef
                          .doc(doc.id)
                          .collection('records')
                          .add(recordData!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added to "$name"')),
                      );
                    } else {
                      // Navigate to detail page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CollectionDetailPage(
                            listId: doc.id,
                            listName: name,
                          ),
                        ),
                      );
                    }
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
