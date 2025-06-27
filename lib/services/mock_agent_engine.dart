import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_twitter_clone/helper/enum.dart';
import 'package:flutter_twitter_clone/model/feedModel.dart';
import 'package:flutter_twitter_clone/model/user.dart'; // For creating a mock agent UserModel
import 'package:flutter_twitter_clone/config/firebase_config.dart'; // Import firebase_config

// Helper to create a mock UserModel for an Agent
UserModel _getMockAgentUser(String agentId, String agentName, String agentType) {
  return UserModel(
    userId: agentId,
    displayName: agentName,
    userName: agentType.toLowerCase().replaceAll(' ', '') + agentId.substring(0, min(5, agentId.length)), // e.g., dealhunterai123
    profilePic: '', // Agents might have profile pics later
    isVerified: true, // Let's say agents are "verified"
    bio: 'Automated AI Agent: $agentName',
    // Other fields as necessary for UserModel, though many might be null/empty for agents
    email: '$agentId@genii.ai',
    createdAt: DateTime.now().toUtc().toIso8601String(),
    roles: [UserRoles.Agent], // Agent has an "Agent" role
  );
}

class MockAgentEngine {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final Random _random = Random();

  Future<void> processAgentPrompt(FeedModel promptPost) async {
    print("MockAgentEngine: Received prompt: ${promptPost.key} from ${promptPost.userId}");

    // Simulate agent "thinking" time
    await Future.delayed(Duration(seconds: _random.nextInt(4) + 2)); // 2-5 seconds delay

    // For now, assume a generic agent replies. Later, this could be determined by promptPost.agentId or type.
    // If promptPost.agentId is set, we should use that. Otherwise, a default agent.
    String replyingAgentId = promptPost.agentId ?? "genAgentSysAI"; // Default system agent ID
    String replyingAgentName = "Genii Assistant";
    String replyingAgentType = AgentTypes.Concierge; // Default type

    // Potentially fetch actual agent details if promptPost.agentId is valid
    // For this mock, we'll just use a generic or derive from promptPost if possible.
    if (promptPost.agentId != null) {
        // In a real scenario, you'd fetch the agent's name/type based on agentId.
        // For mock, let's assume the agentId might give a hint or use defaults.
        replyingAgentName = "Agent ${promptPost.agentId!.substring(0,min(6,promptPost.agentId!.length))}"; // e.g. Agent ag1234
    }


    final mockAgentUser = _getMockAgentUser(replyingAgentId, replyingAgentName, replyingAgentType);

    final replyTextOptions = [
      "I'm on it! Processing your request: \"${promptPost.description ?? promptPost.eventPayload?['promptText']}\"",
      "Understood. I'll get back to you shortly regarding: \"${promptPost.description ?? promptPost.eventPayload?['promptText']}\"",
      "Working on that for you! I'll update you on \"${promptPost.description ?? promptPost.eventPayload?['promptText']}\" soon.",
      "Okay, I've received your prompt and will start working on it.",
      "Let me look into that. I'll provide an update as soon as possible."
    ];
    final replyText = replyTextOptions[_random.nextInt(replyTextOptions.length)];

    final String newPostKey = _database.child(postsCollectionPath).push().key ?? "reply_key_${DateTime.now().millisecondsSinceEpoch}"; // Use dynamic path

    final replyPost = FeedModel(
      key: newPostKey,
      userId: mockAgentUser.userId!, // The agent is the user for this post
      user: mockAgentUser, // Attach the agent's UserModel
      createdAt: DateTime.now().toUtc().toIso8601String(),
      postType: PostTypes.AgentReply,
      parentkey: promptPost.key, // Link back to the original prompt
      agentId: mockAgentUser.userId, // The agent who is replying
      propertyId: promptPost.propertyId, // Carry over propertyId if present
      description: replyText, // Can use description for simple text, or payload
      eventPayload: {
        'replyText': replyText,
        'originalPromptKey': promptPost.key,
        // Potentially add more structured data here later
      },
      status: PostStatus.Resolved, // Use PostStatus constant (Resolved or Complete)
      priority: promptPost.priority, // Inherit priority or set based on reply
    );

    try {
      await _database.child(postsCollectionPath).child(newPostKey).set(replyPost.toJson()); // Use dynamic path
      print("MockAgentEngine: AgentReply ${newPostKey} posted to Firebase ($postsCollectionPath) for prompt ${promptPost.key}");
    } catch (e) {
      print("MockAgentEngine: Error posting AgentReply: $e");
    }
  }
}
