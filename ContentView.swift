//
//  ContentView.swift
//  MemoryGame
//
//  Created by Sri Narendrula on 10/22/25.
//

import SwiftUI
internal import Combine


// MARK: - Card Model
struct Card: Identifiable {
    let id = UUID()
    let emoji: String
    var isFaceUp = false
    var isMatched = false
}

// MARK: - Game Logic
class MemoryGame: ObservableObject {
    @Published var cards: [Card] = []
    @Published var score = 0
    @Published var numberOfPairs = 4
    
    private var indexOfOneAndOnlyFaceUpCard: Int?
    
    // All available emojis
    private let allEmojis = ["🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯", "🦁", "🐮", "🐷", "🐸", "🐵", "🐔"]
    
    init() {
        resetGame()
    }
    
    // MARK: - Card Selection Logic
    func choose(_ card: Card) {
        guard let chosenIndex = cards.firstIndex(where: { $0.id == card.id }),
              !cards[chosenIndex].isFaceUp,
              !cards[chosenIndex].isMatched else {
            return
        }
        
        if let potentialMatchIndex = indexOfOneAndOnlyFaceUpCard {
            // Two cards are now face up, check for match
            if cards[chosenIndex].emoji == cards[potentialMatchIndex].emoji {
                // Match found!
                cards[chosenIndex].isMatched = true
                cards[potentialMatchIndex].isMatched = true
                score += 10
            }
            indexOfOneAndOnlyFaceUpCard = nil
        } else {
            // First card or more than 2 cards face up
            // Flip all non-matched cards face down
            for index in cards.indices {
                if !cards[index].isMatched {
                    cards[index].isFaceUp = false
                }
            }
            indexOfOneAndOnlyFaceUpCard = chosenIndex
        }
        
        cards[chosenIndex].isFaceUp = true
    }
    
    // MARK: - Reset Game
    func resetGame() {
        let selectedEmojis = Array(allEmojis.shuffled().prefix(numberOfPairs))
        let pairedEmojis = (selectedEmojis + selectedEmojis).shuffled()
        
        cards = pairedEmojis.map { Card(emoji: $0) }
        score = 0
        indexOfOneAndOnlyFaceUpCard = nil
    }
    
    // MARK: - Update Number of Pairs
    func updatePairs(_ newValue: Int) {
        numberOfPairs = newValue
        resetGame()
    }
}

// MARK: - Card View
struct CardView: View {
    let card: Card
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let shape = RoundedRectangle(cornerRadius: 12)
                
                if card.isMatched {
                    // Matched cards are completely invisible
                    shape.opacity(0)
                } else if card.isFaceUp {
                    // Face up - show emoji
                    shape.fill(.white)
                    shape.strokeBorder(lineWidth: 2)
                    Text(card.emoji)
                        .font(.system(size: min(geometry.size.width, geometry.size.height) * 0.6))
                } else {
                    // Face down - show back of card
                    shape.fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
            }
        }
        .aspectRatio(2/3, contentMode: .fit)
        .opacity(card.isMatched ? 0 : 1)
    }
}

// MARK: - Main Game View
struct ContentView: View {
    @StateObject private var game = MemoryGame()
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Memory Game")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            // Score
            Text("Score: \(game.score)")
                .font(.title2)
                .foregroundColor(.secondary)
            
            // Pair Selector
            HStack {
                Text("Number of Pairs:")
                    .font(.headline)
                
                Picker("Pairs", selection: Binding(
                    get: { game.numberOfPairs },
                    set: { game.updatePairs($0) }
                )) {
                    Text("2").tag(2)
                    Text("4").tag(4)
                    Text("6").tag(6)
                    Text("8").tag(8)
                    Text("10").tag(10)
                    Text("12").tag(12)
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)
            
            // Scrollable Card Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(game.cards) { card in
                        CardView(card: card)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    game.choose(card)
                                }
                            }
                    }
                }
                .padding(.horizontal)
            }
            
            // Reset Button
            Button(action: {
                withAnimation {
                    game.resetGame()
                }
            }) {
                Text("New Game")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.bottom)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
