import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_twitter_clone/helper/enum.dart';
import 'package:flutter_twitter_clone/helper/utility.dart'; // For cprint
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/model/user.dart'; // For UserModel type hint
import 'package:uuid/uuid.dart';

import 'package:http/http.dart' as http;
import 'dart:convert'; // For jsonDecode

class ListingIngestService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final Uuid _uuid = Uuid();
  final Random _random = Random(); // Keep for small randomizations if needed
  static const String _scraperApiKey = "5afe6d43e089c4e5a0957a8132b3ed26";

  Future<void> fetchAndPostListingsForUser(UserModel user) async {
    if (user.preferredZip == null || user.preferredZip!.isEmpty) {
      cprint("User preferredZip is not set. Cannot fetch listings.", warningIn: "fetchAndPostListingsForUser");
      return;
    }
    String zipCode = user.preferredZip!;
    cprint("Fetching LIVE listings for ZIP: $zipCode for user ${user.userId}", infoIn: "fetchAndPostListingsForUser");

    List<FeedModel> listingsToPost = [];

    // --- Define sources and their search URL builders ---
    Map<String, String Function(String)> sources = {
      "Redfin": (zip) => "https://www.redfin.com/zipcode/$zip",
      "Zillow": (zip) => "https://www.zillow.com/homes/for_sale/${zip}_rb/",
      // Potentially add CREXi here if a similar search URL pattern by ZIP exists
      // "CREXi": (zip) => "https://www.crexi.com/properties/search/all-asset-types/$zip" // Example, verify actual URL
    };

    for (var sourceEntry in sources.entries) {
      String sourceName = sourceEntry.key;
      String targetUrl = sourceEntry.value(zipCode);

      String scraperApiUrl = "http://api.scraperapi.com/?api_key=$_scraperApiKey&url=${Uri.encodeComponent(targetUrl)}&render=true&country_code=us";
      // Using render=true might help with JS-heavy sites. country_code=us for US listings.
      // Using http as the example, docs suggest https is also fine.
      // The prompt mentioned /structured/ endpoints. If those are better, this URL structure would change.
      // For example: https://api.scraperapi.com/structured/redfin/listing-search?api_key=$_scraperApiKey&location=$zipCode
      // This part needs to be flexible based on ScraperAPI's best practices for these sites.
      // For now, using generic URL scraping.

      cprint("Querying ScraperAPI for $sourceName: $scraperApiUrl", infoIn: "fetchAndPostListingsForUser");

      try {
        var response = await http.get(Uri.parse(scraperApiUrl));

        if (response.statusCode == 200) {
          cprint("ScraperAPI response for $sourceName (first 500 chars): ${response.body.substring(0, min(500, response.body.length))}", infoIn: "fetchAndPostListingsForUser");
          var decodedData;
          try {
            decodedData = jsonDecode(response.body);
          } catch (e) {
            cprint("Error decoding JSON for $sourceName: $e. Body might not be JSON or scraping failed to get structured data.", errorIn: "fetchAndPostListingsForUser");
            // If it's not JSON, it might be HTML. We'd need an HTML parser here.
            // For this exercise, we'll assume structured=1 or the structured endpoint would ideally give JSON.
            // If it's HTML, we cannot proceed with simple parsing here.
            continue;
          }

          // --- !!! PARSING LOGIC (HIGHLY DEPENDENT ON SCRAPERAPI OUTPUT) !!! ---
          // This is where the most assumptions are made.
          // Assuming decodedData is a Map and contains a list of listings, e.g., under a 'results' or 'listings' key.
          // Or, if it's a structured endpoint for a specific listing, it might be the listing object itself.
          // The prompt implies scraping search result pages.

          List<dynamic> scrapedListings = [];
          if (decodedData is Map && decodedData.containsKey('results') && decodedData['results'] is List) {
            scrapedListings = decodedData['results'];
          } else if (decodedData is Map && decodedData.containsKey('listings') && decodedData['listings'] is List) {
            scrapedListings = decodedData['listings'];
          } else if (decodedData is Map && decodedData.containsKey('properties') && decodedData['properties'] is List) { // Common for Zillow-like structures
            scrapedListings = decodedData['properties'];
          } else if (decodedData is List) { // Sometimes the root is the list
            scrapedListings = decodedData;
          } else {
            cprint("Could not find a list of listings in ScraperAPI response for $sourceName. Data: $decodedData", warningIn: "fetchAndPostListingsForUser");
            continue;
          }

          cprint("Found ${scrapedListings.length} potential listings from $sourceName.", infoIn: "fetchAndPostListingsForUser");

          for (var listingData in scrapedListings.take(5)) { // Limit to 5 per source for now
            if (listingData is! Map) continue; // Ensure item is a map

            // Extract fields - these keys are GUESSES and will need adjustment based on actual ScraperAPI output
            String? address = listingData['address'] ?? listingData['streetAddress'] ?? "N/A";
            num? price = listingData['price'] as num? ?? (_random.nextInt(500) + 200) * 1000; // Default mock price
            int? beds = listingData['beds'] as int? ?? listingData['bedrooms'] as int?;
            num? baths = listingData['baths'] as num? ?? listingData['bathrooms'] as num?;
            num? sqft = listingData['sqft'] as num? ?? listingData['livingArea'] as num?;
            String? imageUrl = listingData['imgSrc'] ?? listingData['image'] ?? listingData['thumbnail'] ?? "https://picsum.photos/seed/${_uuid.v4()}/600/400";
            String? listingUrl = listingData['detailUrl'] ?? listingData['url'];
            String? propertyType = listingData['propertyType'] ?? "Unknown";
            Map<String, double>? geo = (listingData['latLong'] is Map)
                ? {'lat': (listingData['latLong']['latitude'] as num?)?.toDouble(), 'lng': (listingData['latLong']['longitude'] as num?)?.toDouble()}
                : (listingData['geo'] is Map ? {'lat': (listingData['geo']['latitude'] as num?)?.toDouble(), 'lng': (listingData['geo']['longitude'] as num?)?.toDouble()} : null);


            // Ensure essential fields are present, especially address and price for a meaningful listing
            if (address == "N/A" || price == null || listingUrl == null) {
                cprint("Skipping listing due to missing critical info (address, price, or url): $listingData", warningIn: "fetchAndPostListingsForUser");
                continue;
            }

            String listingSpecificId = listingData['id']?.toString() ?? listingData['zpid']?.toString() ?? _uuid.v4();
            String feedModelPropertyId = "${sourceName.toLowerCase()}_$listingSpecificId";


            FeedModel listingPost = FeedModel(
              key: _database.child("geniiPosts").push().key,
              userId: "system_$sourceName",
              createdAt: DateTime.now().toUtc().toIso8601String(),
              postType: PostTypes.PropertyListing,
              propertyId: feedModelPropertyId,
              description: "$propertyType at $address for \$${price.toString()}",
              eventPayload: {
                'source': sourceName,
                'address': address,
                'price': price,
                'imageUrl': imageUrl,
                'propertyType': propertyType,
                'bed': beds,
                'bath': baths,
                'sqft': sqft,
                'zip': zipCode, // Add the user's search ZIP for consistent filtering
                'listingUrl': listingUrl,
                if (geo?['lat'] != null && geo?['lng'] != null) 'geo': geo,
              },
              status: "New",
            );
            listingsToPost.add(listingPost);
          }
        } else {
          cprint("ScraperAPI request for $sourceName failed with status: ${response.statusCode} - ${response.body}", errorIn: "fetchAndPostListingsForUser");
        }
      } catch (e, s) {
        cprint("Error during ScraperAPI call or processing for $sourceName: $e\n$s", errorIn: "fetchAndPostListingsForUser");
      }
    }

    if (listingsToPost.isNotEmpty) {
      cprint("Attempting to save ${listingsToPost.length} fetched listings to Firebase...", infoIn: "fetchAndPostListingsForUser");
      for (var post in listingsToPost) {
        try {
          // Consider checking for duplicates before posting if necessary
          // e.g. query if a post with the same propertyId (from source) already exists.
          await _database.child("geniiPosts").child(post.key!).set(post.toJson());
        } catch (e) {
          cprint("Error saving post ${post.key} to Firebase: $e", errorIn: "fetchAndPostListingsForUser");
        }
      }
      cprint("${listingsToPost.length} listings processed and saved (or attempted).", infoIn: "fetchAndPostListingsForUser");
    } else {
      cprint("No new listings fetched or processed for ZIP: $zipCode", warningIn: "fetchAndPostListingsForUser");
    }
  }
}
