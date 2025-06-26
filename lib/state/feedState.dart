import 'dart:async';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/firebase_database.dart' as database;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_twitter_clone/helper/enum.dart';
import 'package:flutter_twitter_clone/helper/shared_prefrence_helper.dart';
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/helper/utility.dart';
import 'package:flutter_twitter_clone/model/user.dart';
import 'package:flutter_twitter_clone/state/appState.dart';
import 'package:flutter_twitter_clone/ui/page/common/locator.dart';
// import 'package:link_preview_generator/link_preview_generator.dart'
//     show WebInfo;
import 'package:path/path.dart' as path;
import 'package:translator/translator.dart';

class FeedState extends AppState {
  bool isBusy = false;
  Map<String, List<FeedModel>?>? tweetReplyMap = {};
  FeedModel? _tweetToReplyModel;
  FeedModel? get tweetToReplyModel => _tweetToReplyModel;
  set setTweetToReply(FeedModel model) {
    _tweetToReplyModel = model;
  }

  late List<FeedModel> _commentList;

  List<FeedModel>? _feedList;
  database.Query? _feedQuery;
  List<FeedModel>? _tweetDetailModelList; // This seems to be for detail view, not the main list

  List<FeedModel>? get tweetDetailModel => _tweetDetailModelList; // Retaining for compatibility if used elsewhere

  // Filtering states
  String? _propertyFilterId;
  String? _roleFilter; // User's current active role for filtering
  String? _agentFilterId;
  String? _postTypeFilter;

  // Getters for filters (optional, mainly for external read if needed)
  String? get propertyFilterId => _propertyFilterId;
  String? get roleFilter => _roleFilter;
  String? get agentFilterId => _agentFilterId;
  String? get postTypeFilter => _postTypeFilter;

  // Setters for filters
  void setPropertyFilter(String? propertyId) {
    _propertyFilterId = propertyId;
    notifyListeners(); // Trigger list refresh
  }

  void setRoleFilter(String? role) {
    _roleFilter = role;
    notifyListeners();
  }

  void setAgentFilter(String? agentId) {
    _agentFilterId = agentId;
    notifyListeners();
  }

  void setPostTypeFilter(String? postType) {
    _postTypeFilter = postType;
    notifyListeners();
  }

  void clearFilters() {
    _propertyFilterId = null;
    _roleFilter = null;
    _agentFilterId = null;
    _postTypeFilter = null;
    notifyListeners();
  }

  /// `feedList` always [contain all GeniiPosts] fetched from firebase database
  /// This is the raw, unfiltered list, reversed by time.
  List<FeedModel>? get rawFeedList {
    if (_feedList == null) {
      return null;
    } else {
      return List.from(_feedList!.reversed); // Newest first
    }
  }

