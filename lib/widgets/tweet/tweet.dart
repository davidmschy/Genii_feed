import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/enum.dart';
import 'package:flutter_twitter_clone/helper/utility.dart';
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/state/feedState.dart';
import 'package:flutter_twitter_clone/ui/page/feed/feedPostDetail.dart';
import 'package:flutter_twitter_clone/ui/page/profile/profilePage.dart';
import 'package:flutter_twitter_clone/ui/page/profile/widgets/circular_image.dart';
import 'package:flutter_twitter_clone/ui/theme/theme.dart';
import 'package:flutter_twitter_clone/widgets/newWidget/title_text.dart';
import 'package:intl/intl.dart'; // For currency formatting
import 'package:flutter_twitter_clone/widgets/tweet/widgets/parentTweet.dart';
import 'package:flutter_twitter_clone/widgets/tweet/widgets/tweetIconsRow.dart';
import 'package:flutter_twitter_clone/widgets/url_text/customUrlText.dart';
import 'package:flutter_twitter_clone/widgets/url_text/custom_link_media_info.dart';
import 'package:provider/provider.dart';

import '../customWidgets.dart';
import 'widgets/retweetWidget.dart';
import 'widgets/tweetImage.dart';

class Tweet extends StatelessWidget {
  final FeedModel model;
  final Widget? trailing;
}

class _PropertyListingCard extends StatelessWidget {
  final FeedModel model;
  final TweetType type;
  final Widget? trailing;
  final bool isDisplayOnProfile;

  const _PropertyListingCard({
    Key? key,
    required this.model,
    required this.type,
    this.trailing,
    required this.isDisplayOnProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final payload = model.eventPayload;
    if (payload == null) {
      return const SizedBox.shrink(); // Or some error widget
    }

    final address = payload['address'] as String?;
    final price = payload['price'] as num?; // num to handle int or double
    final bedrooms = payload['bedrooms'] as int?;
    final bathrooms = payload['bathrooms'] as num?; // num for cases like 1.5 baths
    final sqft = payload['sqft'] as num?;
    final imageUrl = payload['imageUrl'] as String?;
    final source = payload['source'] as String?; // e.g., Zillow, CREXi
    // final listingUrl = payload['listingUrl'] as String?; // For future "View Listing" button

    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0); // No decimals for price
    final numberFormatter = NumberFormat.decimalPattern();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0), // No bottom padding, let TweetIconsRow handle it
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User/Source Info Row (similar to other cards)
           Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () { // User who posted this, or system
                    if (isDisplayOnProfile || model.user == null) return;
                    Navigator.push(context, ProfilePage.getRoute(profileId: model.userId));
                  },
                  child: model.user?.profilePic != null && model.user!.profilePic!.isNotEmpty
                      ? CircularImage(path: model.user!.profilePic)
                      : Container( // Placeholder for source icon (Zillow, CREXi etc.)
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary.withAlpha(50),
                          ),
                          child: Icon(
                            AppIcon.home, // Generic home icon
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Row(
                            children: <Widget>[
                              // If posted by a user, show their name. Otherwise, show "Property Listing" or Source.
                              TitleText(source != null ? "$source Listing" : model.user?.displayName ?? 'Property Listing',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(width: 3),
                               model.user?.isVerified == true
                                  ? customIcon(
                                      context,
                                      icon: AppIcon.blueTick,
                                      isTwitterIcon: true,
                                      iconColor: AppColor.primary,
                                      size: 13,
                                      paddingIcon: 3,
                                    )
                                  : const SizedBox.shrink(),
                              const Spacer(),
                              customText(
                                '· ${Utility.getChatTime(model.createdAt)}',
                                style: TextStyles.userNameStyle.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(child: trailing ?? const SizedBox.shrink()),
                      ],
                    ),
                     if(model.user != null && source != null) // Show user who posted, if it's not the source itself
                      customText(
                        '@${model.user!.userName}',
                        style: TextStyles.userNameStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Property Image (if available)
          if (imageUrl != null && imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180, // Adjust height as needed
                  placeholder: (context, url) => Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                     height: 180,
                    color: Colors.grey[300],
                    child: Icon(Icons.error, color: Colors.red[400]),
                  ),
                ),
              ),
            ),

          // Address
          if (address != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(address, style: TextStyles.titleStyle.copyWith(fontSize: 17)),
            ),

          // Price
          if (price != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(currencyFormatter.format(price), style: TextStyles.headline5.copyWith(color: TwitterColor.bondyBlue, fontWeight: FontWeight.bold)),
            ),

          // Details Row (Beds, Baths, Sqft)
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              if (bedrooms != null) ...[
                Icon(AppIcon.bed, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 4),
                Text('${numberFormatter.format(bedrooms)} bed${bedrooms > 1 ? 's' : ''}', style: TextStyles.subtitleStyle),
                const SizedBox(width: 12),
              ],
              if (bathrooms != null) ...[
                Icon(AppIcon.bath, size: 16, color: Colors.grey[700]), // Assuming AppIcon.bath exists
                const SizedBox(width: 4),
                Text('${numberFormatter.format(bathrooms)} bath${bathrooms > 1 ? 's' : ''}', style: TextStyles.subtitleStyle),
                const SizedBox(width: 12),
              ],
              if (sqft != null) ...[
                 Icon(AppIcon.squareFoot, size: 16, color: Colors.grey[700]), // Assuming AppIcon.squareFoot exists
                const SizedBox(width: 4),
                Text('${numberFormatter.format(sqft)} sqft', style: TextStyles.subtitleStyle),
              ],
            ],
          ),
          const SizedBox(height: 8), // Space before TweetIconsRow which is added by the main Tweet widget
          // Action buttons like "View Listing", "Save" could be added here or in TweetIconsRow
        ],
      ),
    );
  }
}

