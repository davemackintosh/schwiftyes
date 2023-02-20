@testable import schwiftyes
import XCTest

struct Sigs: OptionSet {
    let rawValue: Int

    static let sig1 = Sigs(rawValue: 1 << 0)
    static let sig2 = Sigs(rawValue: 1 << 1)
}

class Position: Component<Sigs> {
    var x: Float
    var y: Float

    override var signature: Sigs {
        [.sig1, .sig2]
    }

    init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
}

class PhysicsSystem: schwiftyes.System<Sigs> {
    override var signature: Sigs {
        [.sig1, .sig2]
    }

    required init(_ componentManager: ComponentManager<Sigs>) {
        super.init(componentManager)
    }

    override func update() {
        for entity in entities {
            let position = componentManager.getComponent(entity, Position.self)
            position?.x += 1
        }
    }
}

final class schwiftyesTests: XCTestCase {
    func testEntityManager() throws {
        let entityManager = schwiftyes.EntityManager<Sigs>()
        let entity = entityManager.createEntity()
        let entity2 = entityManager.createEntity()
        let entity3 = entityManager.createEntity()
        XCTAssertEqual(entity, 0)
        XCTAssertEqual(entity2, 1)
        XCTAssertEqual(entity3, 2)
        entityManager.destroyEntity(entity2)
        XCTAssertEqual(entity3, 2)
    }

    func testComponentArray() throws {
        let entityManager = schwiftyes.EntityManager<Sigs>()
        let componentArray = schwiftyes.ComponentArray<Sigs>()

        let entity = entityManager.createEntity()
        var position = Position(x: 0, y: 0)
        componentArray.insertData(&position, entity)

        let position2 = componentArray.getData(entity) as! Position
        XCTAssertEqual(position2.x, 0)

        componentArray.entityDestroyed(entity)
        let position3 = componentArray.getData(entity)
        XCTAssertNil(position3 as? Position)
    }

    func testComponentManager() throws {
        let entityManager = schwiftyes.EntityManager<Sigs>()
        let componentManager = schwiftyes.ComponentManager<Sigs>()

        componentManager.registerComponent(Position.self)

        let entity = entityManager.createEntity()
        var position = Position(x: 0, y: 0)
        componentManager.addComponent(&position, entity)

        let position2 = componentManager.getComponent(entity, Position.self)
        XCTAssertNotNil(position2)
        XCTAssertEqual(position2!.x, 0)

        componentManager.entityDestroyed(entity)
        let position3 = componentManager.getComponent(entity, Position.self)
        XCTAssertNil(position3)
    }

    func testSystemManager() throws {
        let entityManager = schwiftyes.EntityManager<Sigs>()
        let componentManager = schwiftyes.ComponentManager<Sigs>()
        let systemManager = schwiftyes.SystemManager<Sigs>(componentManager)

        systemManager.registerSystem(PhysicsSystem.self)
        componentManager.registerComponent(Position.self)

        let entity = entityManager.createEntity()
        var position = Position(x: 0, y: 0)
        componentManager.addComponent(&position, entity)

        systemManager.entitySignatureChanged(entity, .sig1)
        systemManager.update()

        let position2 = componentManager.getComponent(entity, Position.self)
        XCTAssertNotNil(position2)
        XCTAssertEqual(position2!.x, 1)

        systemManager.update()

        let position3 = componentManager.getComponent(entity, Position.self)
        XCTAssertNotNil(position3)
        XCTAssertEqual(position3!.x, 2)
    }

    func testECS() throws {
        let ecs = schwiftyes.ECS<Sigs>()

        ecs.registerSystem(PhysicsSystem.self)
        ecs.registerComponent(Position.self)

        let entity = ecs.createEntity()
        var position = Position(x: 0, y: 0)
        ecs.addComponent(&position, entity)

        ecs.update()

        let position2 = ecs.getComponent(entity, Position.self)
        XCTAssertNotNil(position2)
        XCTAssertEqual(position2!.x, 1)

        ecs.update()

        let position3 = ecs.getComponent(entity, Position.self)
        XCTAssertNotNil(position3)
        XCTAssertEqual(position3!.x, 2)
    }
}
