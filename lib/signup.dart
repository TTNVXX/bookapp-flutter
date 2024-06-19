import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _alamatController = TextEditingController();
  TextEditingController _mobilePhoneController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _tanggalLahirController = TextEditingController();
  TextEditingController _nipController = TextEditingController();

  String _jenisKelamin = 'Pria';
  String _pekerjaan = 'ASN';
  String _pendidikan = 'TK';
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final data = {
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
      'email': _emailController.text,
      'alamat': _alamatController.text,
      'mobile_phone': _mobilePhoneController.text,
      'jenis_kelamin': _jenisKelamin,
      'pekerjaan': _pekerjaan,
      'username': _usernameController.text,
      'password': _passwordController.text,
      'pendidikan': _pendidikan,
      'tanggal_lahir': _tanggalLahirController.text,
      'nip': _nipController.text,
    };

    try {
      final response = await http.post(
        Uri.parse('https://api-sima.ideasophia.my.id/api/auth/signup/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up successful')),
        );
        Navigator.pushNamed(context, '/login');
      } else {
        throw Exception('Failed to sign up');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during sign up')),
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
      appBar: AppBar(
        title: Text('SIGNUP'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  _buildTextField(_firstNameController, 'First Name'),
                  _buildTextField(_lastNameController, 'Last Name'),
                  _buildTextField(_emailController, 'Email', TextInputType.emailAddress),
                  _buildTextField(_alamatController, 'Alamat'),
                  _buildTextField(_mobilePhoneController, 'Mobile Phone', TextInputType.phone),
                  _buildRadioGroup('Jenis Kelamin', ['Pria', 'Wanita'], (value) {
                    setState(() {
                      _jenisKelamin = value!;
                    });
                  }, _jenisKelamin),
                  _buildDropdown('Pekerjaan', ['ASN', 'Swasta', 'Mahasiswa', 'Pelajar', 'Wiraswasta', 'Pegawai Negara Non Asn', 'Other'], (value) {
                    setState(() {
                      _pekerjaan = value!;
                    });
                  }, _pekerjaan),
                  _buildTextField(_usernameController, 'Username'),
                  _buildTextField(_passwordController, 'Password', TextInputType.visiblePassword, true),
                  _buildDropdown('Pendidikan', ['TK', 'SD', 'SMP', 'SMA', 'D3', 'S1', 'S2', 'S3', 'Other'], (value) {
                    setState(() {
                      _pendidikan = value!;
                    });
                  }, _pendidikan),
                  _buildTextField(_tanggalLahirController, 'Tanggal Lahir', TextInputType.datetime),
                  _buildTextField(_nipController, 'NIP'),
                  SizedBox(height: 20),
                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: _signUp,
                    child: Text('Sign Up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, [TextInputType keyboardType = TextInputType.text, bool obscureText = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildRadioGroup(String label, List<String> options, ValueChanged<String?> onChanged, String groupValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Row(
            children: options.map((option) {
              return Expanded(
                child: RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: groupValue,
                  onChanged: onChanged,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, ValueChanged<String?> onChanged, String selectedValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        items: options.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }
}
