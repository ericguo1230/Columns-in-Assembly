# 🎮 How to Play **COLUMNS** (MIPS Assembly Version)

Welcome to **COLUMNS**, a falling-block puzzle game inspired by classic arcade titles. This version is fully implemented in **MIPS Assembly** and designed to run with a **256×256 bitmap display** using **8×8 pixel units**.

---

## 📺 Display Requirements
To view and play the game correctly, ensure that your simulator is configured with:

- **Bitmap Display Size:** `256 × 256` pixels  
- **Unit Size:** `8 × 8` pixel blocks  
- **Color Format:** 24-bit RGB (0xRRGGBB)  
- **Base Address:** Must be mapped to your `.word 0x10008000` display memory

Each cell on the board corresponds to one 8×8 pixel block.

---

## 🎯 Goal of the Game
Stack falling columns of colored blocks so that **three or more blocks of the same color** line up **horizontally, vertically, or diagonally**.  
Matching sets disappear, points are awarded, and blocks above fall into place—possibly chaining combos.

Survive as long as possible while the speed gradually increases!

---

## ⌨️ Controls

While your falling column is in play, use the keyboard to manipulate it:

### **Movement**
| Key | Action |
|-----|--------|
| **a** | Move column **left** one cell |
| **d** | Move column **right** one cell |
| **s** | Move column **down faster** |

### **Rotation**
| Key | Action |
|-----|--------|
| **w** | **Rotate** the three colors within the column (top ↔ middle ↔ bottom) |

Rotation cycles the colors inside the falling column, allowing you to place matching colors more strategically.

---

## 🧱 Game Mechanics

### Falling Column
- Each piece is a **column of 3 colored blocks**.
- The column drops one cell at a time.
- You may move left, right, or rotate as it falls.

### Landing & Locking
- When the column reaches the bottom or lands on another block:
  - It **locks into place**.
  - The game scans for **matching groups**.

### Matching Rules
A match occurs when **3 or more blocks of the same color** connect:
- In a **row**  
- In a **column**  
- On a **diagonal (both directions)**

Matched colors:
- **Disappear**
- **Score points**
- Cause the above blocks to **fall downward**

Cascade matches yield **bonus points**.

---

## 🕹️ Game Flow

1. **Spawn** a new 3-block column at the top.
2. **Player controls** the column using **w, a, s, d**.
3. The column **falls** until it lands.
4. The board checks for **matches**.
5. If matches occur:
   - They are removed  
   - Blocks fall  
   - New matches are checked again  
6. A new piece spawns.
7. Game ends if the spawn area is blocked.

---

## 🔧 Additional Technical Notes (for players using the Assembly version)
- Input comes from the memory-mapped **keyboard** at `0xFFFF0000`.
- Display is drawn by writing pixel colors to `ADDR_DSPL`.
- Board state is stored in a dedicated `.space` block, simulating a 2D grid of colors.
- Timing is usually controlled via software delay loops or interrupts.
