import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/firebase_database.dart' as db;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_twitter_clone/helper/enum.dart';
import 'package:flutter_twitter_clone/helper/shared_prefrence_helper.dart';
import 'package:flutter_twitter_clone/helper/utility.dart';
import 'package:flutter_twitter_clone/model/user.dart';
import 'package:flutter_twitter_clone/ui/page/common/locator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart' as path;
import 'package:geolocator/geolocator.dart'; // For Position
import 'package:flutter_twitter_clone/services/location_service.dart'; // For LocationService
import 'package:flutter_twitter_clone/services/listing_ingest_service.dart'; // For ListingIngestService

import 'appState.dart';

class AuthState extends AppState {
  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;
  bool isSignInWithGoogle = false;
  User? user;
  late String userId;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  db.Query? _profileQuery;
  // List<UserModel> _profileUserModelList;
  UserModel? _userModel;

  UserModel? get userModel => _userModel;

  UserModel? get profileUserModel => _userModel;

  /// Logout from device
  void logoutCallback() async {
    authStatus = AuthStatus.NOT_LOGGED_IN;
    userId = '';
    _userModel = null;
    user = null;
    _profileQuery!.onValue.drain();
    _profileQuery = null;
    if (isSignInWithGoogle) {
      _googleSignIn.signOut();
      Utility.logEvent('google_logout', parameter: {});
      isSignInWithGoogle = false;
    }
    _firebaseAuth.signOut();
    notifyListeners();
    await getIt<SharedPreferenceHelper>().clearPreferenceValues();
  }

  /// Alter select auth method, login and sign up page
  void openSignUpPage() {
    authStatus = AuthStatus.NOT_LOGGED_IN;
    userId = '';
    notifyListeners();
  }

  void databaseInit() {
    try {
      if (_profileQuery == null) {
        _profileQuery = kDatabase.child("profile").child(user!.uid);
        _profileQuery!.onValue.listen(_onProfileChanged);
        _profileQuery!.onChildChanged.listen(_onProfileUpdated);
      }
    } catch (error) {
      cprint(error, errorIn: 'databaseInit');
    }
  }

  /// Verify user's credentials for login
  Future<String?> signIn(String email, String password,
      {required BuildContext context}) async {
    try {
      isBusy = true;
      var result = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      user = result.user;
      userId = user!.uid;
      return user!.uid;
    } on FirebaseException catch (error) {
      if (error.code == 'firebase_auth/user-not-found') {
        Utility.customSnackBar(context, 'User not found');
      } else {
        Utility.customSnackBar(
          context,
          error.message ?? 'Something went wrong',
        );
      }
      cprint(error, errorIn: 'signIn');
      return null;
    } catch (error) {
      Utility.customSnackBar(context, error.toString());
      cprint(error, errorIn: 'signIn');

      return null;
    } finally {
      isBusy = false;
    }
  }

  /// Create user from `google login`
  /// If user is new then it create a new user
  /// If user is old then it just `authenticate` user and return firebase user data
  Future<User?> handleGoogleSignIn() async {
    try {
      /// Record log in firebase kAnalytics about Google login
      kAnalytics.logLogin(loginMethod: 'google_login');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google login cancelled by user');
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      user = (await _firebaseAuth.signInWithCredential(credential)).user;
      authStatus = AuthStatus.LOGGED_IN;
      userId = user!.uid;
      isSignInWithGoogle = true;
      createUserFromGoogleSignIn(user!);
      notifyListeners();
      return user;
    } on PlatformException catch (error) {
      user = null;
      authStatus = AuthStatus.NOT_LOGGED_IN;
      cprint(error, errorIn: 'handleGoogleSignIn');
      return null;
    } on Exception catch (error) {
      user = null;
      authStatus = AuthStatus.NOT_LOGGED_IN;
      cprint(error, errorIn: 'handleGoogleSignIn');
      return null;
    } catch (error) {
      user = null;
      authStatus = AuthStatus.NOT_LOGGED_IN;
      cprint(error, errorIn: 'handleGoogleSignIn');
      return null;
    }
  }