class _AgentReplyCard extends StatelessWidget {
  final FeedModel model;
  final TweetType type;
  final Widget? trailing;
  final bool isDisplayOnProfile;

  const _AgentReplyCard({
    Key? key,
    required this.model,
    required this.type,
    this.trailing,
    required this.isDisplayOnProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final replyText = model.eventPayload?['replyText'] as String?;
    // The user associated with an AgentReply post should ideally be the Agent itself.
    // We can use model.user.displayName for the agent's name.
    // If model.user is null or not an agent, use a placeholder.
    final agentName = model.user?.displayName ?? "AI Agent";
    final agentUserName = model.user?.userName; // Might be null for agents

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColor.mystic // A slightly different background for replies
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                // Agent profile page if exists, or do nothing
                if (isDisplayOnProfile || model.user == null) return;
                // Assuming agent might have a profile, or this could be disabled for agents
                 Navigator.push(context, ProfilePage.getRoute(profileId: model.userId));
              },
              // Generic Agent Avatar
              child: model.user?.profilePic != null && model.user!.profilePic!.isNotEmpty
                  ? CircularImage(path: model.user!.profilePic)
                  : Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.secondary.withAlpha(100),
                      ),
                      child: Icon(
                        AppIcon.bulb, // Using AppIcon.bulb as a placeholder for agent icon
                        color: Theme.of(context).colorScheme.secondary,
                        size: 20,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          ConstrainedBox(
                            constraints: BoxConstraints(minWidth: 0, maxWidth: context.width * .4),
                            child: TitleText(agentName,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                overflow: TextOverflow.ellipsis),
                          ),
                          // No blue tick for agents by default, unless they are "verified" agents
                          if (agentUserName != null && agentUserName.isNotEmpty) ...[
                            const SizedBox(width: 3),
                            Flexible(
                              child: customText(
                                '@$agentUserName', // Display agent's username if available
                                style: TextStyles.userNameStyle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          const SizedBox(width: 4),
                          customText(
                            '· ${Utility.getChatTime(model.createdAt)}',
                            style: TextStyles.userNameStyle.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(child: trailing ?? const SizedBox.shrink()),
                  ],
                ),
                const SizedBox(height: 6),
                 Row(
                  children: [
                    customIcon(
                      context,
                      icon: AppIcon.reply, // Using reply icon
                      isTwitterIcon: false,
                      iconColor: Theme.of(context).textTheme.bodySmall!.color!,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    const TitleText("Agent Reply", fontSize: 14, color: Colors.black54, fontWeight: FontWeight.normal),
                  ],
                ),

                // Display parent tweet text if this is a reply (Optional, can be complex)
                // if (model.parentkey != null) ...[
                //   SizedBox(height: 5),
                //   Text("Replying to...", style: TextStyles.userNameStyle.copyWith(fontSize: 12)),
                //   // Here you might fetch and display the parent tweet's text snippet
                // ],

                if (replyText != null && replyText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: UrlText(
                      text: replyText,
                      style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w400),
                      urlStyle: const TextStyle(color: Colors.blue, fontSize: 15, fontWeight: FontWeight.w400),
                    ),
                  )
                else if (model.description != null && model.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: UrlText(
                      text: model.description!,
                      style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w400),
                      urlStyle: const TextStyle(color: Colors.blue, fontSize: 15, fontWeight: FontWeight.w400),
                    ),
                  ),
                SizedBox(height: model.childRetwetkey == null ? 8 : 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentPromptCard extends StatelessWidget {
  final FeedModel model;
  final TweetType type; // May not be strictly needed for this card, but good for consistency
  final Widget? trailing;
  final bool isDisplayOnProfile;

  const _AgentPromptCard({
    Key? key,
    required this.model,
    required this.type,
    this.trailing,
    required this.isDisplayOnProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define a simple payload structure for AgentPrompt
    // For example: {'promptText': 'The text of the prompt'}
    final promptText = model.eventPayload?['promptText'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                if (isDisplayOnProfile || model.user == null) return;
                Navigator.push(context, ProfilePage.getRoute(profileId: model.userId));
              },
              child: CircularImage(path: model.user?.profilePic),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          ConstrainedBox(
                            constraints: BoxConstraints(minWidth: 0, maxWidth: context.width * .4),
                            child: TitleText(model.user?.displayName ?? 'Unknown User',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 3),
                          model.user?.isVerified == true
                              ? customIcon(
                                  context,
                                  icon: AppIcon.blueTick,
                                  isTwitterIcon: true,
                                  iconColor: AppColor.primary,
                                  size: 13,
                                  paddingIcon: 3,
                                )
                              : const SizedBox.shrink(),
                          const SizedBox(width: 3),
                           Flexible(
                            child: customText(
                              '${model.user?.userName ?? ''}',
                              style: TextStyles.userNameStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          customText(
                            '· ${Utility.getChatTime(model.createdAt)}',
                            style: TextStyles.userNameStyle.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(child: trailing ?? const SizedBox.shrink()),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    customIcon(
                      context,
                      icon: AppIcon.bulb, // Using AppIcon.bulb as a placeholder for agent interaction
                      isTwitterIcon: false,
                      iconColor: Theme.of(context).textTheme.bodySmall!.color!,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    const TitleText("Agent Prompt", fontSize: 14, color: Colors.black54, fontWeight: FontWeight.normal),
                  ],
                ),
                if (promptText != null && promptText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: UrlText(
                      text: promptText,
                      style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w400),
                      urlStyle: const TextStyle(color: Colors.blue, fontSize: 15, fontWeight: FontWeight.w400),
                    ),
                  )
                else if (model.description != null && model.description!.isNotEmpty)
                  // Fallback to description if promptText is not in payload (for older data or general use)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: UrlText(
                      text: model.description!,
                      style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w400),
                      urlStyle: const TextStyle(color: Colors.blue, fontSize: 15, fontWeight: FontWeight.w400),
                    ),
                  ),
                SizedBox(height: model.childRetwetkey == null ? 8 : 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
  final TweetType type;
  final bool isDisplayOnProfile;
  final GlobalKey<ScaffoldState> scaffoldKey;
  const Tweet({
    Key? key,
    required this.model,
    this.trailing,
    this.type = TweetType.Tweet,
    this.isDisplayOnProfile = false,
    required this.scaffoldKey,
  }) : super(key: key);

  void onLongPressedTweet(BuildContext context) {
    if (type == TweetType.Detail || type == TweetType.ParentTweet) {
      Utility.copyToClipBoard(
          context: context,
          text: model.description ?? "",
          message: "Tweet copy to clipboard");
    }
  }

  void onTapTweet(BuildContext context) {
    var feedState = Provider.of<FeedState>(context, listen: false);
    if (type == TweetType.Detail || type == TweetType.ParentTweet) {
      return;
    }
    if (type == TweetType.Tweet && !isDisplayOnProfile) {
      feedState.clearAllDetailAndReplyTweetStack();
    }
    feedState.getPostDetailFromDatabase(null, model: model);
    Navigator.push(context, FeedPostDetail.getRoute(model.key!));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topLeft,
      children: <Widget>[
        /// Left vertical bar of a tweet
        type != TweetType.ParentTweet
            ? const SizedBox.shrink()
            : Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.only(
                    left: 38,
                    top: 75,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(width: 2.0, color: Colors.grey.shade400),
                    ),
                  ),
                ),
              ),
        InkWell(
          onLongPress: () {
            onLongPressedTweet(context);
          },
          onTap: () {
            onTapTweet(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(
                  top: type == TweetType.Tweet || type == TweetType.Reply
                      ? 12
                      : 0,
                ),
                child: type == TweetType.Tweet || type == TweetType.Reply
                    ? _TweetBody(
                        isDisplayOnProfile: isDisplayOnProfile,
                        model: model,
                        trailing: trailing,
                        type: type,
                      )
                    : _TweetDetailBody(
                        model: model,
                        trailing: trailing,
                        type: type,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: TweetImage(
                  model: model,
                  type: type,
                ),
              ),
              model.childRetwetkey == null
                  ? const SizedBox.shrink()
                  : RetweetWidget(
                      childRetwetkey: model.childRetwetkey!,
                      type: type,
                      isImageAvailable: model.imagePath != null &&
                          model.imagePath!.isNotEmpty,
                    ),
              Padding(
                padding:
                    EdgeInsets.only(left: type == TweetType.Detail ? 10 : 60),
                child: TweetIconsRow(
                  type: type,
                  model: model,
                  isTweetDetail: type == TweetType.Detail,
                  iconColor: Theme.of(context).textTheme.bodySmall!.color!,
                  iconEnableColor: TwitterColor.ceriseRed,
                  size: 20,
                  scaffoldKey: GlobalKey<ScaffoldState>(),
                ),
              ),
              type == TweetType.ParentTweet
                  ? const SizedBox.shrink()
                  : const Divider(height: .5, thickness: .5)
            ],
          ),
        ),
      ],
    );
  }
}

class _TweetBody extends StatelessWidget {
  final FeedModel model;
  final Widget? trailing;
  final TweetType type;
  final bool isDisplayOnProfile;
  const _TweetBody(
      {Key? key,
      required this.model,
      this.trailing,
      required this.type,
      required this.isDisplayOnProfile})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double descriptionFontSize = type == TweetType.Tweet
        ? 15
        : type == TweetType.Detail || type == TweetType.ParentTweet
            ? 18
            : 14;
    FontWeight descriptionFontWeight =
        type == TweetType.Tweet || type == TweetType.Tweet
            ? FontWeight.w400
            : FontWeight.w400;
    TextStyle textStyle = TextStyle(
        color: Colors.black,
        fontSize: descriptionFontSize,
        fontWeight: descriptionFontWeight);
    TextStyle urlStyle = TextStyle(
        color: Colors.blue,
        fontSize: descriptionFontSize,
        fontWeight: descriptionFontWeight);

    // Handle TrustDistributionEvent separately
    if (model.postType == PostTypes.TrustDistributionEvent) { // Using constant
      return _TrustDistributionEventCard(model: model, type: type, trailing: trailing, isDisplayOnProfile: isDisplayOnProfile,);
    } else if (model.postType == PostTypes.AgentPrompt) { // Handle AgentPrompt
      return _AgentPromptCard(model: model, type: type, trailing: trailing, isDisplayOnProfile: isDisplayOnProfile);
    } else if (model.postType == PostTypes.AgentReply) { // Handle AgentReply
      return _AgentReplyCard(model: model, type: type, trailing: trailing, isDisplayOnProfile: isDisplayOnProfile);
    } else if (model.postType == PostTypes.PropertyListing) { // Handle PropertyListing
      return _PropertyListingCard(model: model, type: type, trailing: trailing, isDisplayOnProfile: isDisplayOnProfile);
    }

    // Original Tweet Body Logic (now default)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(width: 10),
        SizedBox(
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              // If tweet is displaying on someone's profile then no need to navigate to same user's profile again.
              if (isDisplayOnProfile) {
                return;
              }
              Navigator.push(
                  context, ProfilePage.getRoute(profileId: model.userId));
            },
            child: CircularImage(path: model.user?.profilePic), // Added null check for model.user
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: context.width - 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        ConstrainedBox(
                          constraints: BoxConstraints(
                              minWidth: 0, maxWidth: context.width * .5),
                          child: TitleText(model.user?.displayName ?? 'Unknown User', // Added null check
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 3),
                        model.user?.isVerified == true // Added null check
                            ? customIcon(
                                context,
                                icon: AppIcon.blueTick,
                                isTwitterIcon: true,
                                iconColor: AppColor.primary,
                                size: 13,
                                paddingIcon: 3,
                              )
                            : const SizedBox(width: 0),
                        SizedBox(
                          width: model.user?.isVerified == true ? 5 : 0, // Added null check
                        ),
                        Flexible(
                          child: customText(
                            '${model.user?.userName ?? ''}', // Added null check
                            style: TextStyles.userNameStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        customText(
                          '· ${Utility.getChatTime(model.createdAt)}',
                          style:
                              TextStyles.userNameStyle.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(child: trailing ?? const SizedBox()),
                ],
              ),
              model.description == null
                  ? const SizedBox()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UrlText(
                          text: model.description!.removeSpaces,
                          onHashTagPressed: (tag) {
                            cprint(tag);
                          },
                          style: textStyle,
                          urlStyle: urlStyle,
                        ),
                      ],
                    ),
              if (model.imagePath == null && model.description != null)
                CustomLinkMediaInfo(text: model.description!),
            ],
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}

class _TrustDistributionEventCard extends StatelessWidget {
  final FeedModel model;
  final TweetType type;
  final Widget? trailing;
  final bool isDisplayOnProfile;

