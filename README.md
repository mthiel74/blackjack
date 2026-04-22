# Blackjack

A classic casino card game built with pure HTML, CSS, and JavaScript. Play against the computer dealer in this fully-featured, browser-based Blackjack game.

![Blackjack Game](https://img.shields.io/badge/Game-Blackjack-brightgreen)
![HTML5](https://img.shields.io/badge/HTML5-E34F26?logo=html5&logoColor=white)
![CSS3](https://img.shields.io/badge/CSS3-1572B6?logo=css3&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?logo=javascript&logoColor=black)

## Features

### Gameplay
- **Player vs Dealer** - Classic one-on-one Blackjack against the computer
- **Standard Blackjack Rules** - Hit, Stand, and automatic win detection
- **Smart Ace Handling** - Aces automatically count as 1 or 11 for optimal hand value
- **Dealer AI** - Dealer follows standard casino rules (hits until 17 or higher)
- **Blackjack Detection** - Instant win/loss detection for natural 21s

### Game Mechanics
- **52-Card Deck** - Full standard deck with automatic reshuffling
- **Hidden Hole Card** - Dealer's second card stays hidden until player stands
- **Bust Detection** - Automatic loss when hand exceeds 21
- **Push/Tie Handling** - Proper tie detection when scores are equal

### Statistics
- **Win Counter** - Track your victories
- **Loss Counter** - Monitor your losses
- **Push Counter** - Keep count of ties
- **Persistent Session Stats** - Stats maintained throughout your gaming session

### Visual Design
- **Casino-Style Theme** - Professional green felt background
- **Beautiful Card Design** - Clean cards with Unicode suit symbols (♠ ♥ ♦ ♣)
- **Color-Coded Suits** - Red for hearts/diamonds, black for spades/clubs
- **Smooth Animations** - Hover effects and transitions
- **Responsive Layout** - Works on desktop, tablet, and mobile devices

## How to Play

### Quick Start
1. Clone this repository or download `index.html`
2. Open `index.html` in any modern web browser
3. Start playing!

```bash
git clone https://github.com/mthiel74/blackjack.git
cd blackjack
open index.html  # macOS
# or
start index.html  # Windows
# or
xdg-open index.html  # Linux
```

### Game Rules

**Objective:** Get a hand value as close to 21 as possible without going over, while beating the dealer's hand.

**Card Values:**
| Card | Value |
|------|-------|
| 2-10 | Face value |
| J, Q, K | 10 |
| Ace | 1 or 11 (automatically optimized) |

**Actions:**
- **Hit** - Draw another card from the deck
- **Stand** - Keep your current hand and let the dealer play
- **New Game** - Start a fresh round

**Winning:**
- Get a higher score than the dealer without busting (going over 21)
- Dealer busts (goes over 21)
- Get a "Blackjack" (Ace + 10-value card on initial deal)

**Losing:**
- Your hand exceeds 21 (bust)
- Dealer has a higher score than you
- Dealer gets Blackjack

**Push (Tie):**
- Both you and the dealer have the same score

## Technical Details

### Built With
- **HTML5** - Semantic markup and structure
- **CSS3** - Modern styling with flexbox, gradients, and animations
- **Vanilla JavaScript** - No frameworks or dependencies

### Browser Support
- Chrome (recommended)
- Firefox
- Safari
- Edge
- Any modern browser with ES6 support

### File Structure
```
blackjack/
├── index.html    # Complete game (HTML + CSS + JS)
└── README.md     # This file
```

## Screenshots

The game features a clean, casino-inspired interface:

- Green felt background reminiscent of real casino tables
- Clear card displays for both player and dealer hands
- Prominent action buttons (Hit, Stand, New Game)
- Real-time score display
- Session statistics tracking

## Customization

The game is contained in a single HTML file, making it easy to customize:

- **Colors:** Modify CSS variables in the `<style>` section
- **Card Size:** Adjust `.card` width/height properties
- **Rules:** Modify JavaScript functions like dealer hit threshold

## License

This project is open source and available under the [MIT License](LICENSE).

## Contributing

Contributions are welcome! Feel free to:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Future Enhancements

Potential features for future versions:
- [ ] Betting system with chips
- [ ] Double down option
- [ ] Split pairs
- [ ] Insurance against dealer Blackjack
- [ ] Multiple deck shoe
- [ ] Sound effects
- [ ] Local storage for persistent stats
- [ ] Multiplayer support

---

Made with ♠ ♥ ♦ ♣
