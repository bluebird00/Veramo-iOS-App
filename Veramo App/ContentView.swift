import SwiftUI

struct ContentView: View {
    // 1. VARIABLES: This holds our data. "@State" tells the screen to update when this number changes.
    @State private var count = 0

    var body: some View {
        // 2. LAYOUT: VStack stacks items vertically (up and down)
        VStack(spacing: 20) {
            
            Image(systemName: "swift") // A built-in Apple icon
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("You clicked: \(count) times")
                .font(.headline)

            // 3. INTERACTION: A button that runs code when tapped
            Button("Click Me!") {
                count += 1 // This simple math updates the screen instantly
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

