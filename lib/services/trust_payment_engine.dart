import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/model/trust_models.dart';
import 'package:flutter_twitter_clone/model/user.dart'; // Assuming UserModel is needed for the 'user' field in FeedModel
import 'package:flutter_twitter_clone/config/firebase_config.dart'; // Import firebase_config

// Mock User Data (Placeholder - replace with actual user fetching if needed)
UserModel _getMockUser(String userId) {
  // In a real app, you'd fetch user details from a service or database
  return UserModel(
      userId: userId,
      displayName: 'User $userId',
      userName: 'user$userId',
      profilePic: 'https://picsum.photos/50/50?random=$userId', // Placeholder image
      isVerified: false,
      // Add other necessary fields for UserModel if FeedModel requires them
      // For example, if FeedModel.user.toJson() is called and expects more fields.
      bio: 'Mock bio for $userId',
      coverImage: '',
      dob: '',
      email: '$userId@example.com',
      followers: 0,
      following: 0,
      followersList: [],
      followingList: [],
      fcmToken: '',
      webSite: '',
      location: ''
      );
}


// Mock Trust Account Data (Step 4 will refine this, placing it here for now for engine implementation)
TrustAccount _getMockTrustAccount(String trustAccountId) {
  // This would typically be fetched from a database or configuration
  if (trustAccountId == "trustAcc123_property123") {
    return TrustAccount(
      id: "trustAcc123_property123",
      propertyId: "property123",
      name: "Main Operating Account for Property 123",
      stakeholders: [
        TrustStakeholder(userId: "userEquity1", role: "Equity", ownershipPercent: 50, paymentMethodId: "pm_equity1"),
        TrustStakeholder(userId: "userInvestor1", role: "Investor", ownershipPercent: 40, paymentMethodId: "pm_investor1"),
        TrustStakeholder(userId: "userAgent1", role: "Agent", ownershipPercent: 10, paymentMethodId: "pm_agent1"),
        TrustStakeholder(userId: "userContractor1", role: "Contractor", paymentMethodId: "pm_contractor1"), // Contractor not in RentReceived rule
      ],
      rules: [
        CashFlowRule(
          trigger: "RentReceived",
          distributions: [
            CashDistribution(stakeholderRole: "Equity", percent: 0.50), // 50%
            CashDistribution(stakeholderRole: "Investor", percent: 0.40), // 40%
            CashDistribution(stakeholderRole: "Agent", percent: 0.10), // 10%
          ],
          description: "Standard rent distribution for Property 123",
        ),
        CashFlowRule(
          trigger: "SpecialAssessment",
          distributions: [ // Example of a different rule
            CashDistribution(stakeholderRole: "Equity", percent: 0.60),
            CashDistribution(stakeholderRole: "Investor", percent: 0.40),
          ],
          description: "Distribution for special assessment income",
        )
      ],
    );
  }
  throw Exception("Trust account not found: $trustAccountId");
}

class TrustPaymentEngine {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> processCashInflow({
    required String trustAccountId,
    required double amount,
    required String triggerEvent,
    String? eventDescription, // Optional: e.g., "Monthly Rent for Unit 5B"
  }) async {
    print("Processing cash inflow: Account $trustAccountId, Amount: $amount, Event: $triggerEvent");

    try {
      // 1. Fetch TrustAccount (using mock version for now)
      final trustAccount = _getMockTrustAccount(trustAccountId);

      // 2. Find matching CashFlowRule
      final rule = trustAccount.rules.firstWhere(
        (r) => r.trigger == triggerEvent,
        orElse: () => throw Exception("No rule found for trigger: $triggerEvent in account: $trustAccountId"),
      );

      // 3. Apply rules to calculate distributions
      List<Map<String, dynamic>> calculatedDistributions = [];
      double totalDistributedPercent = 0.0;

      for (var distRule in rule.distributions) {
        final matchingStakeholders = trustAccount.stakeholders
            .where((s) => s.role == distRule.stakeholderRole)
            .toList();

        if (matchingStakeholders.isEmpty) {
          print("Warning: No stakeholder found for role ${distRule.stakeholderRole} in rule ${rule.trigger}. Skipping this distribution.");
          continue;
        }

        // For simplicity, if multiple stakeholders have the same role (e.g. multiple investors),
        // this logic will give each of them the full percentage defined in the rule.
        // A more complex scenario might divide the role's percentage among them based on their ownershipPercent or other logic.
        // The current prompt implies a simple percentage split based on role directly from the inflow.
        for (var stakeholder in matchingStakeholders) {
          double distributionAmount = amount * distRule.percent;
          calculatedDistributions.add({
            "userId": stakeholder.userId,
            "role": stakeholder.role,
            "amount": double.parse(distributionAmount.toStringAsFixed(2)), // Ensure 2 decimal places
            "paymentMethodId": stakeholder.paymentMethodId, // For future use
          });
        }
        totalDistributedPercent += distRule.percent;
      }

      // Sanity check for distribution percentages
      if ((totalDistributedPercent - 1.0).abs() > 0.001) { // Using a tolerance for double comparison
        print("Warning: Total distributed percentage for rule $triggerEvent is $totalDistributedPercent, which is not 100%. Amount: $amount");
        // Decide if this should throw an error or just be a warning based on business rules.
        // For now, it's a warning, and it will distribute as per rules.
      }

      // 4. Generate GeniiPost (FeedModel) of type TrustDistributionEvent
      final String newPostKey = _database.child(postsCollectionPath).push().key ?? "fallback_key_${DateTime.now().millisecondsSinceEpoch}"; // Use dynamic path

      // The "userId" for the FeedModel could be a system user, the agent initiating, or the property owner.
      // For now, let's use a generic system ID or the first stakeholder's ID as a placeholder.
      final String eventPosterUserId = trustAccount.stakeholders.isNotEmpty ? trustAccount.stakeholders.first.userId : "systemUser";

      final eventPost = FeedModel(
        key: newPostKey,
        userId: eventPosterUserId, // This should ideally be a system/property owner ID
        createdAt: DateTime.now().toUtc().toIso8601String(),
        postType: PostTypes.TrustDistributionEvent, // Use PostTypes constant
        propertyId: trustAccount.propertyId,
        description: eventDescription ?? "${rule.description ?? triggerEvent} processed for ${trustAccount.name}",
        user: _getMockUser(eventPosterUserId), // Attach mock user object
        eventPayload: {
          "trustAccountId": trustAccount.id,
          "totalAmount": amount,
          "sourceEvent": triggerEvent,
          "ruleTriggered": rule.trigger,
          "ruleDescription": rule.description,
          "distributions": calculatedDistributions,
        },
        status: PostStatus.New, // Use PostStatus constant
        // Other FeedModel fields like likeCount, commentCount, etc., are not relevant here and will use defaults or be null.
      );

      // 5. Push this post to Firebase
      await _database.child(postsCollectionPath).child(newPostKey).set(eventPost.toJson()); // Use dynamic path
      print("TrustDistributionEvent post created in Firebase ($postsCollectionPath): $newPostKey");

    } catch (e) {
      print("Error processing cash inflow: $e");
      // Rethrow or handle as per application's error handling strategy
      rethrow;
    }
  }
}
