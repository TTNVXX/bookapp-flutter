import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class BookDetailPage extends StatefulWidget {
  final String bookId;
  final bool isLoggedIn;
  final int userRole;

  BookDetailPage({
    required this.bookId,
    required this.isLoggedIn,
    required this.userRole,
  });

  @override
  _BookDetailPageState createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  bool isLoading = true;
  Map<String, dynamic>? book;
  int? rating;
  String? review;

  @override
  void initState() {
    super.initState();
    fetchBookDetails();
  }

  Future<void> fetchBookDetails() async {
    try {
      final response = await http.post(
        Uri.parse('https://api-sima.ideasophia.my.id/api/main_page/booklist/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': widget.bookId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          book = data['book'];
          rating = data['rating'];
          review = data['review'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load book details');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching book details: $e')),
      );
    }
  }

  String generateStars(int rating) {
    const maxStars = 5;
    String stars = '';
    for (int i = 0; i < maxStars; i++) {
      stars += i < rating ? '⭐' : '☆';
    }
    return stars;
  }

  Future<void> downloadBook(String url) async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission is denied')),
      );
      return;
    }

    final externalDir = await getExternalStorageDirectory();
    final id = await FlutterDownloader.enqueue(
      url: url,
      savedDir: externalDir!.path,
      fileName: 'Downloaded_Book.pdf',
      showNotification: true,
      openFileFromNotification: true,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download started...')),
    );
  }

  Widget buildDownloadButton() {
    if (!widget.isLoggedIn) {
      return Column(
        children: <Widget>[
          ElevatedButton(
            onPressed: null,
            child: Text('Unduh Buku'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
          ),
          SizedBox(height: 8),
          Text('Please log in or sign up to download', style: TextStyle(color: Colors.red)),
        ],
      );
    }

    // Simplified and corrected button for logged-in users
    return ElevatedButton(
      onPressed: () => downloadBook('https://api-sima.ideasophia.my.id${book!['url_buku']}'),
      child: Text('Download Book'),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Details'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            if (book != null) ...[
              Image.network('https://api-sima.ideasophia.my.id${book!['url_image']}', height: 200, width: 150, fit: BoxFit.cover),
              SizedBox(height: 16),
              Text(book!['title'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('Author: ${book!['author']}', style: TextStyle(fontSize: 14)),
              Text('Publisher: ${book!['publisher']}', style: TextStyle(fontSize: 14)),
              Text('Category: ${book!['category']}', style: TextStyle(fontSize: 14)),
              Text('Sub-Category: ${book!['sub_category']}', style: TextStyle(fontSize: 14)),
              Text('Rating: ${rating ?? 0}/5', style: TextStyle(fontSize: 14)),
              Text(generateStars(rating ?? 0), style: TextStyle(fontSize: 14, color: Colors.amber)),
              SizedBox(height: 10),
              Text(review ?? '', style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              buildDownloadButton(),
            ]
          ],
        ),
      ),
    );
  }
}


