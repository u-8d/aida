// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String,
  city: json['city'] as String,
  userType: $enumDecode(_$UserTypeEnumMap, json['userType']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  isVerified: json['isVerified'] as bool? ?? false,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'city': instance.city,
  'userType': _$UserTypeEnumMap[instance.userType]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'isVerified': instance.isVerified,
};

const _$UserTypeEnumMap = {
  UserType.donor: 'donor',
  UserType.ngo: 'ngo',
  UserType.individual: 'individual',
};

NGO _$NGOFromJson(Map<String, dynamic> json) => NGO(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String,
  city: json['city'] as String,
  registrationNumber: json['registrationNumber'] as String,
  missionStatement: json['missionStatement'] as String,
  focusAreas: (json['focusAreas'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  isVerified: json['isVerified'] as bool? ?? false,
);

Map<String, dynamic> _$NGOToJson(NGO instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'city': instance.city,
  'createdAt': instance.createdAt.toIso8601String(),
  'isVerified': instance.isVerified,
  'registrationNumber': instance.registrationNumber,
  'missionStatement': instance.missionStatement,
  'focusAreas': instance.focusAreas,
};

Individual _$IndividualFromJson(Map<String, dynamic> json) => Individual(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String,
  city: json['city'] as String,
  needExplanation: json['needExplanation'] as String,
  urgentNeeds: (json['urgentNeeds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  isVerified: json['isVerified'] as bool? ?? false,
);

Map<String, dynamic> _$IndividualToJson(Individual instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'city': instance.city,
      'createdAt': instance.createdAt.toIso8601String(),
      'isVerified': instance.isVerified,
      'needExplanation': instance.needExplanation,
      'urgentNeeds': instance.urgentNeeds,
    };
