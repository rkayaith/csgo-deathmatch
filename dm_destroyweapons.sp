#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

public Plugin myinfo = {
	name = "Deathmatch: Destroy Weapons",
	author = "trog_",
	description = "Destroys dropped weapons after a set time",
	version = "0.0.1",
	url = ""
};

EngineVersion g_Game;
ConVar g_Cvar_Enable;

public void OnPluginStart() {

	g_Game = GetEngineVersion();
	if (g_Game != Engine_CSGO) {
		SetFailState("This plugin is for CS:GO only. It may need tweaking for other games");
	}

	g_Cvar_Enable = CreateConVar("dm_enable", "1", "Enable the dm_ SourceMod plugins", FCVAR_NOTIFY, true, 0.0, true, 1.0);
}

public Action CS_OnCSWeaponDrop(int client, int weaponIndex) {
	if (g_Cvar_Enable.BoolValue) {
		CreateTimer(2.0, Timer_DestroyWeapon, weaponIndex);
	}
	return Plugin_Continue;
}

public Action Timer_DestroyWeapon(Handle timer, int weapon) {
	AcceptEntityInput(weapon, "Kill");
}
