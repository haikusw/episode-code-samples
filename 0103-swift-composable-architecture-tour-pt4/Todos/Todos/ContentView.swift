import Combine
import ComposableArchitecture
import SwiftUI

struct Todo: Equatable, Identifiable {
  var description = ""
  let id: UUID
  var isComplete = false
}

enum TodoAction: Equatable {
  case checkboxTapped
  case textFieldChanged(String)
}

struct TodoEnvironment {
}

let todoReducer = Reducer<Todo, TodoAction, TodoEnvironment> { state, action, environment in
  switch action {
  case .checkboxTapped:
    state.isComplete.toggle()
    return .none
  case .textFieldChanged(let text):
    state.description = text
    return .none
  }
}

struct AppState: Equatable {
  var todos: IdentifiedArrayOf<Todo> = []
}

enum AppAction: Equatable {
  case addButtonTapped
  case todo(id: UUID, action: TodoAction)
  case todoDelayCompleted
//  case todoCheckboxTapped(index: Int)
//  case todoTextFieldChanged(index: Int, text: String)
}

struct AppEnvironment {
  var mainQueue: AnySchedulerOf<DispatchQueue>

  //AnyScheduler<DispatchQueue.SchedulerTimeType, DispatchQueue.SchedulerOptions>

  //Scheduler where .SchedulerTimeType == DispatchQueue.SchedulerTimeType, .SchedulerOptions == DispatchQueue.SchedulerOptions

  var uuid: () -> UUID
}
// AnyHashable
// AnyIterator
// AnyCollection
// AnySubscriber
// AnyCancellable
// AnyPublisher
// AnyView

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
  todoReducer.forEach(
    state: \AppState.todos,
    action: /AppAction.todo(id:action:),
    environment: { _ in TodoEnvironment() }
  ),
  Reducer { state, action, environment in
    switch action {
    case .addButtonTapped:
      state.todos.insert(Todo(id: environment.uuid()), at: 0)
      return .none
      
    case .todo(id: _, action: .checkboxTapped):
      struct CancelDelayId: Hashable {}

      return Effect(value: AppAction.todoDelayCompleted)
        .debounce(id: CancelDelayId(), for: 1, scheduler: environment.mainQueue)
      
    case .todo(id: let id, action: let action):
      return .none
      
    case .todoDelayCompleted:
      
      state.todos = state.todos
        .enumerated()
        .sorted { lhs, rhs in
          (!lhs.element.isComplete && rhs.element.isComplete)
            || lhs.offset < rhs.offset
      }
      .map(\.element)
      .reduce(into: IdentifiedArray<UUID,Todo>()) { $0.append($1) }
      
      return .none
    }
  }
)
  .debug()
  
//  Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
//  switch action {
//  case .todoCheckboxTapped(index: let index):
//    state.todos[index].isComplete.toggle()
//    return .none
//  case .todoTextFieldChanged(index: let index, text: let text):
//    state.todos[index].description = text
//    return .none
//  }
//}
//.debug()

struct ContentView: View {
  let store: Store<AppState, AppAction>
//  @ObservableObject var viewStore
  
  var body: some View {
    NavigationView {
      WithViewStore(self.store) { viewStore in
        List {
          ForEachStore(
            self.store.scope(state: \.todos, action: AppAction.todo(id:action:)),
            content: TodoView.init(store:)
          )
        }
        .navigationBarTitle("Todos")
        .navigationBarItems(trailing: Button("Add") {
          viewStore.send(.addButtonTapped)
        })
      }
    }
  }
}

struct TodoView: View {
  let store: Store<Todo, TodoAction>
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      HStack {
        Button(action: { viewStore.send(.checkboxTapped) }) {
          Image(systemName: viewStore.isComplete ? "checkmark.square" : "square")
        }
        .buttonStyle(PlainButtonStyle())
        
        TextField(
          "Untitled todo",
          text: viewStore.binding(
            get: \.description,
            send: TodoAction.textFieldChanged
          )
        )
      }
      .foregroundColor(viewStore.isComplete ? .gray : nil)
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(
      store: Store(
        initialState: AppState(
          todos: [
            Todo(
              description: "Milk",
              id: UUID(),
              isComplete: false
            ),
            Todo(
              description: "Eggs",
              id: UUID(),
              isComplete: false
            ),
            Todo(
              description: "Hand Soap",
              id: UUID(),
              isComplete: true
            ),
          ]
        ),
        reducer: appReducer,
        environment: AppEnvironment(
          mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
          uuid: UUID.init
        )
      )
    )
  }
}
