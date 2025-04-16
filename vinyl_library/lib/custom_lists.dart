import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'collection_detail_page.dart'; // Ensure you have this file

class CustomListsPage extends StatelessWidget {
  // Define a required parameter to receive record data from the album detail page.
  final Map<String, dynamic> recordData;

  const CustomListsPage({Key? key, required this.recordData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Retrieve the currently authenticated user.
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not authenticated.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Collections"),
      ),
      // Floating Action Button to create a new collection.
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final TextEditingController _newListController =
              TextEditingController();
          await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("Create New Collection"),
                content: TextField(
                  controller: _newListController,
                  decoration: const InputDecoration(
                    labelText: "Collection Name",
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog.
                    },
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final name = _newListController.text.trim();
                      if (name.isNotEmpty) {
                        try {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('lists')
                              .add({
                            'name': name,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          Navigator.of(context).pop(); // Close the dialog.
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Collection '$name' created")),
                          );
                        } catch (e) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text("Error creating collection: $e")),
                          );
                        }
                      }
                    },
                    child: const Text("Create"),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
        tooltip: "Create New Collection",
      ),
      // Main body: Display list of collections.
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('lists')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<QueryDocumentSnapshot> lists = snapshot.data!.docs;
          if (lists.isEmpty) {
            return const Center(
              child: Text("No collections found. Use the '+' button to create one."),
            );
          }

          return ListView.builder(
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final listDoc = lists[index];
              final String listName = listDoc['name'] ?? "Unnamed Collection";

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(listName),
                  // Nested StreamBuilder to count records in the collection.
                  subtitle: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('lists')
                        .doc(listDoc.id)
                        .collection('records')
                        .snapshots(),
                    builder: (context, recordSnapshot) {
                      if (recordSnapshot.hasError) {
                        return const Text("Error loading records");
                      }
                      if (recordSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Text("Loading records...");
                      }
                      final int recordCount =
                          recordSnapshot.data!.docs.length;
                      return Text(
                          "$recordCount record${recordCount == 1 ? "" : "s"}");
                    },
                  ),
                  // On tapping a collection:
                  // If recordData is non-empty, add the record to the collection.
                  // Then navigate to the CollectionDetailPage to show its albums.
                  onTap: () async {
                    try {
                      // If recordData is non-empty, add it to Firestore.
                      if (recordData.isNotEmpty) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('lists')
                            .doc(listDoc.id)
                            .collection('records')
                            .add(recordData);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Record added to collection")),
                        );
                      }
                      // Navigate to collection detail page.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CollectionDetailPage(
                            listId: listDoc.id,
                            listName: listName,
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
