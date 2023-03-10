open class Component {
	public init() {}
}

final public class ComponentManager {
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

    func addComponent<T: Component>(_ component: inout T, _ entity: Entity) {
        guard let componentArray = getComponentArray(T.self) else {
            return
        }
        componentArray.insertData(&component, entity)
    }

    func removeComponent<T: Component>(_: T.Type, _ entity: Entity) {
        guard let componentArray = getComponentArray(T.self) else {
            return
        }
        componentArray.removeData(entity)
    }

    public func getComponent<T: Component>(_ entity: Entity, _: T.Type) -> T? {
        getComponentArray(T.self)?.getData(entity) as? T
    }

	public func getComponentType<T:Component>(component: T.Type) -> Int {
		Int(bitPattern: ObjectIdentifier(component))
	}

    func entityDestroyed(_ entity: Entity) {
        for componentArray in componentArrays.values {
            componentArray.entityDestroyed(entity)
        }
    }
}
