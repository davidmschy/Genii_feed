import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/enum.dart';
import 'package:flutter_twitter_clone/helper/utility.dart';
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/ui/page/profile/profilePage.dart';
import 'package:flutter_twitter_clone/ui/page/profile/widgets/circular_image.dart';
import 'package:flutter_twitter_clone/ui/theme/theme.dart';
import 'package:flutter_twitter_clone/widgets/newWidget/title_text.dart';
import 'package:flutter_twitter_clone/widgets/url_text/customUrlText.dart';
import 'package:flutter_twitter_clone/widgets/customWidgets.dart';
import 'package:intl/intl.dart';
import 'package:flutter_twitter_clone/widgets/cache_image.dart';
import 'package:url_launcher/url_launcher.dart';

// It's good practice to move shared helper methods or enums to their own files if they grow.
// For now, card-specific helpers can be private static methods or part of the card widgets.

class GeniiPostWidget extends StatelessWidget {
  final FeedModel model;
  final TweetType type; // This 'TweetType' might need to be re-evaluated or made more generic for GeniiPost context
  final Widget? trailing;
  final bool isDisplayOnProfile;

  const GeniiPostWidget({
    Key? key,
    required this.model,
    required this.type, //TODO: Re-evaluate if TweetType is still the best enum here or if we need a GeniiPostDisplayContext
    this.trailing,
    required this.isDisplayOnProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Main dispatcher logic based on model.postType
    switch (model.postType) {
      case PostTypes.TrustDistributionEvent:
        return _TrustDistributionEventCard(model: model, type: type, trailing: trailing, isDisplayOnProfile: isDisplayOnProfile);
      case PostTypes.AgentPrompt:
        return _AgentPromptCard(model: model, type: type, trailing: trailing, isDisplayOnProfile: isDisplayOnProfile);
      case PostTypes.AgentReply:
        return _AgentReplyCard(model: model, type: type, trailing: trailing, isDisplayOnProfile: isDisplayOnProfile);
      case PostTypes.PropertyListing:
        return _PropertyListingCard(model: model, type: type, trailing: trailing, isDisplayOnProfile: isDisplayOnProfile);
      case PostTypes.LoanUpdate:
        return _LoanUpdateCard(model: model, type: type, trailing: trailing, isDisplayOnProfile: isDisplayOnProfile);
      case PostTypes.TaskUpdate:
        return _TaskUpdateCard(model: model, type: type, trailing: trailing, isDisplayOnProfile: isDisplayOnProfile);
      case PostTypes.ServiceMatch:
        return _ServiceMatchCard(model: model, type: type, trailing: trailing, isDisplayOnProfile: isDisplayOnProfile);
      case PostTypes.ExternalAPI:
        return _ExternalApiCard(model: model, type: type, trailing: trailing, isDisplayOnProfile: isDisplayOnProfile);

      case PostTypes.Tweet: // Explicitly handle default tweet type
      default: // Fallback for unknown types or standard Tweet
        return _DefaultTweetCard(model: model, type: type, trailing: trailing, isDisplayOnProfile: isDisplayOnProfile);
    }
  }
}

// Placeholder for the original tweet rendering logic (will be moved from _TweetBody)
class _DefaultTweetCard extends StatelessWidget {
  final FeedModel model;
  final TweetType type;
  final Widget? trailing;
  final bool isDisplayOnProfile;

