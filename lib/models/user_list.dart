import 'user.dart';

class UserList {
  final List<User> users;

  UserList({required this.users});

  factory UserList.fromJson(List<dynamic> json) {
    return UserList(
      users: json.map((e) => User.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'users': users.map((e) => e.toJson()).toList(),
    };
  }
}
