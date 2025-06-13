import 'package:cross_platform_development/groups/models/group.dart';
import 'package:cross_platform_development/groups/models/person.dart';
import 'package:uuid/uuid.dart';

class GroupsCubit {
  GroupsCubit._privateConstructor();
  static final GroupsCubit _instance = GroupsCubit._privateConstructor();
  List<Group> groupsList = [];

  void createGroup(String gName) {
    var uuid = Uuid();
    Group group = Group(
        name: gName,
        id: uuid.v4(),
    );
    group.addMember(
      Person(
        id: uuid.v4(),
        firstName: "PlacHolder harry",
        lastName: "Harries",
      )
    );

    groupsList.add(group);
  }

  List<Group> getGroups() {
    return groupsList;
  }

  static GroupsCubit get instance => _instance;
}