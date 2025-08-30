import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import AuthenticationServices
import GoogleSignIn

// MARK: - Auth Client

protocol AuthClient {
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User
    func signInWithGoogle(presentingViewController: UIViewController) async throws -> User
    func signOut() throws
    func deleteAccount() async throws
}

class FirebaseAuthClient: AuthClient {
    
    private let auth = Auth.auth()
    
    var currentUser: User? {
        guard let firebaseUser = auth.currentUser else { return nil }
        return User(
            id: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL?.absoluteString
        )
    }
    
    var isAuthenticated: Bool {
        return auth.currentUser != nil
    }
    
    // MARK: - Apple Sign In
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidCredential
        }
        
        let firebaseCredential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: tokenString,
            rawNonce: nil // TODO: Implement nonce for security
        )
        
        let result = try await auth.signIn(with: firebaseCredential)
        
        // Update display name if provided
        if let fullName = credential.fullName {
            let displayName = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            if !displayName.isEmpty {
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try await changeRequest.commitChanges()
            }
        }
        
        return User(
            id: result.user.uid,
            email: result.user.email,
            displayName: result.user.displayName,
            photoURL: result.user.photoURL?.absoluteString
        )
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle(presentingViewController: UIViewController) async throws -> User {
        // TODO: Implement Google Sign In
        // Requires GoogleSignIn SDK configuration
        
        /*
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.configurationError
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.invalidCredential
        }
        
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        
        let authResult = try await auth.signIn(with: credential)
        
        return User(
            id: authResult.user.uid,
            email: authResult.user.email,
            displayName: authResult.user.displayName,
            photoURL: authResult.user.photoURL?.absoluteString
        )
        */
        
        throw AuthError.notImplemented
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        try auth.signOut()
    }
    
    // MARK: - Delete Account
    
    func deleteAccount() async throws {
        guard let user = auth.currentUser else {
            throw AuthError.notAuthenticated
        }
        
        // Delete user data from Firestore
        let db = Firestore.firestore()
        try await db.collection(Constants.FirebaseCollection.users).document(user.uid).delete()
        
        // Delete user account
        try await user.delete()
    }
}

// MARK: - Firestore Client

protocol FirestoreClient {
    func save<T: Codable>(_ object: T, to collection: String, id: String?) async throws -> String
    func fetch<T: Codable>(_ type: T.Type, from collection: String, id: String) async throws -> T?
    func fetchAll<T: Codable>(_ type: T.Type, from collection: String, query: Query?) async throws -> [T]
    func delete(from collection: String, id: String) async throws
    func listenToDocument<T: Codable>(_ type: T.Type, collection: String, id: String, handler: @escaping (T?) -> Void) -> ListenerRegistration
    func listenToCollection<T: Codable>(_ type: T.Type, collection: String, query: Query?, handler: @escaping ([T]) -> Void) -> ListenerRegistration
}

class FirestoreClientImpl: FirestoreClient {
    
    private let db = Firestore.firestore()
    
    init() {
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings
    }
    
    func save<T: Codable>(_ object: T, to collection: String, id: String? = nil) async throws -> String {
        let encoder = Firestore.Encoder()
        let data = try encoder.encode(object)
        
        let docRef: DocumentReference
        if let id = id {
            docRef = db.collection(collection).document(id)
        } else {
            docRef = db.collection(collection).document()
        }
        
        try await docRef.setData(data)
        return docRef.documentID
    }
    
    func fetch<T: Codable>(_ type: T.Type, from collection: String, id: String) async throws -> T? {
        let docRef = db.collection(collection).document(id)
        let document = try await docRef.getDocument()
        
        guard document.exists else { return nil }
        
        return try document.data(as: type)
    }
    
    func fetchAll<T: Codable>(_ type: T.Type, from collection: String, query: Query? = nil) async throws -> [T] {
        let collectionRef = db.collection(collection)
        let finalQuery = query ?? collectionRef
        
        let snapshot = try await finalQuery.getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: type)
        }
    }
    
    func delete(from collection: String, id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }
    
    func listenToDocument<T: Codable>(_ type: T.Type, collection: String, id: String, handler: @escaping (T?) -> Void) -> ListenerRegistration {
        return db.collection(collection).document(id).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error listening to document: \(error)")
                handler(nil)
                return
            }
            
            guard let document = snapshot, document.exists else {
                handler(nil)
                return
            }
            
            do {
                let object = try document.data(as: type)
                handler(object)
            } catch {
                print("Error decoding document: \(error)")
                handler(nil)
            }
        }
    }
    
    func listenToCollection<T: Codable>(_ type: T.Type, collection: String, query: Query? = nil, handler: @escaping ([T]) -> Void) -> ListenerRegistration {
        let collectionRef = db.collection(collection)
        let finalQuery = query ?? collectionRef
        
        return finalQuery.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error listening to collection: \(error)")
                handler([])
                return
            }
            
            guard let documents = snapshot?.documents else {
                handler([])
                return
            }
            
            let objects = documents.compactMap { document -> T? in
                do {
                    return try document.data(as: type)
                } catch {
                    print("Error decoding document: \(error)")
                    return nil
                }
            }
            
            handler(objects)
        }
    }
}

// MARK: - Storage Client

protocol StorageClient {
    func upload(data: Data, to path: String, metadata: [String: String]?) async throws -> URL
    func download(from path: String) async throws -> Data
    func delete(at path: String) async throws
    func getDownloadURL(for path: String) async throws -> URL
}

class FirebaseStorageClient: StorageClient {
    