  const _TrustDistributionEventCard({
    Key? key,
    required this.model,
    required this.type,
    this.trailing,
    required this.isDisplayOnProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final payload = model.eventPayload;
    if (payload == null) {
      return const SizedBox.shrink(); // Or some error widget
    }

    final totalAmount = payload['totalAmount'] as double?;
    final sourceEvent = payload['sourceEvent'] as String?;
    final distributions = (payload['distributions'] as List<dynamic>?)
        ?.map((d) => d as Map<String, dynamic>)
        .toList();

    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                if (isDisplayOnProfile) return;
                Navigator.push(context, ProfilePage.getRoute(profileId: model.userId));
              },
              // Using a generic icon for TrustDistributionEvent
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.secondary.withAlpha(50),
                ),
                child: Icon(
                  AppIcon.transferIcon, // Placeholder, replace with a more suitable icon
                  color: Theme.of(context).colorScheme.secondary,
                  size: 20,
                ),
              )
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                     Expanded(
                      child: Row(
                        children: <Widget>[
                          TitleText("Trust Distribution", // Static title for this event type
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                           ),
                           const SizedBox(width: 3),
                           // No blue tick or username for this event type by default
                           const Spacer(), // Pushes time to the right
                           customText(
                            '· ${Utility.getChatTime(model.createdAt)}',
                            style: TextStyles.userNameStyle.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(child: trailing ?? const SizedBox()),
                  ],
                ),
                const SizedBox(height: 8),
                if (model.description != null && model.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(model.description!, style: TextStyles.textStyle14),
                  ),

                Text(
                  "Source: ${sourceEvent ?? 'N/A'}",
                  style: TextStyles.subtitleStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                if (totalAmount != null)
                  Text(
                    "Total Amount: ${currencyFormatter.format(totalAmount)}",
                    style: TextStyles.subtitleStyle.copyWith(fontWeight: FontWeight.bold, color: TwitterColor.bondyBlue),
                  ),
                const SizedBox(height: 8),
                if (distributions != null && distributions.isNotEmpty) ...[
                  const TitleText("Distributions:", fontSize: 14, fontWeight: FontWeight.w600),
                  const SizedBox(height: 4),
                  ...distributions.map((dist) {
                    final userId = dist['userId'] as String?;
                    final role = dist['role'] as String?;
                    final amount = dist['amount'] as double?;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 2, bottom: 2),
                      child: Text(
                        "${role ?? 'Unknown Role'} (${userId ?? 'N/A User'}): ${amount != null ? currencyFormatter.format(amount) : 'N/A'}",
                        style: TextStyles.textStyle14,
                      ),
                    );
                  }).toList(),
                ],
                SizedBox(height: model.childRetwetkey == null ? 8 : 0), // Add some padding if no retweet widget follows
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _TweetDetailBody extends StatelessWidget {
  final FeedModel model;
  final Widget? trailing;
  final TweetType type;
  const _TweetDetailBody({
    Key? key,
    required this.model,
    this.trailing,
    required this.type,
    /*this.isDisplayOnProfile*/
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double descriptionFontSize = type == TweetType.Tweet
        ? context.getDimension(context, 15)
        : type == TweetType.Detail
            ? context.getDimension(context, 18)
            : type == TweetType.ParentTweet
                ? context.getDimension(context, 14)
                : 10;

    FontWeight descriptionFontWeight =
        type == TweetType.Tweet || type == TweetType.Tweet
            ? FontWeight.w300
            : FontWeight.w400;
    TextStyle textStyle = TextStyle(
        color: Colors.black,
        fontSize: descriptionFontSize,
        fontWeight: descriptionFontWeight);
    TextStyle urlStyle = TextStyle(
        color: Colors.blue,
        fontSize: descriptionFontSize,
        fontWeight: descriptionFontWeight);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        model.parentkey != null &&
                model.childRetwetkey == null &&
                type != TweetType.ParentTweet
            ? ParentTweetWidget(
                childRetwetkey: model.parentkey!,
                trailing: trailing,
                type: type,
              )
            : const SizedBox.shrink(),
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context, ProfilePage.getRoute(profileId: model.userId));
                  },
                  child: CircularImage(path: model.user!.profilePic),
                ),
                title: Row(
                  children: <Widget>[
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          minWidth: 0, maxWidth: context.width * .5),
                      child: TitleText(model.user!.displayName!,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 3),
                    model.user!.isVerified!
                        ? customIcon(
                            context,
                            icon: AppIcon.blueTick,
                            isTwitterIcon: true,
                            iconColor: AppColor.primary,
                            size: 13,
                            paddingIcon: 3,
                          )
                        : const SizedBox(width: 0),
                    SizedBox(
                      width: model.user!.isVerified! ? 5 : 0,
                    ),
                  ],
                ),
                subtitle: customText('${model.user!.userName}',
                    style: TextStyles.userNameStyle),
                trailing: trailing,
              ),
              model.description == null
                  ? const SizedBox()
                  : Padding(
                      padding: type == TweetType.ParentTweet
                          ? const EdgeInsets.only(left: 80, right: 16)
                          : const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UrlText(
                              text: model.description!.removeSpaces,
                              onHashTagPressed: (tag) {
                                cprint(tag);
                              },
                              style: textStyle,
                              urlStyle: urlStyle),
                        ],
                      ),
                    ),
              if (model.imagePath == null && model.description != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustomLinkMediaInfo(text: model.description!),
                )
            ],
          ),
        ),
      ],
    );
  }
}
