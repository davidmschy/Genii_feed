enum AuthStatus {
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN,
}
enum TweetType {
  Tweet,
  Detail,
  Reply,
  ParentTweet,
}

enum SortUser {
  Verified,
  Alphabetically,
  Newest,
  Oldest,
  MaxFollower,
}

enum NotificationType {
  NOT_DETERMINED,
  Message,
  Tweet,
  Reply,
  Retweet,
  Follow,
  Mention,
  Like
}

// String constants for GeniiPost postType
class PostTypes {
  static const String Tweet = "Tweet"; // For backward compatibility or simple text posts
  static const String TrustDistributionEvent = "TrustDistributionEvent"; // Existing custom type from previous work

  // New Genii Feed specific post types from prompt
  static const String PropertyListing = "PropertyListing"; // For Zillow, CREXi, etc.
  static const String LoanUpdate = "LoanUpdate"; // For lender API updates
  static const String AgentPrompt = "AgentPrompt"; // User prompt to an AI agent
  static const String AgentReply = "AgentReply"; // AI agent's reply to a prompt
  static const String TaskUpdate = "TaskUpdate"; // For task management updates
  static const String CashFlowEvent = "CashFlowEvent"; // Generic cash flow event (rent, expense, etc.)
  static const String ExternalAPI = "ExternalAPI"; // For generic posts from other external APIs
  static const String ServiceMatch = "ServiceMatch"; // For TaskRabbit, Angi, etc.
  static const String RentalUpdate = "RentalUpdate"; // For Airbnb, Vrbo, etc. (mentioned in API section of prompt)
}
