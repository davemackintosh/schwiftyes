import Foundation

open class System {
    public var entities: [Entity] = []
    public var componentManager: ComponentManager!
    open var signature: Signature {
        fatalError("Must override a system's signature otherwise it's just an expensive loop in each frame.")
    }

    public required init(_ componentManager: inout ComponentManager) {
        self.componentManager = componentManager
    }

    open func update(dt _: CFTimeInterval) {
        fatalError("Must override a system's update method otherwise it's just an expensive loop in each frame.")
    }
}

public final class SystemManager {
    private var systems: [Int: System] = [:]
    private var componentManager: ComponentManager

    init(_ componentManager: ComponentManager) {
        self.componentManager = componentManager
    }

    func update(dt: CFTimeInterval) {
        for system in systems.values {
            system.update(dt: dt)
        }
    }

    func registerSystem(_ system: (some System).Type) {
        let typeID = ObjectIdentifier(system).hashValue
        systems[typeID] = system.init(&componentManager)
    }

    func entitySignatureChanged(_ entity: Entity, _ entitySignature: IndexSet) {
        // Loop over the systems and update their entities if the entity's signature matches the system's signature.
        for (_, system) in systems {
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
        for (_, system) in systems {
            system.entities.removeAll(where: { $0 == entity })
        }
    }
}
