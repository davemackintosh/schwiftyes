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
    private var componentArray: ContiguousArray<Component> = []
    private var entityToIndexMap: ContiguousArray<Entity> = []
    private var indexToEntityMap: ContiguousArray<Entity> = []
    private var size = 0

    func insertData(_ component: Component, _ entity: Entity) {
        let newIndex = size
        size += 1
        componentArray.append(component)
        entityToIndexMap.append(newIndex)
        indexToEntityMap.append(entity)
    }

    func removeData(_ entity: Entity) {
        let indexOfRemovedEntity = entityToIndexMap[entity]
        let indexOfLastElement = size - 1
        componentArray[indexOfRemovedEntity] = componentArray[indexOfLastElement]
        let entityOfLastElement = indexToEntityMap[indexOfLastElement]
        entityToIndexMap[entityOfLastElement] = indexOfRemovedEntity
        indexToEntityMap[indexOfRemovedEntity] = entityOfLastElement
        size -= 1
    }

    func getData(_ entity: Entity) -> Component {
        let index = entityToIndexMap[entity]
        return componentArray[index]
    }

    func entityDestroyed(_ entity: Entity) {
        if entityToIndexMap[entity] < size {
            removeData(entity)
        }
    }
}

public class SystemManager {
    private var signatures: ContiguousArray<any OptionSet> = []
    private var systems: ContiguousArray<any System> = []

    func registerSystem(_ system: some System) {
        let signature = system.signature
        signatures.append(signature)
        systems.append(type(of: system).init())
    }
}
