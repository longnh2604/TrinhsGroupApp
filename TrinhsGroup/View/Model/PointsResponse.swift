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
