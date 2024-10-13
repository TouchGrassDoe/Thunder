//
//  SettingsView.swift
//  Thunder
//
//  Created by Aaron Doe on 13/10/2024.
//

import SwiftUI

struct SettingsView: View {
    @Binding var psnName: String
    @Binding var exophaseName: String
    @State private var showingAboutAlert = false

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("login").font(.headline).frame(maxWidth: .infinity, alignment: .leading)) {
                        TextField("PSN Name", text: $psnName)
                            .autocapitalization(.none)
                        TextField("Exophase Name", text: $exophaseName)
                            .autocapitalization(.none)
                    }
                    .onChange(of: psnName) { _ in
                        updateProfile()
                    }
                    .onChange(of: exophaseName) { _ in
                        updateProfile()
                    }

                    Section(header: Text("About").font(.headline).frame(maxWidth: .infinity, alignment: .leading)) {
                        HStack {
                            Text("About Thunder")
                            Spacer()
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .onTapGesture {
                                    showingAboutAlert = true
                                }
                        }
                    }
                }

                Spacer()

                VStack {
                    Image("SettingsIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        Text("Thunder")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Settings")
            .alert(isPresented: $showingAboutAlert) {
                Alert(
                    title: Text("About Thunder"),
                    message: Text("Thunder is an application developed by Aaron Doe (GitHub: TouchGrassDoe) that lets you track your gaming achievements and progress"),
                    dismissButton: .default(Text("Enjoy!"))
                )
            }
        }
    }

    private func updateProfile() {
    }
}
