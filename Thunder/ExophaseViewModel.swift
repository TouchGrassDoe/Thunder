//
//  ExophaseViewModel.swift
//  Thunder
//
//  Created by Aaron Doe on 13/10/2024.
//

import Foundation
import SwiftSoup

struct AchievementResponse: Codable {
    let success: Bool
    let list: [AchievementData]
}

struct AchievementData: Codable {
    let awardid: String
    let slug: String
    let timestamp: TimeInterval
    let endpoint: String
}

class ExophaseViewModel: ObservableObject {
    @Published var games: [ExophaseGame] = []
    @Published var achievements: [Achievement] = []
    @Published var isLoading: Bool = true
    
    @Published var exophaseName: String
    @Published var psnName: String

    init(exophaseName: String, psnName: String) {
        self.exophaseName = exophaseName
        self.psnName = psnName
        fetchUserProfile()
    }

    func updateUserProfile(psnName: String, exophaseName: String) {
        self.psnName = psnName
        self.exophaseName = exophaseName
        UserDefaults.standard.set(psnName, forKey: "psnName")
        UserDefaults.standard.set(exophaseName, forKey: "exophaseName")
        fetchUserProfile()
    }

    func fetchUserProfile() {
        let url = "https://www.exophase.com/user/\(exophaseName)"
        print("Fetching user profile from: \(url)")

        URLSession.shared.dataTask(with: URL(string: url)!) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to fetch user profile: \(error?.localizedDescription ?? "No data")")
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            self.scrapeUserProfile(data: data)
        }.resume()
    }

    private func scrapeUserProfile(data: Data) {
        do {
            let htmlString = String(data: data, encoding: .utf8)
            print("HTML Response: \(htmlString ?? "nil")")

            let document = try SwiftSoup.parse(htmlString ?? "")
            let userIdElement = try document.select("div[data-userid]").first()
            
            guard let userId = try! userIdElement?.attr("data-userid"), !userId.isEmpty else {
                print("User ID not found")
                DispatchQueue.main.async { self.isLoading = false }
                return
            }

            print("User ID: \(userId)")

            self.fetchLatestGames(platform: "psn", userId: userId)
        } catch {
            print("Error parsing user profile: \(error)")
            DispatchQueue.main.async { self.isLoading = false }
        }
    }

    func fetchLatestGames(platform: String, userId: String) {
        let url = "https://www.exophase.com/\(platform)/user/\(psnName)"
        print("Fetching games from: \(url)")

        URLSession.shared.dataTask(with: URL(string: url)!) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to fetch latest games: \(error?.localizedDescription ?? "No data")")
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            self.scrapeLatestGames(data: data)
        }.resume()
    }

    private func scrapeLatestGames(data: Data) {
        do {
            let htmlString = String(data: data, encoding: .utf8)
            print("HTML Response: \(htmlString ?? "nil")")
            let document = try SwiftSoup.parse(htmlString ?? "")
            let gameElements = try document.select("div.col.col-game.game-info")

            print("Found \(gameElements.size()) games")
            var newGames: [ExophaseGame] = []

            for game in gameElements {
                if let gameLinkElement = try game.select("h3 > a").first() {
                    let gameId = try! gameLinkElement.attr("href").components(separatedBy: "/").last?.components(separatedBy: "#").first ?? ""
                    let title = try gameLinkElement.text()
                    let url = try gameLinkElement.attr("href")
                    let playtimeText = try game.select("span.hours").text()
                    let playtimeComponents = playtimeText.split(separator: " ")
                    let playtimeHours = playtimeComponents.count > 0 ? Int(playtimeComponents[0].dropLast()) ?? 0 : 0
                    let playtimeMinutes = playtimeComponents.count > 2 ? Int(playtimeComponents[2].dropLast()) ?? 0 : 0
                    let playtime = (playtimeHours * 60) + playtimeMinutes
                    let image = ""

                    print("Game found: ID=\(gameId), Title=\(title), Playtime=\(playtime), URL=\(url)")

                    let newGame = ExophaseGame(id: gameId, title: title, trophyCount: 0, details: "", image: image, playtime: playtime, url: url)
                    newGames.append(newGame)

                    fetchAchievements(url: url, gameId: gameId)
                } else {
                    print("No link element found for game: \(try game.outerHtml())")
                }
            }

            DispatchQueue.main.async {
                self.games = newGames
                print("Total games added: \(self.games.count)")
                self.isLoading = false
            }
        } catch {
            print("Error parsing games: \(error)")
            DispatchQueue.main.async { self.isLoading = false }
        }
    }

    func fetchAchievements(url: String, gameId: String) {
        guard let fragment = URL(string: url)?.fragment else { return }
        let apiUrl = "https://api.exophase.com/public/player/\(fragment)/game/\(gameId)/earned"

        URLSession.shared.dataTask(with: URL(string: apiUrl)!) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to fetch achievements: \(error?.localizedDescription ?? "No data")")
                return
            }

            self.scrapeAchievements(data: data)
        }.resume()
    }

    private func scrapeAchievements(data: Data) {
        do {
            let apiData = try JSONDecoder().decode(AchievementResponse.self, from: data)

            guard apiData.success else {
                print("API call was not successful")
                return
            }

            var newAchievements: [Achievement] = []
            for achievement in apiData.list {
                let timestamp = Date(timeIntervalSince1970: achievement.timestamp)
                do {
                    let details = try fetchAchievementDetails(endpoint: achievement.endpoint)

                    let newAchievement = Achievement(
                        id: achievement.awardid,
                        name: achievement.slug.replacingOccurrences(of: "-", with: " ").capitalized,
                        description: details.description,
                        icon: details.icon,
                        time: timestamp
                    )
                    newAchievements.append(newAchievement)
                } catch {
                    print("Error fetching details for achievement \(achievement.awardid): \(error)")
                }
            }

            DispatchQueue.main.async {
                self.achievements = newAchievements
            }
        } catch {
            print("Error parsing achievements: \(error)")
        }
    }

    private func fetchAchievementDetails(endpoint: String) throws -> (description: String, icon: String) {
        do {
            let achievementResponse = try Data(contentsOf: URL(string: endpoint)!)
            let achievementSoup = try SwiftSoup.parse(String(data: achievementResponse, encoding: .utf8)!)
            let description = try achievementSoup.select("div.col.award-details.snippet p").text()
            let icon = try achievementSoup.select("img").attr("src")
            return (description, icon)
        } catch {
            print("Error fetching achievement details: \(error)")
            throw error
        }
    }
}
