import 'package:equatable/equatable.dart';

// ignore: must_be_immutable
class UserModel extends Equatable {
  String? key;
  String? email;
  String? userId;
  String? displayName;
  String? userName;
  String? webSite;
  String? profilePic;
  String? bannerImage;
  String? contact;
  String? bio;
  String? location;
  String? dob;
  String? createdAt;
  bool? isVerified;
  int? followers;
  int? following;
  String? fcmToken;
  List<String>? followersList;
  List<String>? followingList;

  // New fields for Genii Feed User Roles
  List<String> roles;
  String? currentRole;

  // New fields for Geolocation Preferences
  double? preferredLat;
  double? preferredLng;
  String? preferredZip;

  UserModel({
    this.email,
    this.userId,
    this.displayName,
    this.profilePic,
    this.bannerImage,
    this.key,
    this.contact,
    this.bio,
    this.dob,
    this.location,
    this.createdAt,
    this.userName,
    this.followers,
    this.following,
    this.webSite,
    this.isVerified,
    this.fcmToken,
    this.followersList,
    this.followingList,
    List<String>? roles, // Made roles an optional named parameter
    this.currentRole,
    this.preferredLat,
    this.preferredLng,
    this.preferredZip,
  }) : roles = roles ?? []; // Initialize roles to an empty list if null

  UserModel.fromJson(Map<dynamic, dynamic>? map) : roles = [] { // Initialize roles here too
    if (map == null) {
      return;
    }
    followersList ??= [];
    email = map['email'];
    userId = map['userId'];
    displayName = map['displayName'];
    profilePic = map['profilePic'];
    bannerImage = map['bannerImage'];
    key = map['key'];
    dob = map['dob'];
    bio = map['bio'];
    location = map['location'];
    contact = map['contact'];
    createdAt = map['createdAt'];
    followers = map['followers'];
    following = map['following'];
    userName = map['userName'];
    webSite = map['webSite'];
    fcmToken = map['fcmToken'];
    isVerified = map['isVerified'] ?? false;
    if (map['followerList'] != null) {
      followersList = <String>[];
      map['followerList'].forEach((value) {
        followersList!.add(value);
      });
    }
    followers = followersList != null ? followersList!.length : null;
    if (map['followingList'] != null) {
      followingList = <String>[];
      map['followingList'].forEach((value) {
        followingList!.add(value);
      });
    }
    following = followingList != null ? followingList!.length : null;

    // Deserialize roles and currentRole
    if (map['roles'] != null) {
      roles = List<String>.from(map['roles']);
    } else {
      roles = []; // Ensure roles is initialized even if not in JSON
    }
    currentRole = map['currentRole'];

    // Deserialize geolocation preferences
    preferredLat = map['preferredLat'] as double?;
    preferredLng = map['preferredLng'] as double?;
    preferredZip = map['preferredZip'] as String?;
  }

  toJson() {
    return {
      'key': key,
      "userId": userId,
      "email": email,
      'displayName': displayName,
      'profilePic': profilePic,
      'bannerImage': bannerImage,
      'contact': contact,
      'dob': dob,
      'bio': bio,
      'location': location,
      'createdAt': createdAt,
      'followers': followersList != null ? followersList!.length : null,
      'following': followingList != null ? followingList!.length : null,
      'userName': userName,
      'webSite': webSite,
      'isVerified': isVerified ?? false,
      'fcmToken': fcmToken,
      'followerList': followersList,
      'followingList': followingList,
      // Serialize new fields
      'roles': roles,
      'currentRole': currentRole,
      'preferredLat': preferredLat,
      'preferredLng': preferredLng,
      'preferredZip': preferredZip,
    };
  }

  UserModel copyWith({
    String? email,
    String? userId,
    String? displayName,
    String? profilePic,
    String? key,
    String? contact,
    String? bio,
    String? dob,
    String? bannerImage,
    String? location,
    String? createdAt,
    String? userName,
    int? followers,
    int? following,
    String? webSite,
    bool? isVerified,
    String? fcmToken,
    List<String>? followingList,
    List<String>? followersList,
    List<String>? roles,
    String? currentRole,
    double? preferredLat,
    double? preferredLng,
    String? preferredZip,
  }) {
    return UserModel(
      email: email ?? this.email,
      bio: bio ?? this.bio,
      contact: contact ?? this.contact,
      createdAt: createdAt ?? this.createdAt,
      displayName: displayName ?? this.displayName,
      dob: dob ?? this.dob,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      isVerified: isVerified ?? this.isVerified,
      key: key ?? this.key,
      location: location ?? this.location,
      profilePic: profilePic ?? this.profilePic,
      bannerImage: bannerImage ?? this.bannerImage,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      webSite: webSite ?? this.webSite,
      fcmToken: fcmToken ?? this.fcmToken,
      followersList: followersList ?? this.followersList,
      followingList: followingList ?? this.followingList,
      roles: roles ?? this.roles,
      currentRole: currentRole ?? this.currentRole,
      preferredLat: preferredLat ?? this.preferredLat,
      preferredLng: preferredLng ?? this.preferredLng,
      preferredZip: preferredZip ?? this.preferredZip,
    );
  }

  String get getFollower {
    return '${followers ?? 0}';
  }

  String get getFollowing {
    return '${following ?? 0}';
  }

  @override
  List<Object?> get props => [
        key,
        email,
        userId,
        displayName,
        userName,
        webSite,
        profilePic,
        bannerImage,
        contact,
        bio,
        location,
        dob,
        createdAt,
        isVerified,
        followers,
        following,
        fcmToken,
        followersList,
        followingList
      ];
}
