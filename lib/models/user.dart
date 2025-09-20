import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String city;
  final UserType userType;
  final DateTime createdAt;
  final bool isVerified;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.userType,
    required this.createdAt,
    this.isVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class NGO extends User {
  final String registrationNumber;
  final String missionStatement;
  final List<String> focusAreas;

  NGO({
    required String id,
    required String name,
    required String email,
    required String phone,
    required String city,
    required this.registrationNumber,
    required this.missionStatement,
    required this.focusAreas,
    required DateTime createdAt,
    bool isVerified = false,
  }) : super(
          id: id,
          name: name,
          email: email,
          phone: phone,
          city: city,
          userType: UserType.ngo,
          createdAt: createdAt,
          isVerified: isVerified,
        );

  factory NGO.fromJson(Map<String, dynamic> json) => _$NGOFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$NGOToJson(this);
}

@JsonSerializable()
class Individual extends User {
  final String needExplanation;
  final List<String> urgentNeeds;

  Individual({
    required String id,
    required String name,
    required String email,
    required String phone,
    required String city,
    required this.needExplanation,
    required this.urgentNeeds,
    required DateTime createdAt,
    bool isVerified = false,
  }) : super(
          id: id,
          name: name,
          email: email,
          phone: phone,
          city: city,
          userType: UserType.individual,
          createdAt: createdAt,
          isVerified: isVerified,
        );

  factory Individual.fromJson(Map<String, dynamic> json) => _$IndividualFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$IndividualToJson(this);
}

enum UserType {
  donor,
  ngo,
  individual,
  admin,
}
