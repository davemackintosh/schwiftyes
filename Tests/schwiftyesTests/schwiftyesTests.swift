@testable import schwiftyes
import XCTest

struct Sigs: OptionSet {
    let rawValue: Int

    static let sig1 = Sigs(rawValue: 1 << 0)
    static let sig2 = Sigs(rawValue: 1 << 1)
}

struct Position: Component {
    var x: Float
    var y: Float
}

struct PhysicsSystem: schwiftyes.System {
    typealias SystemSignature = Sigs

    var signature: Sigs = [.sig1, .sig2]

    func update() throws {
        print("PhysicsSystem")
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
        print(entity2)
        XCTAssertEqual(entity3, 2)
    }

    func testComponentArray() throws {
        let entityManager = schwiftyes.EntityManager<Sigs>()
        let componentArray = schwiftyes.ComponentArray()

        let entity = entityManager.createEntity()
        let position = Position(x: 0, y: 0)
        componentArray.insertData(position, entity)

        let position2 = componentArray.getData(entity) as! Position
        XCTAssertEqual(position2.x, 0)
    }
}
