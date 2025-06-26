import 'package:shared_preferences/shared_preferences.dart';

class UserPrefs {
  static Future<void> saveUserInfo({
    required String name,
    required String age,
    required String bloodGroup,
    required String gender,
    required String medicalConditions,
    required String disability,
    required String mobileId,
    required String guardianEmail,
    required String tabletName,
    required String tabletFrequency,
    String disabilityOther = '',
    String clinicEmail = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_age', age);
    await prefs.setString('user_bgroup', bloodGroup);
    await prefs.setString('user_gender', gender);
    await prefs.setString('user_medical', medicalConditions);
    await prefs.setString('user_disability', disability);
    await prefs.setString('user_mobile_id', mobileId);
    await prefs.setString('guardian_email', guardianEmail);
    await prefs.setString('tablet_name', tabletName);
    await prefs.setString('tablet_frequency', tabletFrequency);
    await prefs.setString('disability_other', disabilityOther);
    await prefs.setString('clinic_email', clinicEmail);
    await prefs.setBool('isRegistered', true);
  }
}