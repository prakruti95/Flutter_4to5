class UserModel {
  int id;
  String name;
  String surname;
  String email;
  String password;
  int isSynced;

  UserModel({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    required this.password,
    this.isSynced = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: int.parse(json['id'].toString()),
    name: json['name'],
    surname: json['surname'],
    email: json['email'],
    password: json['password'],
    isSynced: int.parse(json['isSynced']?.toString() ?? '1'),
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'email': email,
      'password': password,
      'isSynced': isSynced,
    };
  }
}
