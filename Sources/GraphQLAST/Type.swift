import Foundation

public enum Operation {
    case query(ObjectType)
    case mutation(ObjectType)
    case subscription(ObjectType)

    public var type: ObjectType {
        switch self {
        case let .query(type), let .mutation(type), let .subscription(type):
            return type
        }
    }
}

// MARK: - Named Type Protocol

public enum NamedTypeKind: String, Codable, Equatable {
    case scalar = "SCALAR"
    case object = "OBJECT"
    case interface = "INTERFACE"
    case union = "UNION"
    case enumeration = "ENUM"
    case inputObject = "INPUT_OBJECT"
}

public protocol NamedTypeProtocol {
    var kind: NamedTypeKind { get }
    var name: String { get }
    var description: String? { get }
}

public extension NamedTypeProtocol {
    var isInternal: Bool {
        name.starts(with: "__")
    }
}

// MARK: - Named Types

public struct ScalarType: NamedTypeProtocol, Decodable, Equatable {
    public var kind: NamedTypeKind = .scalar
    public let name: String
    public let description: String?
}

public struct ObjectType: NamedTypeProtocol, Decodable, Equatable {
    public var kind: NamedTypeKind = .object
    public let name: String
    public let description: String?

    public let fields: [Field]
    public let interfaces: [InterfaceTypeRef]?
}

public struct InterfaceType: NamedTypeProtocol, Decodable, Equatable {
    public var kind: NamedTypeKind = .interface
    public let name: String
    public let description: String?

    public let fields: [Field]
    public let interfaces: [InterfaceTypeRef]?
    public let possibleTypes: [ObjectTypeRef]
}

public struct UnionType: NamedTypeProtocol, Decodable, Equatable {
    public var kind: NamedTypeKind = .union
    public let name: String
    public let description: String?

    public let possibleTypes: [ObjectTypeRef]
}

public struct EnumType: NamedTypeProtocol, Decodable, Equatable {
    public var kind: NamedTypeKind = .enumeration
    public let name: String
    public let description: String?

    public let enumValues: [EnumValue]
}

public struct InputObjectType: NamedTypeProtocol, Decodable, Equatable {
    public var kind: NamedTypeKind = .inputObject
    public let name: String
    public let description: String?

    public let inputFields: [InputValue]
}

// MARK: - Collection Types

public enum NamedType: Equatable {
    case scalar(ScalarType)
    case object(ObjectType)
    case interface(InterfaceType)
    case union(UnionType)
    case `enum`(EnumType)
    case inputObject(InputObjectType)

    public var name: String {
        switch self {
        case let .enum(`enum`):
            return `enum`.name
        case let .inputObject(io):
            return io.name
        case let .interface(interface):
            return interface.name
        case let .object(object):
            return object.name
        case let .scalar(scalar):
            return scalar.name
        case let .union(union):
            return union.name
        }
    }
}

extension NamedType: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(NamedTypeKind.self, forKey: .kind)

        switch kind {
        case .scalar:
            let value = try ScalarType(from: decoder)
            self = .scalar(value)
        case .object:
            let value = try ObjectType(from: decoder)
            self = .object(value)
        case .interface:
            let value = try InterfaceType(from: decoder)
            self = .interface(value)
        case .union:
            let value = try UnionType(from: decoder)
            self = .union(value)
        case .enumeration:
            let value = try EnumType(from: decoder)
            self = .enum(value)
        case .inputObject:
            let value = try InputObjectType(from: decoder)
            self = .inputObject(value)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case kind
    }
}
