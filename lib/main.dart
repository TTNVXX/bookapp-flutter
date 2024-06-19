import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'signup.dart';
import 'admin.dart';
import 'book_detail.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perpustakaan',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.amber),
          toolbarTextStyle: TextStyle(
            color: Colors.amber,
            fontSize: 20,
          ),
          titleTextStyle: TextStyle(
            color: Colors.amber,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: MyHomePage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/home': (context) => MyHomePage(),
        '/admin': (context) => AdminPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _searchController = TextEditingController();
  List books = [];
  bool isLoading = false;
  String? userName;
  int? userRole;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('nama');
      userRole = prefs.getInt('role');
      isLoggedIn = prefs.getString('token') != null;
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    setState(() {
      userName = null;
      userRole = null;
      isLoggedIn = false;
    });
  }

  Future<void> _searchBooks() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(Uri.parse(
        'https://api-sima.ideasophia.my.id/api/main_page/booklist/?search=${_searchController.text}'));

    if (response.statusCode == 200) {
      setState(() {
        books = json.decode(response.body)['results'];
      });
    } else {
      // Handle error
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SIMA',
          style: TextStyle(color: Colors.amber),
        ),
        actions: [
          if (userName != null) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  'Welcome, $userName',
                  style: TextStyle(color: Colors.amber),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.logout, color: Colors.amber),
              onPressed: _logout,
            ),
            if (userRole == 1)
              IconButton(
                icon: Icon(Icons.admin_panel_settings, color: Colors.amber),
                onPressed: () {
                  Navigator.pushNamed(context, '/admin');
                },
              ),
          ] else ...[
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Text('Login', style: TextStyle(color: Colors.amber)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: Text('Sign Up', style: TextStyle(color: Colors.amber)),
            ),
          ]
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset('assets/logo.png', width: 100, height: 100),
              Text(
                'SIMA LIBRARY',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              Text('Sumber Ilmu untuk masyarakat', style: TextStyle(fontStyle: FontStyle.italic)),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(color: Colors.black),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                      onPressed: _searchBooks,
                      child: Text(
                        'Search',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              isLoading
                  ? CircularProgressIndicator()
                  : books.isEmpty
                  ? Text('No books found.')
                  : Expanded(
                child: ListView.builder(
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return ListTile(
                      leading: Image.network(book['url_image']),
                      title: Text(book['title']),
                      subtitle: Text(book['author']),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookDetailPage(
                              bookId: book['id'].toString(),
                              userRole: userRole ?? 0,
                              isLoggedIn: isLoggedIn,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
