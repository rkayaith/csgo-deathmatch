#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

#define NUM_TEAMS 4
#define NUM_SLOTS 4
#define MAX_WPN_LENGTH 32

public Plugin myinfo = {
	name = "Deathmatch: Buys",
	author = "trog_",
	description = "Limits for weapon buying",
	version = "0.0.1",
	url = ""
};

EngineVersion g_Game;
ConVar g_Cvar_Enable;

ConVar g_Cvar_DefaultWeapons[NUM_TEAMS][NUM_SLOTS];
ConVar g_Cvar_LoadoutLimit;
ConVar g_Cvar_BuyLimit;

int g_BuyCount[MAXPLAYERS + 1];


public void OnPluginStart() {

	g_Game = GetEngineVersion();
	if (g_Game != Engine_CSGO) {
		SetFailState("This plugin is for CS:GO only. It may need tweaking for other games");
	}

	g_Cvar_Enable 		= CreateConVar("dm_enable", "1", "Enable the dm_ SourceMod plugins", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_LoadoutLimit = CreateConVar("dm_buyloadout_limit", "1", "Number of bought weapons a player can have in their loadout", FCVAR_NOTIFY);
	g_Cvar_BuyLimit 	= CreateConVar("dm_buycount_limit", "1", "Number of times a player can buy per life", FCVAR_NOTIFY);

	g_Cvar_Enable.AddChangeHook(ConVarChange_Enable);

	FindDefaultWeaponCvars();
	EnableHooks(g_Cvar_Enable.BoolValue);
}

void EnableHooks(bool enable) {
	static bool events_hooked = false;
	if (enable != events_hooked) {
		if (enable) {
			HookEvent("player_death", Event_PlayerDeath);
		} else {
			UnhookEvent("player_death", Event_PlayerDeath);
		}
		events_hooked = enable;
	}
}

public void ConVarChange_Enable(ConVar convar, const char[] oldValue, const char[] newValue) {
	EnableHooks(g_Cvar_Enable.BoolValue);
}

public bool OnClientConnect(int client) {
	g_BuyCount[client] = 0;
	return true;
}

public Action CS_OnBuyCommand(client, const char[] weapon) {
	// Do nothing if plugin is disabled
	if (!g_Cvar_Enable.BoolValue) {
		return Plugin_Continue;
	}

	// Block the buy if player has bought too many times this life
	if (g_BuyCount[client] >= g_Cvar_BuyLimit.IntValue && g_Cvar_BuyLimit.IntValue > -1) {
		PrintBuyLimitMsg(client);
		return Plugin_Handled;
	}

	// Remove a bought weapon if the player already bought too many
	if (GetBoughtWeaponCount(client) >= g_Cvar_LoadoutLimit.IntValue) {
		int wpn = GetBoughtWeapon(client);
		PrintLoadoutLimitMsg(client, wpn);
		ReplaceWithDefaultWeapon(client, wpn);
	}

	g_BuyCount[client]++;
	return Plugin_Continue;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	g_BuyCount[GetClientOfUserId(event.GetInt("userid"))] = 0;
}

int GetBoughtWeaponCount(int client) {
	int count = 0;
	for (int i = 0; i < NUM_SLOTS; i++) {
		int wpn = GetPlayerWeaponSlot(client, i);
		if (wpn > -1 && !IsDefaultWeapon(client, wpn)) {
			count ++;
		}
	}
	return count;
}

int GetBoughtWeapon(int client) {
	for (int i = NUM_SLOTS - 1; i >=0 ; i--) {
		int wpn = GetPlayerWeaponSlot(client, i);
		if (wpn > -1 && !IsDefaultWeapon(client, wpn)) {
			return wpn;
		}
	}
	return -1;
}

void ReplaceWithDefaultWeapon(int client, int weapon) {
	int team = GetClientTeam(client);

	for (int i = 0; i < NUM_SLOTS; i++) {
		if (GetPlayerWeaponSlot(client, i) == weapon) {
			char defaultWeapon[MAX_WPN_LENGTH];
			g_Cvar_DefaultWeapons[team][i].GetString(defaultWeapon, sizeof(defaultWeapon));

			RemovePlayerItem(client, weapon);
			GivePlayerItem(client, defaultWeapon);
			return;
		}
	}

	RemovePlayerItem(client, weapon);
}

bool IsDefaultWeapon(int client, int weapon) {
	int team = GetClientTeam(client);
	char classname[MAX_WPN_LENGTH];
	GetEntityClassname(weapon, classname, sizeof(classname));

	for (int i = 0; i < NUM_SLOTS; i++) {
		char defaultWeapon[MAX_WPN_LENGTH];

		g_Cvar_DefaultWeapons[team][i].GetString(defaultWeapon, sizeof(defaultWeapon));
		if (StrEqual(classname, defaultWeapon)) {
			return true;
		}
	}

	return false;
}

void PrintBuyLimitMsg(int client) {
	PrintHintText(client, "You can only buy %i time(s) per life", g_Cvar_BuyLimit.IntValue);
}

void PrintLoadoutLimitMsg(int client, int weapon) {
	char classname[MAX_WPN_LENGTH];
	GetEntityClassname(weapon, classname, sizeof(classname));
	PrintHintText(client, "You can only have %i non-default weapon(s). Removed <font color=\"#ff0000\">%s</font>", g_Cvar_LoadoutLimit.IntValue, classname);
}

void FindDefaultWeaponCvars() {
	for (int i = 0; i < NUM_TEAMS; i++) {
		char team[2];
		switch(i) {
			case CS_TEAM_T: 	team = "t";
			case CS_TEAM_CT: 	team = "ct";
		}

		for (int j = 0; j < NUM_SLOTS; j++) {
			char slot[10];
			switch(j) {
				case CS_SLOT_PRIMARY: 	slot = "primary";
				case CS_SLOT_SECONDARY: slot = "secondary";
				case CS_SLOT_KNIFE: 	slot = "melee";
				case CS_SLOT_GRENADE:	slot = "grenades";
			}

			if (strlen(team) > 0 && strlen(slot) > 0) {
				char command[64];
				Format(command, sizeof(command), "mp_%s_default_%s", team, slot);
				g_Cvar_DefaultWeapons[i][j] = FindConVar(command);
			}
		}
	}
}
