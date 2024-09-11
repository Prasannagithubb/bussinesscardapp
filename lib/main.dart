import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
      theme: ThemeData(
        textTheme: GoogleFonts.nunitoTextTheme(),
        primarySwatch: Colors.teal,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextRecognizer textRecognizer;
  late ImagePicker imagePicker;

  String? pickedImagePath;
  List<String> recognizedWords = [];
  List<String> ignoredFields = [];
  Map<String, String> ignoredFieldsAssignments = {};
  bool isRecognizing = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController designationnameController =
      TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController altMobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController address1Controller = TextEditingController();
  final TextEditingController address2Controller = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    imagePicker = ImagePicker();
  }

  void _pickImageAndProcess({required ImageSource source}) async {
    final pickedImage = await imagePicker.pickImage(source: source);

    if (pickedImage == null) {
      return;
    }

    setState(() {
      pickedImagePath = pickedImage.path;
      isRecognizing = true;
    });

    try {
      final inputImage = InputImage.fromFilePath(pickedImage.path);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      print("words : ${recognizedText}");
      recognizedWords = [];
      print("words : ${recognizedWords}");
      ignoredFields = [];
      ignoredFieldsAssignments = {};
      _clearAllControllers();

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          recognizedWords.add(line.text);
          print("${recognizedWords}");
        }
      }

      _populateTextFields();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error recognizing text: $e'),
        ),
      );
    } finally {
      setState(() {
        isRecognizing = false;
      });
    }
  }

  void _populateTextFields() {
    final phonePattern = RegExp(r'^(\+91[\-\s]?)?[7-9][0-9]{9}$');
    final pincodePattern = RegExp(r'^\d{6}$');
    final emailPattern =
        RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$');

    String name = "";
    String designation = "";
    String companyName = "";
    String mobileNumber = "";
    String altMobileNumber = "";
    String email = "";
    String address1 = "";
    String address2 = "";
    String area = "";
    String city = "";
    String pincode = "";

    for (var line in recognizedWords) {
      if (emailPattern.hasMatch(line) && email.isEmpty) {
        email = line;
      } else if (phonePattern.hasMatch(line) && mobileNumber.isEmpty) {
        mobileNumber = line;
      } else if (phonePattern.hasMatch(line) &&
          mobileNumber.isNotEmpty &&
          altMobileNumber.isEmpty) {
        altMobileNumber = line;
      } else if (pincodePattern.hasMatch(line) && pincode.isEmpty) {
        pincode = line;
      } else if (name.isEmpty) {
        name = line;
      } else if (designation.isEmpty) {
        designation = line; // Added assignment for Designation
      } else if (companyName.isEmpty) {
        companyName = line;
      } else if (address1.isEmpty) {
        address1 = line;
      } else if (address2.isEmpty) {
        address2 = line;
      } else if (area.isEmpty) {
        area = line;
      } else if (city.isEmpty) {
        city = line;
      } else {
        ignoredFields.add(line);
        ignoredFieldsAssignments[line] = 'Select Field';
      }
    }

    nameController.text = name;
    designationnameController.text = designation;
    companyController.text = companyName;
    mobileController.text = mobileNumber;
    altMobileController.text = altMobileNumber;
    emailController.text = email;
    address1Controller.text = address1;
    address2Controller.text = address2;
    areaController.text = area;
    cityController.text = city;
    pincodeController.text = pincode;
  }

  void _clearAllControllers() {
    nameController.clear();
    designationnameController.clear();
    companyController.clear();
    mobileController.clear();
    altMobileController.clear();
    emailController.clear();
    address1Controller.clear();
    address2Controller.clear();
    areaController.clear();
    cityController.clear();
    stateController.clear();
    pincodeController.clear();
  }

  void _chooseImageSourceModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageAndProcess(source: ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a picture'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageAndProcess(source: ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabeledDropdownField(
      String label, TextEditingController controller, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Editable Text Field
              Expanded(
                flex: 3,
                child: TextFormField(
                  cursorColor: Colors.blue,
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Enter or select $label',
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color:
                            Colors.blue, // Set the color for the focused border
                        width: 2.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey, // Default border color
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Dropdown Button for selecting values
              Expanded(
                flex: 2,
                child: DropdownButton<String>(
                  value: options.contains(controller.text)
                      ? controller.text
                      : null, // Pre-select if text matches an option
                  isExpanded: true,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        controller.text = newValue;
                      });
                    }
                  },
                  items: options.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _saveForm() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bussiness Card OCR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // Implement the save functionality here
              _saveForm();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ImagePreview(imagePath: pickedImagePath),
              ),
              ElevatedButton(
                onPressed: isRecognizing ? null : _chooseImageSourceModal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Take a picture',
                      style: TextStyle(color: Colors.blue),
                    ),
                    if (isRecognizing)
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabeledDropdownField(
                        'Name', nameController, recognizedWords),
                    _buildLabeledDropdownField(
                      'Designation',
                      designationnameController,
                      recognizedWords,
                    ),
                    _buildLabeledDropdownField(
                        'Company Name', companyController, recognizedWords),
                    _buildLabeledDropdownField(
                        'Mobile', mobileController, recognizedWords),
                    _buildLabeledDropdownField('Alternate Mobile',
                        altMobileController, recognizedWords),
                    _buildLabeledDropdownField(
                        'Email ID', emailController, recognizedWords),
                    _buildLabeledDropdownField(
                        'Address 1', address1Controller, recognizedWords),
                    _buildLabeledDropdownField(
                        'Address 2', address2Controller, recognizedWords),
                    _buildLabeledDropdownField(
                        'Area', areaController, recognizedWords),
                    _buildLabeledDropdownField(
                        'City', cityController, recognizedWords),
                    _buildLabeledDropdownField(
                        'Pincode', pincodeController, recognizedWords),
                    const SizedBox(height: 16),
                    if (ignoredFields.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Ignored Fields",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          IgnoredFieldsHandler(
                            ignoredFields: ignoredFields,
                            assignments: ignoredFieldsAssignments,
                            onUpdate: (assignments) {
                              setState(() {
                                ignoredFieldsAssignments = assignments;
                                _updateTextFieldsFromAssignments();
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Please verify your address details manually.",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateTextFieldsFromAssignments() {
    final assignmentMap = {
      'Name': nameController,
      'Company Name': companyController,
      'Mobile': mobileController,
      'Alternate Mobile': altMobileController,
      'Email ID': emailController,
      'Address 1': address1Controller,
      'Address 2': address2Controller,
      'Area': areaController,
      'City': cityController,
      'State': stateController,
      'Pincode': pincodeController,
    };

    for (var entry in ignoredFieldsAssignments.entries) {
      final field = entry.key;
      final assignedField = entry.value;

      final controller = assignmentMap[assignedField];
      if (controller != null) {
        controller.text = field;
      }
    }
  }
}

class ImagePreview extends StatelessWidget {
  final String? imagePath;

  const ImagePreview({Key? key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imagePath == null) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(
          child: Text('No image selected'),
        ),
      );
    } else {
      return Image.file(
        File(imagePath!),
        height: 200,
        fit: BoxFit.cover,
      );
    }
  }
}

