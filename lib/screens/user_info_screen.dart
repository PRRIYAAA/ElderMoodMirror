import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  bool hasBP = false, hasDiabetes = false, hasHeart = false, hasAsthma = false;
  bool showOtherConditionField = false;
  bool showOtherDisabilityField = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nameController.text = prefs.getString('user_name') ?? '';
      mobileController.text = prefs.getString('user_mobile_id') ?? '';
      guardianEmailController.text = prefs.getString('guardian_email') ?? '';
      clinicEmailController.text = prefs.getString('clinic_email') ?? '';
      age = prefs.getString('user_age');
      bgroup = prefs.getString('user_bgroup');
      gender = prefs.getString('user_gender');
      disability = prefs.getString('user_disability');
      tabletName = prefs.getString('tablet_name');
      tabletFrequency = prefs.getString('tablet_frequency');
      otherDisabilityController.text = prefs.getString('disability_other') ?? '';
      showOtherDisabilityField = disability == 'Other';
      showOtherConditionField = disability == 'None';

      final medical = prefs.getString('user_medical') ?? '';
      hasBP = medical.contains("BP");
      hasDiabetes = medical.contains("Diabetes");
      hasHeart = medical.contains("Heart");
      hasAsthma = medical.contains("Asthma");

      final others = medical.split(', ').where((x) =>
      !["BP", "Diabetes", "Heart", "Asthma"].contains(x)).join(', ');
      otherMedicalController.text = others;
    });
  }

  Future<void> _saveUserInfo() async {
    if ([nameController.text, mobileController.text, guardianEmailController.text, age, bgroup, gender, disability]
        .any((e) => e == null || e.toString().trim().isEmpty)) {
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
      if (showOtherConditionField && otherMedicalController.text.trim().isNotEmpty)
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
    await prefs.setBool('isFirstTime', false);

    if (widget.isEditing) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => StartScreen(nextScreen: const SurveyScreen())),
            (route) => false,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SurveyScreen()),
      );
    }
  }

  Widget _buildDropdown(String label, String? value, List<String> items, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    showOtherConditionField = (disability ?? '') == 'None';
    showOtherDisabilityField = (disability ?? '') == 'Other';

    return Scaffold(
      appBar: AppBar(title: const Text("Elder Info")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          _buildDropdown("Age", age, List.generate(41, (i) => (60 + i).toString()), (v) => setState(() => age = v)),
          _buildDropdown("Blood Group", bgroup, ['A+', 'B+', 'AB+', 'O+', 'A-', 'B-', 'AB-', 'O-'], (v) => setState(() => bgroup = v)),
          _buildDropdown("Gender", gender, ['Male', 'Female', 'Other'], (v) => setState(() => gender = v)),
          _buildDropdown("Disability", disability, ['None', 'Visual', 'Hearing', 'Mobility', 'Cognitive', 'Bedridden', 'Other'], (v) {
            setState(() {
              disability = v;
              showOtherConditionField = v == 'None';
              showOtherDisabilityField = v == 'Other';
            });
          }),
          if (showOtherDisabilityField)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: TextField(
                controller: otherDisabilityController,
                decoration: const InputDecoration(labelText: "Specify Other Disability", border: OutlineInputBorder()),
              ),
            ),
          if (showOtherConditionField)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: TextField(
                controller: otherMedicalController,
                decoration: const InputDecoration(labelText: "Other Conditions", border: OutlineInputBorder()),
              ),
            ),
          _buildDropdown("Tablet Name", tabletName, ['None', 'Aspirin', 'Paracetamol', 'BP Med', 'Sugar Control'], (v) => setState(() => tabletName = v)),
          _buildDropdown("Tablet Frequency", tabletFrequency, ['Once a day', 'Twice a day', 'Thrice a day'], (v) => setState(() => tabletFrequency = v)),
          TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
          TextField(controller: mobileController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Mobile")),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Medical Conditions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          CheckboxListTile(title: const Text("BP"), value: hasBP, onChanged: (v) => setState(() => hasBP = v!)),
          CheckboxListTile(title: const Text("Diabetes"), value: hasDiabetes, onChanged: (v) => setState(() => hasDiabetes = v!)),
          CheckboxListTile(title: const Text("Heart"), value: hasHeart, onChanged: (v) => setState(() => hasHeart = v!)),
          CheckboxListTile(title: const Text("Asthma"), value: hasAsthma, onChanged: (v) => setState(() => hasAsthma = v!)),
          TextField(controller: guardianEmailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: "Guardian Email ID (Required)")),
          TextField(controller: clinicEmailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: "Clinic Email ID (Optional)")),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text("Save"),
            onPressed: _saveUserInfo,
          )
        ]),
      ),
    );
  }
}