import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_twitter_clone/helper/enum.dart';
import 'package:flutter_twitter_clone/model/user.dart'; // For UserModel type hint
import 'package:flutter_twitter_clone/services/mock_seed_service.dart'; // For fallback
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For jsonDecode
import 'dart:math'; // For min function if needed

class ListingIngestService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final Uuid _uuid = Uuid();
  final Random _random = Random();
  static const String _scraperApiKey = "5afe6d43e089c4e5a0957a8132b3ed26";
  static const String _geniiBotId = "genii_bot";

  // Helper to create a basic UserModel for genii_bot if needed for FeedModel.user
  UserModel get _geniiBotUserModel => UserModel(
      userId: _geniiBotId,
      displayName: "Genii Bot",
      userName: "geniibot",
      roles: [UserRoles.Agent]); // Bot can have an Agent role perhaps

  Future<List<Map<String, dynamic>>> _fetchAndParseSource(
      String sourceName, String targetSearchUrl, String apiKey, String userZip) async {

    // Prioritize structured endpoints if a mapping is known
    String scraperApiUrl;
    if (sourceName == "Redfin" && false) { // Disabled for now, assuming generic for Redfin too
        // Example: scraperApiUrl = "https://api.scraperapi.com/structured/redfin/listing-search?api_key=$apiKey&location=$userZip";
        // This would require ScraperAPI to support location param for this structured endpoint.
        // For now, using generic for both.
        scraperApiUrl = "http://api.scraperapi.com/?api_key=$apiKey&url=${Uri.encodeComponent(targetSearchUrl)}&render=true&country_code=us&autoparse=true";
    } else { // Generic approach for Zillow and potentially Redfin/CREXi
        scraperApiUrl = "http://api.scraperapi.com/?api_key=$apiKey&url=${Uri.encodeComponent(targetSearchUrl)}&render=true&country_code=us&autoparse=true";
    }

    cprint("Querying ScraperAPI for $sourceName: $scraperApiUrl", infoIn: "_fetchAndParseSource");

    try {
      var response = await http.get(Uri.parse(scraperApiUrl)).timeout(const Duration(seconds: 30)); // Added timeout

      if (response.statusCode == 200) {
        cprint("ScraperAPI response for $sourceName (first 500 chars): ${response.body.substring(0, min(500, response.body.length))}", infoIn: "_fetchAndParseSource");
        var decodedData;
        try {
          decodedData = jsonDecode(response.body);
        } catch (e) {
          cprint("Error decoding JSON for $sourceName: $e. Body might not be JSON. Will attempt to find JSON-LD or treat as HTML (currently stubbed).", errorIn: "_fetchAndParseSource");
          // TODO: Implement more robust HTML parsing or JSON-LD extraction here if autoparse fails or returns HTML.
          // For now, if not direct JSON, we assume failure for this source.
          return [];
        }

        List<dynamic> rawListings = [];
        // Try to find a list of listings based on common keys or if the root is a list.
        // This part is highly speculative and depends on ScraperAPI's `autoparse=true` behavior for Zillow/Redfin search pages.
        if (decodedData is Map) {
            if (decodedData.containsKey('results') && decodedData['results'] is List) rawListings = decodedData['results'];
            else if (decodedData.containsKey('listings') && decodedData['listings'] is List) rawListings = decodedData['listings'];
            else if (decodedData.containsKey('properties') && decodedData['properties'] is List) rawListings = decodedData['properties'];
            else if (decodedData.containsKey('data') && decodedData['data'] is Map && decodedData['data'].containsKey('results') && decodedData['data']['results'] is List) rawListings = decodedData['data']['results']; // Common in some APIs
            else if (decodedData.containsKey('props') && decodedData['props'] is Map && decodedData['props'].containsKey('pageProps') && decodedData['props']['pageProps'] is Map && decodedData['props']['pageProps'].containsKey('searchPageState') && decodedData['props']['pageProps']['searchPageState'] is Map) {
                 // More specific Zillow structure sometimes seen
                var searchPageState = decodedData['props']['pageProps']['searchPageState'];
                if (searchPageState.containsKey('searchResults') && searchPageState['searchResults'] is Map && searchPageState['searchResults'].containsKey('listResults') && searchPageState['searchResults']['listResults'] is List) {
                    rawListings = searchPageState['searchResults']['listResults'];
                } else if (searchPageState.containsKey('cat1') && searchPageState['cat1'] is Map && searchPageState['cat1'].containsKey('searchResults') && searchPageState['cat1']['searchResults'] is Map && searchPageState['cat1']['searchResults'].containsKey('listResults') && searchPageState['cat1']['searchResults']['listResults'] is List) {
                    rawListings = searchPageState['cat1']['searchResults']['listResults']; // Zillow sometimes nests it
                }
            }
             // Add more checks for common list keys if needed
        } else if (decodedData is List) {
          rawListings = decodedData;
        }

        if (rawListings.isEmpty && decodedData is Map) {
            // If no list found, but we have a map, maybe it's a single listing result from a direct URL scrape (not a search page)
            // Or, if it's a structured data endpoint for a single property.
            // For this function, we expect a list from a search. If not, log and return empty.
             cprint("Decoded data for $sourceName was a Map but no identifiable list of listings found. Data: ${decodedData.toString().substring(0,min(300,decodedData.toString().length))}", warningIn: "_fetchAndParseSource");
        }

        cprint("Extracted ${rawListings.length} raw items for $sourceName.", infoIn: "_fetchAndParseSource");
        return rawListings.whereType<Map<String, dynamic>>().toList(); // Ensure all items are maps

      } else {
        cprint("ScraperAPI request for $sourceName failed with status: ${response.statusCode} - ${response.body}", errorIn: "_fetchAndParseSource");
        return [];
      }
    } catch (e, s) {
      cprint("Error during ScraperAPI HTTP call or initial processing for $sourceName: $e\n$s", errorIn: "_fetchAndParseSource");
      return [];
    }
  }

  Future<void> fetchAndPostListingsForUser(UserModel user) async {
    String zipCode = user.preferredZip ?? "93711"; // Default to Fresno, CA if no user ZIP
    cprint("Fetching LIVE listings for ZIP: $zipCode for user ${user.userId}", infoIn: "fetchAndPostListingsForUser");

    List<FeedModel> successfullyNormalizedPosts = [];

    Map<String, String Function(String)> sources = {
      "Redfin": (zip) => "https://www.redfin.com/zipcode/$zip/filter/sort=lo-days,property-type=house+multifamily", // Added filters
      "Zillow": (zip) => "https://www.zillow.com/homes/for-sale/${zip}_rb/?searchQueryState=%7B%22sortSelection%22%3A%7B%22value%22%3A%22days%22%7D,%22isSingleFamily%22%3A%7B%22value%22%3Atrue%7D,%22isManufactured%22%3A%7B%22value%22%3Afalse%7D,%22isCondo%22%3A%7B%22value%22%3Afalse%7D,%22isTownhouse%22%3A%7B%22value%22%3Afalse%7D%7D" // More complex Zillow URL with type filters
    };

    for (var sourceEntry in sources.entries) {
      String sourceName = sourceEntry.key;
      String targetSearchUrl = sourceEntry.value(zipCode);

      List<Map<String, dynamic>> scrapedData = await _fetchAndParseSource(sourceName, targetSearchUrl, _scraperApiKey, zipCode);

      cprint("Normalizing ${scrapedData.length} items from $sourceName for ZIP $zipCode", infoIn: "fetchAndPostListingsForUser");
      for (var item in scrapedData.take(5)) { // Process up to 5 from each source
        try {
          // Highly speculative field extraction - WILL NEED ADJUSTMENT
          String? address = item['address']?.toString() ?? item['streetAddress']?.toString() ?? item['full_address']?.toString();
          if (address == null && item['addressLine1'] != null) {
            address = "${item['addressLine1']}, ${item['city']}, ${item['state']} ${item['zipcode']}";
          }

          num? price;
          if (item['price'] is num) price = item['price'] as num;
          else if (item['price'] is String) price = num.tryParse(item['price'].replaceAll(RegExp(r'[^0-9]'),''));
          else if (item['formattedPrice'] is String) price = num.tryParse(item['formattedPrice'].replaceAll(RegExp(r'[^0-9]'),''));


          int? beds = (item['beds'] as num?)?.toInt() ?? (item['bedrooms'] as num?)?.toInt();
          num? baths = item['baths'] as num? ?? (item['bathrooms'] as num?);
          num? sqft = (item['sqft'] as num?) ?? (item['livingArea'] as num?) ?? (item['lotSize'] as num?);

          String? imageUrl = item['imgSrc']?.toString() ?? item['image']?.toString() ?? item['photo']?.toString() ?? item['thumbnail']?.toString();
          if (imageUrl == null && item['photos'] is List && (item['photos'] as List).isNotEmpty) {
            imageUrl = (item['photos'] as List).first is String ? (item['photos'] as List).first : ((item['photos'] as List).first as Map)['url']?.toString();
          }


          String? listingUrl = item['detailUrl']?.toString() ?? item['url']?.toString() ?? item['link']?.toString();
          String? propertyType = item['propertyType']?.toString() ?? item['homeType']?.toString() ?? "Residential";

          Map<String, dynamic>? geoPayload;
          if (item['latLong'] is Map) {
            geoPayload = {
              'lat': (item['latLong']['latitude'] as num?)?.toDouble(),
              'lng': (item['latLong']['longitude'] as num?)?.toDouble()
            };
          } else if (item['latitude'] is num && item['longitude'] is num) {
             geoPayload = {'lat': (item['latitude'] as num).toDouble(), 'lng': (item['longitude'] as num).toDouble()};
          }


          if (address == null || price == null || listingUrl == null) {
            cprint("Skipping item from $sourceName due to missing critical info: address, price, or URL. Item: ${item.toString().substring(0, min(100, item.toString().length))}", warningIn: "fetchAndPostListingsForUser");
            continue;
          }

          String sourceSpecificId = item['zpid']?.toString() ?? item['id']?.toString() ?? _uuid.v4();
          String feedModelPropertyId = "${sourceName.toLowerCase().replaceAll(' ', '_')}_${sourceSpecificId}";

          FeedModel listingPost = FeedModel(
            key: _database.child("geniiPosts").push().key,
            userId: _geniiBotId,
            user: _geniiBotUserModel, // Assign the bot user model
            createdAt: DateTime.now().toUtc().toIso8601String(),
            postType: PostTypes.PropertyListing,
            propertyId: feedModelPropertyId,
            description: "$propertyType at $address for \$${price.toStringAsFixed(0)}",
            eventPayload: {
              'source': sourceName,
              'address': address,
              'price': price,
              'imageUrl': imageUrl ?? "https://picsum.photos/seed/$feedModelPropertyId/600/400",
              'propertyType': propertyType,
              if (beds != null) 'bed': beds,
              if (baths != null) 'bath': baths,
              if (sqft != null) 'sqft': sqft,
              'zip': zipCode,
              'listingUrl': listingUrl,
              if (geoPayload?['lat'] != null && geoPayload?['lng'] != null) 'geo': geoPayload,
            },
            status: PostStatus.New,
            priority: 3,
          );
          successfullyNormalizedPosts.add(listingPost);
        } catch (e,s) {
          cprint("Error normalizing item from $sourceName: $e\nItem: $item\nStackTrace: $s", errorIn: "fetchAndPostListingsForUser");
        }
      }
    }

    if (successfullyNormalizedPosts.isEmpty) {
      cprint("No live listings successfully normalized for ZIP $zipCode. Triggering fallback mock listings.", warningIn: "fetchAndPostListingsForUser");
      // Use the MockSeedService instance correctly
      await MockSeedService().generateAndPostMockListings(zipCode, 2, authorId: "genii_bot_fallback", authorUser: _geniiBotUserModel);
    } else {
      cprint("Attempting to save ${successfullyNormalizedPosts.length} live fetched listings to Firebase...", infoIn: "fetchAndPostListingsForUser");
      for (var post in successfullyNormalizedPosts) {
        try {
          await _database.child("geniiPosts").child(post.key!).set(post.toJson());
        } catch (e) {
          cprint("Error saving post ${post.key} to Firebase: $e", errorIn: "fetchAndPostListingsForUser");
        }
      }
      cprint("${successfullyNormalizedPosts.length} live listings processed and saved.", infoIn: "fetchAndPostListingsForUser");
    }
  }
}
