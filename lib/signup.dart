import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? firstName;
  String? lastName;
  String? email;
  String? address;
  String? mobilePhone;
  String? gender;
  String? job;
  String? username;
  String? password;
  String? education;
  String? birthDate;
  String? nip;

  void _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      var response = await http.post(
        Uri.parse('https://api-sima.ideasophia.my.id/api/auth/signup/'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String?>{
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'alamat': address,
          'mobile_phone': mobilePhone,
          'jenis_kelamin': gender,
          'pekerjaan': job,
          'username': username,
          'password': password,
          'pendidikan': education,
          'tanggal_lahir': birthDate,
          'nip': nip,
        }),
      );

      if (response.statusCode == 200) {
        // Handle successful signup
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Handle error
        throw Exception('Failed to sign up');
      }
    } catch (e) {
      // Handle network error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextFormField(
                  onSaved: (value) => firstName = value,
                  validator: (value) => value!.isEmpty ? 'Enter first name' : null,
                  decoration: InputDecoration(labelText: 'First Name'),
                ),
                TextFormField(
                  onSaved: (value) => lastName = value,
                  validator: (value) => value!.isEmpty ? 'Enter last name' : null,
                  decoration: InputDecoration(labelText: 'Last Name'),
                ),
                TextFormField(
                  onSaved: (value) => email = value,
                  validator: (value) => value!.isEmpty ? 'Enter email' : null,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                TextFormField(
                  onSaved: (value) => address = value,
                  validator: (value) => value!.isEmpty ? 'Enter address' : null,
                  decoration: InputDecoration(labelText: 'Address'),
                ),
                TextFormField(
                  onSaved: (value) => mobilePhone = value,
                  validator: (value) => value!.isEmpty ? 'Enter mobile phone' : null,
                  decoration: InputDecoration(labelText: 'Mobile Phone'),
                ),
                // Add other fields in similar manner
                ElevatedButton(
                  onPressed: _signUp,
                  child: Text('Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
