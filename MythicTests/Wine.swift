// Only the namespace is needed to compile the production transaction source in this hostless test bundle.
// Excluding Wine's process and container dependencies keeps tests from launching Mythic or touching real containers.
enum Wine {}
