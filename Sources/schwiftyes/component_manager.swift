open class Component<S: OptionSet> {
    var signature: S {
        fatalError("Component signature must be set in subclass, otherwise no system will iterate it and it won't be considered valid.")
    }
}

public class ComponentManager<Signatures: OptionSet> {
    private var componentTypes: [Int: Component<Signatures>.Type] = [:]
    private var componentArrays: [Int: ComponentArray<Signatures>] = [:]
    private var nextComponentType = 0
    private func getComponentArray<T: Component<Signatures>>(_: T.Type) -> ComponentArray<Signatures>? {
        let typeID = componentTypes.first(where: {
            $0.value is T.Type
        })?.key

        guard let id = typeID else {
            return nil
        }

        return componentArrays[id]
    }

    func registerComponent(_ component: (some Component<Signatures>).Type) {
        componentTypes[nextComponentType] = component
        componentArrays[nextComponentType] = ComponentArray()
        nextComponentType += 1
    }

    func addComponent<T: Component<Signatures>>(_ component: inout T, _ entity: Entity) {
        guard let componentArray = getComponentArray(T.self) else {
            return
        }
        componentArray.insertData(&component, entity)
    }

    func removeComponent<T: Component<Signatures>>(_: T.Type, _ entity: Entity) {
        guard let componentArray = getComponentArray(T.self) else {
            return
        }
        componentArray.removeData(entity)
    }

    func getComponent<T: Component<Signatures>>(_ entity: Entity, _: T.Type) -> T? {
        getComponentArray(T.self)?.getData(entity) as? T
    }

    func entityDestroyed(_ entity: Entity) {
        for componentArray in componentArrays.values {
            componentArray.entityDestroyed(entity)
        }
    }
}
