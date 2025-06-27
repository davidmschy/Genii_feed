import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_twitter_clone/helper/enum.dart';
import 'package:flutter_twitter_clone/model/user.dart'; // For UserModel type hint
import 'package:flutter_twitter_clone/services/mock_seed_service.dart'; // For fallback
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For jsonDecode
import 'dart:math'; // For min function if needed

/// ListingIngestService is responsible for fetching property listing data from multiple external sources,
/// normalizing this data into a common FeedModel format (specifically PostTypes.PropertyListing),
/// performing deduplication based on available listing identifiers (like MLS numbers),
/// and then posting these processed listings to Firebase.
///
/// It currently supports:
/// 1. Zillow (via ScraperAPI - generic URL scraping)
/// 2. Redfin (via ScraperAPI - generic URL scraping)
/// 3. Repliers.io (direct API integration)
///
/// The service includes fallback logic: if all live data sources fail to yield any listings
/// for a given user's location, it will trigger the MockSeedService to generate
/// a few mock property listings to ensure the feed is not empty.
///
/// Key methods:
/// - fetchAndPostListingsForUser: Orchestrates fetching from all sources, normalization, deduplication, and posting.
/// - _fetchAndParseSource (private): Handles ScraperAPI calls for Zillow/Redfin.
/// - _fetchFromRepliers (private): Handles direct API calls to Repliers.io.
///
/// Parsing logic for ScraperAPI (Zillow/Redfin) is speculative due to the variability of
/// HTML structure and ScraperAPI's `autoparse` feature. It prioritizes finding structured JSON
/// but has placeholders where more robust HTML parsing might be needed in the future.
/// Repliers.io integration assumes a more predictable JSON structure from its direct API.
class ListingIngestService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final Uuid _uuid = Uuid();
  final Random _random = Random();
  static const String _scraperApiKey = "5afe6d43e089c4e5a0957a8132b3ed26";
  static const String _repliersApiKey = "OitUQAztFJR69gB4eTShLSLzGt1ANY";
  static const String _repliersApiBase = "https://api.repliers.io/listings";
  static const String _geniiBotId = "genii_bot";

  // Helper to create a basic UserModel for genii_bot if needed for FeedModel.user
  UserModel get _geniiBotUserModel => UserModel(
      userId: _geniiBotId,
      displayName: "Genii Bot",
      userName: "geniibot",
      roles: [UserRoles.Agent]); // Bot can have an Agent role perhaps

  Future<List<Map<String, dynamic>>> _fetchFromRepliers(String zip, {int page = 1, int perPage = 10}) async {
    final queryParameters = {
      'zipCode': zip, // Assuming 'zipCode' is the correct parameter for Repliers API
      // 'city': zip, // Alternative if 'zipCode' is not supported for ZIPs
      'pageNum': '$page',
      'resultsPerPage': '$perPage',
      // Add other optional filters here if needed e.g. 'maxPrice': '500000'
    };
    final url = Uri.parse(_repliersApiBase).replace(queryParameters: queryParameters);

    cprint("Querying Repliers.io API: $url", infoIn: "_fetchFromRepliers");

    try {
      final response = await http.get(
        url,
        headers: {'Repliers-Api-Key': _repliersApiKey},
      ).timeout(const Duration(seconds: 20)); // Added timeout

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['listings'] is List) {
          // Ensure all items in the list are Map<String, dynamic>
          List<Map<String, dynamic>> listings = (data['listings'] as List)
              .whereType<Map<String, dynamic>>()
              .toList();
          cprint("Fetched ${listings.length} listings from Repliers.io for ZIP $zip", infoIn: "_fetchFromRepliers");
          return listings;
        } else {
          cprint("Repliers.io response for ZIP $zip did not contain a 'listings' list or was null. Data: $data", warningIn: "_fetchFromRepliers");
          return [];
        }
      } else {
        cprint("Repliers.io API error for ZIP $zip: ${response.statusCode} - ${response.body}", errorIn: "_fetchFromRepliers");
        return [];
      }
    } catch (e, s) {
      cprint("Exception during Repliers.io API call for ZIP $zip: $e\n$s", errorIn: "_fetchFromRepliers");
      return [];
    }
  }

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

    List<Map<String, dynamic>> allRawListings = [];

    // --- Fetch from ScraperAPI (Zillow & Redfin) ---
    Map<String, String Function(String)> scraperSources = {
      "Redfin": (zip) => "https://www.redfin.com/zipcode/$zip/filter/sort=lo-days,property-type=house+multifamily",
      "Zillow": (zip) => "https://www.zillow.com/homes/for_sale/${zip}_rb/?searchQueryState=%7B%22sortSelection%22%3A%7B%22value%22%3A%22days%22%7D,%22isSingleFamily%22%3A%7B%22value%22%3Atrue%7D,%22isManufactured%22%3A%7B%22value%22%3Afalse%7D,%22isCondo%22%3A%7B%22value%22%3Afalse%7D,%22isTownhouse%22%3A%7B%22value%22%3Afalse%7D%7D"
    };

    for (var sourceEntry in scraperSources.entries) {
      String sourceName = sourceEntry.key;
      String targetSearchUrl = sourceEntry.value(zipCode);
      try {
        List<Map<String, dynamic>> scrapedData = await _fetchAndParseSource(sourceName, targetSearchUrl, _scraperApiKey, zipCode);
        for (var item in scrapedData) {
          item['_sourceName'] = sourceName; // Tag item with its source
          allRawListings.add(item);
        }
        cprint("Fetched ${scrapedData.length} raw items from $sourceName via ScraperAPI.", infoIn: "fetchAndPostListingsForUser");
      } catch (e,s) {
        cprint("Error fetching or parsing $sourceName via ScraperAPI: $e\n$s", errorIn: "fetchAndPostListingsForUser");
      }
    }

    // --- Fetch from Repliers.io ---
    try {
      List<Map<String, dynamic>> repliersData = await _fetchFromRepliers(zipCode);
      for (var item in repliersData) {
        item['_sourceName'] = 'Repliers'; // Tag item with its source
        allRawListings.add(item);
      }
      cprint("Fetched ${repliersData.length} raw items from Repliers.io.", infoIn: "fetchAndPostListingsForUser");
    } catch (e,s) {
        cprint("Error fetching or parsing Repliers.io: $e\n$s", errorIn: "fetchAndPostListingsForUser");
    }

    cprint("Total raw items from all sources: ${allRawListings.length}", infoIn: "fetchAndPostListingsForUser");

    // --- Normalization & Deduplication ---
    List<FeedModel> normalizedPosts = [];
    Set<String> uniquePropertyIds = {}; // For deduplication using linkedPropertyId

    for (var item in allRawListings) {
      try {
        String sourceName = item['_sourceName'] as String;
        String? linkedPropertyId;
        Map<String, dynamic> payload = {
            'zip': zipCode, // Always include the search zip
            'source': sourceName,
        };

        if (sourceName == 'Repliers') {
          linkedPropertyId = item['mlsNumber']?.toString();
          payload['mlsNumber'] = item['mlsNumber']?.toString();
          // Assuming address is a map: item['address']['full'], item['address']['city'], etc.
          // This needs to be based on actual Repliers API structure.
          var addr = item['address'];
          if (addr is Map) {
             payload['address'] = addr['full']?.toString() ?? addr['streetAddress']?.toString() ?? "${addr['streetNumber']} ${addr['streetName']}, ${addr['city']}, ${addr['state']} ${addr['zip']}";
          } else if (addr is String) {
            payload['address'] = addr;
          }
          payload['price'] = item['price'] as num?;
          payload['beds'] = (item['beds'] as num?)?.toInt();
          payload['baths'] = item['baths'] as num?;
          payload['sqFt'] = (item['sqFt'] as num?) ?? (item['buildingSize'] is Map ? (item['buildingSize']['sqFt'] as num?) : null);
          payload['listingDate'] = item['listingDate']?.toString();
          payload['propertyType'] = item['propertyType']?.toString();
          payload['status'] = item['status']?.toString(); // Listing status from Repliers
          payload['imageUrl'] = (item['images'] is List && (item['images'] as List).isNotEmpty)
              ? (item['images'] as List).first['url']?.toString()
              : item['image']?.toString();
          payload['listingUrl'] = item['url']?.toString(); // Assuming Repliers provides a direct listing URL
           if (item['coordinates'] is Map) { // Assuming coordinates: { lat: ..., lon: ...}
             payload['geo'] = {
               'lat': (item['coordinates']['lat'] as num?)?.toDouble(),
               'lng': (item['coordinates']['lon'] as num?)?.toDouble(), // Note: often 'lon' or 'lng'
             };
           }

        } else { // Zillow or Redfin via ScraperAPI
          linkedPropertyId = item['zpid']?.toString() ?? item['id']?.toString() ?? item['propertyURL']?.split('/').lastWhere((e) => e.isNotEmpty, orElse: () => _uuid.v4());
          if (sourceName == "Redfin" && item['redfinPropertyId'] != null) linkedPropertyId = item['redfinPropertyId'].toString();


          payload['address'] = item['address']?.toString() ?? item['streetAddress']?.toString() ?? item['full_address']?.toString();
           if (payload['address'] == null && item['addressLine1'] != null) { // More detailed address parsing
            payload['address'] = "${item['addressLine1']}, ${item['city']}, ${item['state']} ${item['zipcode']}";
          }

          num? priceNum;
          if (item['price'] is num) priceNum = item['price'] as num;
          else if (item['price'] is String) priceNum = num.tryParse(item['price'].replaceAll(RegExp(r'[^0-9.]'),'')); // Allow decimal for price
          else if (item['formattedPrice'] is String) priceNum = num.tryParse(item['formattedPrice'].replaceAll(RegExp(r'[^0-9.]'),''));
          payload['price'] = priceNum;

          payload['beds'] = (item['beds'] as num?)?.toInt() ?? (item['bedrooms'] as num?)?.toInt();
          payload['baths'] = item['baths'] as num? ?? (item['bathrooms'] as num?);
          payload['sqft'] = (item['sqft'] as num?) ?? (item['livingArea'] as num?) ?? (item['lotSize'] as num?);

          String? tempImageUrl = item['imgSrc']?.toString() ?? item['image']?.toString() ?? item['photo']?.toString() ?? item['thumbnail']?.toString();
          if (tempImageUrl == null && item['photos'] is List && (item['photos'] as List).isNotEmpty) {
            var firstPhoto = (item['photos'] as List).first;
            if (firstPhoto is String) tempImageUrl = firstPhoto;
            else if (firstPhoto is Map) tempImageUrl = firstPhoto['url']?.toString();
          }
          payload['imageUrl'] = tempImageUrl;
          payload['listingUrl'] = item['detailUrl']?.toString() ?? item['url']?.toString() ?? item['link']?.toString();
          payload['propertyType'] = item['propertyType']?.toString() ?? item['homeType']?.toString() ?? "Residential";

          if (item['latLong'] is Map) {
            payload['geo'] = {
              'lat': (item['latLong']['latitude'] as num?)?.toDouble(),
              'lng': (item['latLong']['longitude'] as num?)?.toDouble()
            };
          } else if (item['latitude'] is num && item['longitude'] is num) {
             payload['geo'] = {'lat': (item['latitude'] as num).toDouble(), 'lng': (item['longitude'] as num).toDouble()};
          }
        }

        if (payload['address'] == null || payload['price'] == null || payload['listingUrl'] == null) {
          cprint("Skipping item from $sourceName due to missing critical info (address, price, or URL). Item: ${item.toString().substring(0, min(100,item.toString().length))}", warningIn: "fetchAndPostListingsForUser");
          continue;
        }
        if (linkedPropertyId == null || linkedPropertyId.isEmpty) {
            linkedPropertyId = "${sourceName.toLowerCase().replaceAll(' ', '_')}_${_uuid.v4()}"; // Fallback unique ID
        }


        FeedModel listingPost = FeedModel(
          key: _database.child("geniiPosts").push().key,
          userId: _geniiBotId,
          user: _geniiBotUserModel,
          createdAt: DateTime.now().toUtc().toIso8601String(),
          postType: PostTypes.PropertyListing,
          propertyId: linkedPropertyId, // This is our deduplication key
          description: "${payload['propertyType']} at ${payload['address']} for \$${(payload['price'] as num).toStringAsFixed(0)}",
          eventPayload: payload,
          status: PostStatus.New,
          priority: 3,
        );
        normalizedPosts.add(listingPost);

      } catch (e,s) {
        cprint("Error normalizing item: $e\nItem: $item\nStackTrace: $s", errorIn: "fetchAndPostListingsForUser");
      }
    }
    cprint("Total normalized posts from all sources: ${normalizedPosts.length}", infoIn: "fetchAndPostListingsForUser");

    // Deduplication
    List<FeedModel> finalPostsToSave = [];
    for (var post in normalizedPosts) {
      if (post.propertyId != null && uniquePropertyIds.add(post.propertyId!)) {
        finalPostsToSave.add(post);
      } else if (post.propertyId == null) {
        // If propertyId is somehow null (should have fallback), add it to avoid losing data, but log it.
        finalPostsToSave.add(post);
        cprint("Warning: Post has null propertyId during deduplication. Key: ${post.key}", warningIn: "fetchAndPostListingsForUser");
      }
    }
    cprint("Posts after deduplication: ${finalPostsToSave.length}", infoIn: "fetchAndPostListingsForUser");


    if (finalPostsToSave.isEmpty) {
      cprint("No live listings successfully normalized and deduplicated for ZIP $zipCode. Triggering fallback mock listings.", warningIn: "fetchAndPostListingsForUser");
      await MockSeedService().generateAndPostMockListings(zipCode, 5, authorId: _geniiBotId, authorUser: _geniiBotUserModel);
    } else {
      cprint("Attempting to save ${finalPostsToSave.length} live fetched listings to Firebase...", infoIn: "fetchAndPostListingsForUser");
      for (var post in finalPostsToSave) {
        try {
          await _database.child("geniiPosts").child(post.key!).set(post.toJson());
        } catch (e) {
          cprint("Error saving post ${post.key} to Firebase: $e", errorIn: "fetchAndPostListingsForUser");
        }
      }
      cprint("${finalPostsToSave.length} live listings processed and saved.", infoIn: "fetchAndPostListingsForUser");
    }
  }
}
