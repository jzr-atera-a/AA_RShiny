"""
maze.py — Core maze data structures and parsing
Part of: Meta AI-Enabled Coding Interview — Maze Solver
"""

from __future__ import annotations
from dataclasses import dataclass, field
from typing import Optional
import textwrap


# ── Cell types ────────────────────────────────────────────────────────────────
WALL     = '#'
OPEN     = ' '
START    = 'S'
END      = 'E'
CHUTE    = '>'   # one-way: moves player one step RIGHT automatically

# Keys  : lowercase a-z  (pick up on entry)
# Doors : uppercase A-Z  (requires matching key to pass)


@dataclass(frozen=True)
class Pos:
    """Immutable (row, col) position."""
    row: int
    col: int

    def neighbours(self) -> list[Pos]:
        return [
            Pos(self.row - 1, self.col),
            Pos(self.row + 1, self.col),
            Pos(self.row,     self.col - 1),
            Pos(self.row,     self.col + 1),
        ]

    def __repr__(self) -> str:
        return f"({self.row},{self.col})"


@dataclass
class Maze:
    """
    Parsed maze grid with helpers.

    Grid conventions:
      '#'        wall
      ' ' or '.' open floor
      'S'        start
      'E'        end / exit
      'a'–'z'   key  (lowercase)
      'A'–'Z'   door (uppercase, needs matching lowercase key)
      '>'        one-way chute (landing square; enter from left, exit right)
    """
    grid:  list[list[str]]
    start: Pos
    end:   Pos
    rows:  int
    cols:  int

    @classmethod
    def from_string(cls, text: str) -> "Maze":
        """Parse a multi-line string into a Maze."""
        lines = text.split('\n')
        # Normalise line lengths
        max_len = max(len(l) for l in lines)
        grid = [list(l.ljust(max_len)) for l in lines]

        start = end = None
        for r, row in enumerate(grid):
            for c, cell in enumerate(row):
                if cell == START:
                    start = Pos(r, c)
                elif cell == END:
                    end = Pos(r, c)

        if start is None or end is None:
            raise ValueError("Maze must contain 'S' (start) and 'E' (end).")

        return cls(grid=grid, start=start, end=end,
                   rows=len(grid), cols=max_len)

    def cell(self, pos: Pos) -> str:
        if 0 <= pos.row < self.rows and 0 <= pos.col < self.cols:
            return self.grid[pos.row][pos.col]
        return WALL  # out-of-bounds treated as wall

    def in_bounds(self, pos: Pos) -> bool:
        return 0 <= pos.row < self.rows and 0 <= pos.col < self.cols

    def is_wall(self, pos: Pos) -> bool:
        return self.cell(pos) == WALL

    def is_key(self, pos: Pos) -> bool:
        return self.cell(pos).islower()

    def is_door(self, pos: Pos) -> bool:
        return self.cell(pos).isupper() and self.cell(pos) != END

    def is_chute(self, pos: Pos) -> bool:
        return self.cell(pos) == CHUTE

    def render(self, path: Optional[list[Pos]] = None) -> str:
        """Return a string rendering of the maze, optionally overlaying a path."""
        path_set = set(path or [])
        rows = []
        for r, row in enumerate(self.grid):
            line = []
            for c, cell in enumerate(row):
                pos = Pos(r, c)
                if pos in path_set and cell not in (START, END):
                    line.append('*')
                else:
                    line.append(cell)
            rows.append(''.join(line))
        return '\n'.join(rows)
