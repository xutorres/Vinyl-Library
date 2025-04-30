import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please sign in to view your profile.")),
      );
    }

    final listsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('lists');

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Show email
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(user.email ?? 'No email'),
            ),
            const SizedBox(height: 24),

            // Listen to the lists collection
            StreamBuilder<QuerySnapshot>(
              stream: listsRef.snapshots(),
              builder: (context, listSnap) {
                if (listSnap.hasError) {
                  return Text(
                    "Error: ${listSnap.error}",
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  );
                }
                if (!listSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final lists = listSnap.data!.docs;
                final collectionsCount = lists.length;

                // For each list, fetch its records once
                return FutureBuilder<List<QuerySnapshot>>(
                  future: Future.wait(lists.map((doc) {
                    return listsRef
                        .doc(doc.id)
                        .collection('records')
                        .get();
                  })),
                  builder: (context, recSnap) {
                    if (recSnap.hasError) {
                      return Text(
                        "Error: ${recSnap.error}",
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      );
                    }
                    if (!recSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Sum all record counts
                    final totalRecords = recSnap.data!
                        .map((qs) => qs.docs.length)
                        .fold<int>(0, (a, b) => a + b);

                    return Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.folder),
                          title: Text(
                            '$collectionsCount collection${collectionsCount == 1 ? '' : 's'}',
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.library_music),
                          title: Text(
                            '$totalRecords record${totalRecords == 1 ? '' : 's'} saved',
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            // Push the sign-out button to the bottom
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              onPressed: () => FirebaseAuth.instance.signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
