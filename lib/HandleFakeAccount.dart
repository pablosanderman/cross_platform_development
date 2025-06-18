import 'package:cross_platform_development/groups/groups.dart';
import 'package:uuid/uuid.dart';


class FakeAccount {
  FakeAccount._();

  static FakeAccount? _instance;
  static User? loggedInUser;
  // static List<User> people = [
  //   _createDefaultUser("Henk", "Henkies"),
  //   _createDefaultUser("Elise", "Morrinson"),
  //   _createDefaultUser("Peter", "Pan"),
  // ];

  static User _createDefaultUser(String firstName, String lastName) {
    const uuid = Uuid();
    return User(
      id: uuid.v4(),
      firstName: firstName,
      lastName: lastName,
    );
  }

  factory FakeAccount() {
    _instance ??= FakeAccount._();
    return _instance!;
  }
}