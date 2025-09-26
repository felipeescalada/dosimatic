import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../services/contact_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';

class ContactFormScreen extends StatefulWidget {
  final Contact? contact;

  const ContactFormScreen({super.key, this.contact});

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _isLoading = false;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  int _selectedCountry = 1;
  int _selectedCity = 1;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _firstNameController.text = widget.contact!.firstName;
      _lastNameController.text = widget.contact!.lastName;
      _businessNameController.text = widget.contact!.businessName;
      _emailController.text = widget.contact!.email;
      _phoneController.text = widget.contact!.phoneNumber;
      _zipCodeController.text = widget.contact!.zipCode;
      _selectedCountry = widget.contact!.country;
      _selectedCity = widget.contact!.city;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _businessNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _zipCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('KYC Form'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Please input all the fild for sign in to your account to get access to your dashboard.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // First Name and Last Name Row
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _firstNameController,
                      labelText: 'First Name',
                      hintText: 'Enter First Name',
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _lastNameController,
                      labelText: 'Last Name',
                      hintText: 'Enter Last Name',
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomTextField(
                maxLines: 1,
                controller: _businessNameController,
                labelText: 'Business Name',
                hintText: 'Enter Business Name',
              ),
              const SizedBox(height: 16),

              CustomTextField(
                maxLines: 1,
                controller: _emailController,
                labelText: 'Email Address',
                hintText: 'Enter Email Address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                maxLines: 1,
                controller: _phoneController,
                labelText: 'Phone Number',
                hintText: '+1684 XXX XXXX XXX',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              CustomDropdown(
                hint: 'Select Country',
                value: _selectedCountry,
                items: const [
                  {'id': 1, 'name': 'United States'},
                  {'id': 2, 'name': 'Canada'},
                  {'id': 3, 'name': 'UK'},
                  {'id': 4, 'name': 'Australia'}
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCountry = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomDropdown(
                      hint: 'Select City',
                      value: _selectedCity,
                      items: const [
                        {'id': 1, 'name': 'New York'},
                        {'id': 2, 'name': 'Toronto'},
                        {'id': 3, 'name': 'London'},
                        {'id': 4, 'name': 'Sydney'}
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCity = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      maxLines: 1,
                      controller: _zipCodeController,
                      labelText: 'Zip Code',
                      hintText: 'Enter Zip Code',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Front Part',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Icon(Icons.cloud_upload_outlined,
                              color: Colors.grey.shade400, size: 32),
                          const SizedBox(height: 4),
                          Text('Drop your file',
                              style: TextStyle(color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Back Part',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Icon(Icons.cloud_upload_outlined,
                              color: Colors.grey.shade400, size: 32),
                          const SizedBox(height: 4),
                          Text('Drop your file',
                              style: TextStyle(color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomTextField(
                maxLines: 1,
                controller: _passwordController,
                labelText: 'Password',
                hintText: 'Enter Password',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                maxLines: 1,
                controller: _confirmPasswordController,
                labelText: 'Confirm Password',
                hintText: 'Enter Confirm Password',
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Row(
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: Colors.red[700]),
                                    const SizedBox(width: 8),
                                    const Text('Error Details'),
                                  ],
                                ),
                                content: Text(_errorMessage!),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[700]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _errorMessage = null),
                        color: Colors.red[700],
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                try {
                                  setState(() {
                                    _isLoading = true;
                                    _errorMessage = null;
                                  });

                                  final contact = Contact(
                                    idContact: widget.contact?.idContact ??
                                        ContactService.generateId(),
                                    firstName: _firstNameController.text,
                                    lastName: _lastNameController.text,
                                    businessName: _businessNameController.text,
                                    email: _emailController.text,
                                    phoneNumber: _phoneController.text,
                                    country: _selectedCountry,
                                    city: _selectedCity,
                                    zipCode: _zipCodeController.text,
                                    frontPartUrl: '',
                                    backPartUrl: '',
                                    createdAt: widget.contact?.createdAt ??
                                        DateTime.now(),
                                  );

                                  // TODO: Implement API call here
                                  // Example:
                                  // final response = await apiService.saveContact(contact);
                                  // if (response.success) {
                                  //   Navigator.pop(context, contact);
                                  // } else {
                                  //   throw Exception(response.message);
                                  // }

                                  // Temporary: just return the contact
                                  await Future.delayed(const Duration(
                                      seconds: 1)); // Simulated API call
                                  Navigator.pop(context, contact);
                                } catch (e) {
                                  setState(() {
                                    _errorMessage = e.toString();
                                  });
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Accept',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
