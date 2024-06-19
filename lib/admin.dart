import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_buku.dart';
import 'update_buku.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _books = [];
  int _totalCount = 0;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _searchBooks();
  }

  Future<void> _logout() async {
    try {
      final response = await http.post(
        Uri.parse('https://api-sima.ideasophia.my.id/api/auth/logout/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'JWT ${await _getToken()}',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to logout');
      }

      await _clearLocalStorage();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (error) {
      print('Error during logout: $error');
      _showErrorDialog('Error during logout');
    }
  }

  Future<void> _searchBooks({int page = 1}) async {
    setState(() {
      _isLoading = true;
    });

    final query = _searchController.text;
    final url =
        'https://api-sima.ideasophia.my.id/api/main_page/booklist/?page=$page&search=$query';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _books = data['results'];
          _totalCount = data['count'];
          _currentPage = page;
        });
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (error) {
      print('Error fetching data: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateBook(int id) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateBookPage(bookId: id.toString()),
      ),
    );
  }

  Future<void> _deleteBook(int id) async {
    final confirmation = await _showConfirmationDialog('Are you sure you want to delete this book?');
    if (!confirmation) return;

    try {
      final response = await http.delete(
        Uri.parse('https://api-sima.ideasophia.my.id/api/main_page/bookcrud/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': await _getToken(),
        },
        body: json.encode({'id': id}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete book');
      }

      _showSuccessDialog('Book deleted successfully');
      _searchBooks();
    } catch (error) {
      print('Error deleting book: $error');
      _showErrorDialog('Error deleting book');
    }
  }

  Future<void> _clearLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<String> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<bool> _showConfirmationDialog(String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmation'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin - Perpustakaan'),
        actions: [
          TextButton(
            onPressed: _logout,
            child: Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddBookPage(),
                      ),
                    );
                  },
                  child: Text('Add Buku'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD4AF37),
                  ),
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Cari judul, pengarang, ISBN, publisher ...',
                    ),
                    onChanged: (value) {
                      _searchBooks();
                    },
                  ),
                ),
              ],
            ),
          ),
          _isLoading
              ? CircularProgressIndicator()
              : Expanded(
            child: ListView.builder(
              itemCount: _books.length,
              itemBuilder: (context, index) {
                final book = _books[index];
                return Card(
                  child: ListTile(
                    leading: Image.network(book['url_image']),
                    title: Text(book['title']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pengarang: ${book['author']}'),
                        Text('Penerbit: ${book['publisher']}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () => _updateBook(book['id']),
                          child: Text('Update'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                        SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: () => _deleteBook(book['id']),
                          child: Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_totalCount > 0)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                children: List.generate(
                  (_totalCount / 10).ceil(),
                      (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      onPressed: () => _searchBooks(page: index + 1),
                      child: Text('${index + 1}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentPage == index + 1
                            ? Color(0xFFD4AF37)
                            : Colors.white,
                        foregroundColor: _currentPage == index + 1
                            ? Colors.black
                            : Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

