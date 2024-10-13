//
//  ContentView.swift
//  Thunder
//
//  Created by Aaron Doe on 13/10/2024.
//

import SwiftUI


struct ContentView: View {
    @StateObject private var viewModel = ExophaseViewModel(
        exophaseName: UserDefaults.standard.string(forKey: "exophaseName") ?? "",
        psnName: UserDefaults.standard.string(forKey: "psnName") ?? ""
    )

    var body: some View {
        TabView {
            NavigationView {
                VStack {
                    if viewModel.isLoading {
                        Text("Loading...").padding()
                    } else if viewModel.games.isEmpty {
                        Text("No games found.").padding()
                    } else {
                        List(viewModel.games) { game in
                            GameRow(game: game)
                        }
                    }
                }
                .navigationTitle("Thunder")
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            SettingsView(psnName: $viewModel.psnName, exophaseName: $viewModel.exophaseName)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
