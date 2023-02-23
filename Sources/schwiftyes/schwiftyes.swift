import Foundation

#if MAX_ENTITIES
#else
    let MAX_ENTITIES = 1000
#endif

#if MAX_COMPONENTS
#else
    let MAX_COMPONENTS = 1000
#endif

public final class ECS {
    private var entityManager: EntityManager
    private var componentManager: ComponentManager
    private var systemManager: SystemManager

    public init() {
        entityManager = EntityManager()
        componentManager = ComponentManager()
        systemManager = SystemManager(componentManager)
    }

    public func createEntity() -> Entity {
        entityManager.createEntity()
    }

    public func destroyEntity(_ entity: Entity) {
        entityManager.destroyEntity(entity)
    }

    public func registerComponent<T: Component>(_: T.Type) {
        componentManager.registerComponent(T.self)
    }

	public func addComponent<T: Component>(_ component: inout T, _ entity: Entity) {
		var sig = entityManager.getSignature(entity)
		sig.insert(componentManager.getComponentType(component: type(of:component)))
		entityManager.setSignature(entity, sig)
        componentManager.addComponent(&component, entity)
		systemManager.entitySignatureChanged(entity, sig)
    }

    public func removeComponent<T: Component>(_ component: T, _ entity: Entity) {
		var sig = entityManager.getSignature(entity)
		sig.remove(componentManager.getComponentType(component: type(of:component)))
		entityManager.setSignature(entity, sig)
        componentManager.removeComponent(T.self, entity)
		systemManager.entitySignatureChanged(entity, sig)
    }

    public func getComponent<T: Component>(_ entity: Entity, _: T.Type) -> T? {
        componentManager.getComponent(entity, T.self)
    }

    public func registerSystem(_ system: (some System).Type) {
        systemManager.registerSystem(system)
    }

    public func update(dt: CFTimeInterval) {
        systemManager.update(dt: dt)
    }

    public func getSystem<T: System>(_ system: T.Type) -> T? {
		systemManager.getSystem(system)
	}
}
