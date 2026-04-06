"""
main.py — Demo runner with 6 illustrative maze scenarios
Part of: Meta AI-Enabled Coding Interview — Maze Solver

Run:  python main.py
Test: python test_maze.py

Interview context:
  This demonstrates all features an interviewer would ask you to
  implement in the AI-Enabled Coding format:
    Part 1 — Read and understand the starter code (maze.py)
    Part 2 — Implement BFS traversal (solver.py)
    Part 3 — Add keys/doors and chute logic (solver.py)
    Part 4 — Write test cases and handle edge cases (test_maze.py)
"""

import time
from maze import Maze
from solver import solve, print_result


def run_demo(title: str, maze_str: str) -> None:
    print("=" * 60)
    print(f"  {title}")
    print("=" * 60)
    print()
    maze = Maze.from_string(maze_str)
    print("  Maze:")
    for line in maze.render().split('\n'):
        print(f"    {line}")
    print()
    t0 = time.perf_counter()
    path = solve(maze, verbose=True)
    elapsed = (time.perf_counter() - t0) * 1000
    print_result(maze, path)
    print(f"  Solved in {elapsed:.2f} ms")
    print()


# ── Scenario 1: Simple BFS ────────────────────────────────────────────────
MAZE_SIMPLE = """\
##########
#S       #
# ###### #
#        #
# ######E#
##########"""


# ── Scenario 2: Key + Door ────────────────────────────────────────────────
MAZE_KEY_DOOR = """\
############
#S   a   A E#
############"""


# ── Scenario 3: Multiple keys, same letter (Interview favourite) ──────────
#   Two 'a' tiles on the board.  BFS state-space correctly avoids
#   treating 're-visit with same key set' as a new state.
MAZE_SAME_KEY = """\
##############
#S  a    a  A E#
##############"""


# ── Scenario 4: Multiple different keys ──────────────────────────────────
MAZE_MULTI_KEY = """\
#####################
#S  a  A  b  B  c  C E#
#####################"""


# ── Scenario 5: One-way chute ─────────────────────────────────────────────
#   '>' at (1,4): entering from the left slides the player to (1,5)
#   The chute provides a shortcut skipping one cell.
MAZE_CHUTE = """\
###########
#S  a  A> E#
###########"""


# ── Scenario 6: No solution ───────────────────────────────────────────────
MAZE_NO_PATH = """\
#######
#S ### E#
#######"""


def main():
    print()
    print("=" * 60)
    print("  MAZE SOLVER DEMO")
    print("  BFS with Keys, Doors and One-Way Chutes")
    print("  Meta AI-Enabled Coding Interview Preparation")
    print("=" * 60)
    print()
    print("  Symbols:")
    print("    S  = Start          E  = End / Exit")
    print("    #  = Wall           ' ' = Open floor")
    print("    a-z = Key (pick up) A-Z = Door (needs key)")
    print("    >  = One-way chute (slides player RIGHT)")
    print("    *  = Path taken (in rendered solution)")
    print()

    run_demo("Scenario 1 — Simple BFS (no keys)", MAZE_SIMPLE)
    run_demo("Scenario 2 — Single Key + Door", MAZE_KEY_DOOR)
    run_demo("Scenario 3 — Multiple Keys, Same Letter", MAZE_SAME_KEY)
    run_demo("Scenario 4 — Multiple Different Keys and Doors", MAZE_MULTI_KEY)
    run_demo("Scenario 5 — One-Way Chute Shortcut", MAZE_CHUTE)
    run_demo("Scenario 6 — No Solution (wall blocks all paths)", MAZE_NO_PATH)

    print("=" * 60)
    print("  All scenarios complete.")
    print("  Run 'python test_maze.py' for the full test suite.")
    print("=" * 60)


if __name__ == "__main__":
    main()
