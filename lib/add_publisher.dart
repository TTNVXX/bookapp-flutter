import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AddPublisherPage extends StatefulWidget {
  @override
  _AddPublisherPageState createState() => _AddPublisherPageState();
}

class _AddPublisherPageState extends State<AddPublisherPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _cityController = TextEditingController();
  TextEditingController _countryController = TextEditingController();
  TextEditingController _websiteController = TextEditingController();
  TextEditingController _contactController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addPublisher() async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';

    try {
      final response = await http.post(
        Uri.parse('https://api-sima.ideasophia.my.id/api/main_page/publishercrud/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: json.encode({
          'name': _nameController.text,
          'address': _addressController.text,
          'city': _cityController.text,
          'country': _countryController.text,
          'website': _websiteController.text,
          'contact': _contactController.text,
        }),
      );

      if (response.statusCode == 200) {
        print('Publisher added successfully');
        Navigator.pushNamed(context, '/admin');
      } else {
        throw Exception('Failed to add publisher');
      }
    } catch (error) {
      print('Error adding publisher: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Publisher'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Address'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(labelText: 'City'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter city';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _countryController,
                decoration: InputDecoration(labelText: 'Country'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter country';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _websiteController,
                decoration: InputDecoration(labelText: 'Website'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter website';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(labelText: 'Contact'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _addPublisher();
                  }
                },
                child: Text('Add Publisher'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