  /// Contain GeniiPost list for home page, applying current filters.
  /// Renamed from getTweetList to getPostList.
  List<FeedModel>? getPostList(UserModel? currentUser) {
    if (rawFeedList == null || rawFeedList!.isEmpty) {
      return null;
    }

    List<FeedModel> postsToFilter = List.from(rawFeedList!);
    List<FeedModel> filteredList = [];

    // Apply conceptual filters first (Property, Agent, specific PostType)
    // These are still conceptual and will be implemented fully later.
    // For now, they print to console. If they were active, they'd modify 'postsToFilter'.
    if (_propertyFilterId != null) {
      postsToFilter = postsToFilter.where((post) => post.propertyId == _propertyFilterId).toList();
      cprint("Filtering by property ID: $_propertyFilterId");
    }
    if (_postTypeFilter != null) {
      postsToFilter = postsToFilter.where((post) => post.postType == _postTypeFilter).toList();
      cprint("Filtering by post type: $_postTypeFilter");
    }
    if (_agentFilterId != null) {
      postsToFilter = postsToFilter.where((post) => post.agentId == _agentFilterId).toList();
      cprint("Filtering by agent ID: $_agentFilterId");
    }

    // Apply Role-Based Filtering
    final String? activeRole = currentUser?.currentRole;

    if (activeRole == null) {
      // If no role is active, show all non-role-specific posts or a limited set.
      // For now, let's assume it shows posts that are not explicitly role-restricted,
      // or perhaps just 'Tweet' and 'PropertyListing' as a default.
      // This behavior can be refined.
      // filteredList = postsToFilter.where((post) {
      //   return post.postType == PostTypes.Tweet || post.postType == PostTypes.PropertyListing;
      // }).toList();
      // For simplicity in this step, if no role, show all from `postsToFilter`
      filteredList.addAll(postsToFilter);
      cprint("No active role, showing all posts after conceptual filters.");
    } else {
      cprint("Filtering for role: $activeRole");
      Map<String, List<String>> rolePermissions = {
        UserRoles.Owner: [// All types are visible to Owner
          PostTypes.PropertyListing, PostTypes.LoanUpdate, PostTypes.AgentPrompt,
          PostTypes.AgentReply, PostTypes.TaskUpdate, PostTypes.CashFlowEvent,
          PostTypes.ExternalAPI, PostTypes.ServiceMatch, PostTypes.TrustDistributionEvent, PostTypes.Tweet
        ],
        UserRoles.Agent: [
          PostTypes.AgentPrompt, PostTypes.AgentReply, PostTypes.PropertyListing, PostTypes.TaskUpdate
        ],
        UserRoles.Investor: [
          PostTypes.PropertyListing, PostTypes.TrustDistributionEvent, PostTypes.LoanUpdate, PostTypes.CashFlowEvent
        ],
        UserRoles.Contractor: [
          PostTypes.TaskUpdate, PostTypes.ServiceMatch
        ],
        UserRoles.Lender: [
          PostTypes.LoanUpdate, PostTypes.TrustDistributionEvent, PostTypes.CashFlowEvent
        ],
        // Tenant and Manufacturer roles can be added here if they have specific views
         UserRoles.Tenant: [ // Example: Tenants might see property announcements or service updates
            PostTypes.PropertyListing, // General property info they might be interested in
            // Potentially a new PostType like "Announcement" or relevant "ServiceMatch"
        ],
        UserRoles.Manufacturer: [ // Example: Might see requests for proposals or specific supply chain tasks
            // Potentially new PostTypes like "SupplyRequest" or relevant "TaskUpdate"
        ],
      };

      List<String>? allowedTypes = rolePermissions[activeRole];

      if (activeRole == UserRoles.Owner) { // Owner sees all
        filteredList.addAll(postsToFilter);
      } else if (allowedTypes != null) {
        filteredList.addAll(postsToFilter.where((post) {
          return allowedTypes.contains(post.postType);
          // Additionally, more granular checks can be added here:
          // e.g., for a Contractor, only show TaskUpdates where post.payload['contractorId'] == currentUser.userId
          // e.g., for an Agent, only show AgentPrompts/Replies relevant to them (post.agentId == currentUser.userId)
          // For now, it's a simple postType check.
        }));
      } else {
        // Role not in map or has no specific permissions defined, show nothing or a default set.
        // For now, show nothing if role has no explicit permissions (except Owner).
         cprint("Role $activeRole has no specific post types defined, showing no posts.");
      }
    }

    // Original logic from getTweetList (related to comments and specific user posts) - RE-EVALUATE
    // This might need re-evaluation in the context of GeniiPosts.
    // For now, I'm commenting it out as the new filters take precedence for this step.
    /*
    if (currentUser != null) {
      filteredList = filteredList.where((x) {
        /// If Post is a comment then no need to add it in main feed list (unless it's a reply to a prompt?)
        if (x.parentkey != null && x.childRetwetkey == null && x.user!.userId != currentUser.userId) {
          // This logic might change depending on how replies/comments work for GeniiPosts
          // return false;
        }
        return true;
      }).toList();
    }
    */

    if (filteredList.isEmpty) {
      return null;
    }

    return filteredList;
  }

  Map<String, dynamic> _linkWebInfos = {};
  Map<String, dynamic> get linkWebInfos => _linkWebInfos;
  void addWebInfo(String url, dynamic webInfo) {
    _linkWebInfos.addAll({url: webInfo});
  }

  Map<String, Translation?> _tweetsTranslations = {};
  Map<String, Translation?> get tweetsTranslations => _tweetsTranslations;
  void addTweetTranslation(String tweet, Translation? translation) {
    _tweetsTranslations.addAll({tweet: translation});
    notifyListeners();
  }

