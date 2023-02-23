@testable import schwiftyes
import XCTest

class Position: Component {
    var x: Float
    var y: Float

    init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
}

class PhysicsSystem: schwiftyes.System {
    override var signature: schwiftyes.Signature {
        Signature.from([Position.self])
    }

    required init(_ componentManager: inout ComponentManager) {
        super.init(&componentManager)
    }

    override func update(dt _: CFTimeInterval) {
        for entity in entities {
            let position = componentManager.getComponent(entity, Position.self)
            position?.x += 1
        }
    }
}

final class schwiftyesTests: XCTestCase {
    func testEntityManager() throws {
        let entityManager = schwiftyes.EntityManager()
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
        let entityManager = schwiftyes.EntityManager()
        let componentArray = schwiftyes.ComponentArray()

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
        let entityManager = schwiftyes.EntityManager()
        let componentManager = schwiftyes.ComponentManager()

        componentManager.registerComponent(Position.self)

        let entity = entityManager.createEntity()
        var sig = entityManager.getSignature(entity)
        sig.insert(componentManager.getComponentType(component: Position.self))
        entityManager.setSignature(entity, sig)
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
        let entityManager = schwiftyes.EntityManager()
        let componentManager = schwiftyes.ComponentManager()
        let systemManager = schwiftyes.SystemManager(componentManager)

        systemManager.registerSystem(PhysicsSystem.self)
        componentManager.registerComponent(Position.self)

        let entity = entityManager.createEntity()
        var sig = entityManager.getSignature(entity)
        print("Type \(componentManager.getComponentType(component: Position.self))")
        sig.insert(componentManager.getComponentType(component: Position.self))
        entityManager.setSignature(entity, sig)
        var position = Position(x: 0, y: 0)
        componentManager.addComponent(&position, entity)

        systemManager.entitySignatureChanged(entity, sig)
        systemManager.update(dt: 0.0)

        let position2 = componentManager.getComponent(entity, Position.self)
        XCTAssertNotNil(position2)
        XCTAssertEqual(position2!.x, 1)

        systemManager.update(dt: 0.0)

        let position3 = componentManager.getComponent(entity, Position.self)
        XCTAssertNotNil(position3)
        XCTAssertEqual(position3!.x, 2)

        let system = systemManager.getSystem(PhysicsSystem.self)
        XCTAssertNotNil(system)
    }

    func testECS() throws {
        let ecs = schwiftyes.ECS()

        ecs.registerSystem(PhysicsSystem.self)
        ecs.registerComponent(Position.self)

        let entity = ecs.createEntity()
        var position = Position(x: 0, y: 0)
        ecs.addComponent(&position, entity)
        ecs.update(dt: 0.0)

        let position2 = ecs.getComponent(entity, Position.self)
        XCTAssertNotNil(position2)
        XCTAssertEqual(position2!.x, 1)

        ecs.update(dt: 0.0)

        let position3 = ecs.getComponent(entity, Position.self)
        XCTAssertNotNil(position3)
        XCTAssertEqual(position3!.x, 2)
    }
}
