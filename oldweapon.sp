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

char g_WeaponNames[MAXPLAYERS + 1][2][32];

public void OnPluginStart () {
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	int clientHealth = GetEntProp(client, Prop_Data, "m_iHealth");

	if (clientHealth <= 0){
		for(int i = 0; i < 2; i++){
			if (GetPlayerWeaponSlot(client,i) != -1){
				GetEntityClassname(GetPlayerWeaponSlot(client, i), g_WeaponNames[client][i], sizeof(g_WeaponNames[][]));
			}
		}
	}
}


public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (StrContains (g_WeaponNames[client][0], "weapon_") > -1) {
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 0));
		GivePlayerItem(client, g_WeaponNames[client][0]);
	}

	if (StrContains (g_WeaponNames[client][1], "weapon_") > -1) {
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
		GivePlayerItem(client, g_WeaponNames[client][1]);
	}
}
