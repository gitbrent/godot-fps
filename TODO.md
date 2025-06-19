# TODO

## CHANGELOG: Version-0.1

[x] - ADDED: respawn enemies in main controller
[x] - ADDED: fade/queue_free enemy on death
[x] - ADDED: enemy moves toward direction shot from
[x] - ADDED:  main menu HUD; start button; enable restart after die
[x] - FIXED: maximizing window skews Main Menu labels/buttons
[x] - ADDED: start button has 3-sec delay before spawning enemiesl shows 3-2-1 countdown
[x] - ADDED: new scene to show weapons (allow rotate around z-axis)
[x] - FIXED: state thrashing with enemies ("i see him!", "i lost him!")
[x] - ADDED: new scene: shooting_range to test effects, enemy states, etc.
[x] - ADDED: show bullet splat/blood spurt on enemies when hit
[x] - ADDED: show bullet tracers
[x] - ADDED: remap inputs to match CoD, rename to new standard
[x] - FIXED: blood spurt on hit should be attached to enemy, not bullet_projectile!
[x] - ADDED: enemy gallery (with state menu buttons)
[x] - ADDED: ui:main_menu:options with "Invert Look" option; save/read player settings
[WIP] - ADDED: create `CoverPoint` scene - work on enemy AI cover
[ ] - UPDATED: player damage flash to use high-quality png with strong edges (e.g., Doom or CoD)

## FIXME

[ ] - give enemies their own bullet Layer (so they dont shoot themselves) (same for player)
[ ] - fix laser sight

## New Features: Future

[ ] - PlayerController uses both `_unhandled_input` and `_physics_process` for Inputs - refactor to best practice
[ ] - when paused, show real scene with rotating camera (see `main_menu.tscn`)
[ ] - add `AudioManager.gd` to manage "I lost them!" etc. so they dont all cluster
[ ] - add crouch to player controller
[ ] - setup `AnimationTree` for enemy states, design & test (gun shown=done)
[ ] - separate `game_controller.gd` from `TestMap.tscn`; allow mulitple map selection
[ ] - add: ui > main_menu > settings > controller with pic of PS5 controller & buttons labeled
[ ] - add exploding barrels
[ ] - exploding barrels set enemies on fire
