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

int g_SpawnPrimaryWeapons[MAXPLAYERS + 1];
int g_SpawnSecondaryWeapons[MAXPLAYERS + 1];
int g_PrimaryWeapons[MAXPLAYERS + 1];
int g_SecondaryWeapons[MAXPLAYERS + 1];
char g_PrimaryWeaponName[32];
char g_SecondaryWeaponName[32];

public void OnPluginStart () {
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	int clientHealth = GetEntProp(client, Prop_Data, "m_iHealth");
	if (clientHealth > 0){
	g_PrimaryWeapons[client] = GetWeaponOne(client);
	g_SecondaryWeapons[client] = GetWeaponTwo(client);
	GetEntityClassname(g_PrimaryWeapons[client], g_PrimaryWeaponName, sizeof(g_PrimaryWeaponName));
	GetEntityClassname(g_SecondaryWeapons[client], g_SecondaryWeaponName, sizeof(g_SecondaryWeaponName));
	}
	PrintToChatAll("client: %i health:%i wep1:%i wep2:%i", client, clientHealth, GetWeaponOne(client), GetWeaponTwo(client));
}


public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_SpawnPrimaryWeapons[client] = GetWeaponOne(client);
	g_SpawnSecondaryWeapons[client] = GetWeaponOne(client);

	if (IsValidEntity(g_PrimaryWeapons[client])) {
		RemovePlayerItem(client, g_SpawnPrimaryWeapons[client]);
		GivePlayerItem(client, g_PrimaryWeaponName);
	} else {
		PrintToChatAll("weapon not valid");
	}
	if (IsValidEntity(g_SecondaryWeapons[client])) {
		RemovePlayerItem(client, g_SpawnSecondaryWeapons[client]);
		GivePlayerItem(client, g_SecondaryWeaponName);
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
