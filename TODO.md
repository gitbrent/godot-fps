# TODO

## New Features: Current

[x] - respawn enemies in main controller
[x] - fade/queue_free enemy on death
[x] - enemy moves toward direction shot from
[x] - add main menu HUD; start button; enable restart after die
[x] - maximizing window skews Main Menu labels/buttons
[x] - start button has 3-sec delay before spawning enemiesl shows 3-2-1 countdown
[x] - add new scene to show weapons (allow rotate around z-axis)
[x] - fix state thrashing with enemies ("i see him!", "i lost him!")
[x] - new scene: shooting_range to test effects, enemy states, etc.
[x] - show bullet splat/blood spurt on enemies when hit
[ ] - remap inputs to match CoD, rename to new standard
[ ] - show bullet tracers
[ ] - add crouch to player controller
[ ] - blood spurt on hit should be attached to enemy, not bullet_projectile!
[ ] - NEW: enemy gallery (with state menu buttons)

## FIXME

[ ] - 

## Questions

[ ] - 

## New Features: Future

[ ] - when paused, show real scene with rotating camera (see `main_menu.tscn`)
[ ] - setup `AnimationTree` for enemy states, design & test
[ ] - update player damage flash to use high-quality png with strong edges (e.g., Doom or CoD)
[ ] - separate `game_controller.gd` from `TestMap.tscn`; allow mulitple map selection
[ ] - add: ui > settings > controller with pic of PS5 controller & buttons labeled
[ ] - add exploding barrels
[ ] - exploding barrels set enemies on fire
[ ] - use holodeck-style walls (instead of Kenney checkers)
[ ] - add `AudioManager.gd` to manage "I lost them!" etc. so they dont all cluster
