#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

public Plugin myinfo = {
	name = "Keep Weapon",
	author = "Kyle",
	description = "Spawn with the same weapons you had before death",
	version = "1.0",
	url = ""
};

int serverWeaponsPrimary[MAXPLAYERS];
int serverWeaponsSecondary[MAXPLAYERS];
int player;

public void OnPluginStart () {
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_spawned", Event_PlayerSpawned);
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
	player = GetClientOfUserId(event.GetInt("userid"));
	int playerHealth = GetEntProp(player, Prop_Data, "m_iHealth");
	serverWeaponsPrimary[player-1] = getWeaponOne(player);
	serverWeaponsSecondary[player-1] = getWeaponTwo(player);
}

public void Event_PlayerSpawned(Event event, const char[] name, bool dontBroadcast) {
	EquipPlayerWeapon(player, serverWeaponsPrimary[player-1]);
	EquipPlayerWeapon(player, serverWeaponsPrimary[player-1]);
}


int getWeaponOne(int client) {
	return GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
}
int getWeaponTwo(int client) {
	return GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
}
