"""
solver.py — BFS-based maze solver with keys, doors, one-way chutes
Part of: Meta AI-Enabled Coding Interview — Maze Solver

Algorithm: BFS over state space (position, frozenset_of_keys_held)
  - Standard BFS guarantees shortest path in unweighted graphs
  - State includes key inventory so visiting the same cell with
    different keys is treated as a DIFFERENT state (avoids false loops)
  - Chutes: landing cell is processed normally, then player is
    automatically moved one step RIGHT (if in-bounds and not a wall)
  - Keys: picked up on entering the cell (one-time use enforced
    by including them in state — re-visiting with same keys = skip)
  - Doors: traversable only if matching lowercase key is in inventory

Time  complexity: O(R * C * 2^K)  where K = number of distinct keys
Space complexity: O(R * C * 2^K)
"""

from __future__ import annotations
from collections import deque
from typing import Optional
from maze import Maze, Pos, WALL, START, END, CHUTE


# ── State ──────────────────────────────────────────────────────────────────
State = tuple[Pos, frozenset]   # (position, keys_held)


def reconstruct_path(came_from: dict, state: State) -> list[Pos]:
    """Walk back through came_from to build the path of positions."""
    path = []
    while state is not None:
        path.append(state[0])
        state = came_from[state]
    path.reverse()
    return path


# ── Main solver ────────────────────────────────────────────────────────────
def solve(maze: Maze, verbose: bool = True) -> Optional[list[Pos]]:
    """
    BFS maze solver.

    Returns the shortest list of Pos representing the path from
    start to end (inclusive), or None if no path exists.

    Args:
        maze    : parsed Maze object
        verbose : print progress to stdout
    """
    if verbose:
        print(f"\n  [BFS] Grid size : {maze.rows} rows x {maze.cols} cols")
        print(f"  [BFS] Start     : {maze.start}")
        print(f"  [BFS] End       : {maze.end}")

    initial_keys: frozenset = frozenset()
    # If start cell itself is a key, pick it up immediately
    start_cell = maze.cell(maze.start)
    if start_cell.islower():
        initial_keys = frozenset([start_cell])

    start_state: State = (maze.start, initial_keys)

    queue:      deque[State]      = deque([start_state])
    came_from:  dict[State, Optional[State]] = {start_state: None}
    states_explored = 0

    while queue:
        pos, keys = queue.popleft()
        states_explored += 1

        if verbose and states_explored % 500 == 0:
            print(f"  [BFS] States explored: {states_explored:,}  |  Queue size: {len(queue):,}")

        # ── Goal check ────────────────────────────────────────────────────
        if pos == maze.end:
            if verbose:
                print(f"  [BFS] Goal reached! States explored: {states_explored:,}")
            path = reconstruct_path(came_from, (pos, keys))
            return path

        # ── Expand neighbours ─────────────────────────────────────────────
        for npos in pos.neighbours():
            if not maze.in_bounds(npos):
                continue
            cell = maze.cell(npos)

            # Wall — impassable
            if cell == WALL:
                continue

            # Door — need the matching key
            if maze.is_door(npos):
                required = cell.lower()
                if required not in keys:
                    if verbose:
                        pass  # too noisy to print every blocked door
                    continue

            # Collect any key at the new position
            new_keys = keys
            if maze.is_key(npos):
                if cell not in new_keys:
                    new_keys = keys | frozenset([cell])
                    if verbose:
                        print(f"  [KEY] Collected '{cell}' at {npos}  |  Keys held: {sorted(new_keys)}")

            # Handle one-way chute: land on '>', then slide one RIGHT
            landing = npos
            if maze.is_chute(npos):
                slide_to = Pos(npos.row, npos.col + 1)
                if maze.in_bounds(slide_to) and not maze.is_wall(slide_to):
                    if verbose:
                        print(f"  [CHUTE] Entered at {npos}, slid to {slide_to}")
                    landing = slide_to
                    # Pick up key at slide destination too
                    if maze.is_key(slide_to):
                        k2 = maze.cell(slide_to)
                        if k2 not in new_keys:
                            new_keys = new_keys | frozenset([k2])
                            if verbose:
                                print(f"  [KEY] Collected '{k2}' at {slide_to} (post-chute)")

            next_state: State = (landing, new_keys)
            if next_state not in came_from:
                came_from[next_state] = (pos, keys)
                queue.append(next_state)

    if verbose:
        print(f"  [BFS] No path found after {states_explored:,} states explored.")
    return None


def print_result(maze: Maze, path: Optional[list[Pos]]) -> None:
    """Pretty-print the solution or failure."""
    print()
    if path is None:
        print("  RESULT: No path exists from S to E.")
    else:
        print(f"  RESULT: Shortest path found — {len(path)} steps (including start and end).")
        print()
        print(maze.render(path))
        print()
        print(f"  Path: {' -> '.join(str(p) for p in path)}")
    print()