    private let storage = Storage.storage()
    private let maxUploadSize: Int64 = 25 * 1024 * 1024 // 25 MB
    
    func upload(data: Data, to path: String, metadata: [String: String]? = nil) async throws -> URL {
        guard data.count <= maxUploadSize else {
            throw StorageError.fileTooLarge
        }
        
        let storageRef = storage.reference().child(path)
        
        let storageMetadata = StorageMetadata()
        storageMetadata.customMetadata = metadata
        
        // Detect content type
        if path.hasSuffix(".jpg") || path.hasSuffix(".jpeg") {
            storageMetadata.contentType = "image/jpeg"
        } else if path.hasSuffix(".png") {
            storageMetadata.contentType = "image/png"
        } else if path.hasSuffix(".pdf") {
            storageMetadata.contentType = "application/pdf"
        }
        
        _ = try await storageRef.putDataAsync(data, metadata: storageMetadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL
    }
    
    func download(from path: String) async throws -> Data {
        let storageRef = storage.reference().child(path)
        let data = try await storageRef.data(maxSize: maxUploadSize)
        return data
    }
    
    func delete(at path: String) async throws {
        let storageRef = storage.reference().child(path)
        try await storageRef.delete()
    }
    
    func getDownloadURL(for path: String) async throws -> URL {
        let storageRef = storage.reference().child(path)
        return try await storageRef.downloadURL()
    }
}

// MARK: - Firestore Security Rules Example

let firestoreRules = """
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isRoomMember(roomId) {
      return isAuthenticated() && 
        exists(/databases/$(database)/documents/rooms/$(roomId)/members/$(request.auth.uid));
    }
    
    function isRoomAdmin(roomId) {
      return isAuthenticated() && 
        get(/databases/$(database)/documents/rooms/$(roomId)/members/$(request.auth.uid)).data.role in ['admin', 'owner'];
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isOwner(userId);
      allow write: if isOwner(userId);
    }
    
    // Rides collection
    match /rides/{rideId} {
      allow read: if isOwner(resource.data.userId) || 
                     (resource.data.roomId != null && isRoomMember(resource.data.roomId));
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId);
    }
    
    // Expenses collection
    match /expenses/{expenseId} {
      allow read: if isOwner(resource.data.paidBy) || 
                     request.auth.uid in resource.data.participants ||
                     (resource.data.roomId != null && isRoomMember(resource.data.roomId));
      allow create: if isAuthenticated();
      allow update: if isOwner(resource.data.paidBy) || 
                      (resource.data.roomId != null && isRoomAdmin(resource.data.roomId));
      allow delete: if isOwner(resource.data.paidBy) || 
                      (resource.data.roomId != null && isRoomAdmin(resource.data.roomId));
    }
    
    // Rooms collection
    match /rooms/{roomId} {
      allow read: if isRoomMember(roomId);
      allow create: if isAuthenticated();
      allow update: if isRoomAdmin(roomId);
      allow delete: if false; // Only allow through Cloud Functions
      
      // Room members subcollection
      match /members/{memberId} {
        allow read: if isRoomMember(roomId);
        allow create: if isAuthenticated() && request.auth.uid == memberId;
        allow update: if isRoomAdmin(roomId) || isOwner(memberId);
        allow delete: if isRoomAdmin(roomId) || isOwner(memberId);
      }
      
      // Room messages subcollection
      match /messages/{messageId} {
        allow read: if isRoomMember(roomId);
        allow create: if isRoomMember(roomId) && request.resource.data.senderId == request.auth.uid;
        allow update: if false;
        allow delete: if isOwner(resource.data.senderId) || isRoomAdmin(roomId);
      }
    }
    
    // POIs collection (public read, authenticated write)
    match /pois/{poiId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update: if isOwner(resource.data.createdBy);
      allow delete: if false; // Only through admin
    }
  }
}
"""

// MARK: - Models

struct User: Codable {
    let id: String
    let email: String?
    let displayName: String?
    let photoURL: String?
}

struct UserProfile: Codable {
    let userId: String
    let displayName: String
    let email: String?
    let phoneNumber: String?
    let photoURL: String?
    let createdAt: Date
    var updatedAt: Date
    var preferences: UserPreferences
    var stats: UserStats
}

struct UserPreferences: Codable {
    var recordingMode: RecordingMode = .auto
    var defaultVehicleId: String?
    var mapProvider: MapProvider = .google
    var notifications: NotificationPreferences
    var privacy: PrivacySettings
}

struct UserStats: Codable {
    var totalRides: Int = 0
    var totalDistance: Double = 0
    var totalExpenses: Double = 0
    var totalRooms: Int = 0
}

struct NotificationPreferences: Codable {
    var rideReminders: Bool = true
    var serviceReminders: Bool = true
    var documentExpiry: Bool = true
    var roomInvites: Bool = true
}

struct PrivacySettings: Codable {
    var shareLocation: Bool = false
    var shareStats: Bool = false
    var publicProfile: Bool = false
}

enum MapProvider: String, Codable {
    case google = "google"
    case apple = "apple"
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidCredential
    case notAuthenticated
    case configurationError
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid authentication credentials"
        case .notAuthenticated:
            return "User is not authenticated"
        case .configurationError:
            return "Authentication configuration error"
        case .notImplemented:
            return "This feature is not yet implemented"
        }
    }
}

enum StorageError: LocalizedError {
    case fileTooLarge
    case uploadFailed
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .fileTooLarge:
            return "File size exceeds maximum limit"
        case .uploadFailed:
            return "Failed to upload file"
        case .downloadFailed:
            return "Failed to download file"
        }
    }
}