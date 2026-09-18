# ModKit

Passive diagnostic mod. It verifies loading from this repository and writes a UE4SS log message. It does not touch actors, saves, or rendering.

[`../mods.txt`](../mods.txt) is the canonical load manifest. ModKit is loaded from that file along with the other active modules; it does not require an `enabled.txt` marker.
