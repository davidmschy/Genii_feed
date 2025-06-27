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

  // Helper to get all post type values, useful for "Owner" role seeing all
  static List<String> get values => [
        Tweet, TrustDistributionEvent, PropertyListing, LoanUpdate, AgentPrompt,
        AgentReply, TaskUpdate, CashFlowEvent, ExternalAPI, ServiceMatch, RentalUpdate
      ];
}

// String constants for User Roles
class UserRoles {
  static const String Owner = "Owner";
  static const String Agent = "Agent"; // Real estate agent or AI agent controller
  static const String Contractor = "Contractor";
  static const String Investor = "Investor";
  static const String Lender = "Lender";
  static const String Manufacturer = "Manufacturer"; // Or Supplier
  static const String Tenant = "Tenant"; // Added Tenant as it's a common role in real estate
  static const String Admin = "Admin"; // System administrator
}

// String constants for AI Agent Types
class AgentTypes {
  static const String DealHunter = "DealHunter";
  static const String TaskManager = "TaskManager";
  static const String Concierge = "Concierge";
  // Add any other specific agent types here
}

// String constants for GeniiPost status
class PostStatus {
  static const String Open = "Open";
  static const String InProgress = "InProgress";
  static const String PendingApproval = "PendingApproval";
  static const String Resolved = "Resolved";
  static const String Closed = "Closed";
  static const String Archived = "Archived";
  static const String Draft = "Draft";
  static const String New = "New"; // For new listings, etc.
}
