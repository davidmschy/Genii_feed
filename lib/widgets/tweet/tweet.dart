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
import 'package:flutter_twitter_clone/widgets/post/genii_post_widget.dart'; // Import GeniiPostWidget
import 'package:flutter_twitter_clone/widgets/tweet/widgets/parentTweet.dart';
import 'package:flutter_twitter_clone/widgets/tweet/widgets/tweetIconsRow.dart';
import 'package:flutter_twitter_clone/widgets/url_text/customUrlText.dart';
import 'package:flutter_twitter_clone/widgets/url_text/custom_link_media_info.dart';
import 'package:provider/provider.dart';

import '../customWidgets.dart';
import 'widgets/retweetWidget.dart'; // Ensure these are here, they might have been pushed down
import 'widgets/tweetImage.dart'; // Ensure these are here
import 'widgets/retweetWidget.dart';
import 'widgets/tweetImage.dart';

class Tweet extends StatelessWidget {
  final FeedModel model;
  final Widget? trailing;
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

    final source = payload['source'] as String?; // e.g., "Zillow", "Airbnb", "Public Weather API"
    final title = payload['title'] as String?;
    final summary = payload['summary'] as String?;
    final url = payload['url'] as String?;
    // final data = payload['data'] as Map<String, dynamic>?; // For more complex data, not rendered by this generic card

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
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
                    AppIcon.link, // Generic icon for external link/API
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
                            child: TitleText(source ?? "External Update", // Show source or generic title
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
                    if (model.user != null) // If a user posted this (e.g. via an agent action)
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

          // External API Content
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

          // The 'data' field is not explicitly rendered here as it's generic.
          // Specific post types should be created if detailed rendering of 'data' is needed.

          const SizedBox(height: 8),
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

    final source = payload['source'] as String?; // e.g., "Zillow", "Airbnb", "Public Weather API"
    final title = payload['title'] as String?;
    final summary = payload['summary'] as String?;
    final url = payload['url'] as String?;
    // final data = payload['data'] as Map<String, dynamic>?; // For more complex data, not rendered by this generic card

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
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
                    AppIcon.link, // Generic icon for external link/API
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
                            child: TitleText(source ?? "External Update", // Show source or generic title
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
                    if (model.user != null) // If a user posted this (e.g. via an agent action)
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

          // External API Content
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

          // The 'data' field is not explicitly rendered here as it's generic.
          // Specific post types should be created if detailed rendering of 'data' is needed.

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
    final contactInfo = payload['contactInfo'] as String?; // Could be phone, email, or profile link
    final priceEstimate = payload['priceEstimate'] as String?; // e.g., "$50-100", "Quote Required"

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
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
                    AppIcon.settings, // Assuming an icon for services/tools
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
                    // Display who posted this update if it's a user (e.g. an agent found this match)
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

          // Service Match Details
          if (serviceType != null)
            _buildDetailRow(context, AppIcon.work, "Service:", serviceType, isBoldValue: true),

          if (providerName != null)
            _buildDetailRow(context, Icons.business_center_outlined, "Provider:", providerName),

          if (contactInfo != null)
            _buildDetailRow(context, Icons.contact_phone_outlined, "Contact:", contactInfo, isSelectable: true),

          if (priceEstimate != null && priceEstimate.isNotEmpty)
            _buildDetailRow(context, AppIcon.dollar, "Estimate:", priceEstimate),

          const SizedBox(height: 8),
          // Consider adding action buttons like "Contact Provider" or "View Profile"
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value, {bool isBoldValue = false, bool isSelectable = false}) {
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
    final percentComplete = (payload['percentComplete'] as num?)?.toDouble(); // Ensure it's a double

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
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
                    AppIcon.calender // Assuming an icon for tasks/calendar
                         ?? Icons.task_alt_outlined, // Fallback icon
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
                     // Display who posted this update if it's a user
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

          // Task Details
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

  // Helper to get status color
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
          // Header Row (Icon, Title, Timestamp, Trailing)
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
                    AppIcon.dollar, // Assuming an icon for loans/finance
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
                    // If model.user is the one who posted this update (e.g. an agent)
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

          // Loan Details
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
             _buildDetailRow(context, AppIcon.percent, "Interest Rate:", percentFormatter.format(interestRate / 100)), // Assuming rate is like 3.5 for 3.5%

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
    } else if (model.postType == PostTypes.LoanUpdate) { // Handle LoanUpdate
      return _LoanUpdateCard(model: model, type: type, trailing: trailing, isDisplayOnProfile: isDisplayOnProfile);
    } else if (model.postType == PostTypes.TaskUpdate) { // Handle TaskUpdate
      return _TaskUpdateCard(model: model, type: type, trailing: trailing, isDisplayOnProfile: isDisplayOnProfile);
    } else if (model.postType == PostTypes.ServiceMatch) { // Handle ServiceMatch
      return _ServiceMatchCard(model: model, type: type, trailing: trailing, isDisplayOnProfile: isDisplayOnProfile);
    } else if (model.postType == PostTypes.ExternalAPI) { // Handle ExternalAPI
      return _ExternalApiCard(model: model, type: type, trailing: trailing, isDisplayOnProfile: isDisplayOnProfile);
    }

    // _TweetBody is now simplified to use GeniiPostWidget
    return GeniiPostWidget(
      model: model,
      type: type,
      trailing: trailing,
      isDisplayOnProfile: isDisplayOnProfile,
    );
  }
}

// All individual card widgets (_TrustDistributionEventCard, _AgentPromptCard, etc.)
// have been moved to lib/widgets/post/genii_post_widget.dart
// The definitions below are now removed from this file.

/*
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
