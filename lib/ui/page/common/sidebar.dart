import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/constant.dart';
import 'package:flutter_twitter_clone/state/authState.dart';
import 'package:flutter_twitter_clone/ui/page/bookmark/bookmarkPage.dart';
import 'package:flutter_twitter_clone/ui/page/profile/follow/followerListPage.dart';
import 'package:flutter_twitter_clone/ui/page/profile/follow/followingListPage.dart';
import 'package:flutter_twitter_clone/ui/page/profile/profilePage.dart';
import 'package:flutter_twitter_clone/ui/page/profile/qrCode/scanner.dart';
import 'package:flutter_twitter_clone/ui/page/profile/widgets/circular_image.dart';
import 'package:flutter_twitter_clone/ui/theme/theme.dart';
import 'package:flutter_twitter_clone/widgets/customWidgets.dart';
import 'package:flutter_twitter_clone/widgets/url_text/customUrlText.dart';
import 'package:provider/provider.dart';
import 'package:flutter_twitter_clone/helper/enum.dart'; // For UserRoles, AppIcon if needed for roles
import 'package:flutter_twitter_clone/services/mock_seed_service.dart'; // Import for seeder

class SidebarMenu extends StatefulWidget {
  const SidebarMenu({Key? key, this.scaffoldKey}) : super(key: key);

  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  _SidebarMenuState createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  Widget _menuHeader() {
    final state = context.watch<AuthState>();
    if (state.userModel == null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 200, minHeight: 100),
        child: Center(
          child: Text(
            'Login to continue',
            style: TextStyles.onPrimaryTitleText,
          ),
        ),
      ).ripple(() {
        _logOut();
      });
    } else {
      return Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 56,
              width: 56,
              margin: const EdgeInsets.only(left: 17, top: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(28),
                image: DecorationImage(
                  image: customAdvanceNetworkImage(
                    state.userModel!.profilePic ?? Constants.dummyProfilePic,
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            ListTile(
              onTap: () {
                Navigator.push(context,
                    ProfilePage.getRoute(profileId: state.userModel!.userId!));
              },
              title: Row(
                children: <Widget>[
                  UrlText(
                    text: state.userModel!.displayName ?? "",
                    style: TextStyles.onPrimaryTitleText
                        .copyWith(color: Colors.black, fontSize: 20),
                  ),
                  const SizedBox(
                    width: 3,
                  ),
                  state.userModel!.isVerified ?? false
                      ? customIcon(context,
                          icon: AppIcon.blueTick,
                          isTwitterIcon: true,
                          iconColor: AppColor.primary,
                          size: 18,
                          paddingIcon: 3)
                      : const SizedBox(
                          width: 0,
                        ),
                ],
              ),
              subtitle: customText(
                state.userModel!.userName,
                style: TextStyles.onPrimarySubTitleText
                    .copyWith(color: Colors.black54, fontSize: 15),
              ),
              trailing: customIcon(context,
                  icon: AppIcon.arrowDown,
                  iconColor: AppColor.primary,
                  paddingIcon: 20),
            ),
            Container(
              alignment: Alignment.center,
              child: Row(
                children: <Widget>[
                  const SizedBox(
                    width: 17,
                  ),
                  _textButton(context, state.userModel!.getFollower,
                      ' Followers', 'FollowerListPage'),
                  const SizedBox(width: 10),
                  _textButton(context, state.userModel!.getFollowing,
                      ' Following', 'FollowingListPage'),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _textButton(
      BuildContext context, String count, String text, String navigateTo) {
    return InkWell(
      onTap: () {
        var authState = context.read<AuthState>();
        late List<String> usersList;
        // authState.getProfileUser(); // This might not be needed here if userModel is already up-to-date
        Navigator.pop(context); // Close drawer before navigating
        switch (navigateTo) {
          case "FollowerListPage":
            usersList = authState.userModel!.followersList ?? [];
            Navigator.push(
              context,
              FollowerListPage.getRoute(
                profile: authState.userModel!,
                userList: usersList,
              ),
            );
            break;
          case "FollowingListPage":
            usersList = authState.userModel!.followingList ?? [];
            Navigator.push(
              context,
              FollowingListPage.getRoute(
                profile: authState.userModel!,
                userList: usersList,
              ),
            );
            break;
        }
      },
      child: Row(
        children: <Widget>[
          customText(
            '$count ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          customText(
            text,
            style: const TextStyle(color: AppColor.darkGrey, fontSize: 17),
          ),
        ],
      ),
    );
  }

  ListTile _menuListRowButton(String title,
      {Function? onPressed, IconData? icon, bool isEnable = false}) {
    return ListTile(
      onTap: () {
        if (onPressed != null) {
          // Close drawer before executing onPressed, if it doesn't navigate itself
          if (title != "Logout" && title != "Settings and privacy") { // Example: keep drawer open for settings or logout confirmation
             // Navigator.pop(context);
          }
          onPressed();
        }
      },
      leading: icon == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 5),
              child: customIcon(
                context,
                icon: icon,
                size: 25,
                iconColor: isEnable ? AppColor.darkGrey : AppColor.lightGrey,
              ),
            ),
      title: customText(
        title,
        style: TextStyle(
          fontSize: 20,
          color: isEnable ? AppColor.secondary : AppColor.lightGrey,
        ),
      ),
    );
  }

  Widget _buildRoleSwitcher() {
    final authState = context.watch<AuthState>();

    if (authState.userModel == null || authState.userModel!.roles.isEmpty) {
      return const SizedBox.shrink();
    }

    String? currentDisplayRole = authState.userModel!.currentRole;
    if (currentDisplayRole == null || !authState.userModel!.roles.contains(currentDisplayRole)) {
      currentDisplayRole = authState.userModel!.roles.isNotEmpty ? authState.userModel!.roles.first : null;
    }

    if (currentDisplayRole == null && authState.userModel!.roles.isEmpty) {
        return const SizedBox.shrink();
    }
    // If currentDisplayRole is still null but roles list is not empty, pick the first one.
    // This ensures DropdownButton always has a valid value if items are available.
    if (currentDisplayRole == null && authState.userModel!.roles.isNotEmpty) {
        currentDisplayRole = authState.userModel!.roles.first;
    }


    return ListTile(
      dense: true, // Makes the ListTile a bit more compact
      leading: Padding(
        padding: const EdgeInsets.only(top: 0, left: 5),
        child: customIcon(
          context,
          icon: AppIcon.users,
          size: 23,
          iconColor: AppColor.darkGrey,
        ),
      ),
      title: Container(
        // No horizontal padding for DropdownButton itself, ListTile handles padding
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentDisplayRole,
            isExpanded: true,
            icon: Icon(AppIcon.arrowDown, color: AppColor.primary, size: 20),
            onChanged: (String? newValue) {
              if (newValue != null) {
                context.read<AuthState>().updateUserCurrentRole(newValue);
                 Navigator.pop(context); // Close drawer after role selection
              }
            },
            items: authState.userModel!.roles
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 18, color: AppColor.secondary),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            hint: const Text("Select Role", style: TextStyle(fontSize: 18, color: AppColor.lightGrey)),
          ),
        ),
      ),
    );
  }


  Positioned _footer() {
    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: Column(
        children: <Widget>[
          const Divider(height: 0),
          Row(
            children: <Widget>[
              const SizedBox(
                width: 10,
                height: 45,
              ),
              customIcon(context,
                  icon: AppIcon.bulbOn,
                  isTwitterIcon: true,
                  size: 25,
                  iconColor: TwitterColor.dodgeBlue),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close drawer
                  if (context.read<AuthState>().userModel != null) {
                     Navigator.push(
                        context,
                        ScanScreen.getRoute(
                            context.read<AuthState>().userModel!)); // profileUserModel changed to userModel
                  }
                },
                child: Image.asset(
                  "assets/images/qr.png",
                  height: 25,
                ),
              ),
              const SizedBox(
                width: 0,
                height: 45,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _logOut() {
    final state = Provider.of<AuthState>(context, listen: false);
    Navigator.pop(context);
    state.logoutCallback();
  }

  void _navigateTo(String path) {
    Navigator.pop(context);
    Navigator.of(context).pushNamed('/$path');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 45),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: <Widget>[
                  Container(
                    child: _menuHeader(),
                  ),
                  const Divider(),
                  _menuListRowButton('Profile',
                      icon: AppIcon.profile, isEnable: true, onPressed: () {
                    var state = context.read<AuthState>();
                     Navigator.pop(context); // Close drawer
                    Navigator.push(
                        context, ProfilePage.getRoute(profileId: state.userId));
                  }),
                  _menuListRowButton(
                    'Bookmark',
                    icon: AppIcon.bookmark,
                    isEnable: true,
                    onPressed: () {
                       Navigator.pop(context); // Close drawer
                      Navigator.push(context, BookmarkPage.getRoute());
                    },
                  ),
                  _menuListRowButton('Lists', icon: AppIcon.lists), // onPressed: () { Navigator.pop(context); ...}
                  _menuListRowButton('Moments', icon: AppIcon.moments), // onPressed: () { Navigator.pop(context); ...}
                  const Divider(),
                  _buildRoleSwitcher(),
                  const Divider(),
                  _menuListRowButton('Seed Mock Data', icon: AppIcon.seed, isEnable: true, onPressed: () { // Seed Data Button
                    Navigator.pop(context); // Close drawer
                    final authState = context.read<AuthState>();
                    if (authState.userId.isNotEmpty) {
                      MockSeedService().seedInitialData(currentAuthUserId: authState.userId).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Mock data seeding initiated.")),
                        );
                        // Optionally, refresh feed or other states if needed
                        // Provider.of<FeedState>(context, listen: false).getDataFromDatabase();
                      }).catchError((e) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error seeding data: $e")),
                        );
                      });
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("User not logged in. Cannot seed data.")),
                      );
                    }
                  }),
                  const Divider(),
                  _menuListRowButton('Settings and privacy', isEnable: true,
                      onPressed: () {
                    _navigateTo('SettingsAndPrivacyPage');
                  }),
                  _menuListRowButton('Help Center'), // onPressed: () { Navigator.pop(context); ...}
                  const Divider(),
                  _menuListRowButton('Logout',
                      icon: null, onPressed: _logOut, isEnable: true),
                ],
              ),
            ),
            _footer()
          ],
        ),
      ),
    );
  }
}
