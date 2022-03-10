import Foundation

/*
 This file contains utility functions that we generally use when writing queries
 using SwiftGraphQL.
 */

// MARK: - Selection Transformation

public extension Selection where TypeLock: Decodable {
    
    /// Lets you convert a type selection into a list selection.
    var list: Selection<[Type], [TypeLock]> {
        Selection<[Type], [TypeLock]> { fields in
            let selection = self.selection()
            fields.select(selection)
            
            switch fields.state {
            case let .decoding(data):
                return try data.map {
                    try self.decode(data: $0)
                }
            case .mocking:
                let item = try self.mock()
                return [item]
            }
        }
    }
    
    /// Lets you decode nullable values.
    var nullable: Selection<Type?, TypeLock?> {
        Selection<Type?, TypeLock?> { fields in
            let selection = self.selection()
            fields.select(selection)

            switch fields.state {
            case let .decoding(data):
                return try data.map { try self.decode(data: $0) }
            case .mocking:
                return try self.mock()
            }
        }
    }
    
    /// Lets you decode nullable values into non-null ones.
    var nonNullOrFail: Selection<Type, TypeLock?> {
        Selection<Type, TypeLock?> { fields in
            let selection = self.selection()
            fields.select(selection)
            
            switch fields.state {
            case let .decoding(data):
                if let data = data {
                    return try self.decode(data: data)
                }
                throw SelectionError.badpayload
            case .mocking:
                return try self.mock()
            }
        }
    }
    
    /// Lets you make a failable (nullable) decoder comply accept nullable values.
    func optional<T>() -> Selection<Type, TypeLock?> where Type == T? {
        Selection<Type, TypeLock?> { fields in
            let selection = self.selection()
            fields.select(selection)

            switch fields.state {
            case let .decoding(data):
                return try data.map { try self.decode(data: $0) }.flatMap { $0 }
            case .mocking:
                return try self.mock()
            }
        }
    }
}

/*
 Selection mapping functions.
 */

public extension Selection where TypeLock: Decodable {
    
    /// Maps selection's return value into a new value using provided mapping function.
    func map<MappedType>(_ fn: @escaping (Type) -> MappedType) -> Selection<MappedType, TypeLock> {
        Selection<MappedType, TypeLock> { fields in
            let selection = self.selection()
            fields.select(selection)

            switch fields.state {
            case let .decoding(data):
                return fn(try self.decode(data: data))
            case .mocking:
                return fn(try self.mock())
            }
        }
    }
}

// MARK: - Fields Extensions

public extension Fields {

    /// Lets you make a selection inside selection set on the entire field.
    func selection<T>(_ selection: Selection<T, TypeLock>) throws -> T {
        self.select(selection.selection())

        /* Decoder */
        switch state {
        case let .decoding(data):
            return try selection.decode(data: data)
        case .mocking:
            return try selection.mock()
        }
    }
}

/*
 Helper functions that let you make changes upfront.
 */

public extension Selection where TypeLock: Decodable {
    
    /// Lets you provide non-list selection for list field.
    static func list<NonListType, NonListTypeLock>(
        _ selection: Selection<NonListType, NonListTypeLock>
    ) -> Selection<Type, TypeLock> where Type == [NonListType], TypeLock == [NonListTypeLock] {
        selection.list
    }

    /// Lets you provide non-nullable selection for nullable field.
    static func nullable<NonNullType, NonNullTypeLock>(
        _ selection: Selection<NonNullType, NonNullTypeLock>
    ) -> Selection<Type, TypeLock> where Type == NonNullType?, TypeLock == NonNullTypeLock? {
        selection.nullable
    }
}

