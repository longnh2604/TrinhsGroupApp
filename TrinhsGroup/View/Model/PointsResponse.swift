import Foundation

struct PointsResponse: Decodable {
    let userId: Int
    let type: String
    let balance: Double

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case type
        case balance
    }
}

// MARK: - WooCommerce Customer Response for Points
struct WooCustomerMetaData: Decodable {
    let id: Int
    let key: String
    let value: MetaValue
    
    enum MetaValue: Decodable {
        case string(String)
        case int(Int)
        case double(Double)
        case dictionary([String: AnyCodable])
        case array([AnyCodable])
        case null
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            
            if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
            } else if let intValue = try? container.decode(Int.self) {
                self = .int(intValue)
            } else if let doubleValue = try? container.decode(Double.self) {
                self = .double(doubleValue)
            } else if let dictValue = try? container.decode([String: AnyCodable].self) {
                self = .dictionary(dictValue)
            } else if let arrayValue = try? container.decode([AnyCodable].self) {
                self = .array(arrayValue)
            } else if container.decodeNil() {
                self = .null
            } else {
                self = .null
            }
        }
        
        var doubleValue: Double? {
            switch self {
            case .string(let str):
                return Double(str)
            case .int(let intVal):
                return Double(intVal)
            case .double(let doubleVal):
                return doubleVal
            default:
                return nil
            }
        }
    }
}

struct WooCustomerPointsResponse: Decodable {
    let id: Int
    let metaData: [WooCustomerMetaData]
    
    enum CodingKeys: String, CodingKey {
        case id
        case metaData = "meta_data"
    }
    
    /// Extract mycred_default points from meta_data
    func getMyCreditPoints() -> Double {
        for meta in metaData {
            if meta.key == "mycred_default" {
                return meta.value.doubleValue ?? 0.0
            }
        }
        return 0.0
    }
}

// MARK: - Redeem Response Model
struct RedeemResponse: Decodable {
    let couponCode: String
    let amount: Double
    let currency: String
    let expiresAt: String
    let pointsUsed: Int
    let balance: Double
    
    enum CodingKeys: String, CodingKey {
        case couponCode = "coupon_code"
        case amount
        case currency
        case expiresAt = "expires_at"
        case pointsUsed = "points_used"
        case balance
    }
    
    /// Parse expiration date
    var expirationDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: expiresAt) ?? ISO8601DateFormatter().date(from: expiresAt)
    }
}

// MARK: - Redeem Error Response
struct RedeemErrorResponse: Decodable {
    let error: String
    let balance: Double?
}

// MARK: - User Vouchers Response
struct UserVouchersResponse: Decodable {
    let userId: Int
    let vouchers: [VoucherResponse]
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case vouchers
        case count
    }
}

// MARK: - WooCommerce Coupon Response (from WC REST API)
struct WCCouponResponse: Decodable, Identifiable {
    let id: Int
    let code: String
    let amount: String  // WC returns amount as string
    let discountType: String
    let description: String
    let dateExpires: String?
    let dateExpiresGmt: String?
    let usageCount: Int
    let usageLimit: Int?
    let usageLimitPerUser: Int?
    let individualUse: Bool
    let minimumAmount: String
    let maximumAmount: String
    let emailRestrictions: [String]
    let usedBy: [String]  // Can contain emails or user IDs as strings
    
