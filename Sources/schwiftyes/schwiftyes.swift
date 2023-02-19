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
public class System<Signatures: OptionSet> {
    var signature: Signatures { fatalError("Must override") }
    var entities: [Entity] = []
    var componentManager: ComponentManager<Signatures>

    required init(_ componentManager: ComponentManager<Signatures>) {
        self.componentManager = componentManager
    }

    func update() {}
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

public class ComponentManager<Signatures: OptionSet> {
    private var componentTypes: [Int: Component.Type] = [:]
    private var componentArrays: [Int: ComponentArray] = [:]
    private var nextComponentType = 0
    private func getComponentArray<T: Component>(_: T.Type) -> ComponentArray? {
        let typeID = componentTypes.first(where: {
            $0.value is T.Type
        })?.key

        guard let id = typeID else {
            return nil
        }

        return componentArrays[id]
    }

    func registerComponent(_ component: (some Component).Type) {
        componentTypes[nextComponentType] = component
        componentArrays[nextComponentType] = ComponentArray()
        nextComponentType += 1
    }

    func addComponent<T: Component>(_ component: T, _ entity: Entity) {
        guard let componentArray = getComponentArray(T.self) else {
            return
        }
        componentArray.insertData(component, entity)
    }

    func removeComponent<T: Component>(_: T.Type, _ entity: Entity) {
        guard let componentArray = getComponentArray(T.self) else {
            return
        }
        componentArray.removeData(entity)
    }

    func getComponent<T: Component>(_ entity: Entity, _: T.Type) -> T? {
        guard let componentArray = getComponentArray(T.self) else {
            fatalError("Component not registered.")
        }
        return componentArray.getData(entity) as? T
    }

    func entityDestroyed(_ entity: Entity) {
        for componentArray in componentArrays.values {
            componentArray.entityDestroyed(entity)
        }
    }
}

public class SystemManager<Signatures: OptionSet> {
    private var systems: [Int: System<Signatures>] = [:]
    private var signatures: [Int: Signatures] = [:]
    private var componentManager: ComponentManager<Signatures>

    init(_ componentManager: ComponentManager<Signatures>) {
        self.componentManager = componentManager
    }

    func registerSystem(_ system: System<Signatures>.Type) {
        let typeID = ObjectIdentifier(system).hashValue
        systems[typeID] = system.init(componentManager)
        signatures[typeID] = systems[typeID]?.signature
    }

    func entitySignatureChanged(_ entity: Entity, _ entitySignature: Signatures) {
        // Loop over the systems and update their entities if the entity's signature matches the system's signature.
        for (typeID, var system) in systems {
            let systemSignature = signatures[typeID]!

            // Compare the entity's signature with the system's signature
            // and if there are any matches, add the entity to the system.
            if entitySignature.isDisjoint(with: systemSignature) {
                system.entities.append(entity)
            } else {
                // If the entity's signature doesn't match the system's signature,
                // remove the entity from the system.
                system.entities.removeAll(where: { $0 == entity })
            }
        }
    }

    func entityDestroyed(_ entity: Entity) {
        for (_, var system) in systems {
            system.entities.removeAll(where: { $0 == entity })
        }
    }
}
