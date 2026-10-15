# Zomboid Moodle Focus

A controller-friendly Moodle information overlay for Project Zomboid Build 42.

## Features

- Hover a visible Moodle with the mouse to show a larger icon, its localized vanilla name and its vanilla description.
- Controller: hold **Back/View**, choose **Moodles**, then use D-pad up/down to cycle through active Moodles.
- Press **A** or **B** to close the controller card.
- Does not replace the normal D-pad-up action, which Build 42 already uses for contextual radial menus and vehicle cruise control.

## Local installation

Copy `Contents/mods/ZomboidMoodleFocus` to:

```text
~/Zomboid/mods/ZomboidMoodleFocus
```

Enable **Zomboid Moodle Focus** in the game's Mods menu and reload the save.

## Tests

```sh
find Contents -type f -name '*.lua' -exec luac -p {} \;
lua tests/test_moodle_focus.lua
```

This is an initial Build 42 prototype. The Lua syntax and controller/hover behavior are covered by a standalone mock; live-game visual tuning may still be needed.
