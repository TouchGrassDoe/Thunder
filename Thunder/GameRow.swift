//
//  GamerRow.swift
//  Thunder
//
//  Created by Aaron Doe on 13/10/2024.
//

import SwiftUI

struct GameRow: View {
    let game: ExophaseGame

    var body: some View {
        HStack {
            AsyncImage(url: URL(string: game.image)) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            } placeholder: {
                ProgressView()
                    .frame(width: 50, height: 50)
            }

            VStack(alignment: .leading) {
                Text(game.title)
                    .font(.headline)
                Text("Playtime: \(game.playtime) minutes")
                    .font(.subheadline)
            }
            .padding(.leading, 8)
        }
        .padding()
    }
}