    enum CodingKeys: String, CodingKey {
        case id
        case code
        case amount
        case discountType = "discount_type"
        case description
        case dateExpires = "date_expires"
        case dateExpiresGmt = "date_expires_gmt"
        case usageCount = "usage_count"
        case usageLimit = "usage_limit"
        case usageLimitPerUser = "usage_limit_per_user"
        case individualUse = "individual_use"
        case minimumAmount = "minimum_amount"
        case maximumAmount = "maximum_amount"
        case emailRestrictions = "email_restrictions"
        case usedBy = "used_by"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        code = try container.decode(String.self, forKey: .code)
        amount = try container.decode(String.self, forKey: .amount)
        discountType = try container.decode(String.self, forKey: .discountType)
        description = try container.decode(String.self, forKey: .description)
        dateExpires = try container.decodeIfPresent(String.self, forKey: .dateExpires)
        dateExpiresGmt = try container.decodeIfPresent(String.self, forKey: .dateExpiresGmt)
        usageCount = try container.decode(Int.self, forKey: .usageCount)
        usageLimit = try container.decodeIfPresent(Int.self, forKey: .usageLimit)
        usageLimitPerUser = try container.decodeIfPresent(Int.self, forKey: .usageLimitPerUser)
        individualUse = try container.decode(Bool.self, forKey: .individualUse)
        minimumAmount = try container.decode(String.self, forKey: .minimumAmount)
        maximumAmount = try container.decode(String.self, forKey: .maximumAmount)
        emailRestrictions = try container.decode([String].self, forKey: .emailRestrictions)
        
        // Handle usedBy as mixed array (can contain Int or String)
        var usedByArray: [String] = []
        if var usedByContainer = try? container.nestedUnkeyedContainer(forKey: .usedBy) {
            while !usedByContainer.isAtEnd {
                if let intValue = try? usedByContainer.decode(Int.self) {
                    usedByArray.append(String(intValue))
                } else if let stringValue = try? usedByContainer.decode(String.self) {
                    usedByArray.append(stringValue)
                } else {
                    // Skip unknown types
                    _ = try? usedByContainer.decode(AnyCodable.self)
                }
            }
        }
        usedBy = usedByArray
    }
    
    /// Get amount as Double
    var amountValue: Double {
        return Double(amount) ?? 0
    }
    
    /// Parse expiration date
    var expirationDate: Date? {
        guard let dateExpires = dateExpires, !dateExpires.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateExpires) {
            return date
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateExpires) {
            return date
        }
        // Try simple date format
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return simpleFormatter.date(from: dateExpires)
    }
    
    /// Check if coupon is expired
    var isExpired: Bool {
        guard let expDate = expirationDate else { return false }
        return expDate < Date()
    }
    
    /// Check if coupon is still valid (not expired, not fully used)
    var isValid: Bool {
        // Check expiration
        if isExpired { return false }
        // Check usage limit
        if let limit = usageLimit, limit > 0, usageCount >= limit {
            return false
        }
        return true
    }
    
    /// Formatted expiry date string
    var formattedExpiryDate: String {
        guard let expDate = expirationDate else { return "No expiry" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: expDate)
    }
    
    /// Convert to VoucherResponse for UI compatibility
    func toVoucherResponse() -> VoucherResponse {
        return VoucherResponse(
            id: id,
            code: code,
            amount: amountValue,
            currency: "AUD",
            expiresAt: dateExpires,
            usageCount: usageCount,
            usageLimit: usageLimit ?? 0,
            status: isValid ? "active" : "inactive"
        )
    }
}

// MARK: - Voucher Response from API
struct VoucherResponse: Decodable, Identifiable {
    let id: Int
    let code: String
    let amount: Double
    let currency: String
    let expiresAt: String?
    let usageCount: Int
    let usageLimit: Int
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case code
        case amount
        case currency
        case expiresAt = "expires_at"
        case usageCount = "usage_count"
        case usageLimit = "usage_limit"
        case status
    }
    
    /// Parse expiration date
    var expirationDate: Date? {
        guard let expiresAt = expiresAt else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: expiresAt) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: expiresAt) {
            return date
        }
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return simpleFormatter.date(from: expiresAt)
    }
    
    /// Check if voucher is expired
    var isExpired: Bool {
        guard let expDate = expirationDate else { return false }
        return expDate < Date()
    }
    
    /// Formatted expiry date string
    var formattedExpiryDate: String {
        guard let expDate = expirationDate else { return "No expiry" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: expDate)
    }
}

// MARK: - AnyCodable helper for flexible JSON decoding
struct AnyCodable: Decodable {
    let value: Any
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
}
