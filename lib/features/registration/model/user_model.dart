class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final int age;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.age,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'age': age,
    };
  }

  static UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      age: map['age'] ?? 0,
    );
  }
}
