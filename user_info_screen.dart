import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // Required package
import 'survey_screen.dart';
import 'start_screen.dart';

class UserInfoScreen extends StatefulWidget {
  final bool isEditing;
  const UserInfoScreen({Key? key, this.isEditing = false}) : super(key: key);

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final guardianEmailController = TextEditingController();
  final clinicEmailController = TextEditingController();
  final otherMedicalController = TextEditingController();
  final otherDisabilityController = TextEditingController();

  String? age, bgroup, gender, disability, tabletName, tabletFrequency;

  // New state for profile picture
  String? _profilePicPath;

  bool hasBP = false, hasDiabetes = false, hasHeart = false, hasAsthma = false;
  bool showOtherConditionField = false;
  bool showOtherDisabilityField = false;

  // Define required fields for simplified validation check
  final requiredFields = ['name', 'mobile', 'guardianEmail', 'age', 'bgroup', 'gender', 'disability'];


  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadUserInfo();
    else _setInitialState();
  }

  void _setInitialState() {
    // Set default placeholder for dropdowns
    age = '60';
    bgroup = 'O+';
    gender = 'Male';
    disability = 'None';
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nameController.text = prefs.getString('user_name') ?? '';
      mobileController.text = prefs.getString('user_mobile_id') ?? '';
      guardianEmailController.text = prefs.getString('guardian_email') ?? '';
      clinicEmailController.text = prefs.getString('clinic_email') ?? '';

      _profilePicPath = prefs.getString('user_profile_pic'); // Load profile pic path

      age = prefs.getString('user_age');
      bgroup = prefs.getString('user_bgroup');
      gender = prefs.getString('user_gender');
      disability = prefs.getString('user_disability');
      tabletName = prefs.getString('tablet_name');
      tabletFrequency = prefs.getString('tablet_frequency');
      otherDisabilityController.text = prefs.getString('disability_other') ?? '';

      showOtherDisabilityField = disability == 'Other';

      final medical = prefs.getString('user_medical') ?? '';
      hasBP = medical.contains("BP");
      hasDiabetes = medical.contains("Diabetes");
      hasHeart = medical.contains("Heart");
      hasAsthma = medical.contains("Asthma");

      final others = medical.split(', ').where((x) =>
      !["BP", "Diabetes", "Heart", "Asthma"].contains(x)).join(', ');
      otherMedicalController.text = others;
      // Show 'Other Conditions' field if 'None' is selected AND there are previously saved 'Other' conditions
      showOtherConditionField = (disability == 'None' || disability == null) && otherMedicalController.text.isNotEmpty;
    });
  }

  Future<void> _pickProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    // Using image source gallery
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image != null) {
      setState(() {
        _profilePicPath = image.path;
      });
    }
  }

  Future<void> _saveUserInfo() async {
    // Basic validation check
    final requiredValues = [nameController.text, mobileController.text, guardianEmailController.text, age, bgroup, gender, disability];
    if (requiredValues.any((e) => e == null || e.toString().trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    if (disability == "Other" && otherDisabilityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please specify the 'Other' disability")),
      );
      return;
    }

    String medical = [
      if (hasBP) "BP",
      if (hasDiabetes) "Diabetes",
      if (hasHeart) "Heart",
      if (hasAsthma) "Asthma",
      if (otherMedicalController.text.trim().isNotEmpty)
        otherMedicalController.text.trim(),
    ].join(', ');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', nameController.text.trim());
    await prefs.setString('user_age', age!);
    await prefs.setString('user_bgroup', bgroup!);
    await prefs.setString('user_gender', gender!);
    await prefs.setString('user_disability', disability!);
    await prefs.setString('disability_other', otherDisabilityController.text.trim());
    await prefs.setString('user_medical', medical);
    await prefs.setString('user_mobile_id', mobileController.text.trim());
    await prefs.setString('tablet_name', tabletName ?? '');
    await prefs.setString('tablet_frequency', tabletFrequency ?? '');
    await prefs.setString('guardian_email', guardianEmailController.text.trim());
    await prefs.setString('clinic_email', clinicEmailController.text.trim());
    await prefs.setString('user_profile_pic', _profilePicPath ?? ''); // Save profile pic path
    await prefs.setBool('isFirstTime', false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User information saved successfully!")),
    );

    if (widget.isEditing) {
      // Navigate back to the StartScreen (which will rebuild and show the new profile)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const StartScreen(nextScreen: SurveyScreen())),
            (route) => false,
      );
    } else {
      // First time setup, navigate to survey
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SurveyScreen()),
      );
    }
  }

  // Helper for consistent TextFields
  Widget _buildTextField(TextEditingController controller, String label, {TextInputType type = TextInputType.text, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: required ? "$label *" : label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // Helper for consistent Dropdowns
  Widget _buildDropdown(String label, String? value, List<String> items, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "$label *",
          border: const OutlineInputBorder(),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            hint: Text("Select $label"),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  // Helper for section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    showOtherDisabilityField = (disability ?? 'None') == 'Other';
    // Only show the "Other Conditions" field if disability is 'None'
    showOtherConditionField = (disability ?? 'None') == 'None';

    // Logic to determine the displayed ImageProvider
    final ImageProvider? imageProvider = _profilePicPath != null && _profilePicPath!.isNotEmpty
        ? FileImage(File(_profilePicPath!))
        : const AssetImage('assets/images/default_avatar.png'); // Default Asset Image

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.isEditing ? "Update Elder Profile" : "Elder Profile Setup"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- PROFILE PICTURE SECTION ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              margin: const EdgeInsets.only(bottom: 25),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Profile Image Display
                    GestureDetector(
                      onTap: _pickProfilePicture,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.teal.shade100,
                        backgroundImage: imageProvider, // Use the determined image provider
                        child: (_profilePicPath == null || _profilePicPath!.isEmpty) && imageProvider == null
                            ? Icon(Icons.person, size: 50, color: Colors.teal) // Fallback to Icon if asset not found
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _pickProfilePicture,
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: Text((_profilePicPath != null && _profilePicPath!.isNotEmpty) ? "Change Photo" : "Add Profile Photo"),
                      style: TextButton.styleFrom(foregroundColor: Colors.teal),
                    ),
                  ],
                ),
              ),
            ),

            // --- USER & CONTACT INFO ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSectionHeader("Personal & Contact Information"),
                    _buildTextField(nameController, "Name", required: true),
                    _buildTextField(mobileController, "Mobile ID", type: TextInputType.phone, required: true),
                    _buildTextField(guardianEmailController, "Guardian Email ID", type: TextInputType.emailAddress, required: true),
                    _buildTextField(clinicEmailController, "Clinic Email ID (Optional)", type: TextInputType.emailAddress, required: false),
                  ],
                ),
              ),
            ),

            // --- HEALTH & DISABILITY INFO ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSectionHeader("Health & Physical Status"),

                    _buildDropdown("Age", age, List.generate(41, (i) => (60 + i).toString()), (v) => setState(() => age = v)),
                    _buildDropdown("Blood Group", bgroup, ['A+', 'B+', 'AB+', 'O+', 'A-', 'B-', 'AB-', 'O-'], (v) => setState(() => bgroup = v)),
                    _buildDropdown("Gender", gender, ['Male', 'Female', 'Other'], (v) => setState(() => gender = v)),

                    _buildDropdown("Disability", disability, ['None', 'Visual', 'Hearing', 'Mobility', 'Cognitive', 'Bedridden', 'Other'], (v) {
                      setState(() {
                        disability = v;
                        showOtherDisabilityField = v == 'Other';
                        showOtherConditionField = v == 'None';
                      });
                    }),

                    if (showOtherDisabilityField)
                      _buildTextField(otherDisabilityController, "Specify Other Disability", required: true),

                    // Medical Conditions Checkboxes
                    _buildSectionHeader("Chronic Conditions"),

                    CheckboxListTile(title: const Text("BP (Blood Pressure)"), activeColor: Colors.teal, value: hasBP, onChanged: (v) => setState(() => hasBP = v!)),
                    CheckboxListTile(title: const Text("Diabetes"), activeColor: Colors.teal, value: hasDiabetes, onChanged: (v) => setState(() => hasDiabetes = v!)),
                    CheckboxListTile(title: const Text("Heart Condition"), activeColor: Colors.teal, value: hasHeart, onChanged: (v) => setState(() => hasHeart = v!)),
                    CheckboxListTile(title: const Text("Asthma"), activeColor: Colors.teal, value: hasAsthma, onChanged: (v) => setState(() => hasAsthma = v!)),

                    if (showOtherConditionField) // Only appears if Disability is 'None'
                      _buildTextField(otherMedicalController, "Other Medical Conditions (e.g., Arthritis)", required: false),
                  ],
                ),
              ),
            ),

            // --- MEDICATION INFO ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSectionHeader("Medication Schedule"),
                    _buildDropdown("Primary Tablet Name", tabletName, ['None', 'Aspirin', 'Paracetamol', 'BP Med', 'Sugar Control', 'Other'], (v) => setState(() => tabletName = v)),
                    _buildDropdown("Tablet Frequency", tabletFrequency, ['Once a day', 'Twice a day', 'Thrice a day', 'As needed'], (v) => setState(() => tabletFrequency = v)),
                  ],
                ),
              ),
            ),

            // --- SAVE BUTTON ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: Text(widget.isEditing ? "Update Profile" : "Complete Setup", style: TextStyle(fontSize: 18, color: Colors.white)),
                onPressed: _saveUserInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}