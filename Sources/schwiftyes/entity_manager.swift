public typealias Entity = Int

public class EntityManager<Signatures: OptionSet> {
    private var entities: ContiguousArray<Entity> = .init(unsafeUninitializedCapacity: MAX_ENTITIES) { buffer, count in
        for i in 0 ..< MAX_ENTITIES {
            buffer[i] = i
        }
        count = MAX_ENTITIES
    }

    private var signatures: ContiguousArray<Signatures> = .init(repeating: Signatures(), count: MAX_ENTITIES)

    private var livingEntities = 0

    func createEntity() -> Entity {
        let entity = entities[livingEntities]
        livingEntities += 1
        return entity
    }

    func destroyEntity(_ entity: Entity) {
        // Reset the signature of the destroyed entity.
        signatures[entity] = Signatures()

        // Swap the destroyed entity with the last living entity.
        entities.remove(at: entity)
        entities.append(entity)

        // Update the living entity count.
        livingEntities -= 1
    }

    func setSignature(_ entity: Entity, _ signature: Signatures) {
        signatures[entity] = signature
    }

    func getSignature(_ entity: Entity) -> Signatures {
        signatures[entity]
    }
}
