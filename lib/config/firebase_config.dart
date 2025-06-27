// Configuration for Firebase settings, including collection path toggles for Dev/Prod.

// Set to true to use development collections (e.g., "geniiPosts_dev")
// Set to false to use production collections (e.g., "geniiPosts")
const bool kUseDevCollections = true;

// Collection Path Getters
String get postsCollectionPath => kUseDevCollections ? "geniiPosts_dev" : "geniiPosts";
String get usersCollectionPath => kUseDevCollections ? "profile_dev" : "profile"; // 'profile' is used for users in this codebase
String get propertiesCollectionPath => kUseDevCollections ? "properties_dev" : "properties";
String get agentsCollectionPath => kUseDevCollections ? "agents_dev" : "agents";
String get trustAccountsCollectionPath => kUseDevCollections ? "trustAccounts_dev" : "trustAccounts"; // For TrustPaymentEngine if it saves accounts
String get bookmarksCollectionPath => kUseDevCollections ? "bookmark_dev" : "bookmark"; // From FeedState
String get notificationsCollectionPath => kUseDevCollections ? "notification_dev" : "notification"; // From FeedState & NotificationState
String get chatUsersCollectionPath => kUseDevCollections ? "chatUsers_dev" : "chatUsers"; // For user-specific chat metadata
String get chatCollectionPath => kUseDevCollections ? "chats_dev" : "chats"; // For actual chat messages between users
String get messagesCollectionPath => kUseDevCollections ? "messages_dev" : "messages"; // Standard name for sub-collection of messages (might not be used if chats/{channelName} stores messages directly)

// Note: The kDatabase constant in utility.dart often refers to FirebaseDatabase.instance.ref().
// If specific top-level nodes within Realtime Database also need dev/prod separation,
// similar logic would apply, e.g. kDatabase.child(dynamicNodeName)
// For Firestore, this pattern is for collection names.
// For Realtime Database, if the root itself is not changing, but child nodes are,
// then the paths used with .child() would incorporate this logic.
// Example: FirebaseDatabase.instance.ref(kUseDevCollections ? "dev" : "prod").child("tweet")
// However, the current app uses kDatabase.child("collectionName"), so we are targeting collectionName.
// The existing kDatabase points to FirebaseDatabase.instance.ref(), so Firebase Realtime Database.
// The code uses `kDatabase.child('tweet')` (now `geniiPosts`) or `kDatabase.child('profile')`.
// So, these getters will provide the correct child node names.
// `FirebaseFirestore.instance.collection()` would also use these getters.
// The current project seems to mostly use Firebase Realtime Database for these paths.
// I will update paths for Realtime Database children.
// Firestore is also a dependency, so if it's used, this applies there too.
// The logic for `kDatabase.child(postsCollectionPath)` will correctly use these.

// Example usage:
// FirebaseDatabase.instance.ref().child(postsCollectionPath)...
// FirebaseFirestore.instance.collection(usersCollectionPath)...
