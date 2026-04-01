#!/usr/bin/env python3
"""Build a pairwise merge tree for CI analysis files.

Takes check-ids as space-separated arguments and outputs an XML
<processing-order> structure with batches and groups for the
analyses-merger agent to consume.

Example:
    $ python ci-merge-tree.py 0 1 2 3 4
    <processing-order>
    <batch id="0">
    <group id="5"><input1>0</input1><input2>1</input2></group>
    <group id="6"><input1>2</input1><input2>3</input2></group>
    </batch>
    <batch id="1">
    <group id="7"><input1>5</input1><input2>6</input2></group>
    </batch>
    <batch id="2">
    <group id="8"><input1>4</input1><input2>7</input2></group>
    </batch>
    </processing-order>
"""

import sys
from collections import deque


def build_merge_tree(ids):
    """Build pairwise merge tree from list of IDs.

    Returns list of batches, where each batch is a dict of
    group_id -> [input1, input2] pairs.
    """
    batches = []
    queue = deque(ids)
    # Next available merge ID starts after the highest original ID
    # Original IDs are sequential ints, so start from len(ids)
    next_id = max(int(x) for x in ids) + 1 if ids else 0

    while len(queue) > 1:
        batch = {}
        pairs_count = len(queue) // 2
        for _ in range(pairs_count):
            g1 = queue.popleft()
            g2 = queue.popleft()
            batch[str(next_id)] = [str(g1), str(g2)]
            queue.append(str(next_id))
            next_id += 1
        batches.append(batch)
        # If odd element remains, it stays in queue for next batch

    return batches


def format_xml(batches):
    """Format batches as XML processing-order."""
    lines = ["<processing-order>"]
    for batch_idx, batch in enumerate(batches):
        lines.append(f'<batch id="{batch_idx}">')
        for group_id, (input1, input2) in batch.items():
            lines.append(
                f"<group id=\"{group_id}\">"
                f"<input1>{input1}</input1>"
                f"<input2>{input2}</input2>"
                f"</group>"
            )
        lines.append("</batch>")
    lines.append("</processing-order>")
    return "\n".join(lines)


def main():
    if len(sys.argv) < 2:
        print("Usage: ci-merge-tree.py <id1> <id2> [id3 ...]", file=sys.stderr)
        sys.exit(1)

    ids = sys.argv[1:]

    if len(ids) < 2:
        print(
            "Error: Need at least 2 IDs to build a merge tree",
            file=sys.stderr,
        )
        sys.exit(1)

    batches = build_merge_tree(ids)
    print(format_xml(batches))


if __name__ == "__main__":
    main()