  /// set tweet for detail tweet page
  /// Setter call when tweet is tapped to view detail
  /// Add Tweet detail is added in _tweetDetailModelList
  /// It makes `Fwitter` to view nested Tweets
  set setFeedModel(FeedModel model) {
    _tweetDetailModelList ??= [];

    /// [Skip if any duplicate tweet already present]

    _tweetDetailModelList!.add(model);
    cprint("Detail Tweet added. Total Tweet: ${_tweetDetailModelList!.length}");
    notifyListeners();
  }

  /// `remove` last Tweet from tweet detail page stack
  /// Function called when navigating back from a Tweet detail
  /// `_tweetDetailModelList` is map which contain lists of comment Tweet list
  /// After removing Tweet from Tweet detail Page stack its comments tweet is also removed from `_tweetDetailModelList`
  void removeLastTweetDetail(String tweetKey) {
    if (_tweetDetailModelList != null && _tweetDetailModelList!.isNotEmpty) {
      // var index = _tweetDetailModelList.in
      FeedModel removeTweet =
          _tweetDetailModelList!.lastWhere((x) => x.key == tweetKey);
      _tweetDetailModelList!.remove(removeTweet);
      tweetReplyMap?.removeWhere((key, value) => key == tweetKey);
      cprint(
          "Last index Tweet removed from list. Remaining Tweet: ${_tweetDetailModelList!.length}");
      notifyListeners();
    }
  }

  /// [clear all tweets] if any tweet present in tweet detail page or comment tweet
  void clearAllDetailAndReplyTweetStack() {
    if (_tweetDetailModelList != null) {
      _tweetDetailModelList!.clear();
    }
    if (tweetReplyMap != null) {
      tweetReplyMap!.clear();
    }
    cprint('Empty tweets from stack');
  }

  /// [Subscribe Tweets] firebase Database
  Future<bool> databaseInit() {
    try {
      if (_feedQuery == null) {
        // Reading from "geniiPosts" instead of "tweet"
        _feedQuery = kDatabase.child("geniiPosts");
        _feedQuery!.onChildAdded.listen(_onTweetAdded);
        _feedQuery!.onChildChanged.listen(_onTweetChanged);
        _feedQuery!.onChildRemoved.listen(_onTweetRemoved);
      }

      return Future.value(true);
    } catch (error) {
      cprint(error, errorIn: 'databaseInit');
      return Future.value(false);
    }
  }

  /// get [Post list] from firebase realtime database (formerly Tweet list)
  void getDataFromDatabase() {
    try {
      isBusy = true;
      _feedList = null;
      notifyListeners();
      // Reading from "geniiPosts" instead of "tweet"
      kDatabase.child('geniiPosts').once().then((DatabaseEvent event) {
        final snapshot = event.snapshot;
        _feedList = <FeedModel>[];
        if (snapshot.value != null) {
          var map = snapshot.value as Map<dynamic, dynamic>?;
          if (map != null) {
            map.forEach((key, value) {
              var model = FeedModel.fromJson(value);
              model.key = key;
              // Assuming isValidTweet is still relevant or will be adapted
              // For TrustDistributionEvent, user might be null or a system user.
              // The isValidTweet check might need adjustment if it heavily relies on user details not present in these events.
              // For now, we keep it to see if it causes issues.
              // A TrustDistributionEvent might not have a user in the same way a tweet does.
              // Let's refine `isValidTweet` or ensure `user` is populated for these events.
              // The TrustPaymentEngine currently assigns a mock user.
              if (model.isValidTweet) {
                _feedList!.add(model);
              } else {
                // If isValidTweet is false, we might still want to add it if it's a valid GeniiPost type
                if (model.postType == "TrustDistributionEvent" && model.eventPayload != null) {
                  // Potentially add custom validation for TrustDistributionEvent here
                  // For now, let's add it if it's the correct type, assuming payload makes it valid.
                  cprint("Adding TrustDistributionEvent that failed isValidTweet check, but seems valid: ${model.key}");
                  _feedList!.add(model);
                } else {
                  cprint("Skipping invalid model: ${model.key}, type: ${model.postType}");
                }
              }
            });

            /// Sort Post by time
            /// It helps to display newest Post first.
            _feedList!.sort((x, y) => DateTime.parse(x.createdAt)
                .compareTo(DateTime.parse(y.createdAt)));
          }
        } else {
          _feedList = null;
        }
        isBusy = false;
        notifyListeners();
      });
    } catch (error) {
      isBusy = false;
      cprint(error, errorIn: 'getDataFromDatabase');
    }
  }