  const _DefaultTweetCard({
    Key? key,
    required this.model,
    required this.type,
    this.trailing,
    required this.isDisplayOnProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Logic moved from _TweetBody in lib/widgets/tweet/tweet.dart
    double descriptionFontSize = type == TweetType.Tweet
        ? 15
        : type == TweetType.Detail || type == TweetType.ParentTweet
            ? 18
            : 14; // This 'type' (TweetType) might need to be adapted if GeniiPostWidget handles different display contexts beyond simple feed view
    FontWeight descriptionFontWeight =
        type == TweetType.Tweet || type == TweetType.Tweet // Same as above for 'type'
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(width: 10),
        SizedBox(
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              if (isDisplayOnProfile || model.user == null) {
                return;
              }
              Navigator.push(
                  context, ProfilePage.getRoute(profileId: model.userId));
            },
            child: CircularImage(path: model.user?.profilePic),
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: MediaQuery.of(context).size.width - 80, // Using MediaQuery for width
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
                              minWidth: 0, maxWidth: MediaQuery.of(context).size.width * .5), // Using MediaQuery for width
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
                            : const SizedBox(width: 0),
                        SizedBox(
                          width: model.user?.isVerified == true ? 5 : 0,
                        ),
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
                          style:
                              TextStyles.userNameStyle.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(child: trailing ?? const SizedBox()),
                ],
              ),
              if (model.description != null && model.description!.isNotEmpty)
                Padding( // Added padding for description
                  padding: const EdgeInsets.only(top: 6.0),
                  child: UrlText(
                    text: model.description!.removeSpaces,
                    onHashTagPressed: (tag) {
                      cprint(tag);
                    },
                    style: textStyle,
                    urlStyle: urlStyle,
                  ),
                ),
              // CustomLinkMediaInfo was part of original _TweetBody,
              // it might be relevant if standard tweets can have link previews.
              // if (model.imagePath == null && model.description != null)
              //   CustomLinkMediaInfo(text: model.description!),
            ],
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}

// NOTE: The individual card widgets (_TrustDistributionEventCard, _AgentPromptCard, etc.)
// need to be moved here from lib/widgets/tweet/tweet.dart or be made accessible.
// For this step, I'll assume they are moved here.
// The following are placeholders indicating they need to be defined/moved into this file.

// Example of how one card would look if moved here (structure only):
// class _TrustDistributionEventCard extends StatelessWidget { ... }
// class _AgentPromptCard extends StatelessWidget { ... }
// ... and so on for all other custom cards.
// For the actual implementation, I will copy-paste them from tweet.dart into this file.

// [Card Widget Definitions will be pasted here from tweet.dart]
// _TrustDistributionEventCard, _AgentPromptCard, _AgentReplyCard,
// _PropertyListingCard, _LoanUpdateCard, _TaskUpdateCard,
// _ServiceMatchCard, _ExternalApiCard
// will be defined below this comment.

// --- START OF COPIED WIDGETS (with necessary imports already at top of file) ---

// Copied from lib/widgets/tweet/tweet.dart and made private to this file or part of GeniiPostWidget context

