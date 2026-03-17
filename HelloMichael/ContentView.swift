//
//  ContentView.swift
//  HelloMichael
//
//  Created by Evie Rockwood on 3/16/26.
//

//import SwiftUI
//
//struct ContentView: View {
//    var body: some View {
//        VStack(spacing: 20) {
//            Image(systemName: "icloud")
//                .imageScale(.large)
//                .foregroundStyle(.tint)
//
//            Text("Hello, Michael")
//                .font(.largeTitle)
//
//            Button("Connect to Cloud Storage") {
//                // later this will call Firebase Storage code
//            }
//            .buttonStyle(.borderedProminent)
//        }
//        .padding()
//    }
//}
//
//#Preview {
//    ContentView()
//}

import SwiftUI
import FirebaseStorage

struct ContentView: View {
    @State private var fileContents = "Tap the button to load test.txt"

    var body: some View {
        VStack(spacing: 20) {

            Image(systemName: "externaldrive.badge.cloud")
                .imageScale(.large)

            Text("Hello, Michael")
                .font(.largeTitle)

            Button("Load test.txt from Firebase") {
                Task {
                    await loadTestFile()
                }
            }
            .buttonStyle(.borderedProminent)

            ScrollView {
                Text(fileContents)
                    .padding()
            }
        }
        .padding()
    }

    func loadTestFile() async {

        do {
            let storage = Storage.storage()
            let ref = storage.reference(withPath: "test.txt")

            let data = try await ref.data(maxSize: 1 * 1024 * 1024)

            if let text = String(data: data, encoding: .utf8) {
                fileContents = text
            } else {
                fileContents = "File downloaded but could not decode text."
            }

        } catch {
            fileContents = "Error: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ContentView()
}
