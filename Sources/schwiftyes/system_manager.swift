import Foundation

open class System<Signatures: OptionSet> {
    var signature: Signatures { fatalError("Must override a system's signatures otherwise it won't run on any entities.") }
    var entities: [Entity] = []
    public var componentManager: ComponentManager<Signatures>!

    public required init(_ componentManager: ComponentManager<Signatures>) {
        self.componentManager = componentManager
    }

    public func update(dt _: CFTimeInterval) {
        fatalError("Must override a system's update method otherwise it's just an expensive loop in each frame.")
    }
}

public class SystemManager<Signatures: OptionSet> {
    private var systems: [Int: System<Signatures>] = [:]
    private var signatures: [Int: Signatures] = [:]
    private var componentManager: ComponentManager<Signatures>

    init(_ componentManager: ComponentManager<Signatures>) {
        self.componentManager = componentManager
    }

    func update(dt: CFTimeInterval) {
        for system in systems.values {
            system.update(dt: dt)
        }
    }

    func registerSystem(_ system: (some System<Signatures>).Type) {
        let typeID = ObjectIdentifier(system).hashValue
        systems[typeID] = system.init(componentManager)
        signatures[typeID] = systems[typeID]?.signature
    }

    func entitySignatureChanged(_ entity: Entity, _ entitySignature: Signatures) {
        // Loop over the systems and update their entities if the entity's signature matches the system's signature.
        for (typeID, system) in systems {
            let systemSignature = signatures[typeID]!

            // Compare the entity's signature with the system's signature
            // and if there are any matches, add the entity to the system.
            if !entitySignature.isDisjoint(with: systemSignature) {
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
