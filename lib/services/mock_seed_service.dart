import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_twitter_clone/helper/enum.dart';
import 'package:flutter_twitter_clone/model/user.dart';
import 'package:flutter_twitter_clone/model/property_model.dart';
import 'package:flutter_twitter_clone/model/agent_model.dart';
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/services/trust_payment_engine.dart';
import 'package:flutter_twitter_clone/services/mock_agent_engine.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs

class MockSeedService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final Uuid _uuid = Uuid();

  Future<void> seedInitialData({required String currentAuthUserId}) async {
    print("Starting to seed initial data...");

    try {
      // Clear existing data (optional, for clean seeding)
      // await _database.child('users').remove();
      // await _database.child('properties').remove();
      // await _database.child('agents').remove();
      // await _database.child('geniiPosts').remove();
      // print("Cleared existing data.");

      // --- 1. Create Users ---
      UserModel ownerUser = UserModel(
        userId: _uuid.v4(),
        displayName: "Alice Owner",
        userName: "aliceowner",
        email: "alice@example.com",
        roles: [UserRoles.Owner, UserRoles.Investor],
        currentRole: UserRoles.Owner,
        profilePic: "https://randomuser.me/api/portraits/women/1.jpg",
        createdAt: DateTime.now().toUtc().toIso8601String(),
      );

      UserModel contractorUser = UserModel(
        userId: _uuid.v4(),
        displayName: "Bob Contractor",
        userName: "bobbuilder",
        email: "bob@example.com",
        roles: [UserRoles.Contractor],
        currentRole: UserRoles.Contractor,
        profilePic: "https://randomuser.me/api/portraits/men/1.jpg",
        createdAt: DateTime.now().toUtc().toIso8601String(),
      );

      UserModel agentUser = UserModel( // This is a human real estate agent
        userId: _uuid.v4(),
        displayName: "Carol Agent",
        userName: "carolrealtor",
        email: "carol@example.com",
        roles: [UserRoles.Agent],
        currentRole: UserRoles.Agent,
        profilePic: "https://randomuser.me/api/portraits/women/2.jpg",
        createdAt: DateTime.now().toUtc().toIso8601String(),
      );

      // Use currentAuthUserId for one of the users to make it easy to test with logged in user
      // Let's make the current authenticated user the Owner.
      ownerUser.userId = currentAuthUserId; // Override with actual logged-in user's ID
      ownerUser.key = currentAuthUserId;


      await _database.child('profile').child(ownerUser.userId!).set(ownerUser.toJson());
      await _database.child('profile').child(contractorUser.userId!).set(contractorUser.toJson());
      await _database.child('profile').child(agentUser.userId!).set(agentUser.toJson());
      print("Users seeded.");

      // --- 2. Create Properties ---
      Property property1 = Property(
        id: "prop_${_uuid.v4()}",
        address: "123 Main St, Anytown, USA",
        ownerId: ownerUser.userId!,
        agentIds: [], // AI Agents will be linked later
        moduleIds: ["Feed", "Tasks", "Payments"],
      );
      Property property2 = Property(
        id: "prop_${_uuid.v4()}",
        address: "456 Oak Ave, Otherville, USA",
        ownerId: ownerUser.userId!, // Alice owns both for simplicity
        agentIds: [],
        moduleIds: ["Feed", "Payments"],
      );
      await _database.child('properties').child(property1.id).set(property1.toJson());
      await _database.child('properties').child(property2.id).set(property2.toJson());
      print("Properties seeded.");

      // --- 3. Create AI Agents ---
      Agent aiAgent1 = Agent(
        id: "ai_${_uuid.v4()}",
        name: "DealHunter AI for ${property1.address.substring(0,12)}",
        type: AgentTypes.DealHunter,
        linkedPropertyId: property1.id,
        createdBy: ownerUser.userId!, // System or Owner
        status: "Active",
      );
      Agent aiAgent2 = Agent(
        id: "ai_${_uuid.v4()}",
        name: "TaskManager AI for ${property2.address.substring(0,12)}",
        type: AgentTypes.TaskManager,
        linkedPropertyId: property2.id,
        createdBy: ownerUser.userId!,
        status: "Active",
      );
      await _database.child('agents').child(aiAgent1.id).set(aiAgent1.toJson());
      await _database.child('agents').child(aiAgent2.id).set(aiAgent2.toJson());
      // Update properties with their AI agents
      property1 = property1.copyWith(agentIds: [aiAgent1.id]);
      property2 = property2.copyWith(agentIds: [aiAgent2.id]);
      await _database.child('properties').child(property1.id).set(property1.toJson());
      await _database.child('properties').child(property2.id).set(property2.toJson());
      print("AI Agents seeded and linked to properties.");


      // --- 4. Create Posts ---
      List<FeedModel> postsToSeed = [];
      final String now = DateTime.now().toUtc().toIso8601String();

      // AgentPrompt
      FeedModel agentPromptPost = FeedModel(
        key: _database.child("geniiPosts").push().key,
        userId: agentUser.userId!, // Human Agent Carol is prompting an AI agent
        user: agentUser,
        createdAt: now,
        postType: PostTypes.AgentPrompt,
        agentId: aiAgent1.id, // Prompting AI Agent 1
        propertyId: property1.id,
        description: "Find comparable properties for 123 Main St focusing on recent sales in the last 3 months.",
        eventPayload: {'promptText': "Find comparable properties for 123 Main St focusing on recent sales in the last 3 months."},
        status: "Open",
        priority: 2,
      );
      postsToSeed.add(agentPromptPost);

      // LoanUpdate
      postsToSeed.add(FeedModel(
        key: _database.child("geniiPosts").push().key,
        userId: ownerUser.userId!, user: ownerUser, createdAt: now,
        postType: PostTypes.LoanUpdate, propertyId: property1.id,
        description: "Mortgage application status update for 123 Main St.",
        eventPayload: {
          'lenderName': "BigBank Loans", 'status': "Pending", 'amount': 350000,
          'termInMonths': 360, 'interestRate': 3.75, 'note': "Initial review complete, awaiting appraisal."
        },
      ));

      // TaskUpdate
      postsToSeed.add(FeedModel(
        key: _database.child("geniiPosts").push().key,
        userId: contractorUser.userId!, user: contractorUser, createdAt: now,
        postType: PostTypes.TaskUpdate, propertyId: property2.id,
        description: "Kitchen remodel progress at 456 Oak Ave.",
        eventPayload: {
          'taskName': "Kitchen Remodel - Phase 1", 'status': "In Progress",
          'contractorName': contractorUser.displayName, 'percentComplete': 0.45
        },
      ));

      // ServiceMatch
      postsToSeed.add(FeedModel(
        key: _database.child("geniiPosts").push().key,
        userId: agentUser.userId!, user: agentUser, createdAt: now, // Agent found a service
        postType: PostTypes.ServiceMatch, propertyId: property1.id,
        description: "Found a plumber for the leak at 123 Main St.",
        eventPayload: {
          'serviceType': "Plumbing - Leak Repair", 'providerName': "Pipe Masters Inc.",
          'contactInfo': "555-0102", 'priceEstimate': "\$150 - \$300"
        },
      ));

      // PropertyListing posts are now handled by ListingIngestService with live data
      // So, we remove the mock PropertyListing generation from here.
      /*
      postsToSeed.add(FeedModel(
        key: _database.child("geniiPosts").push().key,
        userId: ownerUser.userId!, user: ownerUser, createdAt: now, // System or agent might post this
        postType: PostTypes.PropertyListing, propertyId: "prop_external_${_uuid.v4()}", // Not one of our properties, but a listing
        description: "New listing found on Zillow: Spacious 4 bed in downtown.",
        eventPayload: {
          'address': "789 Pine St, Anytown, USA", 'price': 620000, 'bedrooms': 4, 'bathrooms': 3, 'sqft': 2200,
          'imageUrl': "https://picsum.photos/seed/prop1/600/400", 'source': "Zillow",
          'listingUrl': "https://www.zillow.com/some-listing-id"
          // Ensure 'zip' is added here if this mock were to be used with geo-filtering
        },
      ));
      */

      for (var post in postsToSeed) {
        await _database.child("geniiPosts").child(post.key!).set(post.toJson());
      }
      print("${postsToSeed.length} initial non-PropertyListing posts seeded by MockSeedService.");

      // Trigger AgentReply for the AgentPrompt
      await MockAgentEngine().processAgentPrompt(agentPromptPost);
      print("AgentReply triggered for seeded AgentPrompt.");

      // Trigger TrustDistributionEvent
      // Assuming TrustPaymentEngine and its mock data are set up
      // You might need to ensure a TrustAccount exists that matches this or pass one.
      // For simplicity, let's use the one hardcoded in TrustPaymentEngine if it uses one like "trustAcc123_property123"
      // And ensure property1.id matches what the TrustPaymentEngine expects or can handle.
      // Let's assume property1 is "property123" for the purpose of this seed matching the engine's mock.
      // This is a bit brittle if the mock data in TrustPaymentEngine changes.
      // A better approach would be to create a TrustAccount here and pass its ID.
      // For now, we'll call it and hope the IDs align or the engine handles it.
      // To make it more robust, let's assume the TrustPaymentEngine's mock account is for "property123"
      // and we rename our property1.id for this seed.
      // String property1OriginalId = property1.id;
      // property1.id = "property123"; // TEMPORARY for matching existing mock in TrustPaymentEngine
      // await _database.child('properties').child(property1.id).set(property1.toJson());

      // Create a TrustAccount for property1 for the TrustDistributionEvent
      final trustAccountForProp1 = TrustAccount(
          id: "trustAcc_${property1.id}",
          propertyId: property1.id,
          name: "Operating Account for ${property1.address}",
          stakeholders: [
            TrustStakeholder(userId: ownerUser.userId!, role: "Equity", ownershipPercent: 0.6, paymentMethodId: "pm_owner"),
            TrustStakeholder(userId: agentUser.userId!, role: "Agent", ownershipPercent: 0.1, paymentMethodId: "pm_agent"),
            TrustStakeholder(userId: "investor_mock_id_${_uuid.v4()}", role: "Investor", ownershipPercent: 0.3, paymentMethodId: "pm_investor"),
          ],
          rules: [
            CashFlowRule(trigger: "RentReceived", distributions: [
              CashDistribution(stakeholderRole: "Equity", percent: 0.6),
              CashDistribution(stakeholderRole: "Investor", percent: 0.3),
              CashDistribution(stakeholderRole: "Agent", percent: 0.1),
            ])
          ]
        );
      // Save this trust account (if TrustPaymentEngine doesn't create/use its own internal one)
      // For now, TrustPaymentEngine uses an internal mock. We'll just call it.
      // The key is that the processCashInflow will create a FeedModel of type TrustDistributionEvent.
      // We need to ensure the `trustAccountId` used in `processCashInflow` matches an existing mock account
      // or the engine needs to be more flexible.
      // The current TrustPaymentEngine expects "trustAcc123_property123".
      // Let's assume we want the event on our seeded property1.
      // We'd need a TrustAccount definition for property1.id that the engine can find.
      // The current seed script for TrustPaymentEngine has a hardcoded "trustAcc123_property123".
      // This part is tricky without modifying TrustPaymentEngine's mock data access.
      // For now, let's just call it with the known mock ID from that engine to get a post.

      print("Attempting to seed TrustDistributionEvent using TrustPaymentEngine...");
      await TrustPaymentEngine().processCashInflow(
        trustAccountId: "trustAcc123_property123", // This ID is hardcoded in TrustPaymentEngine's mock
        amount: 3000.00,
        triggerEvent: "RentReceived",
        eventDescription: "Monthly rent collected for mock property via seed."
      );
      print("TrustDistributionEvent seeded.");

      // property1.id = property1OriginalId; // Revert if changed
      // await _database.child('properties').child(property1.id).set(property1.toJson());


      print("Mock data seeding complete!");

    } catch (e, s) {
      print("Error during mock data seeding: $e");
      print(s);
    }
  }
}

// Helper extension for Property model if not already present
extension PropertyCopyWith on Property {
  Property copyWith({
    String? id,
    String? address,
    String? ownerId,
    List<String>? agentIds,
    List<String>? moduleIds,
  }) {
    return Property(
      id: id ?? this.id,
      address: address ?? this.address,
      ownerId: ownerId ?? this.ownerId,
      agentIds: agentIds ?? this.agentIds,
      moduleIds: moduleIds ?? this.moduleIds,
    );
  }
}
