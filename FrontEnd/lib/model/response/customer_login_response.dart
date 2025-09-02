import 'package:jwt_decoder/jwt_decoder.dart';

class CustomerLoginPostResponse {
  final bool success;
  final String message;
  final String token;
  final Member member;

  CustomerLoginPostResponse({
    required this.success,
    required this.message,
    required this.token,
    required this.member,
  });

  // สร้าง instance จาก JSON response (โดย decode token เพื่อสร้าง Member)
  factory CustomerLoginPostResponse.fromJson(Map<String, dynamic> json) {
    final token = json['token'] as String;

    // decode JWT token payload
    final decodedPayload = JwtDecoder.decode(token);

    // สร้าง Member จาก payload
    final member = Member.fromJson(decodedPayload);

    return CustomerLoginPostResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      token: token,
      member: member,
    );
  }

  // แปลงเป็น JSON (อาจใช้ตอนส่งกลับหรือเก็บข้อมูล)
  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'token': token,
        'member': member.toJson(),
      };
}

class Member {
  final String username;
  final int money;
  final String role;

  Member({
    required this.username,
    required this.money,
    required this.role,
  });

  // สร้าง Member จาก Map JSON (จาก payload JWT)
  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      username: json['username'] as String,
      money: (json['money'] as num).toInt(),
      role: json['role'] as String,
    );
  }

  // แปลง Member เป็น JSON map
  Map<String, dynamic> toJson() => {
        'username': username,
        'money': money,
        'role': role,
      };

  @override
  String toString() {
    return 'Member(username: $username, money: $money, role: $role)';
  }
}
