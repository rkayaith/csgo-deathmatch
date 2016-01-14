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
	char weaponOneName[32];
	char weaponTwoName[32];

	GetEntityClassname(getWeaponOne(client), weaponOneName, sizeof(weaponOneName));
	GetEntityClassname(getWeaponTwo(client), weaponTwoName, sizeof(weaponTwoName));

	if (clientHealth > 0){
		g_WeaponNames[client][0] = weaponOneName;
		g_WeaponNames[client][1] = weaponTwoName;
	}
}


public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (StrContains (g_WeaponNames[client][0], "weapon_") > -1) {
		RemovePlayerItem(client, getWeaponOne(client));
		GivePlayerItem(client, g_WeaponNames[client][0]);
	}

	if (StrContains (g_WeaponNames[client][1], "weapon_") > -1) {
		RemovePlayerItem(client, getWeaponTwo(client));
		GivePlayerItem(client, g_WeaponNames[client][1]);
	}
}

int getWeaponOne(int client) {
	return GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
}
int getWeaponTwo(int client) {
	return GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
}
