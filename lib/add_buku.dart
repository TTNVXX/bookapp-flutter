import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class AddBookPage extends StatefulWidget {
  @override
  _AddBookPageState createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _isbnController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _sinopsisController = TextEditingController();

  String? _selectedAuthor;
  String? _selectedPublisher;
  String? _selectedCategory;
  String? _selectedSubCategory;
  bool _isPremium = false;

  File? _selectedImage;
  File? _selectedPdf;

  List<String> _authors = [];
  List<String> _publishers = [];

  @override
  void initState() {
    super.initState();
    _fetchAuthors();
    _fetchPublishers();
  }

  Future<void> _fetchAuthors() async {
    try {
      final response = await http.get(Uri.parse('https://api-sima.ideasophia.my.id/api/main_page/authorlist/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _authors = List<String>.from(data.map((author) => author['name']));
          if (_authors.isNotEmpty) _selectedAuthor = _authors[0];
        });
      }
    } catch (error) {
      print('Error fetching authors: $error');
    }
  }

  Future<void> _fetchPublishers() async {
    try {
      final response = await http.get(Uri.parse('https://api-sima.ideasophia.my.id/api/main_page/publisherlist/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _publishers = List<String>.from(data.map((publisher) => publisher['name']));
          if (_publishers.isNotEmpty) _selectedPublisher = _publishers[0];
        });
      }
    } catch (error) {
      print('Error fetching publishers: $error');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedPdf = File(result.files.single.path!);
      });
    }
  }

  Future<void> _addBook() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final token = await _getToken();
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api-sima.ideasophia.my.id/api/main_page/bookcrud/'),
        );

        request.headers['Authorization'] = token;

        request.fields['title'] = _titleController.text;
        request.fields['code'] = _codeController.text;
        request.fields['author'] = _selectedAuthor ?? '';
        request.fields['isbn'] = _isbnController.text;
        request.fields['publisher'] = _selectedPublisher ?? '';
        request.fields['category'] = _selectedCategory ?? '';
        request.fields['sub_category'] = _selectedSubCategory ?? '';
        request.fields['stok'] = _stokController.text;
        request.fields['rating'] = _ratingController.text;
        request.fields['premium'] = _isPremium ? 'True' : 'False';
        request.fields['sinopsis'] = _sinopsisController.text;

        if (_selectedImage != null) {
          request.files.add(
            await http.MultipartFile.fromPath('image', _selectedImage!.path),
          );
        }

        if (_selectedPdf != null) {
          request.files.add(
            await http.MultipartFile.fromPath('pdf', _selectedPdf!.path),
          );
        }

        final response = await request.send();

        if (response.statusCode == 200) {
          _showSuccessDialog('Book added successfully');
        } else {
          throw Exception('Failed to add book');
        }
      } catch (error) {
        print('Error adding book: $error');
        _showErrorDialog('Error adding book');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
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
    ).then((_) {
      Navigator.of(context).pop(); // Close the AddBookPage
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Book'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(labelText: 'Code'),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter code';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedAuthor,
                items: _authors
                    .map((author) => DropdownMenuItem(
                  child: Text(author),
                  value: author,
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAuthor = value;
                  });
                },
                decoration: InputDecoration(labelText: 'Author'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an author';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _isbnController,
                decoration: InputDecoration(labelText: 'ISBN'),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter ISBN';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedPublisher,
                items: _publishers
                    .map((publisher) => DropdownMenuItem(
                  child: Text(publisher),
                  value: publisher,
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPublisher = value;
                  });
                },
                decoration: InputDecoration(labelText: 'Publisher'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a publisher';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: ['Fiksi', 'Non-Fiksi']
                    .map((category) => DropdownMenuItem(
                  child: Text(category),
                  value: category,
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                decoration: InputDecoration(labelText: 'Category'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedSubCategory,
                items: [
                  'Novel',
                  'Komik',
                  'Sains',
                  'Humaniora',
                  'Biografi',
                  'Pendidikan',
                  'Agama',
                  'Psikologi',
                  'Pertanian',
                  'Journal'
                ]
                    .map((subCategory) => DropdownMenuItem(
                  child: Text(subCategory),
                  value: subCategory,
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubCategory = value;
                  });
                },
                decoration: InputDecoration(labelText: 'Sub Category'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a sub category';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _stokController,
                decoration: InputDecoration(labelText: 'Stok'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter stok';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _ratingController,
                decoration: InputDecoration(labelText: 'Rating'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter rating';
                  }
                  return null;
                },
              ),
              SwitchListTile(
                title: Text('Premium'),
                value: _isPremium,
                onChanged: (value) {
                  setState(() {
                    _isPremium = value;
                  });
                },
              ),
              TextFormField(
                controller: _sinopsisController,
                decoration: InputDecoration(labelText: 'Sinopsis'),
                maxLines: 3,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter sinopsis';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextButton.icon(
                icon: Icon(Icons.image),
                label: Text('Upload Image'),
                onPressed: _pickImage,
              ),
              if (_selectedImage != null) Text('Image selected: ${_selectedImage!.path}'),
              TextButton.icon(
                icon: Icon(Icons.picture_as_pdf),
                label: Text('Upload PDF'),
                onPressed: _pickPdf,
              ),
              if (_selectedPdf != null) Text('PDF selected: ${_selectedPdf!.path}'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addBook,
                child: Text('Add Book'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