class _TrustDistributionEventCard extends StatelessWidget {
  final FeedModel model;
  final TweetType type; // Consider if this is still needed or should be adapted
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
      return const SizedBox.shrink();
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
                if (isDisplayOnProfile || model.user == null) return; // Check user null
                Navigator.push(context, ProfilePage.getRoute(profileId: model.userId));
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.secondary.withAlpha(50),
                ),
                child: Icon(
                  AppIcon.transferIcon,
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
                          TitleText("Trust Distribution",
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                           ),
                           const SizedBox(width: 3),
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
  final TweetType type;
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
                      icon: AppIcon.bulb,
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
    final agentName = model.user?.displayName ?? "AI Agent";
    final agentUserName = model.user?.userName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColor.mystic
      ),
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
              child: model.user?.profilePic != null && model.user!.profilePic!.isNotEmpty
                  ? CircularImage(path: model.user!.profilePic)
                  : Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.secondary.withAlpha(100),
                      ),
                      child: Icon(
                        AppIcon.bulb,
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
                          if (agentUserName != null && agentUserName.isNotEmpty) ...[
                            const SizedBox(width: 3),
                            Flexible(
                              child: customText(
                                '@$agentUserName',
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
                      icon: AppIcon.reply,
                      isTwitterIcon: false,
                      iconColor: Theme.of(context).textTheme.bodySmall!.color!,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    const TitleText("Agent Reply", fontSize: 14, color: Colors.black54, fontWeight: FontWeight.normal),
                  ],
                ),
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
      return const SizedBox.shrink();
    }

    final address = payload['address'] as String?;
    final price = payload['price'] as num?;
    final bedrooms = payload['bedrooms'] as int?;
    final bathrooms = payload['bathrooms'] as num?;
    final sqft = payload['sqft'] as num?;
    final imageUrl = payload['imageUrl'] as String?;
    final source = payload['source'] as String?;

    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final numberFormatter = NumberFormat.decimalPattern();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
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
                  child: model.user?.profilePic != null && model.user!.profilePic!.isNotEmpty
                      ? CircularImage(path: model.user!.profilePic)
                      : Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary.withAlpha(50),
                          ),
                          child: Icon(
                            AppIcon.home,
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
                     if(model.user != null && source != null)
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

          if (imageUrl != null && imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: CachedNetworkImage( // Assuming you have cached_network_image package
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                  placeholder: (context, url) => Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                     height: 180,
                    color: Colors.grey[300],
                    child: Icon(Icons.error, color: Colors.red[400]),
                  ),
                ),
              ),
            ),

          if (address != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(address, style: TextStyles.titleStyle.copyWith(fontSize: 17)),
            ),

          if (price != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(currencyFormatter.format(price), style: TextStyles.headline5.copyWith(color: TwitterColor.bondyBlue, fontWeight: FontWeight.bold)),
            ),

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
                Icon(AppIcon.bath, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 4),
                Text('${numberFormatter.format(bathrooms)} bath${bathrooms > 1 ? 's' : ''}', style: TextStyles.subtitleStyle),
                const SizedBox(width: 12),
              ],
              if (sqft != null) ...[
                 Icon(AppIcon.squareFoot, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 4),
                Text('${numberFormatter.format(sqft)} sqft', style: TextStyles.subtitleStyle),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LoanUpdateCard extends StatelessWidget {
  final FeedModel model;
  final TweetType type;
  final Widget? trailing;
  final bool isDisplayOnProfile;

  const _LoanUpdateCard({
    Key? key,
    required this.model,
    required this.type,
    this.trailing,
    required this.isDisplayOnProfile,
  }) : super(key: key);

  Color _getStatusColor(String? status) {
    status = status?.toLowerCase();
    if (status == 'approved' || status == 'funded') {
      return Colors.green.shade700;
    } else if (status == 'pending' || status == 'under review') {
      return Colors.orange.shade700;
    } else if (status == 'rejected' || status == 'denied') {
      return Colors.red.shade700;
    }
    return Colors.grey.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final payload = model.eventPayload;
    if (payload == null) {
      return const SizedBox.shrink();
    }

    final lenderName = payload['lenderName'] as String?;
    final status = payload['status'] as String?;
    final amount = payload['amount'] as num?;
    final termInMonths = payload['termInMonths'] as int?;
    final interestRate = payload['interestRate'] as double?;
    final note = payload['note'] as String?;

    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final percentFormatter = NumberFormat.percentPattern(locale: 'en_US');


    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary.withAlpha(50),
                  ),
                  child: Icon(
                    AppIcon.dollar,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
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
                            child: TitleText("Loan Update",
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                overflow: TextOverflow.ellipsis),
                          ),
                          customText(
                            '· ${Utility.getChatTime(model.createdAt)}',
                            style: TextStyles.userNameStyle.copyWith(fontSize: 12),
                          ),
                          Container(child: trailing ?? const SizedBox.shrink()),
                        ],
                      ),
                    if (lenderName != null)
                      Text(lenderName, style: TextStyles.subtitleStyle),
                    if (model.user != null && model.user?.displayName != lenderName)
                       customText(
                        'Posted by: @${model.user!.userName}',
                        style: TextStyles.userNameStyle.copyWith(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (status != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text("Status: ", style: TextStyles.titleStyle.copyWith(fontSize: 15)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(status), width: 1)
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyles.subtitleStyle.copyWith(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          if (amount != null)
            _buildDetailRow(context, AppIcon.money, "Amount:", currencyFormatter.format(amount)),

          if (interestRate != null)
             _buildDetailRow(context, AppIcon.percent, "Interest Rate:", percentFormatter.format(interestRate / 100)),

          if (termInMonths != null)
            _buildDetailRow(context, AppIcon.calendar, "Term:", "$termInMonths months"),

          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text("Note:", style: TextStyles.titleStyle.copyWith(fontSize: 15)),
            const SizedBox(height: 4),
            Text(note, style: TextStyles.textStyle14),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(label, style: TextStyles.subtitleStyle.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Expanded(child: Text(value, style: TextStyles.subtitleStyle, textAlign: TextAlign.end,)),
        ],
      ),
    );
  }
}

