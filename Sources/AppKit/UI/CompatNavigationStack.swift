import ComposableArchitecture
import SwiftUI

public struct CompatNavigationStack<State, Action, Root: View, Destination: View>: View {
  let store: Store<StackState<State>, StackAction<State, Action>>
  let root: Root
  let destination: (Store<State, Action>) -> Destination
  
  public init(
    store: Store<StackState<State>, StackAction<State, Action>>,
    @ViewBuilder root: () -> Root,
    @ViewBuilder destination: @escaping (Store<State, Action>) -> Destination
  ) {
    self.store = store
    self.root = root()
    self.destination = destination
  }

  public var body: some View {
    NavigationView {
      root
        .background(
          RecursiveLink(store: store, destination: destination, index: 0)
        )
    }
    .navigationViewStyle(.stack)
  }
}

private struct RecursiveLink<State, Action, Destination: View>: View {
  let store: Store<StackState<State>, StackAction<State, Action>>
  let destination: (Store<State, Action>) -> Destination
  let index: Int
  
  var body: some View {
    WithPerceptionTracking {
      if index < store.ids.count {
        let id = store.ids[index]
        // We create a binding that assumes if we are rendering, we are active.
        // When the user taps back, isActive becomes false, and we send a pop action.
        let isActive = Binding(
          get: { true },
          set: { newValue in
            if !newValue {
              store.send(.popFrom(id: id))
            }
          }
        )
        
        NavigationLink(isActive: isActive) {
          // Scope the store to the specific element
          // usage: store.scope(state: \.[id: id], action: \.[id: id])
          // Note: We need to handle the case where the ID might not exist in state physically anymore if popped,
          // but relying on index < store.ids.count should be safe enough for the view update cycle relative to Perception.
          if let childStore = store.scope(state: \.[id: id], action: \.[id: id]) {
            destination(childStore)
              .background(
                RecursiveLink(store: store, destination: destination, index: index + 1)
              )
          }
        } label: {
          EmptyView()
        }
        .isDetailLink(false) 
      }
    }
  }
}
