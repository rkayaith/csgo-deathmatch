# csgo-deathmatch 

Some SourceMod plugins for making a custom deathmatch mode in CS:GO.  
The plugins are completely independent and can be used seperately.

**Any plugins with version < 1.0 are very WIP!!**

##How to use:
Install SourceMod then take any of the compiled plugins from /compiled/ and put it in your server's /sourcemod/plugins/ folder.

##Plugins:

**dm_healthammo:**  
Gives health / ammo on kill. The amount given is a factor of the player's max health / weapon's max clip size. Both primary and secondary weapons are given ammo on kill.

Commands:  
`dm_health_kill`, `dm_health_kill_headshot`, `dm_ammo_kill`, `dm_ammo_kill_headshot`

**dm_cash:**  
Implements some of the `cash_player_*` commands without all annoying chat printing. `mp_playercashawards 0` is set when the plugin first starts to avoid conflicts with the default behaviour of the commands.

Implemented Commands:  
`mp_maxmoney`, `cash_player_killed_enemy_default`, `cash_player_killed_enemy_factor`, `cash_player_killed_teammate`, `cash_player_get_killed`, `cash_player_respawn_amount`

NOT Implemented:
`cash_player_bomb_defused`, `cash_player_bomb_planted`, `cash_player_damage_hostage`, `cash_player_interact_with_hostage`, `cash_player_killed_hostage`, `cash_player_rescued_hostage`