class IgnoredFieldsHandler extends StatefulWidget {
  final List<String> ignoredFields;
  final Map<String, String> assignments;
  final Function(Map<String, String>) onUpdate;

  const IgnoredFieldsHandler({
    Key? key,
    required this.ignoredFields,
    required this.assignments,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _IgnoredFieldsHandlerState createState() => _IgnoredFieldsHandlerState();
}

class _IgnoredFieldsHandlerState extends State<IgnoredFieldsHandler> {
  final List<String> availableFields = [
    'Name',
    'Company Name',
    'Mobile',
    'Alternate Mobile',
    'Email ID',
    'Address 1',
    'Address 2',
    'Area',
    'City',
    'State',
    'Pincode'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Assign Ignored Fields",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...widget.ignoredFields.map((field) {
          final currentAssignment = widget.assignments[field] ?? 'Select Field';

          return Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: false,
                  controller: TextEditingController(text: field),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() {
                    widget.assignments[field] = value;
                    widget.onUpdate(widget.assignments);
                  });
                },
                itemBuilder: (context) {
                  return availableFields.map((field) {
                    return PopupMenuItem<String>(
                      value: field,
                      child: Text(field),
                    );
                  }).toList();
                },
                child: Row(
                  children: [
                    Text(currentAssignment),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}