  /// get [Post Detail] from firebase realtime kDatabase (formerly Tweet Detail)
  /// If model is null then fetch tweet from firebase
  /// [getPostDetailFromDatabase] is used to set prepare Tweet to display Tweet detail
  /// After getting tweet detail fetch tweet comments from firebase
  void getPostDetailFromDatabase(String? postID, {FeedModel? model}) async {
    try {
      FeedModel? _tweetDetail;
      if (model != null) {
        // set tweet data from tweet list data.
        // No need to fetch tweet from firebase db if data already present in tweet list
        _tweetDetail = model;
        setFeedModel = _tweetDetail;
        postID = model.key;
      } else {
        assert(postID != null);
        // Fetch tweet data from firebase
        kDatabase
            .child('tweet')
            .child(postID!)
            .once()
            .then((DatabaseEvent event) {
          final snapshot = event.snapshot;
          if (snapshot.value != null) {
            var map = snapshot.value as Map<dynamic, dynamic>;
            _tweetDetail = FeedModel.fromJson(map);
            _tweetDetail!.key = snapshot.key!;
            setFeedModel = _tweetDetail!;
          }
        });
      }

      if (_tweetDetail != null) {
        // Fetch comment tweets
        _commentList = <FeedModel>[];
        // Check if parent tweet has reply tweets or not
        if (_tweetDetail!.replyTweetKeyList != null &&
            _tweetDetail!.replyTweetKeyList!.isNotEmpty) {
          for (String? x in _tweetDetail!.replyTweetKeyList!) {
            if (x == null) {
              return;
            }
            kDatabase
                .child('tweet')
                .child(x)
                .once()
                .then((DatabaseEvent event) {
              final snapshot = event.snapshot;
              if (snapshot.value != null) {
                var commentModel = FeedModel.fromJson(snapshot.value as Map);
                String key = snapshot.key!;
                commentModel.key = key;

                /// add comment tweet to list if tweet is not present in [comment tweet ]list
                /// To reduce delicacy
                if (!_commentList.any((x) => x.key == key)) {
                  _commentList.add(commentModel);
                }
              } else {}
              if (x == _tweetDetail!.replyTweetKeyList!.last) {
                /// Sort comment by time
                /// It helps to display newest Tweet first.
                _commentList.sort((x, y) => DateTime.parse(y.createdAt)
                    .compareTo(DateTime.parse(x.createdAt)));
                tweetReplyMap!.putIfAbsent(postID!, () => _commentList);
                notifyListeners();
              }
            });
          }
        } else {
          tweetReplyMap!.putIfAbsent(postID!, () => _commentList);
          notifyListeners();
        }
      }
    } catch (error) {
      cprint(error, errorIn: 'getPostDetailFromDatabase');
    }
  }

  /// Fetch `Retweet` model from firebase realtime kDatabase.
  /// Retweet itself  is a type of `Tweet`
  Future<FeedModel?> fetchTweet(String postID) async {
    FeedModel? _tweetDetail;

    /// If tweet is available in feedList then no need to fetch it from firebase
    if (feedList!.any((x) => x.key == postID)) {
      _tweetDetail = feedList!.firstWhere((x) => x.key == postID);
    }

    /// If tweet is not available in feedList then need to fetch it from firebase
    else {
      cprint("Fetched from DB: " + postID);
      var model = await kDatabase.child('tweet').child(postID).once().then(
        (DatabaseEvent event) {
          final snapshot = event.snapshot;
          if (snapshot.value != null) {
            var map = snapshot.value as Map<dynamic, dynamic>;
            _tweetDetail = FeedModel.fromJson(map);
            _tweetDetail!.key = snapshot.key!;
            print(_tweetDetail!.description);
          }
        },
      );
      if (model != null) {
        _tweetDetail = model;
      } else {
        cprint("Fetched null value from  DB");
      }
    }
    return _tweetDetail;
  }

  /// create [New Tweet]
  /// returns Tweet key
  Future<String?> createTweet(FeedModel model) async {
    ///  Create tweet in [Firebase kDatabase]
    isBusy = true;
    notifyListeners();
    String? tweetKey;
    try {
      DatabaseReference dbReference = kDatabase.child('tweet').push();

      await dbReference.set(model.toJson());

      tweetKey = dbReference.key;
    } catch (error) {
      cprint(error, errorIn: 'createTweet');
    }
    isBusy = false;
    notifyListeners();
    return tweetKey;
  }

