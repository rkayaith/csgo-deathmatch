#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

public Plugin myinfo = {
	name = "Keep Weapon",
	author = "Kyle",
	description = "Spawn with the same weapons you had before death",
	version = "0.0.1",
	url = ""
};

int g_PrimaryWeapons[MAXPLAYERS + 1];
int g_SecondaryWeapons[MAXPLAYERS + 1];

public void OnPluginStart () {
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_spawned", Event_PlayerSpawned);
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	int clientHealth = GetEntProp(client, Prop_Data, "m_iHealth");
	g_PrimaryWeapons[client] = GetWeaponOne(client);
	g_SecondaryWeapons[client] = GetWeaponTwo(client);
	PrintToChatAll("client: %i health:%i wep1:%i wep2:%i", client, clientHealth, GetWeaponOne(client), GetWeaponTwo(client));
}

public void Event_PlayerSpawned(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidEntity(g_PrimaryWeapons[client])) {
		EquipPlayerWeapon(client, g_PrimaryWeapons[client]);
	} else {
		PrintToChatAll("weapon not valid");
	}
	if (IsValidEntity(g_SecondaryWeapons[client])) {
		EquipPlayerWeapon(client, g_SecondaryWeapons[client]);
	} else {
		PrintToChatAll("weapon not valid");
	}
}


int GetWeaponOne(int client) {
	return GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
}
int GetWeaponTwo(int client) {
	return GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
}
