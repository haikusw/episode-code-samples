import ComposableArchitecture
import XCTest
@testable import Todos

class TodosTests: XCTestCase {
  let scheduler = DispatchQueue.test

  func testCompletingTodo() {
    let todos: IdentifiedArrayOf<Todo> = [
      Todo(
        description: "Milk",
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
        isComplete: false
      )
    ]
    
    let store = TestStore(
      initialState: AppState(todos: todos),
      reducer: appReducer,
      environment: AppEnvironment(
        mainQueue: scheduler.eraseToAnyScheduler(),
        uuid: { fatalError("unimplemented") }
      )
    )
    
    store.send(.todo(id: todos[0].id, action: .checkboxTapped)) {
      $0.todos[id: $0.todos[0].id]?.isComplete = true
    }
    
    self.scheduler.advance(by: 1)
    store.receive(.todoDelayCompleted)
  }
  
  func testAddTodo() {
    let store = TestStore(
      initialState: AppState(),
      reducer: appReducer,
      environment: AppEnvironment(
      mainQueue: scheduler.eraseToAnyScheduler(),
        uuid: { UUID(uuidString: "DEADBEEF-DEAD-BEEF-DEAD-DEADBEEFDEAD")! }
      )
    )
    
    store.send(.addButtonTapped) {
        $0.todos = [
          Todo(
            description: "",
            id: UUID(uuidString: "DEADBEEF-DEAD-BEEF-DEAD-DEADBEEFDEAD")!,
            isComplete: false
          )
        ]
      }
  }
  
  func testTodoSorting() {
    let todos: IdentifiedArray<UUID,Todo> = [
      Todo(
        description: "Milk",
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
        isComplete: false
      ),
      Todo(
        description: "Eggs",
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        isComplete: false
      )
    ]

    let store = TestStore(
      initialState: AppState(todos: todos),
      reducer: appReducer,
      environment: AppEnvironment(
      mainQueue: scheduler.eraseToAnyScheduler(),
        uuid: { fatalError("unimplemented") }
      )
    )
    
    store.send(.todo(id: todos[0].id, action: .checkboxTapped)) {
      $0.todos[id: todos[0].id]?.isComplete = true
    }

    self.scheduler.advance(by: 1)
    store.receive(.todoDelayCompleted) {
        $0.todos.swapAt(0, 1)
    }
  }

  func testTodoSorting_Cancellation() {
    let todos: IdentifiedArray<UUID,Todo> = [
      Todo(
        description: "Milk",
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
        isComplete: false
      ),
      Todo(
        description: "Eggs",
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        isComplete: false
      )
    ]
    
    let store = TestStore(
      initialState: AppState(todos: todos),
      reducer: appReducer,
      environment: AppEnvironment(
        mainQueue: scheduler.eraseToAnyScheduler(),
        uuid: { fatalError("unimplemented") }
      )
    )
    
    store.send(.todo(id: todos[0].id, action: .checkboxTapped)) {
      $0.todos[id: todos[0].id]?.isComplete = true
    }
    
    self.scheduler.advance(by: 0.5)
    
    store.send(.todo(id: todos[0].id, action: .checkboxTapped)) {
      $0.todos[id: todos[0].id]?.isComplete = false
    }
    self.scheduler.advance(by: 1)
    
    store.receive(.todoDelayCompleted)
  }
}