  /// Create user profile from google login
  void createUserFromGoogleSignIn(User user) {
    var diff = DateTime.now().difference(user.metadata.creationTime!);
    // Check if user is new or old
    // If user is new then add new user to firebase realtime kDatabase
    if (diff < const Duration(seconds: 15)) {
      UserModel model = UserModel(
        bio: 'Edit profile to update bio',
        dob: DateTime(1950, DateTime.now().month, DateTime.now().day + 3)
            .toString(),
        location: 'Somewhere in universe',
        profilePic: user.photoURL!,
        displayName: user.displayName!,
        email: user.email!,
        key: user.uid,
        userId: user.uid,
        contact: user.phoneNumber!,
        isVerified: user.emailVerified,
      );
      createUser(model, newUser: true);
    } else {
      cprint('Last login at: ${user.metadata.lastSignInTime}');
    }
  }

  /// Create new user's profile in db
  Future<String?> signUp(UserModel userModel,
      {required BuildContext context, required String password}) async {
    try {
      isBusy = true;
      var result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: userModel.email!,
        password: password,
      );
      user = result.user;
      authStatus = AuthStatus.LOGGED_IN;
      kAnalytics.logSignUp(signUpMethod: 'register');
      result.user!.updateDisplayName(
        userModel.displayName,
      );
      result.user!.updatePhotoURL(userModel.profilePic);

      _userModel = userModel;
      _userModel!.key = user!.uid;
      _userModel!.userId = user!.uid;
      createUser(_userModel!, newUser: true);
      return user!.uid;
    } catch (error) {
      isBusy = false;
      cprint(error, errorIn: 'signUp');
      Utility.customSnackBar(context, error.toString());
      return null;
    }
  }

  /// `Create` and `Update` user
  /// IF `newUser` is true new user is created
  /// Else existing user will update with new values
  void createUser(UserModel user, {bool newUser = false}) {
    if (newUser) {
      // Create username by the combination of name and id
      user.userName =
          Utility.getUserName(id: user.userId!, name: user.displayName!);
      kAnalytics.logEvent(name: 'create_newUser');

      // Time at which user is created
      user.createdAt = DateTime.now().toUtc().toString();
    }

    kDatabase.child('profile').child(user.userId!).set(user.toJson());
    _userModel = user;
    isBusy = false;
  }

  /// Fetch current user profile
  Future<User?> getCurrentUser() async {
    try {
      isBusy = true;
      Utility.logEvent('get_currentUSer', parameter: {});
      user = _firebaseAuth.currentUser;
      if (user != null) {
        await getProfileUser(); // This populates _userModel
        authStatus = AuthStatus.LOGGED_IN;
        userId = user!.uid;
        // After user profile is loaded, fetch their location if not already set
        if (_userModel != null && (_userModel!.preferredZip == null || _userModel!.preferredZip!.isEmpty)) {
          cprint("User profile loaded, preferredZip is missing. Fetching location and then listings.", infoIn: "getCurrentUser");
          fetchAndSetCurrentUserLocation().then((_) {
            // After location is set (or attempted), if zip is now available, fetch listings
            if (_userModel?.preferredZip != null && _userModel!.preferredZip!.isNotEmpty) {
              ListingIngestService().fetchAndPostListingsForUser(_userModel!); // No await, background task
            }
          });
        } else if (_userModel != null && _userModel!.preferredZip != null && _userModel!.preferredZip!.isNotEmpty) {
          cprint("User profile loaded, preferredZip already exists: ${_userModel!.preferredZip}. Fetching listings.", infoIn: "getCurrentUser");
          // Fetch listings if ZIP is already there (e.g. on subsequent app starts)
          // Add a flag/timestamp check here later to avoid fetching too often. For now, always fetch.
          ListingIngestService().fetchAndPostListingsForUser(_userModel!); // No await, background task
        }
      } else {
        authStatus = AuthStatus.NOT_LOGGED_IN;
      }
      isBusy = false;
      return user;
    } catch (error) {
      isBusy = false;
      cprint(error, errorIn: 'getCurrentUser');
      authStatus = AuthStatus.NOT_LOGGED_IN;
      return null;
    }
  }

  /// Reload user to get refresh user data
  void reloadUser() async {
    await user!.reload();
    user = _firebaseAuth.currentUser;
    if (user!.emailVerified) {
      userModel!.isVerified = true;
      // If user verified his email
      // Update user in firebase realtime kDatabase
      createUser(userModel!);
      cprint('UserModel email verification complete');
      Utility.logEvent('email_verification_complete',
          parameter: {userModel!.userName!: user!.email!});
    }
  }

  /// Send email verification link to email2
  Future<void> sendEmailVerification(BuildContext context) async {
    User user = _firebaseAuth.currentUser!;
    user.sendEmailVerification().then((_) {
      Utility.logEvent('email_verification_sent',
          parameter: {userModel!.displayName!: user.email!});
      Utility.customSnackBar(
        context,
        'An email verification link is send to your email.',
      );
    }).catchError((error) {
      cprint(error.message, errorIn: 'sendEmailVerification');
      Utility.logEvent('email_verification_block',
          parameter: {userModel!.displayName!: user.email!});
      Utility.customSnackBar(
        context,
        error.message,
      );
    });
  }

  /// Check if user's email is verified
  Future<bool> emailVerified() async {
    User user = _firebaseAuth.currentUser!;
    return user.emailVerified;
  }

  /// Send password reset link to email
  Future<void> forgetPassword(String email,
      {required BuildContext context}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email).then((value) {
        Utility.customSnackBar(context,
            'A reset password link is sent yo your mail.You can reset your password from there');
        Utility.logEvent('forgot+password', parameter: {});
      }).catchError((error) {
        cprint(error.message);
      });
    } catch (error) {
      Utility.customSnackBar(context, error.toString());
      return Future.value(false);
    }
  }

  /// `Update user` profile
  Future<void> updateUserProfile(UserModel? userModel,
      {File? image, File? bannerImage}) async {
    try {
      if (image == null && bannerImage == null) {
        createUser(userModel!);
      } else {
        /// upload profile image if not null
        if (image != null) {
          /// get image storage path from server
          userModel!.profilePic = await _uploadFileToStorage(image,
              'user/profile/${userModel.userName}/${path.basename(image.path)}');
          // print(fileURL);
          var name = userModel.displayName ?? user!.displayName;
          _firebaseAuth.currentUser!.updateDisplayName(name);
          _firebaseAuth.currentUser!.updatePhotoURL(userModel.profilePic);
          Utility.logEvent('user_profile_image');
        }

        /// upload banner image if not null
        if (bannerImage != null) {
          /// get banner storage path from server
          userModel!.bannerImage = await _uploadFileToStorage(bannerImage,
              'user/profile/${userModel.userName}/${path.basename(bannerImage.path)}');
          Utility.logEvent('user_banner_image');
        }

        if (userModel != null) {
          createUser(userModel);
        } else {
          createUser(_userModel!);
        }
      }

      Utility.logEvent('update_user');
    } catch (error) {
      cprint(error, errorIn: 'updateUserProfile');
    }
  }

  Future<String> _uploadFileToStorage(File file, path) async {
    var task = _firebaseStorage.ref().child(path);
    var status = await task.putFile(file);
    cprint(status.state.name);

    /// get file storage path from server
    return await task.getDownloadURL();
  }

  /// `Fetch` user `detail` whose userId is passed
  Future<UserModel?> getUserDetail(String userId) async {
    UserModel user;
    var event = await kDatabase.child('profile').child(userId).once();

    final map = event.snapshot.value as Map?;
    if (map != null) {
      user = UserModel.fromJson(map);
      user.key = event.snapshot.key!;
      return user;
    } else {
      return null;
    }
  }

  /// Fetch user profile
  /// If `userProfileId` is null then logged in user's profile will fetched
  FutureOr<void> getProfileUser({String? userProfileId}) {
    try {
      userProfileId = userProfileId ?? user!.uid;
      kDatabase
          .child("profile")
          .child(userProfileId)
          .once()
          .then((DatabaseEvent event) async {
        final snapshot = event.snapshot;
        if (snapshot.value != null) {
          var map = snapshot.value as Map<dynamic, dynamic>?;
          if (map != null) {
            if (userProfileId == user!.uid) {
              _userModel = UserModel.fromJson(map);
              _userModel!.isVerified = user!.emailVerified;
              if (!user!.emailVerified) {
                // Check if logged in user verified his email address or not
                // reloadUser();
              }
              if (_userModel!.fcmToken == null) {
                updateFCMToken();
              }

              getIt<SharedPreferenceHelper>().saveUserProfile(_userModel!);
            }

            Utility.logEvent('get_profile', parameter: {});
          }
        }
        isBusy = false;
      });
    } catch (error) {
      isBusy = false;
      cprint(error, errorIn: 'getProfileUser');
    }
  }

  /// if firebase token not available in profile
  /// Then get token from firebase and save it to profile
  /// When someone sends you a message FCM token is used
  void updateFCMToken() {
    if (_userModel == null) {
      return;
    }
    getProfileUser();
    _firebaseMessaging.getToken().then((String? token) {
      assert(token != null);
      _userModel!.fcmToken = token;
      createUser(_userModel!);
    });
  }

  /// Trigger when logged-in user's profile change or updated
  /// Firebase event callback for profile update
  void _onProfileChanged(DatabaseEvent event) {
    final val = event.snapshot.value;
    if (val is Map) {
      final updatedUser = UserModel.fromJson(val);
      _userModel = updatedUser;
      cprint('UserModel Updated');
      getIt<SharedPreferenceHelper>().saveUserProfile(_userModel!);
      notifyListeners();
    }
  }

  void _onProfileUpdated(DatabaseEvent event) {
    final val = event.snapshot.value;
    if (val is List &&
        ['following', 'followers'].contains(event.snapshot.key)) {
      final list = val.cast<String>().map((e) => e).toList();
      if (event.previousChildKey == 'following') {
        _userModel = _userModel!.copyWith(
          followingList: val.cast<String>().map((e) => e).toList(),
          following: list.length,
        );
      } else if (event.previousChildKey == 'followers') {
        _userModel = _userModel!.copyWith(
          followersList: list,
          followers: list.length,
        );
      }
      getIt<SharedPreferenceHelper>().saveUserProfile(_userModel!);
      cprint('UserModel Updated');
      notifyListeners();
    }
  }

  /// Update the user's current active role and persist it to Firebase.
  Future<void> updateUserCurrentRole(String newRole) async {
    if (_userModel == null) {
      cprint("Cannot update current role: userModel is null.", errorIn: "updateUserCurrentRole");
      return;
    }

    // Check if the newRole is actually one of the user's assigned roles.
    // This is good practice, though the UI should ideally only present valid roles.
    if (!_userModel!.roles.contains(newRole) && _userModel!.roles.isNotEmpty) {
        // If roles list is not empty and newRole is not in it, perhaps default to first role or log warning.
        // For now, we'll allow setting it, but this could be a point of validation.
        cprint("Warning: Setting currentRole to '$newRole' which is not in user's roles list: ${_userModel!.roles}", warningIn: "updateUserCurrentRole");
    }

    _userModel!.currentRole = newRole;

    try {
      // The existing createUser method updates the profile in Firebase.
      createUser(_userModel!);
      cprint("User's current role updated to: $newRole and saved to Firebase.");
      notifyListeners(); // Notify listeners after successful update.
    } catch (e) {
      cprint("Error saving user model after updating current role: $e", errorIn: "updateUserCurrentRole");
      // Optionally, revert _userModel.currentRole or handle error appropriately.
    }
  }

  /// Updates the user's location preferences in Firebase and locally.
  Future<void> updateUserLocationPreferences(String userId, double? lat, double? lng, String? zip) async {
    if (_userModel == null || _userModel!.userId != userId) {
      // If the local userModel is not the one we're updating,
      // we might need to fetch it first or just update Firebase directly.
      // For now, we'll primarily focus on updating Firebase.
      // If it's the current user, we'll update the local model too.
      cprint("Updating location for user ID: $userId (may not be the currently loaded _userModel)", warningIn: "updateUserLocationPreferences");
    }

    Map<String, dynamic> locationUpdate = {
      'preferredLat': lat,
      'preferredLng': lng,
      'preferredZip': zip,
    };

    try {
      await kDatabase.child('profile').child(userId).update(locationUpdate);
      cprint("User location preferences updated in Firebase for user $userId: $zip, $lat, $lng");

      // If this is the currently logged-in user, update the local model and notify.
      if (_userModel != null && _userModel!.userId == userId) {
        _userModel = _userModel!.copyWith(
          preferredLat: lat,
          preferredLng: lng,
          preferredZip: zip,
        );
        // The createUser method also calls notifyListeners and saves the whole model,
        // but since we only updated specific fields, a direct update and notify might be cleaner.
        // However, to ensure consistency with how other profile updates are handled (e.g. via createUser),
        // we could call createUser or a similar method that saves the entire model.
        // For now, let's update locally and notify. The next full profile save would catch it.
        // OR, more robustly, ensure the local model is fully updated and then call createUser.

        // Let's use a targeted local update and then ensure persistence through createUser
        // which handles the full userModel object.
        // CreateUser will also call notifyListeners.
        createUser(_userModel!); // This will save the whole model including new location.
        cprint("Local userModel updated with new location preferences.");
      }
    } catch (e) {
      cprint("Error updating user location preferences in Firebase for user $userId: $e", errorIn: "updateUserLocationPreferences");
    }
  }

  /// Fetches the current user's location, derives ZIP code, and updates their profile.
  /// To be called after login or on app start if location data is missing.
  Future<void> fetchAndSetCurrentUserLocation() async {
    if (user == null || _userModel == null) {
      cprint("No logged-in user to fetch location for.", warningIn: "fetchAndSetCurrentUserLocation");
      return;
    }

    // Optional: Check if location is already set and recent enough
    // if (_userModel!.preferredZip != null && _userModel!.preferredZip!.isNotEmpty) {
    //   // Potentially check a timestamp if we add one for last location update
    //   cprint("User location already set to ZIP: ${_userModel!.preferredZip}. Skipping fetch.", infoIn: "fetchAndSetCurrentUserLocation");
    //   return;
    // }

    final locationService = LocationService(); // Assuming LocationService is in scope (import may be needed)

    final hasPermission = await locationService.handleLocationPermission();
    if (!hasPermission) {
      cprint("Location permission not granted. Cannot fetch location.", warningIn: "fetchAndSetCurrentUserLocation");
      // Optionally, notify the user through a UI message that location is needed for some features.
      return;
    }

    cprint("Fetching current position...", infoIn: "fetchAndSetCurrentUserLocation");
    Position? position = await locationService.getCurrentPosition();

    if (position != null) {
      cprint("Position fetched: Lat ${position.latitude}, Lng ${position.longitude}", infoIn: "fetchAndSetCurrentUserLocation");
      String? zipCode = await locationService.getZipCodeFromCoordinates(position.latitude, position.longitude);

      if (zipCode != null) {
        cprint("ZIP code derived: $zipCode. Updating user preferences.", infoIn: "fetchAndSetCurrentUserLocation");
        await updateUserLocationPreferences(user!.uid, position.latitude, position.longitude, zipCode);
        // updateUserLocationPreferences already calls notifyListeners through createUser
      } else {
        cprint("Could not derive ZIP code from coordinates.", warningIn: "fetchAndSetCurrentUserLocation");
        // Optionally, still save lat/lng even if ZIP is not found
        // await updateUserLocationPreferences(user.uid, position.latitude, position.longitude, null);
      }
    } else {
      cprint("Could not fetch current position.", warningIn: "fetchAndSetCurrentUserLocation");
    }
  }
}
