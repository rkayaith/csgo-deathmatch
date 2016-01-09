# csgo-deathmatch

Some SourceMod plugins for making a custom deathmatch mode in CS:GO.  
The plugins are completely independent and can be used separately.

**Any plugins with version < 1.0 are very WIP!!**

## How to use:
Install SourceMod then take any of the compiled plugins from `/compiled/` and put it in your server's `/sourcemod/plugins/` folder.  
Use `dm_enable [0/1]` to turn on/off all of the plugins.

## Plugins:

### dm_healthammo:
Gives health / ammo on kill. The amount given is a factor of the player's max health / weapon's max clip size (so `dm_ammo_kill 0.5` will give 15 bullets for an ak47 but only 5 for an AWP). Both primary and secondary weapons are given ammo on kill.

Commands:  
`dm_health_kill` `dm_health_kill_headshot` `dm_ammo_kill` `dm_ammo_kill_headshot`

### dm_cash:
Implements some of the `cash_player_*` commands without all the annoying chat printing. `mp_playercashawards 0` is set when the plugin first starts to avoid conflicts with the default behaviour of the commands.

Implemented Commands:  
`mp_maxmoney` `cash_player_killed_enemy_default` `cash_player_killed_enemy_factor` `cash_player_killed_teammate` `cash_player_get_killed` `cash_player_respawn_amount`

NOT Implemented (yet):  
`cash_player_bomb_defused` `cash_player_bomb_planted` `cash_player_damage_hostage` `cash_player_interact_with_hostage` `cash_player_killed_hostage` `cash_player_rescued_hostage`

### dm_rounds
Tracks the kills per team using the round scores. Reaching `dm_rounds_fraglimit` ends the round and resets scores. Set to `0` for no limit.

Commands:
`dm_rounds_fraglimit`
