import 'package:cross_platform_development/groups/models/person.dart';
import 'package:equatable/equatable.dart';

class Group {
  Group({
    required this.name,
    this.groupMembers = const [],
  });

  final String name;
  final List<Person> groupMembers;

  void addMember(Person person) {
    groupMembers.add(person);
  }

  void removeMember(Person personToRemove) {
    for (Person person in groupMembers) {
      if(person == personToRemove) {
        groupMembers.remove(person);
      }
    }
  }
}