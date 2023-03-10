import Foundation

open class System: NSObject {
    // MARK: Lifecycle

    public required init(_ componentManager: inout ComponentManager) {
        self.componentManager = componentManager
    }

    // MARK: Open

    open var signature: Signature {
        fatalError("Must override a system's signature otherwise it's just an expensive loop in each frame.")
    }

    open func update(dt _: CFTimeInterval) {
        fatalError("Must override a system's update method otherwise it's just an expensive loop in each frame.")
    }

    // MARK: Public

    public var entities: [Entity] = []
    public var componentManager: ComponentManager!
}

public final class SystemManager {
    // MARK: Lifecycle

    init(_ componentManager: ComponentManager) {
        self.componentManager = componentManager
    }

    // MARK: Internal

    func update(dt: CFTimeInterval) {
        for system in systems {
            system.update(dt: dt)
        }
    }

    func registerSystem(_ system: (some System).Type) {
		systems.append(system.init(&componentManager))
    }

    func entitySignatureChanged(_ entity: Entity, _ entitySignature: IndexSet) {
        // Loop over the systems and update their entities if the entity's signature matches the system's signature.
        for system in systems {
            // Compare the entity's signature with the system's signature
            // and if there are any matches, add the entity to the system.
            if entitySignature.isSubset(of: system.signature) {
                system.entities.append(entity)
            } else {
                // If the entity's signature doesn't match the system's signature,
                // remove the entity from the system.
                system.entities.removeAll(where: { $0 == entity })
            }
        }
    }

    func entityDestroyed(_ entity: Entity) {
        for system in systems {
            system.entities.removeAll(where: { $0 == entity })
        }
    }

    // MARK: Private

    private var systems: ContiguousArray<System> = []
    private var componentManager: ComponentManager
}
