private class NoComponent: Component {}

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

    func insertData(_ component: inout some Component, _ entity: Entity) {
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

    // getData returns a reference so that a component can be modified directly
    // by the system responsible for it.
    func getData(_ entity: Entity) -> Component {
        // let index = entityToIndexMap[entity]
        // return componentArray[index]
        componentArray[entityToIndexMap[entity]]
    }

    func entityDestroyed(_ entity: Entity) {
        removeData(entity)
    }
}
