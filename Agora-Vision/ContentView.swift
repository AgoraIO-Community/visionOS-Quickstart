//
//  ContentView.swift
//  Agora-Vision
//
//  Created by Max Cobb on 11/6/23.
//

import SwiftUI
import RealityKit
import RealityKitContent

internal struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) { self.build = build }
    var body: Content { build() }
}

struct ContentView: View {
    @State var channelName: String = ""
    @State var joiningChannel: Bool = false
    var body: some View {
        NavigationStack {
            VStack {
                Model3D(named: "Scene", bundle: realityKitContentBundle)
                    .padding(.bottom, 50)
                TextField("Channel name", text: $channelName)
                    .textInputAutocapitalization(.never)
                    .frame(maxWidth: 200, maxHeight: 10).padding(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 1.0))
                    )
                NavigationLink(destination: {
                    NavigationLazyView(VisionVideoCallView(channel: channelName))
                }, label: {
                    Text("Join Channel")
                }).disabled(channelName.isEmpty)
            }.padding()
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
