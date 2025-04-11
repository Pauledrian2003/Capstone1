import 'package:afk/reusable_widget.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:logger/logger.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});
  @override
  AddPropertyScreenState createState() => AddPropertyScreenState();
}

class AddPropertyScreenState extends State<AddPropertyScreen> {
  static final _logger = Logger();
  final _formKey = GlobalKey<FormState>();
  String? _imageBase64;
  String _imageDescription = '';
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _bedsController = TextEditingController();
  final _bathsController = TextEditingController();
  final _sqftController = TextEditingController();
  final _priceController = TextEditingController();
  bool isSaleSelected = true;


  final _monthlyRentController = TextEditingController();
  final _availableFromController = TextEditingController();
  final _phoneController = TextEditingController();
  final _availabilityDateController = TextEditingController();


  String _selectedLeaseTerm = 'Month-to-Month';
  final List<String> _leaseTerms = ['Month-to-Month', '6 Months', '1 Year'];

  
  String _selectedPropertyType = 'House';
  final List<String> _propertyTypes = [
    'House',
    'Apartment',
    'Condo',
    'Townhouse',
    'Land'
  ];

  // Add features map
  final Map<String, bool> _features = {
    'Air Conditioning': false,
    'Garage': false,
    'Parking Space': false,
    'Swimming Pool': false,
    'Garden': false,
    'Furnished': false,
    'Security System': false,
  };

  
  final _yearBuiltController = TextEditingController();
  bool _isNegotiable = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> addProperty(Map<String, dynamic> propertyData) async {
    try {
      // Add approval status to property data
      propertyData['approvalStatus'] = 'pending'; 
      propertyData['reviewedBy'] = null;
      propertyData['reviewedAt'] = null;

      // First, verify the user is logged in
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.e("No user is currently logged in");
        throw Exception("User not authenticated");
      }

   
      propertyData['userId'] = user.uid;

    
      propertyData['createdAt'] = FieldValue.serverTimestamp();

     
      _logger.d("Attempting to add property with userId: ${user.uid}");

      final docRef = await FirebaseFirestore.instance
          .collection('properties')
          .add(propertyData);

      _logger.i("Property added successfully with ID: ${docRef.id}");
    } catch (e) {
      _logger.e("Error adding property: $e");
      rethrow; 
    }
  }

  Future<void> savePropertyWithImage() async {
    try {
      
      final user = FirebaseAuth.instance.currentUser;

     
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      final profileData = userData.data()?['profile'] as Map<String, dynamic>?;

      
      if (_imageBase64 == null || _imageBase64!.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload an image')),
        );
        return;
      }

      if (_imageDescription.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add a description')),
        );
        return;
      }

      

      final propertyData = {
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'imageDescription': _imageDescription.trim(),
        'imageBase64': _imageBase64,
        'isRental': !isSaleSelected,
        'propertyType': _selectedPropertyType,
        'listingStatus': isSaleSelected ? 'For Sale' : 'For Rent',
        'features': _features.entries
            .where((feature) => feature.value)
            .map((feature) => feature.key)
            .toList(),
        'userId': user.uid,
        'userInfo': {
          'name': profileData?['fullName'] ?? user.displayName ?? 'Anonymous',
          'phone': profileData?['phoneNumber'] ?? _phoneController.text.trim(),
          'email': profileData?['email'] ?? user.email,
          'profileImage': profileData?['profileImage'] ?? '',
          'userId': user.uid,
        },
        'timestamp': FieldValue.serverTimestamp(),
        'searchTerms': [
          _nameController.text.toLowerCase(),
          _locationController.text.toLowerCase(),
        ],
        ...isSaleSelected
            ? {
                'beds': int.tryParse(_bedsController.text) ?? 0,
                'baths': int.tryParse(_bathsController.text) ?? 0,
                'size': double.tryParse(_sqftController.text) ?? 0.0,
                'price': double.tryParse(_priceController.text) ?? 0.0,
              }
            : {
                'monthlyRent':
                    double.tryParse(_monthlyRentController.text) ?? 0.0,
                'beds': int.tryParse(_bedsController.text) ?? 0,
                'baths': int.tryParse(_bathsController.text) ?? 0,
                'size': double.tryParse(_sqftController.text) ?? 0.0,
                'availableFrom': _availableFromController.text,
                'leaseTerm': _selectedLeaseTerm,
                'availabilityDate': _availabilityDateController.text,
              },
        'yearBuilt': int.tryParse(_yearBuiltController.text),
        'isNegotiable': _isNegotiable,
      };

     
      _logger.d("Current user ID: ${user.uid}");
      _logger.d("Attempting to save property...");

      
      await addProperty(propertyData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property added successfully!')),
      );

     
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/MainDashboard',
        (route) => false,
      );
    } catch (e) {
      _logger.e("Error in savePropertyWithImage: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding property: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
   
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _logger.w("Warning: No user is logged in");
     
    } else {
      _logger.d("Current user ID: ${user.uid}");
    }
  }

  @override
  void dispose() {
    _yearBuiltController.dispose();
    _availabilityDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Add New Property'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_imageBase64 != null)
                Image.memory(
                  base64Decode(_imageBase64!),
                  height: 200,
                  fit: BoxFit.cover,
                  semanticLabel: _imageDescription,
                ),
              Container(
                  height: 100,
                  width: 100,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.lightBlue),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 60,
                                child: Lottie.asset(
                                  'assets/animations/Upload Animation.json',
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                ),
                              ),
                              const Text('Upload Image'),
                            ],
                          )))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => isSaleSelected = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSaleSelected
                            ? const Color(0xFF2D7AED)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Property for Sale',
                        style: TextStyle(
                          color: isSaleSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => setState(() => isSaleSelected = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: !isSaleSelected
                            ? const Color(0xFF2D7AED)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Property for Rent',
                        style: TextStyle(
                          color: !isSaleSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (isSaleSelected) ...[
               
                if (_imageBase64 != null)
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Tell us about the property',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.lightBlue),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.lightBlue),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _imageDescription = value;
                      });
                    },
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please add a description'
                        : null,
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.lightBlue),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(' Basic Information',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Property Name',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter property name'
                            : null,
                      ),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter address'
                            : null,
                      ),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Asking Price (₱)',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter asking price'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Property Details',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Text('Bedrooms: '),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              final currentValue =
                                  int.tryParse(_bedsController.text) ?? 0;
                              if (currentValue > 0) {
                                setState(() {
                                  _bedsController.text =
                                      (currentValue - 1).toString();
                                });
                              }
                            },
                          ),
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: TextFormField(
                              controller: _bedsController,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              final currentValue =
                                  int.tryParse(_bedsController.text) ?? 0;
                              setState(() {
                                _bedsController.text =
                                    (currentValue + 1).toString();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Bathrooms: '),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              final currentValue = int.tryParse(_bathsController.text) ?? 0;
                              if (currentValue > 0) {
                                setState(() {
                                  _bathsController.text = (currentValue - 1).toString();
                                });
                              }
                            },
                          ),
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: TextFormField(
                              controller: _bathsController,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              final currentValue = int.tryParse(_bathsController.text) ?? 0;
                              setState(() {
                                _bathsController.text = (currentValue + 1).toString();
                              });
                            },
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: _sqftController,
                        decoration: const InputDecoration(
                          labelText: 'Size (sqft)',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter size' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(' Property Type',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButtonFormField<String>(
                        value: _selectedPropertyType,
                        decoration: const InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedPropertyType = newValue ?? 'House';
                          });
                        },
                        items: _propertyTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                      ),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Select Year"),
                                content: SizedBox(
                                 
                                  height: 300,
                                  width: 300,
                                  child: YearPicker(
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                    selectedDate:
                                        _yearBuiltController.text.isEmpty
                                            ? DateTime.now()
                                            : DateTime(int.parse(
                                                _yearBuiltController.text)),
                                    onChanged: (DateTime dateTime) {
                                      setState(() {
                                        _yearBuiltController.text =
                                            dateTime.year.toString();
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Year Built',
                            hintText: 'Select year of construction/renovation',
                            labelStyle: TextStyle(color: Colors.grey),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.lightBlue),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.lightBlue),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_yearBuiltController.text.isEmpty
                                  ? 'Select Year'
                                  : _yearBuiltController.text),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Negotiable: ',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              )),
                          Switch(
                            value: _isNegotiable,
                            onChanged: (bool value) {
                              setState(() {
                                _isNegotiable = value;
                              });
                            },
                            activeColor: Colors.lightBlue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Amenities and Features',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _features.keys.map((feature) {
                          return FilterChip(
                            label: Text(feature),
                            selected: _features[feature]!,
                            onSelected: (bool selected) {
                              setState(() {
                                _features[feature] = selected;
                              });
                            },
                            selectedColor: Colors.lightBlue[100],
                            checkmarkColor: Colors.blue,
                            labelStyle: TextStyle(
                              color: _features[feature]!
                                  ? Colors.blue
                                  : Colors.black,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Rent form fields
                if (_imageBase64 != null)
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Tell us about the property',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _imageDescription = value;
                      });
                    },
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please add a description'
                        : null,
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.lightBlue),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Basic Information',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Property Name',
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter property name'
                            : null,
                      ),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter address'
                            : null,
                      ),
                      TextFormField(
                        controller: _monthlyRentController,
                        decoration: const InputDecoration(
                          labelText: 'Monthly Rent (₱)',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter monthly rent'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Property Details',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Text('Bedrooms: '),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              final currentValue =
                                  int.tryParse(_bedsController.text) ?? 0;
                              if (currentValue > 0) {
                                setState(() {
                                  _bedsController.text =
                                      (currentValue - 1).toString();
                                });
                              }
                            },
                          ),
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: TextFormField(
                              controller: _bedsController,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              final currentValue =
                                  int.tryParse(_bedsController.text) ?? 0;
                              setState(() {
                                _bedsController.text =
                                    (currentValue + 1).toString();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Bathrooms: '),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              final currentValue = int.tryParse(_bathsController.text) ?? 0;
                              if (currentValue > 0) {
                                setState(() {
                                  _bathsController.text = (currentValue - 1).toString();
                                });
                              }
                            },
                          ),
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: TextFormField(
                              controller: _bathsController,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              final currentValue = int.tryParse(_bathsController.text) ?? 0;
                              setState(() {
                                _bathsController.text = (currentValue + 1).toString();
                              });
                            },
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: _sqftController,
                        decoration: const InputDecoration(
                          labelText: 'Size (sqft)',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter size' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Lease Term'),
                      DropdownButtonFormField<String>(
                        value: _selectedLeaseTerm,
                        decoration: const InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                        ),
                        items: _leaseTerms.map((term) {
                          return DropdownMenuItem(
                            value: term,
                            child: Text(term),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLeaseTerm = value!;
                          });
                        },
                      ),
                      TextFormField(
                        controller: _availabilityDateController,
                        decoration: const InputDecoration(
                          labelText: 'Available Date for Occupancy',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.lightBlue),
                          ),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() {
                              _availabilityDateController.text =
                                  "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                            });
                          }
                        },
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please select availability date'
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: myButton2(
                  context,
                  'Save Property',
                  () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      if (_imageBase64 == null || _imageBase64!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please upload an image')),
                        );
                        return;
                      }

                      if (_imageDescription.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please add a description')),
                        );
                        return;
                      }
                      await savePropertyWithImage();
                    }
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