class _TaskUpdateCard extends StatelessWidget {
  final FeedModel model;
  final TweetType type;
  final Widget? trailing;
  final bool isDisplayOnProfile;

  const _TaskUpdateCard({
    Key? key,
    required this.model,
    required this.type,
    this.trailing,
    required this.isDisplayOnProfile,
  }) : super(key: key);

  Color _getStatusColor(String? status) {
    status = status?.toLowerCase();
    if (status == 'completed' || status == 'done') {
      return Colors.green.shade700;
    } else if (status == 'in progress' || status == 'active') {
      return Colors.blue.shade700;
    } else if (status == 'pending' || status == 'todo' || status == 'to do') {
      return Colors.orange.shade700;
    } else if (status == 'blocked' || status == 'on hold') {
      return Colors.red.shade700;
    }
    return Colors.grey.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final payload = model.eventPayload;
    if (payload == null) {
      return const SizedBox.shrink();
    }

    final taskName = payload['taskName'] as String?;
    final status = payload['status'] as String?;
    final contractorName = payload['contractorName'] as String?;
    final percentComplete = (payload['percentComplete'] as num?)?.toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary.withAlpha(50),
                  ),
                  child: Icon(
                    AppIcon.calender
                         ?? Icons.task_alt_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
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
                            child: TitleText("Task Update",
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                overflow: TextOverflow.ellipsis),
                          ),
                          customText(
                            '· ${Utility.getChatTime(model.createdAt)}',
                            style: TextStyles.userNameStyle.copyWith(fontSize: 12),
                          ),
                          Container(child: trailing ?? const SizedBox.shrink()),
                        ],
                      ),
                    if (model.user != null)
                       customText(
                        'Update by: @${model.user!.userName}',
                        style: TextStyles.userNameStyle.copyWith(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (taskName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(taskName, style: TextStyles.titleStyle.copyWith(fontSize: 17)),
            ),

          if (status != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text("Status: ", style: TextStyles.textStyle14.copyWith(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                       border: Border.all(color: _getStatusColor(status).withAlpha(100), width: 0.5)
                    ),
                    child: Text(
                      status,
                      style: TextStyles.textStyle12.copyWith(color: _getStatusColor(status), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          if (contractorName != null && contractorName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 6),
                  Text("Assigned to: ", style: TextStyles.textStyle14.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(contractorName, style: TextStyles.textStyle14)),
                ],
              ),
            ),

          if (percentComplete != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0, top: 4.0),
              child: Text("Progress: ${(percentComplete * 100).toStringAsFixed(0)}%", style: TextStyles.textStyle14.copyWith(fontWeight: FontWeight.bold)),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentComplete,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentComplete >= 1.0 ? Colors.green :
                  percentComplete > 0.7 ? Colors.blue :
                  percentComplete > 0.3 ? Colors.orange : Colors.red.shade300
                ),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ServiceMatchCard extends StatelessWidget {
  final FeedModel model;
  final TweetType type;
  final Widget? trailing;
  final bool isDisplayOnProfile;

  const _ServiceMatchCard({
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
      return const SizedBox.shrink();
    }

    final serviceType = payload['serviceType'] as String?;
    final providerName = payload['providerName'] as String?;
    final contactInfo = payload['contactInfo'] as String?;
    final priceEstimate = payload['priceEstimate'] as String?;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary.withAlpha(50),
                  ),
                  child: Icon(
                    AppIcon.settings,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
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
                            child: TitleText("Service Match",
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                overflow: TextOverflow.ellipsis),
                          ),
                          customText(
                            '· ${Utility.getChatTime(model.createdAt)}',
                            style: TextStyles.userNameStyle.copyWith(fontSize: 12),
                          ),
                          Container(child: trailing ?? const SizedBox.shrink()),
                        ],
                      ),
                    if (model.user != null)
                       customText(
                        'Match found by: @${model.user!.userName}',
                        style: TextStyles.userNameStyle.copyWith(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (serviceType != null)
            _buildDetailRowSM(context, AppIcon.work, "Service:", serviceType, isBoldValue: true),

          if (providerName != null)
            _buildDetailRowSM(context, Icons.business_center_outlined, "Provider:", providerName),

          if (contactInfo != null)
            _buildDetailRowSM(context, Icons.contact_phone_outlined, "Contact:", contactInfo, isSelectable: true),

          if (priceEstimate != null && priceEstimate.isNotEmpty)
            _buildDetailRowSM(context, AppIcon.dollar, "Estimate:", priceEstimate),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDetailRowSM(BuildContext context, IconData icon, String label, String value, {bool isBoldValue = false, bool isSelectable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Text(label, style: TextStyles.subtitleStyle.copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(width: 6),
          Expanded(
            child: isSelectable
                ? SelectableText(value, style: TextStyles.subtitleStyle.copyWith(fontSize: 15, fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal))
                : Text(value, style: TextStyles.subtitleStyle.copyWith(fontSize: 15, fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal)),
          ),
        ],
      ),
    );
  }
}

class _ExternalApiCard extends StatelessWidget {
  final FeedModel model;
  final TweetType type;
  final Widget? trailing;
  final bool isDisplayOnProfile;

  const _ExternalApiCard({
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
      return const SizedBox.shrink();
    }

    final source = payload['source'] as String?;
    final title = payload['title'] as String?;
    final summary = payload['summary'] as String?;
    final url = payload['url'] as String?;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.secondary.withAlpha(50),
                  ),
                  child: Icon(
                    AppIcon.link,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 20,
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
                            child: TitleText(source ?? "External Update",
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                overflow: TextOverflow.ellipsis),
                          ),
                          customText(
                            '· ${Utility.getChatTime(model.createdAt)}',
                            style: TextStyles.userNameStyle.copyWith(fontSize: 12),
                          ),
                          Container(child: trailing ?? const SizedBox.shrink()),
                        ],
                      ),
                    if (model.user != null)
                       customText(
                        'Triggered by: @${model.user!.userName}',
                        style: TextStyles.userNameStyle.copyWith(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (title != null && title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(title, style: TextStyles.titleStyle.copyWith(fontSize: 17)),
            ),

          if (summary != null && summary.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(summary, style: TextStyles.textStyle14, maxLines: 3, overflow: TextOverflow.ellipsis,),
            ),

          if (url != null && url.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () async {
                  // ignore: deprecated_member_use
                  if (await canLaunch(url)) {
                    // ignore: deprecated_member_use
                    await launch(url);
                  } else {
                    cprint('Could not launch $url');
                     ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not launch URL: $url')),
                      );
                  }
                },
                child: Text(
                  url,
                  style: TextStyles.textStyle14.copyWith(color: TwitterColor.bondyBlue, decoration: TextDecoration.underline),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// --- END OF COPIED WIDGETS ---
