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
import 'package:flutter_twitter_clone/services/listing_ingest_service.dart'; // Import for listing ingest

class SidebarMenu extends StatefulWidget {
  const SidebarMenu({Key? key, this.scaffoldKey}) : super(key: key);

  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  _SidebarMenuState createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  late TextEditingController _zipController;

  @override
  void initState() {
    super.initState();
    _zipController = TextEditingController();
    // Initialize text field with current user's zip if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthState>();
      if (authState.userModel?.preferredZip != null) {
        _zipController.text = authState.userModel!.preferredZip!;
      }
    });
  }

  @override
  void dispose() {
    _zipController.dispose();
    super.dispose();
  }

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
      // Update zip controller if userModel changes (e.g. after login or location fetch)
      if (state.userModel!.preferredZip != null && _zipController.text != state.userModel!.preferredZip) {
          _zipController.text = state.userModel!.preferredZip!;
      }
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
        Navigator.pop(context);
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

    if (currentDisplayRole == null && authState.userModel!.roles.isEmpty) { // Should be caught by first check
        return const SizedBox.shrink();
    }
    if (currentDisplayRole == null && authState.userModel!.roles.isNotEmpty) {
        currentDisplayRole = authState.userModel!.roles.first;
    }

    return ListTile(
      dense: true,
      leading: Padding(
        padding: const EdgeInsets.only(top: 0, left: 5),
        child: customIcon(
          context,
          icon: AppIcon.users,
          size: 23,
          iconColor: AppColor.darkGrey,
        ),
      ),
      title: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentDisplayRole,
          isExpanded: true,
          icon: Icon(AppIcon.arrowDown, color: AppColor.primary, size: 20),
          onChanged: (String? newValue) {
            if (newValue != null) {
              context.read<AuthState>().updateUserCurrentRole(newValue);
              Navigator.pop(context);
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
    );
  }

  Widget _buildLocationTools() {
    final authState = context.watch<AuthState>();
    if (authState.userModel == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _menuListRowButton('Fetch Listings (My ZIP)', icon: AppIcon.refresh, isEnable: true, onPressed: () {
          Navigator.pop(context);
          if (authState.userModel?.preferredZip != null && authState.userModel!.preferredZip!.isNotEmpty) {
            ListingIngestService().fetchAndPostListingsForUser(authState.userModel!).then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Fetching listings for your ZIP...")),
              );
            }).catchError((e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error fetching listings: $e")),
              );
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Your preferred ZIP code is not set. Please update it.")),
            );
          }
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text("Update Location (Dev):", style: TextStyles.titleStyle.copyWith(fontSize: 16)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: _zipController,
            decoration: const InputDecoration(
              labelText: "Enter ZIP Code",
              hintText: "e.g. 90210",
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary),
            onPressed: () async {
              Navigator.pop(context);
              final newZip = _zipController.text.trim();
              if (newZip.isNotEmpty && authState.userModel != null) {
                // For simplicity, setting lat/lng to null when ZIP is manually updated.
                // A more robust solution might try to geocode the new ZIP to get lat/lng.
                await authState.updateUserLocationPreferences(authState.userModel!.userId!, null, null, newZip);
                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text("Preferred ZIP updated to $newZip. Fetching new listings...")),
                );
                // Fetch new listings for the new ZIP
                ListingIngestService().fetchAndPostListingsForUser(authState.userModel!);
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text("Please enter a valid ZIP code.")),
                );
              }
            },
            child: const Text("Update ZIP & Fetch Listings", style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
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
                  Navigator.pop(context);
                  if (context.read<AuthState>().userModel != null) {
                     Navigator.push(
                        context,
                        ScanScreen.getRoute(
                            context.read<AuthState>().userModel!));
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
    // Ensure _zipController is initialized with current user's ZIP when widget builds/rebuilds
    // This is especially important if the user logs out and logs back in or if authState updates.
    final authState = context.watch<AuthState>();
    if (authState.userModel?.preferredZip != null && _zipController.text != authState.userModel!.preferredZip) {
        _zipController.text = authState.userModel!.preferredZip!;
    }


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
                     Navigator.pop(context);
                    Navigator.push(
                        context, ProfilePage.getRoute(profileId: state.userId));
                  }),
                  _menuListRowButton(
                    'Bookmark',
                    icon: AppIcon.bookmark,
                    isEnable: true,
                    onPressed: () {
                       Navigator.pop(context);
                      Navigator.push(context, BookmarkPage.getRoute());
                    },
                  ),
                  _menuListRowButton('Lists', icon: AppIcon.lists, onPressed: (){ Navigator.pop(context);}),
                  _menuListRowButton('Moments', icon: AppIcon.moments, onPressed: (){ Navigator.pop(context);}),
                  const Divider(),
                  _buildRoleSwitcher(),
                  const Divider(),
                   _menuListRowButton('Seed Mock Data', icon: AppIcon.seed, isEnable: true, onPressed: () {
                    Navigator.pop(context);
                    final authState = context.read<AuthState>();
                    if (authState.userId.isNotEmpty) {
                      MockSeedService().seedInitialData(currentAuthUserId: authState.userId).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Mock data seeding initiated.")),
                        );
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
                  _buildLocationTools(), // Location Tools Section
                  const Divider(),
                  _menuListRowButton('Settings and privacy', isEnable: true,
                      onPressed: () {
                    _navigateTo('SettingsAndPrivacyPage');
                  }),
                  _menuListRowButton('Help Center', onPressed: (){ Navigator.pop(context);}),
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
