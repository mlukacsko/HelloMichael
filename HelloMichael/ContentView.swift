//
//  ContentView.swift
//  HelloMichael
//
//  Created by Evie Rockwood on 3/16/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "icloud")
                .imageScale(.large)
                .foregroundStyle(.tint)

            Text("Hello, Michael")
                .font(.largeTitle)

            Button("Connect to Cloud Storage") {
                // later this will call Firebase Storage code
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