  ///  It will create tweet in [Firebase kDatabase] just like other normal tweet.
  ///  update retweet count for retweet model
  Future<String?> createReTweet(FeedModel model) async {
    String? tweetKey;
    try {
      tweetKey = await createTweet(model);
      if (_tweetToReplyModel != null) {
        if (_tweetToReplyModel!.retweetCount == null) {
          _tweetToReplyModel!.retweetCount = 0;
        }
        _tweetToReplyModel!.retweetCount =
            _tweetToReplyModel!.retweetCount! + 1;
        updateTweet(_tweetToReplyModel!);
      }
    } catch (error) {
      cprint(error, errorIn: 'createReTweet');
    }
    return tweetKey;
  }

  /// [Delete tweet] in Firebase kDatabase
  /// Remove Tweet if present in home page Tweet list
  /// Remove Tweet if present in Tweet detail page or in comment
  deleteTweet(String tweetId, TweetType type, {String? parentkey} //FIXME
      ) {
    try {
      /// Delete tweet if it is in nested tweet detail page
      kDatabase.child('tweet').child(tweetId).remove().then((_) {
        if (type == TweetType.Detail &&
            _tweetDetailModelList != null &&
            _tweetDetailModelList!.isNotEmpty) {
          // var deletedTweet =
          //     _tweetDetailModelList.firstWhere((x) => x.key == tweetId);
          _tweetDetailModelList!.remove(_tweetDetailModelList!);
          if (_tweetDetailModelList!.isEmpty) {
            _tweetDetailModelList = null;
          }

          cprint('Tweet deleted from nested tweet detail page tweet');
        }
      });
    } catch (error) {
      cprint(error, errorIn: 'deleteTweet');
    }
  }

  /// upload [file] to firebase storage and return its  path url
  Future<String?> uploadFile(File file) async {
    try {
      isBusy = true;
      notifyListeners();
      var storageReference = FirebaseStorage.instance
          .ref()
          .child("tweetImage")
          .child(path.basename(DateTime.now().toIso8601String() + file.path));
      await storageReference.putFile(file);

      var url = await storageReference.getDownloadURL();
      // ignore: unnecessary_null_comparison
      if (url != null) {
        return url;
      }
      return null;
    } catch (error) {
      cprint(error, errorIn: 'uploadFile');
      return null;
    }
  }

  /// [Delete file] from firebase storage
  Future<void> deleteFile(String url, String baseUrl) async {
    try {
      var filePath = url.split(".com/o/")[1];
      filePath = filePath.replaceAll(RegExp(r'%2F'), '/');
      filePath = filePath.replaceAll(RegExp(r'(\?alt).*'), '');
      //  filePath = filePath.replaceAll('tweetImage/', '');
      cprint('[Path]' + filePath);
      var storageReference = FirebaseStorage.instance.ref();
      await storageReference.child(filePath).delete().catchError((val) {
        cprint('[Error]' + val);
      }).then((_) {
        cprint('[Success] Image deleted');
      });
    } catch (error) {
      cprint(error, errorIn: 'deleteFile');
    }
  }

  /// [update] tweet
  Future<void> updateTweet(FeedModel model) async {
    await kDatabase.child('tweet').child(model.key!).set(model.toJson());
  }

  /// Add/Remove like on a Tweet
  /// [postId] is tweet id, [userId] is user's id who like/unlike Tweet
  addLikeToTweet(FeedModel tweet, String userId) {
    try {
      if (tweet.likeList != null &&
          tweet.likeList!.isNotEmpty &&
          tweet.likeList!.any((id) => id == userId)) {
        // If user wants to undo/remove his like on tweet
        tweet.likeList!.removeWhere((id) => id == userId);
        tweet.likeCount = tweet.likeCount! - 1;
      } else {
        // If user like Tweet
        tweet.likeList ??= [];
        tweet.likeList!.add(userId);
        tweet.likeCount = tweet.likeCount! + 1;
      }
      // update likeList of a tweet
      kDatabase
          .child('tweet')
          .child(tweet.key!)
          .child('likeList')
          .set(tweet.likeList);

      // Sends notification to user who created tweet
      // UserModel owner can see notification on notification page
      kDatabase
          .child('notification')
          .child(tweet.userId)
          .child(tweet.key!)
          .set({
        'type':
            tweet.likeList!.isEmpty ? null : NotificationType.Like.toString(),
        'updatedAt':
            tweet.likeList!.isEmpty ? null : DateTime.now().toUtc().toString(),
      });
    } catch (error) {
      cprint(error, errorIn: 'addLikeToTweet');
    }
  }

