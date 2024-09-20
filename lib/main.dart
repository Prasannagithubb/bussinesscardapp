import 'dart:developer';
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
  List<String> scannedFields = [];

  Map<String, String> ignoredFieldsAssignments = {};
  Map<String, String> scannedvalues = {};
  bool isRecognizing = false;
  String? ignoredFieldValue;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController designationnameController =
      TextEditingController();
  final TextEditingController designationController = TextEditingController();
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

  final Map<String, TextEditingController> fieldControllers = {
    'Name': TextEditingController(),
    'Designation': TextEditingController(),
    'Company Name': TextEditingController(),
    'Mobile': TextEditingController(),
    'Alternate Mobile': TextEditingController(),
    'Email ID': TextEditingController(),
    'Address 1': TextEditingController(),
    'Address 2': TextEditingController(),
    'Area': TextEditingController(),
    'City': TextEditingController(),
    'State': TextEditingController(),
    'Pincode': TextEditingController(),
  };

  final List<String> availableFields = [
    'Name',
    'Designation',
    'Company Name',
    'Mobile',
    'Alternate Mobile',
    'Email ID',
    'Address 1',
    'Address 2',
    'Area',
    'City',
    'State',
    'Pincode',
  ];

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
      recognizedWords = [];
      ignoredFields = [];
      scannedFields = [];
      ignoredFieldsAssignments = {};
      _clearAllControllers();

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          recognizedWords.add(line.text);
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
    final phonePattern = RegExp(r'(\+91[\-\s]?)?[7-9][0-9]{9}');
    final pincodePattern = RegExp(r'[1-9][0-9]{5}');
    final emailPattern =
        RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    final addressPattern =
        RegExp(r'[\d\w\s,.]+'); // Generic pattern for address

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

    ignoredFields.clear();
    scannedFields.clear();

    ignoredFieldsAssignments.clear();

    for (var line in recognizedWords) {
      if (phonePattern.hasMatch(line) && mobileNumber.isEmpty) {
        mobileNumber = line;
      } else if (phonePattern.hasMatch(line) &&
          mobileNumber.isNotEmpty &&
          altMobileNumber.isEmpty) {
        altMobileNumber = line;
      } else if (emailPattern.hasMatch(line) && email.isEmpty) {
        email = line;
      } else if (pincodePattern.hasMatch(line) && pincode.isEmpty) {
        pincode = line;
      } else if (line.contains('Designation Keyword') && designation.isEmpty) {
        designation = line;
      } else if (line.contains('Company Keyword') && companyName.isEmpty) {
        companyName = line;
      } else if (name.isEmpty &&
          !line.contains('Designation Keyword') &&
          !line.contains('Company Keyword')) {
        name = line;
      } else if (addressPattern.hasMatch(line) && address1.isEmpty) {
        address1 = line;
      } else if (addressPattern.hasMatch(line) && address2.isEmpty) {
        address2 = line;
      } else if (addressPattern.hasMatch(line) && area.isEmpty) {
        area = line;
      } else if (addressPattern.hasMatch(line) && city.isEmpty) {
        city = line;
      } else {
        ignoredFields.add(line);
        ignoredFieldsAssignments[line] = 'Select Field';
      }
    }

    nameController.text = name;
    designationController.text = designation;
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

  void _onDropdownSelected(String selectedField) {
    setState(() {
      if (ignoredFieldValue != null) {
        fieldControllers[selectedField]?.text = ignoredFieldValue!;
      }
    });
  }

  void _clearAllControllers() {
    nameController.clear();
    designationController.clear();
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

  fetchingdata() {}
  List<TextEditingController> mycontroller =
      List.generate(50, (index) => TextEditingController());
  Widget _buildLabeledDropdownField(
      String label, TextEditingController controller) {
    final Map<String, TextEditingController> controllersMap = {
      'Name': nameController,
      'Designation': designationController,
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
              // The TextFormField to display the selected value
              Container(
                // color: Colors.blue,
                width: 250,
                child: TextFormField(
                  cursorColor: Colors.blue,
                  controller:
                      controller, // This will reflect the selected value
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'Select $label',
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blue,
                        width: 2.0,
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blue,
                        width: 2.0,
                      ),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // The dropdown button

              Assignedvalue(
                availableFields: availableFields,
                selectedField222: label,
                controllersMap: controllersMap,
                onFieldSelected: (selectedField, assignedValue) {
                  // Do something when a field is selected
                },
              ),

              // IgnoredFieldsHandler(
              //             ignoredFields: ignoredFields,
              //             assignments: ignoredFieldsAssignments,
              //             onUpdate: (assignments) {
              //               setState(() {
              //                 ignoredFieldsAssignments = assignments;
              //                 _updateTextFieldsFromAssignments();
              //               });
              //             },
              //           ),
              // Expanded(
              //   flex: 2,
              //   child: PopupMenuButton<String>(
              //     onSelected: (String selectedField) {
              //       setState(() {
              //         // Update the controller's value to reflect the selected item
              //         controller.text = selectedField;
              //         // Also update ignoredFieldValue if needed for other state management
              //         // ignoredFieldValue = selectedField;
              //         // _onDropdownSelected(
              //         //     selectedField); // Any additional logic
              //       });
              //     },
              //     itemBuilder: (BuildContext context) {
              //       // Building the list of options in the dropdown
              //       return fieldControllers.entries.map<PopupMenuItem<String>>(
              //           (MapEntry<String, TextEditingController> entry) {
              //         return PopupMenuItem<String>(
              //           value: entry.key, // field name as the value
              //           child: Text(
              //             entry.key, // Display field name in the dropdown
              //             style: const TextStyle(fontSize: 14),
              //           ),
              //         );
              //       }).toList();
              //     },
              //     child: Row(
              //       children: [
              //         Text(
              //           // Display the selected value or the default hint
              //           // controller.text.isNotEmpty
              //           //     ? controller.text
              //           //     :
              //           "Select Field",
              //           style: const TextStyle(fontSize: 14),
              //         ),
              //         const Icon(Icons.arrow_drop_down),
              //       ],
              //     ),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  _saveForm() {
    // Implement the save functionality here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Card OCR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
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
                    _buildLabeledDropdownField('Name', nameController),
                    _buildLabeledDropdownField(
                        'Designation', designationController),
                    _buildLabeledDropdownField(
                        'Company Name', companyController),
                    _buildLabeledDropdownField('Mobile', mobileController),
                    _buildLabeledDropdownField(
                        'Alternate Mobile', altMobileController),
                    _buildLabeledDropdownField('Email ID', emailController),
                    _buildLabeledDropdownField('Address 1', address1Controller),
                    _buildLabeledDropdownField('Address 2', address2Controller),
                    _buildLabeledDropdownField('Area', areaController),
                    _buildLabeledDropdownField('City', cityController),
                    _buildLabeledDropdownField('Pincode', pincodeController),
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

  updatevaluefromscanned() {}

  void updateTextFieldFromScannedValues() {
    // Map field names to their corresponding controllers
    final assignMap = {
      'Name': nameController,
      'Designation': designationController, // Added this missing field
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

    for (var incomingvalue in scannedvalues.entries) {
      final buildfield = incomingvalue.key;
      final assignedvalues = incomingvalue.value;
      final buildcontroller = assignMap[buildfield];
      if (buildcontroller != null) {
        buildcontroller.text = assignedvalues;
      }
    }
  }

  void _updateTextFieldsFromAssignments() {
    final assignmentMap = {
      'Name': nameController,
      'Designation': designationController,
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

class Assignedvalue extends StatefulWidget {
  final List<String> availableFields;
  String? selectedField222;
  //  log('Field: $selectedField, Assigned Value: $assignedValue');
  // List of dropdown fields
  final Map<String, TextEditingController>
      controllersMap; // Map of field names to controllers
  final Function(String selectedField, String assignedValue) onFieldSelected;

  Assignedvalue({
    Key? key,
    required this.availableFields,
    required this.selectedField222,
    required this.controllersMap,
    required this.onFieldSelected,
  }) : super(key: key);

  @override
  _AssignedvalueState createState() => _AssignedvalueState();
}

class _AssignedvalueState extends State<Assignedvalue> {
  String? selectedField;

  @override
  Widget build(BuildContext context) {
    //  PopupMenuItem<String>(
    //                   value: field,
    //                   child: Text(field),
    //                 );
    //               }).toList();
    //             },
    //             child: Row(
    //               children: [
    //                 Text(currentAssignment),
    //                 const Icon(Icons.arrow_drop_down),

    return Row(
      children: [
        Container(
          // color: Colors.green,
          // width: 100,
          // height: 10,
          child: DropdownButton<String>(
            hint: const Text('Select'),
            value: selectedField,
            items: widget.availableFields.map((field) {
              return DropdownMenuItem<String>(
                value: field,
                child: Text(
                  field,
                  style: TextStyle(fontSize: 10, color: Colors.black),
                ),
              );
            }).toList(),
            onChanged: (newField) {
              setState(() {
                selectedField = newField;
                // log("message" + controllercontroller.toString());
                // Assign value to the corresponding controller
                if (newField != null &&
                    widget.controllersMap[newField] != null) {
                  final controller = widget.controllersMap[newField]!;
                  log(controller.text.toString());
                  controller.text =
                      widget.controllersMap[widget.selectedField222!]!.text;
                  // Update the controller's text with the selected field name or any value you need
                  // controller.text =
                  //     'Assigned Value'; // Replace with desired value if needed

                  // Notify the parent widget if necessary
                  widget.onFieldSelected(newField, controller.text);
                }
              });
            },
          ),
        ),
        // const Icon(Icons.arrow_drop_down),
      ],
    );
  }
}

class ScannedFieldHandler extends StatefulWidget {
  final List<String> scannedvalues;
  final Map<String, String> valueassignments;
  final Function(Map<String, String>) onUptodate;

  ScannedFieldHandler({
    Key? key,
    required this.onUptodate,
    required this.scannedvalues,
    required this.valueassignments,
  });

  @override
  _ScannedFieldHandlerState createState() => _ScannedFieldHandlerState();
}

class _ScannedFieldHandlerState extends State<ScannedFieldHandler> {
  final List<String> buildavailableFields = [
    'Name',
    'Designation',
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
        // ...widget.scannedvalues.map((field) {
        // return
        PopupMenuButton<String>(
          onSelected: (value) {
            setState(() {
              // widget.valueassignments[field] = value;
              widget.onUptodate(widget.valueassignments);
            });
          },
          itemBuilder: (context) {
            return buildavailableFields.map((availableField) {
              return PopupMenuItem<String>(
                value: availableField,
                child: Text(availableField),
              );
            }).toList();
          },
          child: Container(
            color: Colors.yellow,
            child: Row(
              children: [
                Text("Select field"),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        // }).toList(),

        // const Text(
        //   "Select field",
        //   style: TextStyle(fontWeight: FontWeight.bold),
        // ),
        // const SizedBox(height: 16),

        // Correctly map over scanned values here
        // ...widget.scannedvalues.map((field) {
        //   final currentAssignments =
        //       widget.valueassignments[field] ?? 'Select Field';

        //   return Padding(
        //     padding: const EdgeInsets.symmetric(
        //         vertical: 8.0), // Add spacing between fields
        //     child: Row(
        //       children: [
        //         // TextField(
        //         //   readOnly: true,
        //         //   controller: TextEditingController(text: field),
        //         //   decoration: InputDecoration(
        //         //     border: OutlineInputBorder(),
        //         //   ),
        //         // ),
        //         const SizedBox(width: 16),
        //         PopupMenuButton<String>(
        //           onSelected: (value) {
        //             setState(() {
        //               widget.valueassignments[field] = value;
        //               widget.onUptodate(widget.valueassignments);
        //             });
        //           },
        //           itemBuilder: (context) {
        //             return buildavailableFields.map((availableField) {
        //               return PopupMenuItem<String>(
        //                 value: availableField,
        //                 child: Text(availableField),
        //               );
        //             }).toList();
        //           },
        //           child: Row(
        //             children: [
        //               Text(currentAssignments),
        //               const Icon(Icons.arrow_drop_down),
        //             ],
        //           ),
        //         ),
        //       ],
        //     ),
        //   );
        // }).toList(),
      ],
    );
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
    'Designation',
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
          final currentAssignment = 'Select Field';
          return Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: true,
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
