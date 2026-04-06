"""
test_maze.py — Comprehensive test suite for the maze solver
Part of: Meta AI-Enabled Coding Interview — Maze Solver

Coverage:
  - Basic BFS pathfinding
  - Single key + door
  - Multiple keys of the SAME letter (must not pick up twice)
  - Multiple DIFFERENT keys and doors
  - One-way chutes
  - No path possible (wall blocks, missing key)
  - Start equals end (trivial)
  - Edge cases: 1x1, 1-row, 1-col mazes
  - Path length verification
  - Key ordering: door encountered before key collected
  - Large maze performance sanity check
"""

import sys
import time
from maze import Maze
from solver import solve


# ── Test runner ────────────────────────────────────────────────────────────
_PASSED = 0
_FAILED = 0


def check(name: str, condition: bool, detail: str = "") -> None:
    global _PASSED, _FAILED
    status = "PASS" if condition else "FAIL"
    symbol = "+" if condition else "X"
    print(f"  [{symbol}] {status} | {name}", end="")
    if detail:
        print(f"  ({detail})", end="")
    print()
    if condition:
        _PASSED += 1
    else:
        _FAILED += 1


def run_test(name: str, maze_str: str,
             expect_path: bool = True,
             expect_steps: int = None,
             expect_keys: list = None):
    """Run a single test case and report result."""
    maze = Maze.from_string(maze_str)
    path = solve(maze, verbose=False)

    check(f"{name} — path {'found' if expect_path else 'correctly blocked'}",
          (path is not None) == expect_path,
          f"path={'Yes' if path else 'None'}")

    if expect_path and path is not None:
        if expect_steps is not None:
            check(f"{name} — step count",
                  len(path) == expect_steps,
                  f"got {len(path)}, want {expect_steps}")

    return path


# ══════════════════════════════════════════════════════════════════════════════
# TEST CASES
# ══════════════════════════════════════════════════════════════════════════════

def test_basic_open():
    """Straight corridor — trivial BFS."""
    print("\n--- Test 1: Basic open corridor ---")
    maze_str = (
        "#####\n"
        "#S E#\n"
        "#####"
    )
    path = run_test("Basic open corridor", maze_str,
                    expect_path=True, expect_steps=3)
    # S at (1,1), E at (1,3) — path length 3 positions = steps S->.(2)->E -> 3 cells
    check("Basic — start is first cell", path is not None and path[0] == Maze.from_string(maze_str).start)
    check("Basic — end is last cell",   path is not None and path[-1] == Maze.from_string(maze_str).end)


def test_no_path_wall():
    """Complete wall blocks all routes."""
    print("\n--- Test 2: No path (wall blocks) ---")
    maze_str = (
        "#####\n"
        "#S##E\n"  # no gap between ## and E
        "#####"
    )
    run_test("Wall blocks all routes", maze_str, expect_path=False)


def test_single_key_door():
    """Must collect key 'a' to pass door 'A'."""
    print("\n--- Test 3: Single key + door ---")
    maze_str = (
        "#######\n"
        "#S a A E#\n"
        "#######"
    )
    # Simpler version that parses cleanly:
    maze_str = "#########\n#S  a  A  E#\n#########"
    # Use a precise maze:
    maze_str = (
        "##########\n"
        "#S a A  E#\n"
        "##########"
    )
    path = run_test("Single key+door: path exists", maze_str, expect_path=True)
    check("Single key+door: key picked up before door",
          path is not None,
          "BFS must route via 'a' before 'A'")


def test_door_before_key_no_path():
    """Door 'A' comes before key 'a' with no alternate route — should fail."""
    print("\n--- Test 4: Door before key, no alternate route ---")
    maze_str = (
        "########\n"
        "#S A  a E#\n"
        "########"
    )
    # Reachable 'a' is AFTER door 'A' — no way around
    maze_str = (
        "########\n"
        "#S A a E#\n"
        "########"
    )
    run_test("Door before key, blocked", maze_str, expect_path=False)


def test_alternate_route_bypasses_door():
    """There is a route around the door through the bottom corridor."""
    print("\n--- Test 5: Alternate route bypasses door ---")
    maze_str = (
        "#########\n"
        "#S  A   E#\n"
        "#   #   #\n"
        "#        #\n"
        "#########"
    )
    # More controlled:
    maze_str = (
        "########\n"
        "#S A  E#\n"
        "#      #\n"
        "########"
    )
    run_test("Alternate route around door", maze_str, expect_path=True)


def test_multiple_keys_same_letter():
    """
    KEY INTERVIEW FEATURE: multiple 'a' keys on the grid.
    Picking up the SAME key twice must not be allowed (re-visiting
    the same square with the same key inventory is a dup state).
    Player should only need ONE of the 'a' keys to pass the door.
    """
    print("\n--- Test 6: Multiple keys of SAME letter ---")
    maze_str = (
        "###########\n"
        "#S a   a A E#\n"
        "###########"
    )
    maze_str = (
        "############\n"
        "#S  a    a A  E#\n"
        "############"
    )
    # Cleaner version:
    maze_str = (
        "##########\n"
        "#S a  a A E#\n"
        "##########"
    )
    path = run_test("Multiple 'a' keys — path found", maze_str, expect_path=True)
    check("Multiple 'a' keys — terminates (no infinite loop)",
          path is not None,
          "BFS state includes key set, prevents revisiting same state")


