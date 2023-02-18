#if MAX_ENTITIES
#else
    let MAX_ENTITIES = 1000
#endif

#if MAX_COMPONENTS
#else
    let MAX_COMPONENTS = 1000
#endif

public typealias Entity = Int
public protocol Component {}
public protocol System {
    associatedtype SystemSignature: OptionSet
    var signature: SystemSignature { get }

    init()
    func update()
}

private class NoComponent: Component {}

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

public class ComponentArray {
    private var componentArray: ContiguousArray<Component> = .init(repeating: NoComponent(), count: MAX_ENTITIES)

    private var entityToIndexMap: ContiguousArray<Entity> = .init(unsafeUninitializedCapacity: MAX_ENTITIES) { buffer, count in
        for i in 0 ..< MAX_ENTITIES {
            buffer[i] = i
        }
        count = MAX_ENTITIES
    }

    private var indexToEntityMap: ContiguousArray<Entity> = .init(unsafeUninitializedCapacity: MAX_ENTITIES) { buffer, count in
        for i in 0 ..< MAX_ENTITIES {
            buffer[i] = i
        }
        count = MAX_ENTITIES
    }

    private var size = 0

    func insertData(_ component: Component, _ entity: Entity) {
        let newIndex = size

        componentArray[newIndex] = component
        entityToIndexMap[entity] = newIndex
        indexToEntityMap[newIndex] = entity

        size += 1
    }

    func removeData(_ entity: Entity) {
        // Copy element at end into deleted element's place to maintain density
        let indexOfRemovedEntity = entityToIndexMap[entity]
        let indexOfLastElement = size - 1

        // Update map to point to moved spot
        let entityOfLastElement = indexToEntityMap[indexOfLastElement]
        entityToIndexMap[entityOfLastElement] = indexOfRemovedEntity
        indexToEntityMap[indexOfRemovedEntity] = entityOfLastElement

        // Remove the last element
        componentArray[indexOfRemovedEntity] = NoComponent()
        entityToIndexMap[entity] = 0
        indexToEntityMap[indexOfLastElement] = 0
    }

    func getData(_ entity: Entity) -> Component {
        let index = entityToIndexMap[entity]
        return componentArray[index]
    }

    func entityDestroyed(_ entity: Entity) {
        removeData(entity)
    }
}

public class SystemManager<Signatures: OptionSet> {
    private var signatures: ContiguousArray<Signatures> = []
    private var systems: ContiguousArray<any System> = []

    func registerSystem(_ system: some System) {
        let signature = system.signature
        signatures.append(signature as! Signatures)
        systems.append(type(of: system).init())
    }
}
