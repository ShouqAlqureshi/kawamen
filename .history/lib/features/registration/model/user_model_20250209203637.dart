class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final int age;
  final Map<String, dynamic> dashboard;
  final List<Map<String, dynamic>> emotionalData;
  final List<Map<String, dynamic>> userTreatments;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.age,
    required this.dashboard,
    required this.emotionalData,
    required this.userTreatments,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'age': age,
      'dashboard': dashboard,
      'emotionalData': emotionalData,
      'userTreatments': userTreatments,
    };
  }

  static UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      age: map['age'] ?? 0,
      dashboard: Map<String, dynamic>.from(map['dashboard'] ?? {}),
      emotionalData:
          List<Map<String, dynamic>>.from(map['emotionalData'] ?? []),
      userTreatments:
          List<Map<String, dynamic>>.from(map['userTreatments'] ?? []),
    );
  }
}
