import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_twitter_clone/helper/enum.dart';
import 'package:flutter_twitter_clone/helper/utility.dart'; // For cprint
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/model/user.dart'; // For UserModel type hint
import 'package:uuid/uuid.dart';

class ListingIngestService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final Uuid _uuid = Uuid();
  final Random _random = Random();

  Future<void> fetchAndPostListingsForUser(UserModel user) async {
    if (user.preferredZip == null || user.preferredZip!.isEmpty) {
      cprint("User preferredZip is not set. Cannot fetch listings.", warningIn: "fetchAndPostListingsForUser");
      return;
    }
    String zipCode = user.preferredZip!;
    cprint("Fetching listings for ZIP: $zipCode for user ${user.userId}", infoIn: "fetchAndPostListingsForUser");

    List<FeedModel> listingsToPost = [];

    // --- Mock Zillow Listings (2-3) ---
    for (int i = 0; i < _random.nextInt(2) + 2; i++) { // Generates 2 or 3 listings
      String mockPropertyId = "mock_zillow_${_uuid.v4()}";
      int beds = _random.nextInt(3) + 2; // 2-4 beds
      int baths = _random.nextInt(2) + 1; // 1-2 baths
      int sqft = 1000 + _random.nextInt(1500); // 1000-2499 sqft
      int price = (150000 + _random.nextInt(350000)) ~/ 1000 * 1000; // Rounded price

      FeedModel zillowListing = FeedModel(
        key: _database.child("geniiPosts").push().key, // Firebase unique key for the post
        userId: "system_zillow", // Or could be attributed to an agent later
        // user: UserModel(userId: "system_zillow", displayName: "Zillow Listings", userName: "zillow"), // Optional: if system users have profiles
        createdAt: DateTime.now().toUtc().toIso8601String(),
        postType: PostTypes.PropertyListing,
        propertyId: mockPropertyId, // Unique ID for the property itself
        description: "Zillow Listing: $beds bed, $baths bath home in $zipCode",
        eventPayload: {
          'source': "Zillow (Mock)",
          'address': "${_random.nextInt(800) + 100} Mockingbird Ln, Cityville, $zipCode",
          'price': price,
          'imageUrl': "https://picsum.photos/seed/$mockPropertyId/600/400",
          'propertyType': "Single Family",
          'bed': beds,
          'bath': baths,
          'sqft': sqft,
          'zip': zipCode, // Crucial for filtering
          'listingUrl': "https://www.zillow.com/mock/$mockPropertyId"
        },
        status: "New",
      );
      listingsToPost.add(zillowListing);
    }

    // --- Mock CREXi Listings (1-2) ---
     for (int i = 0; i < _random.nextInt(2) + 1; i++) { // Generates 1 or 2 listings
      String mockPropertyId = "mock_crexi_${_uuid.v4()}";
      int sqft = 2000 + _random.nextInt(8000); // 2000-9999 sqft for commercial
      int price = (500000 + _random.nextInt(1500000)) ~/ 10000 * 10000; // Rounded price
      List<String> commercialTypes = ["Office Space", "Retail Unit", "Warehouse", "Industrial"];
      String propertyType = commercialTypes[_random.nextInt(commercialTypes.length)];

      FeedModel crexiListing = FeedModel(
        key: _database.child("geniiPosts").push().key,
        userId: "system_crexi",
        createdAt: DateTime.now().toUtc().toIso8601String(),
        postType: PostTypes.PropertyListing,
        propertyId: mockPropertyId,
        description: "CREXi Listing: $propertyType in $zipCode",
        eventPayload: {
          'source': "CREXi (Mock)",
          'address': "${_random.nextInt(50) + 1} Commerce Dr, Business Park, $zipCode",
          'price': price,
          'imageUrl': "https://picsum.photos/seed/$mockPropertyId/600/400",
          'propertyType': propertyType,
          'sqft': sqft,
          'zip': zipCode, // Crucial for filtering
          'brokerName': "Commercial Brokers LLC",
          'listingUrl': "https://www.crexi.com/mock/$mockPropertyId"
        },
        status: "New",
      );
      listingsToPost.add(crexiListing);
    }

    // Save all generated listings to Firebase
    if (listingsToPost.isNotEmpty) {
      cprint("Generated ${listingsToPost.length} mock listings. Saving to Firebase...", infoIn: "fetchAndPostListingsForUser");
      for (var post in listingsToPost) {
        try {
          await _database.child("geniiPosts").child(post.key!).set(post.toJson());
        } catch (e) {
          cprint("Error saving post ${post.key} to Firebase: $e", errorIn: "fetchAndPostListingsForUser");
        }
      }
      cprint("Mock listings saved.", infoIn: "fetchAndPostListingsForUser");
    } else {
      cprint("No mock listings generated for ZIP: $zipCode", warningIn: "fetchAndPostListingsForUser");
    }
  }
}
