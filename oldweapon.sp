#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

#define TheNumberRahulGaveMe 2
char g_WeaponNames[MAXPLAYERS + 1][2][32];

public Plugin myinfo = {
	name = "Keep Weapon",
	author = "Kyle",
	description = "Spawn with the same weapons you had before death",
	version = "1.0",
	url = ""
};

public void OnPluginStart () {
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	int clientHealth = GetEntProp(client, Prop_Data, "m_iHealth");
	int weaponSlotId;
	if (clientHealth <= 0){
		for(int i = 0; i < TheNumberRahulGaveMe; i++){
			weaponSlotId = GetPlayerWeaponSlot(client,i);
			if (weaponSlotId != -1){
				GetEntityClassname(weaponSlotId, g_WeaponNames[client][i], sizeof(g_WeaponNames[][]));
			}else {
				g_WeaponNames[client][i] = "none";
			}
		}
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	for(int i = 0; i < 2; i++){
		if (StrContains (g_WeaponNames[client][i], "weapon_") > -1) {
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, i));
			GivePlayerItem(client, g_WeaponNames[client][i]);
		}
	}
}
