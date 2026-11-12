class LoginResponse {
  final String accessToken;
  final String accountStatus;
  final String message;
  final String phoneNumber;
  final String state;
  final String userId;
  final String username;
  final int userRole;

  LoginResponse({
    required this.accessToken,
    required this.accountStatus,
    required this.message,
    required this.phoneNumber,
    required this.state,
    required this.userId,
    required this.username,
    required this.userRole,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] ?? '',
      accountStatus: json['accountstatus'] ?? '',
      message: json['message'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      state: json['state'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userRole: json['userrole'] ?? 0,
    );
  }

  Null get isSuccess => null;

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'accountstatus': accountStatus,
      'message': message,
      'phone_number': phoneNumber,
      'state': state,
      'userId': userId,
      'username': username,
      'userrole': userRole,
    };
  }
}

/*
class LoginResponse {
  final String status;
  final String message;
  final DriverResult? result;
  final String? authCode;

  LoginResponse({
    required this.status,
    required this.message,
    this.result,
    this.authCode,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['Status'],
      message: json['Message'],
      result: json['Result'] != null
          ? DriverResult.fromJson(json['Result'])
          : null,
      authCode: json['AuthCode'],
    );
  }
}

class DriverResult {
  final String driverId;
  final String firstName;
  final String email;
  final String phone;
  final bool isOnline;
  final String? profileImageURL;

  DriverResult({
    required this.driverId,
    required this.firstName,
    required this.email,
    required this.phone,
    required this.isOnline,
    this.profileImageURL,
  });

  factory DriverResult.fromJson(Map<String, dynamic> json) {
    return DriverResult(
      driverId: json['DriverId'],
      firstName: json['FirstName'],
      email: json['Email'],
      phone: json['Phone'],
      isOnline: json['IsOnline'],
      profileImageURL: json['ProfileImageURL'],
    );
  }
}*/