  /// Add [new comment tweet] to any tweet
  /// Comment is a Tweet itself
  Future<String?> addCommentToPost(FeedModel replyTweet) async {
    try {
      isBusy = true;
      notifyListeners();
      // String tweetKey;
      if (_tweetToReplyModel != null) {
        FeedModel tweet =
            _feedList!.firstWhere((x) => x.key == _tweetToReplyModel!.key);
        var json = replyTweet.toJson();
        DatabaseReference ref = kDatabase.child('tweet').push();
        await ref.set(json);
        tweet.replyTweetKeyList!.add(ref.key);
        await updateTweet(tweet);
        return ref.key;
      } else {
        return null;
      }
    } catch (error) {
      cprint(error, errorIn: 'addCommentToPost');
      return null;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  /// Add Tweet in bookmark
  Future addBookmark(String tweetId) async {
    final pref = getIt<SharedPreferenceHelper>();
    var userId = await pref.getUserProfile().then((value) => value!.userId);
    DatabaseReference dbReference =
        kDatabase.child('bookmark').child(userId!).child(tweetId);
    await dbReference.set(
        {"tweetId": tweetId, "created_at": DateTime.now().toUtc().toString()});
  }

  /// Trigger when any tweet changes or update
  /// When any tweet changes it update it in UI
  /// No matter if Tweet is in home page or in detail page or in comment section.
  _onTweetChanged(DatabaseEvent event) {
    var model =
        FeedModel.fromJson(event.snapshot.value as Map<dynamic, dynamic>);
    model.key = event.snapshot.key!;
    if (_feedList!.any((x) => x.key == model.key)) {
      var oldEntry = _feedList!.lastWhere((entry) {
        return entry.key == event.snapshot.key;
      });
      _feedList![_feedList!.indexOf(oldEntry)] = model;
    }

    if (_tweetDetailModelList != null && _tweetDetailModelList!.isNotEmpty) {
      if (_tweetDetailModelList!.any((x) => x.key == model.key)) {
        var oldEntry = _tweetDetailModelList!.lastWhere((entry) {
          return entry.key == event.snapshot.key;
        });
        _tweetDetailModelList![_tweetDetailModelList!.indexOf(oldEntry)] =
            model;
      }
      if (tweetReplyMap != null && tweetReplyMap!.isNotEmpty) {
        if (true) {
          var list = tweetReplyMap![model.parentkey];
          //  var list = tweetReplyMap.values.firstWhere((x) => x.any((y) => y.key == model.key));
          if (list != null && list.isNotEmpty) {
            var index =
                list.indexOf(list.firstWhere((x) => x.key == model.key));
            list[index] = model;
          } else {
            list = [];
            list.add(model);
          }
        }
      }
    }
    // if (event.snapshot != null) {
    cprint('Tweet updated');
    isBusy = false;
    notifyListeners();
    // }
  }

  /// Trigger when new tweet added
  /// It will add new Tweet in home page list.
  /// IF Tweet is comment it will be added in comment section too.
  _onTweetAdded(DatabaseEvent event) {
    FeedModel tweet = FeedModel.fromJson(event.snapshot.value as Map);
    tweet.key = event.snapshot.key!;

    /// Check if Tweet is a comment
    _onCommentAdded(tweet);
    tweet.key = event.snapshot.key!;
    _feedList ??= <FeedModel>[];
    if ((_feedList!.isEmpty || _feedList!.any((x) => x.key != tweet.key)) &&
        tweet.isValidTweet) {
      _feedList!.add(tweet);
      cprint('Tweet Added');
    }
    isBusy = false;
    notifyListeners();
  }

  /// Trigger when comment tweet added
  /// Check if Tweet is a comment
  /// If Yes it will add tweet in comment list.
  /// add [new tweet] comment to comment list
  _onCommentAdded(FeedModel tweet) {
    if (tweet.childRetwetkey != null) {
      /// if Tweet is a type of retweet then it can not be a comment.
      return;
    }
    if (tweetReplyMap != null && tweetReplyMap!.isNotEmpty) {
      if (tweetReplyMap![tweet.parentkey] != null) {
        /// Insert new comment at the top of all available comment
        tweetReplyMap![tweet.parentkey]!.insert(0, tweet);
      } else {
        tweetReplyMap![tweet.parentkey!] = [tweet];
      }
      cprint('Comment Added');
    }
    isBusy = false;
    notifyListeners();
  }

  /// Trigger when Tweet `Deleted`
  /// It removed Tweet from home page list, Tweet detail page list and from comment section if present
  _onTweetRemoved(DatabaseEvent event) async {
    FeedModel tweet = FeedModel.fromJson(event.snapshot.value as Map);
    tweet.key = event.snapshot.key!;
    var tweetId = tweet.key;
    var parentkey = tweet.parentkey;

    ///  Delete tweet in [Home Page]
    try {
      late FeedModel deletedTweet;
      if (_feedList!.any((x) => x.key == tweetId)) {
        /// Delete tweet if it is in home page tweet.
        deletedTweet = _feedList!.firstWhere((x) => x.key == tweetId);
        _feedList!.remove(deletedTweet);

        if (deletedTweet.parentkey != null &&
            _feedList!.isNotEmpty &&
            _feedList!.any((x) => x.key == deletedTweet.parentkey)) {
          // Decrease parent Tweet comment count and update
          var parentModel =
              _feedList!.firstWhere((x) => x.key == deletedTweet.parentkey);
          parentModel.replyTweetKeyList!.remove(deletedTweet.key);
          parentModel.commentCount = parentModel.replyTweetKeyList!.length;
          updateTweet(parentModel);
        }
        if (_feedList!.isEmpty) {
          _feedList = null;
        }
        cprint('Tweet deleted from home page tweet list');
      }

      /// [Delete tweet] if it is in nested tweet detail comment section page
      if (parentkey != null &&
          parentkey.isNotEmpty &&
          tweetReplyMap != null &&
          tweetReplyMap!.isNotEmpty &&
          tweetReplyMap!.keys.any((x) => x == parentkey)) {
        // (type == TweetType.Reply || tweetReplyMap.length > 1) &&
        deletedTweet =
            tweetReplyMap![parentkey]!.firstWhere((x) => x.key == tweetId);
        tweetReplyMap![parentkey]!.remove(deletedTweet);
        if (tweetReplyMap![parentkey]!.isEmpty) {
          tweetReplyMap![parentkey] = null;
        }

        if (_tweetDetailModelList != null &&
            _tweetDetailModelList!.isNotEmpty &&
            _tweetDetailModelList!.any((x) => x.key == parentkey)) {
          var parentModel =
              _tweetDetailModelList!.firstWhere((x) => x.key == parentkey);
          parentModel.replyTweetKeyList!.remove(deletedTweet.key);
          parentModel.commentCount = parentModel.replyTweetKeyList!.length;
          cprint('Parent tweet comment count updated on child tweet removal');
          updateTweet(parentModel);
        }

        cprint('Tweet deleted from nested tweet detail comment section');
      }

      /// Delete tweet image from firebase storage if exist.
      if (deletedTweet.imagePath != null &&
          deletedTweet.imagePath!.isNotEmpty) {
        deleteFile(deletedTweet.imagePath!, 'tweetImage');
      }

      /// If a retweet is deleted then retweetCount of original tweet should be decrease by 1.
      if (deletedTweet.childRetwetkey != null) {
        await fetchTweet(deletedTweet.childRetwetkey!)
            .then((FeedModel? retweetModel) {
          if (retweetModel == null) {
            return;
          }
          if (retweetModel.retweetCount! > 0) {
            retweetModel.retweetCount = retweetModel.retweetCount! - 1;
          }
          updateTweet(retweetModel);
        });
      }

      /// Delete notification related to deleted Tweet.
      if (deletedTweet.likeCount! > 0) {
        kDatabase
            .child('notification')
            .child(tweet.userId)
            .child(tweet.key!)
            .remove();
      }
      notifyListeners();
    } catch (error) {
      cprint(error, errorIn: '_onTweetRemoved');
    }
  }
}
