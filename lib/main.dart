import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore List Web',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2962FF)),
      home: const ItemListApp(),
    );
  }
}

class ItemListApp extends StatefulWidget {
  const ItemListApp({super.key});

  @override
  State<ItemListApp> createState() => _ItemListAppState();
}

class _ItemListAppState extends State<ItemListApp> {
  final TextEditingController _newItemTextField = TextEditingController();
  late final CollectionReference<Map<String, dynamic>> items;

  @override
  void initState() {
    super.initState();
    items = FirebaseFirestore.instance.collection('ITEMS');
  }

  Future<void> _addItem() async {
    final newItem = _newItemTextField.text.trim();
    if (newItem.isEmpty) return;
    await items.add({
      'item_name': newItem,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _newItemTextField.clear();
  }

  Future<void> _removeItemAt(String id) async {
    await items.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firestore List Web Demo')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          children: [
            NewItemWidget(),
            const SizedBox(height: 24),
            Expanded(
              child: ItemListWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget NewItemWidget() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _newItemTextField,
            onSubmitted: (_) => _addItem(),
            decoration: const InputDecoration(
              labelText: 'New Item Name',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(onPressed: _addItem, child: const Text('Add')),
      ],
    );
  }

  Widget ItemListWidget() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: items.orderBy('createdAt').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Text('Firebase Snapshot Error: ${snap.error}');
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.data == null || snap.data!.docs.isEmpty) {
          return const Center(child: Text('No Items Yet...'));
        }

        final docs = snap.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final String itemId = doc.id;
            final String itemName = doc.data()['item_name'] ?? 'Unnamed';
            return Dismissible(
              key: ValueKey(itemId),
              background: Container(color: Colors.red),
              onDismissed: (_) => _removeItemAt(itemId),
              child: ListTile(
                leading: const Icon(Icons.check_box),
                title: Text(itemName),
                onTap: () => _removeItemAt(itemId),
              ),
            );
          },
        );
      },
    );
  }
}

