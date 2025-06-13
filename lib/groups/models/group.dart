import 'package:cross_platform_development/groups/models/person.dart';

class Group {
  Group({
    required this.name,
    required this.id,
    List<Person>? groupMembers,
  }) : groupMembers = groupMembers ?? [];



  final String name;
  final String id ;
  final List<Person> groupMembers;

  void addMember(Person person) {
    groupMembers.add(person);
  }

  void removeMember(Person personToRemove) {
    groupMembers.removeWhere((person) => person == personToRemove);
  }

}