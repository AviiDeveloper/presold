import Foundation

/// User record extending `auth.users`. Mirrors the `users` table in
/// `docs/data-model.md`. Named `AppUser` to avoid clashing with the
/// `User` types in `AuthenticationServices` and Supabase auth payloads.
public struct AppUser: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let email: String
    public let createdAt: Date
    public let subscriptionStatus: SubscriptionStatus
    public let subscriptionProvider: SubscriptionProvider?
    public let subscriptionExpiresAt: Date?
    /// Token used for inbound sale-email parsing
    /// (`<token>@sales.presold.app`).
    public let saleEmailToken: String

    public init(
        id: UUID,
        email: String,
        createdAt: Date,
        subscriptionStatus: SubscriptionStatus = .trial,
        subscriptionProvider: SubscriptionProvider? = nil,
        subscriptionExpiresAt: Date? = nil,
        saleEmailToken: String
    ) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
        self.subscriptionStatus = subscriptionStatus
        self.subscriptionProvider = subscriptionProvider
        self.subscriptionExpiresAt = subscriptionExpiresAt
        self.saleEmailToken = saleEmailToken
    }
}

public enum SubscriptionStatus: String, Codable, CaseIterable, Sendable {
    case trial
    case active
    case cancelled
    case expired

    public var isPayingOrTrialing: Bool {
        self == .trial || self == .active
    }
}

public enum SubscriptionProvider: String, Codable, CaseIterable, Sendable {
    case storekit
    case stripe
}