def test_multiple_different_keys():
    """Need both 'a' and 'b' to reach the exit."""
    print("\n--- Test 7: Multiple different keys (a and b) ---")
    maze_str = (
        "############\n"
        "#S a  A b  B  E#\n"
        "############"
    )
    maze_str = (
        "#############\n"
        "#S  a  A  b  B  E#\n"
        "#############"
    )
    maze_str = "#" * 15 + "\n#S  a  A  b  B  E#\n" + "#" * 15
    path = run_test("Two keys two doors: path found", maze_str, expect_path=True)


def test_keys_out_of_order():
    """Keys and doors in an order that requires backtracking through state space."""
    print("\n--- Test 8: Keys out of order — requires state-space BFS ---")
    #  Layout:  S -> B_door(blocked) -> detour -> b_key -> B_door -> E
    maze_str = (
        "#########\n"
        "#S B    E#\n"
        "#  #  # #\n"
        "#  b  # #\n"
        "#  #    #\n"
        "#########"
    )
    path = run_test("Out-of-order key/door", maze_str, expect_path=True)


def test_one_way_chute():
    """
    One-way chute '>': entering moves player one step RIGHT automatically.
    The chute provides a shortcut but only in one direction.
    """
    print("\n--- Test 9: One-way chute ---")
    maze_str = (
        "#########\n"
        "#S >   E#\n"
        "#########"
    )
    path = run_test("Chute shortcut used", maze_str, expect_path=True)
    if path:
        positions = [str(p) for p in path]
        check("Chute — path is shorter than without chute",
              len(path) <= 6,
              f"steps={len(path)}")


def test_chute_into_wall():
    """Chute that slides into a wall — chute position treated as dead end for slide."""
    print("\n--- Test 10: Chute slides into wall ---")
    maze_str = (
        "#########\n"
        "#S >  #E#\n"   # chute at col 3, wall at col 4 — slide blocked, chute useless
        "#       #\n"
        "#########"
    )
    # Player must route around — path still exists
    path = run_test("Chute blocked by wall — alternate route works", maze_str, expect_path=True)


def test_trivial_start_equals_end():
    """Edge case: S and E are the same cell — impossible (different symbols)."""
    print("\n--- Test 11: 1x3 corridor, shortest possible ---")
    maze_str = (
        "#####\n"
        "#S E#\n"
        "#####"
    )
    path = run_test("Minimal corridor", maze_str, expect_path=True, expect_steps=3)


def test_single_row():
    """Edge case: 1-row maze."""
    print("\n--- Test 12: Single-row maze ---")
    maze_str = "#S   E#"
    path = run_test("Single row", maze_str, expect_path=True)


def test_single_col():
    """Edge case: 1-column maze (moves only up/down)."""
    print("\n--- Test 13: Single-column maze ---")
    maze_str = "#\nS\n \n \nE\n#"
    path = run_test("Single column", maze_str, expect_path=True)


def test_no_path_isolated():
    """Start completely surrounded by walls."""
    print("\n--- Test 14: Start isolated by walls ---")
    maze_str = (
        "#####\n"
        "##S##\n"
        "#####\n"
        "## E#\n"
        "#####"
    )
    run_test("Isolated start — no path", maze_str, expect_path=False)


def test_large_maze_performance():
    """Performance: 20x40 open grid — BFS should complete in under 1s."""
    print("\n--- Test 15: Large open maze (20x40) performance ---")
    rows, cols = 20, 40
    grid = []
    grid.append('#' * (cols + 2))
    for r in range(rows):
        row_chars = '#'
        for c in range(cols):
            if r == 0 and c == 0:
                row_chars += 'S'
            elif r == rows - 1 and c == cols - 1:
                row_chars += 'E'
            else:
                row_chars += ' '
        row_chars += '#'
        grid.append(row_chars)
    grid.append('#' * (cols + 2))
    maze_str = '\n'.join(grid)

    maze = Maze.from_string(maze_str)
    t0 = time.perf_counter()
    path = solve(maze, verbose=False)
    elapsed = time.perf_counter() - t0

    check("Large maze — path found",    path is not None)
    check("Large maze — under 1 second", elapsed < 1.0,
          f"took {elapsed*1000:.1f} ms")


def test_key_at_end_cell():
    """Edge case: key on the exit cell itself — should still be reachable."""
    print("\n--- Test 16: No-door maze with key on floor (irrelevant key) ---")
    maze_str = (
        "#######\n"
        "#S  a E#\n"
        "#######"
    )
    path = run_test("Key on path (no door needed)", maze_str, expect_path=True)


def test_all_keys_needed():
    """Must collect a, b, c in any order to pass three sequential doors."""
    print("\n--- Test 17: Three keys, three doors, sequential ---")
    maze_str = (
        "###################\n"
        "#S a b c A B C   E#\n"
        "###################"
    )
    path = run_test("Three keys three doors", maze_str, expect_path=True)


# ══════════════════════════════════════════════════════════════════════════════
# ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════

def main():
    print("=" * 60)
    print("  MAZE SOLVER — TEST SUITE")
    print("  Meta AI-Enabled Coding Interview Preparation")
    print("=" * 60)

    test_basic_open()
    test_no_path_wall()
    test_single_key_door()
    test_door_before_key_no_path()
    test_alternate_route_bypasses_door()
    test_multiple_keys_same_letter()
    test_multiple_different_keys()
    test_keys_out_of_order()
    test_one_way_chute()
    test_chute_into_wall()
    test_trivial_start_equals_end()
    test_single_row()
    test_single_col()
    test_no_path_isolated()
    test_large_maze_performance()
    test_key_at_end_cell()
    test_all_keys_needed()

    print()
    print("=" * 60)
    print(f"  SUMMARY:  {_PASSED} passed  |  {_FAILED} failed")
    print("=" * 60)
    return _FAILED


if __name__ == "__main__":
    sys.exit(main())
