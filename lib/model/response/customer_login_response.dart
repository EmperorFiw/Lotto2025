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

  factory CustomerLoginPostResponse.fromJson(Map<String, dynamic> json) =>
      CustomerLoginPostResponse(
        success: json["success"],
        message: json["message"],
        token: json["token"],
        member: Member.fromJson(json["member"]),
      );

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
        money: json["money"],
        role: json["role"],
      );

  Map<String, dynamic> toJson() => {
        "username": username,
        "money": money,
        "role": role,
      };
}
