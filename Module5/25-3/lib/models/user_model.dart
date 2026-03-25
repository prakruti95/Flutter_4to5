class UserModel {
  int id;
  String name;
  String email;
  String password;
  int isSynced;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.isSynced = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: int.parse(json['id'].toString()),
    name: json['name'],
    email: json['email'],
    password: json['password'],
    isSynced: int.parse(json['isSynced']?.toString() ?? '1'),
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'isSynced': isSynced,
    };
  }
}
