import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class UpdateBookPage extends StatefulWidget {
  final String bookId;

  UpdateBookPage({required this.bookId});

  @override
  _UpdateBookPageState createState() => _UpdateBookPageState();
}

class _UpdateBookPageState extends State<UpdateBookPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _codeController = TextEditingController();
  TextEditingController _isbnController = TextEditingController();
  TextEditingController _stokController = TextEditingController();
  TextEditingController _ratingController = TextEditingController();
  TextEditingController _sinopsisController = TextEditingController();
  String? _selectedAuthor;
  String? _selectedPublisher;
  String _selectedCategory = 'Fiksi';
  String _selectedSubCategory = 'Novel';
  bool _isPremium = false;
  bool _isLoading = false;
  List<String> _authors = [];
  List<String> _publishers = [];
  File? _selectedImage;
  File? _selectedPdf;

  @override
  void initState() {
    super.initState();
    _fetchAuthors();
    _fetchPublishers();
    _fetchBookData(widget.bookId);
  }

  Future<void> _fetchAuthors() async {
    try {
      final response = await http.get(
          Uri.parse('https://api-sima.ideasophia.my.id/api/main_page/authorlist/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _authors = data.map((author) => author['name'] as String).toList();
        });
      } else {
        throw Exception('Failed to load authors');
      }
    } catch (error) {
      print('Error fetching authors: $error');
    }
  }

  Future<void> _fetchPublishers() async {
    try {
      final response = await http.get(
          Uri.parse('https://api-sima.ideasophia.my.id/api/main_page/publisherlist/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _publishers = data.map((publisher) => publisher['name'] as String).toList();
        });
      } else {
        throw Exception('Failed to load publishers');
      }
    } catch (error) {
      print('Error fetching publishers: $error');
    }
  }

  Future<void> _fetchBookData(String id) async {
    final token = await _getToken();
    try {
      final response = await http.get(
        Uri.parse('https://api-sima.ideasophia.my.id/api/main_page/bookcrud/?id=$id'),
        headers: {'Authorization': 'JWT $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _populateForm(data);
      } else {
        throw Exception('Failed to load book data');
      }
    } catch (error) {
      print('Error fetching book data: $error');
    }
  }

  void _populateForm(Map<String, dynamic> data) {
    setState(() {
      final book = data['book'];
      _titleController.text = book['title'];
      _codeController.text = book['code'];
      _isbnController.text = book['isbn'];
      _stokController.text = book['stok'].toString();
      _ratingController.text = data['rating'].toString();
      _sinopsisController.text = data['review'];
      _selectedAuthor = book['author'];
      _selectedPublisher = book['publisher'];
      _selectedCategory = book['category'];
      _selectedSubCategory = book['sub_category'];
      _isPremium = book['premium'];
    });
  }

  Future<String> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _updateBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final token = await _getToken();
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('https://api-sima.ideasophia.my.id/api/main_page/bookcrud/'),
    );
    request.headers['Authorization'] = token;
    request.fields['id'] = widget.bookId;
    request.fields['title'] = _titleController.text;
    request.fields['code'] = _codeController.text;
    request.fields['author'] = _selectedAuthor!;
    request.fields['isbn'] = _isbnController.text;
    request.fields['publisher'] = _selectedPublisher!;
    request.fields['category'] = _selectedCategory;
    request.fields['sub_category'] = _selectedSubCategory;
    request.fields['stok'] = _stokController.text;
    request.fields['rating'] = _ratingController.text;
    request.fields['premium'] = _isPremium ? 'True' : 'False';
    request.fields['sinopsis'] = _sinopsisController.text;

    if (_selectedImage != null) {
      request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));
    }

    if (_selectedPdf != null) {
      request.files.add(await http.MultipartFile.fromPath('buku', _selectedPdf!.path));
    }

    try {
      final response = await request.send();
      if (response.statusCode != 200) {
        throw Exception('Failed to update book');
      }

      final responseData = await response.stream.bytesToString();
      final result = json.decode(responseData);
      print('Book updated successfully: $result');
      _showDialog('Success', 'Book updated successfully');
    } catch (error) {
      print('Error updating book: $error');
      _showDialog('Error', 'Error updating book');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (title == 'Success') {
                Navigator.of(context).pop();
              }
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
      });
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedPdf = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Book'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(labelText: 'Code'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the code';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedAuthor,
                items: _authors
                    .map((author) => DropdownMenuItem(
                  value: author,
                  child: Text(author),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAuthor = value;
                  });
                },
                decoration: InputDecoration(labelText: 'Author'),
              ),
              TextFormField(
                controller: _isbnController,
                decoration: InputDecoration(labelText: 'ISBN'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the ISBN';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedPublisher,
                items: _publishers
                    .map((publisher) => DropdownMenuItem(
                  value: publisher,
                  child: Text(publisher),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPublisher = value;
                  });
                },
                decoration: InputDecoration(labelText: 'Publisher'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: ['Fiksi', 'Non Fiksi']
                    .map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration: InputDecoration(labelText: 'Category'),
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
                  value: subCategory,
                  child: Text(subCategory),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubCategory = value!;
                  });
                },
                decoration: InputDecoration(labelText: 'Sub Category'),
              ),
              TextFormField(
                controller: _stokController,
                decoration: InputDecoration(labelText: 'Stok'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the stock';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _ratingController,
                decoration: InputDecoration(labelText: 'Rating'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the rating';
                  }
                  return null;
                },
              ),
              Row(
                children: [
                  Text('Premium:'),
                  Radio(
                    value: true,
                    groupValue: _isPremium,
                    onChanged: (value) {
                      setState(() {
                        _isPremium = value as bool;
                      });
                    },
                  ),
                  Text('True'),
                  Radio(
                    value: false,
                    groupValue: _isPremium,
                    onChanged: (value) {
                      setState(() {
                        _isPremium = value as bool;
                      });
                    },
                  ),
                  Text('False'),
                ],
              ),
              TextFormField(
                controller: _sinopsisController,
                decoration: InputDecoration(labelText: 'Sinopsis'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the sinopsis';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text(_selectedImage == null
                    ? 'Select Image'
                    : 'Change Image'),
              ),
              ElevatedButton(
                onPressed: _pickPdf,
                child: Text(_selectedPdf == null
                    ? 'Select PDF'
                    : 'Change PDF'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _updateBook,
                child: Text('Update Book'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
