#if MAX_ENTITIES
#else
    let MAX_ENTITIES = 1000
#endif

#if MAX_COMPONENTS
#else
    let MAX_COMPONENTS = 1000
#endif

final class ECS<Signatures: OptionSet> {
    private var entityManager: EntityManager<Signatures>
    private var componentManager: ComponentManager<Signatures>
    private var systemManager: SystemManager<Signatures>

    init() {
        entityManager = EntityManager<Signatures>()
        componentManager = ComponentManager<Signatures>()
        systemManager = SystemManager<Signatures>(componentManager)
    }

    func createEntity() -> Entity {
        entityManager.createEntity()
    }

    func destroyEntity(_ entity: Entity) {
        entityManager.destroyEntity(entity)
    }

    func addComponent(_ component: inout some Component<Signatures>, _ entity: Entity) {
        componentManager.addComponent(&component, entity)
        systemManager.entitySignatureChanged(entity, component.signature)
    }

    func removeComponent<T: Component<Signatures>>(_ component: T, _ entity: Entity) {
        componentManager.removeComponent(T.self, entity)
        systemManager.entitySignatureChanged(entity, component.signature)
    }

    func getComponent<T: Component<Signatures>>(_ entity: Entity, _: T.Type) -> T? {
        componentManager.getComponent(entity, T.self)
    }

    func registerSystem(_ system: (some System<Signatures>).Type) {
        systemManager.registerSystem(system)
    }

    func update() {
        systemManager.update()
    }
}
