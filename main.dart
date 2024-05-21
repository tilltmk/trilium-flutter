import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(TriliumApp());
}

class TriliumApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trilium App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NotesPage(),
    );
  }
}

class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<dynamic> notes = [];
  bool isLoading = false;
  String apiUrl = 'https://your-trilium-instance.com/api/notes';
  String apiKey = 'your_api_key';

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          notes = data;
        });
      } else {
        print('Failed to fetch notes');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch notes')),
        );
      }
    } catch (e) {
      print('An error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> createNote() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: contentController,
                decoration: InputDecoration(labelText: 'Content'),
                maxLines: 5,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final response = await http.post(
                  Uri.parse(apiUrl),
                  headers: {
                    'Authorization': 'Bearer $apiKey',
                    'Content-Type': 'application/json',
                  },
                  body: json.encode({
                    'title': titleController.text,
                    'content': contentController.text,
                  }),
                );

                if (response.statusCode == 201) {
                  fetchNotes();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create note')),
                  );
                }
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trilium Notes'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: createNote,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(note['title']),
                    subtitle: Text(note['dateCreated']),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteDetailPage(note: note, apiKey: apiKey, apiUrl: apiUrl),
                        ),
                      ).then((_) => fetchNotes());
                    },
                  ),
                );
              },
            ),
    );
  }
}

class NoteDetailPage extends StatefulWidget {
  final dynamic note;
  final String apiKey;
  final String apiUrl;

  NoteDetailPage({required this.note, required this.apiKey, required this.apiUrl});

  @override
  _NoteDetailPageState createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late TextEditingController titleController;
  late TextEditingController contentController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note['title']);
    contentController = TextEditingController(text: widget.note['content']);
  }

  Future<void> updateNote() async {
    final response = await http.put(
      Uri.parse('${widget.apiUrl}/${widget.note['id']}'),
      headers: {
        'Authorization': 'Bearer ${widget.apiKey}',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'title': titleController.text,
        'content': contentController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update note')),
      );
    }
  }

  Future<void> deleteNote() async {
    final response = await http.delete(
      Uri.parse('${widget.apiUrl}/${widget.note['id']}'),
      headers: {
        'Authorization': 'Bearer ${widget.apiKey}',
      },
    );

    if (response.statusCode == 204) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete note')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note['title']),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: deleteNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 16),
            Text('Created on: ${widget.note['dateCreated']}'),
            SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: InputDecoration(labelText: 'Content'),
              maxLines: 15,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: updateNote,
              child: Text('Update Note'),
            ),
          ],
        ),
      ),
    );
  }
}
