import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_model.dart';

class UserState {
  static final UserState _instance = UserState._internal();

  factory UserState() => _instance;

  UserState._internal();

  UserModel? currentUser;

  String? _token;
  String? get token => _token;

  set token(String? newToken) {
    if (newToken == null) {
      _token = null;
      currentUser = null;
    } else if (_token != newToken) {
      _token = newToken;
      _decodeAndSetUser(newToken);
      saveTokenToStorage(newToken);
    }
  }

  // ฟังก์ชัน decode token แล้วสร้าง UserModel
  void _decodeAndSetUser(String jwtToken) {
    Map<String, dynamic> payload = JwtDecoder.decode(jwtToken);
    currentUser = UserModel(
      username: payload['username'] ?? '',
      phone: payload['phone'] ?? '',
      role: payload['role'] ?? '',
      money: double.tryParse(payload['money'].toString()) ?? 0.0,
    );
  }

  // อัพเดทยอดเงิน user
  void updateMoney(double newMoney) {
    if (currentUser != null) {
      currentUser = UserModel(
        username: currentUser!.username,
        phone: currentUser!.phone,
        role: currentUser!.role,
        money: newMoney,
      );
    }
  }

  // ล้างข้อมูล user และ token
  Future<void> clear() async {
    _token = null;
    currentUser = null;
    await clearTokenFromStorage();
  }

  // เซฟ token ลง SharedPreferences
  Future<void> saveTokenToStorage(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  // โหลด token จาก SharedPreferences
  Future<String?> loadTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('jwt_token');
    if (savedToken != null) {
      token = savedToken; // ใช้ setter จะ decode อัตโนมัติ
    }
    return savedToken;
  }

  // ลบ token จาก SharedPreferences
  Future<void> clearTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}
