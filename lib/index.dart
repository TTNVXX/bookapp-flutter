import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class IndexPage extends StatefulWidget {
  @override
  _IndexPageState createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  bool _isLoading = false;
  List<dynamic> _books = [];

  @override
  void initState() {
    super.initState();
    _searchBooks('');
  }

  void _searchBooks(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      var response = await http.get(
        Uri.parse('https://api-sima.ideasophia.my.id/api/main_page/booklist/?search=$query'),
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _books = data['results'];
        });
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SIMA Library')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _searchBooks,
              decoration: InputDecoration(
                labelText: 'Search books',
                suffixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _books.length,
              itemBuilder: (context, index) {
                var book = _books[index];
                return ListTile(
                  title: Text(book['title']),
                  subtitle: Text(book['author']),
                  onTap: () {
                    Navigator.pushNamed(context, '/book_detail', arguments: book['id']);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
