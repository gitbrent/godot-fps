# TODO

## CHANGELOG: Version-0.2

[x] - UPDATED: player damage flash to use high-quality png with strong edges (e.g., Doom or CoD)
[x] - ADDED: adjusted position/size of enemy CollisionShape for crouch/stand
[WIP] - ADDED: create `CoverPoint` scene - work on enemy AI cover
[ ] - ^^^ ADD: AnimationTree with real transitions
[ ] - continue AI by having it effectively switch staes like patrol/attack/idle

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
