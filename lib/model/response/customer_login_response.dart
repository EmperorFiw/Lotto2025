import 'package:jwt_decoder/jwt_decoder.dart';

class CustomerLoginPostResponse {
  bool success;
  String message;
  String token;
  Member member;

  CustomerLoginPostResponse({
    required this.success,
    required this.message,
    required this.token,
    required this.member,
  });

  factory CustomerLoginPostResponse.fromJson(Map<String, dynamic> json) {
    final token = json["token"];
    final decodedToken = JwtDecoder.decode(token);
    final member = Member.fromJson(decodedToken);

    return CustomerLoginPostResponse(
      success: json["success"],
      message: json["message"],
      token: token,
      member: member,
    );
  }

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "token": token,
        "member": member.toJson(),
      };
}

class Member {
  String username;
  int money;
  String role;

  Member({
    required this.username,
    required this.money,
    required this.role,
  });

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        username: json["username"],
        money: (json["money"] as num).toInt(), // ป้องกัน double->int
        role: json["role"],
      );

  Map<String, dynamic> toJson() => {
        "username": username,
        "money": money,
        "role": role,
      };
}
