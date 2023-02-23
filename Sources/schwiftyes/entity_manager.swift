import Foundation

public typealias Entity = Int
public typealias Signature = IndexSet

public extension Signature {
    static func from(_ componentTypes: [Component.Type]) -> Signature {
        var signature = Signature()
        for component in componentTypes {
            let type = Int(bitPattern: ObjectIdentifier(component))
            signature.insert(type)
        }
        return signature
    }
}

public final class EntityManager {
    private var entities: ContiguousArray<Entity> = .init(unsafeUninitializedCapacity: MAX_ENTITIES) { buffer, count in
        for i in 0 ..< MAX_ENTITIES {
            buffer[i] = i
        }
        count = MAX_ENTITIES
    }

    private var signatures: ContiguousArray<Signature> = .init(repeating: .init(), count: MAX_ENTITIES)

    private var livingEntities = 0

    func createEntity() -> Entity {
        let entity = entities[livingEntities]
        livingEntities += 1
        return entity
    }

    func destroyEntity(_ entity: Entity) {
        // Reset the signature of the destroyed entity.
        signatures[entity] = .init()

        // Swap the destroyed entity with the last living entity.
        entities.remove(at: entity)
        entities.append(entity)

        // Update the living entity count.
        livingEntities -= 1
    }

    func setSignature(_ entity: Entity, _ signature: Signature) {
        signatures[entity] = signature
    }

    func getSignature(_ entity: Entity) -> Signature {
        signatures[entity]
    }
}
