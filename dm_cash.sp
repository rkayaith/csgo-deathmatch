#include <sourcemod>
#include <sdktools>
#include <cstrike>

EngineVersion g_Game;
ConVar g_Cvar_Enabled;

ConVar g_Cvar_CashAwardsEnabled;
ConVar g_Cvar_TeammatesAreEnemies;
ConVar g_Cvar_Maxmoney;

ConVar g_Cvar_CashKillEnemy;
ConVar g_Cvar_CashKillEnemyFactor;
ConVar g_Cvar_CashKillTeammate;
ConVar g_Cvar_CashGetKilled;
ConVar g_Cvar_CashRespawn;


public Plugin myinfo = {
	name = "Deathmatch: Cash",
	author = "trog_",
	description = "Implements some of the cash_player_* commands without all the printing to chat",
	version = "1.1",
	url = ""
};

public void OnPluginStart() {

	g_Game = GetEngineVersion();
	if (g_Game != Engine_CSGO) {
		SetFailState("This plugin is for CS:GO only. It may need tweaking for other games");
	}

	g_Cvar_Enabled 				= CreateConVar("dm_enabled", "1", "Enable the dm_ SourceMod plugins", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_CashAwardsEnabled	= FindConVar("mp_playercashawards");
	g_Cvar_TeammatesAreEnemies 	= FindConVar("mp_teammates_are_enemies");
	g_Cvar_Maxmoney 			= FindConVar("mp_maxmoney");

	g_Cvar_CashKillEnemy 		= FindConVar("cash_player_killed_enemy_default");
	g_Cvar_CashKillEnemyFactor 	= FindConVar("cash_player_killed_enemy_factor");
	g_Cvar_CashKillTeammate 	= FindConVar("cash_player_killed_teammate");
	g_Cvar_CashGetKilled 		= FindConVar("cash_player_get_killed");
	g_Cvar_CashRespawn 			= FindConVar("cash_player_respawn_amount");

	g_Cvar_Enabled.AddChangeHook(ConVarChange_Enabled);
	g_Cvar_CashAwardsEnabled.AddChangeHook(ConVarChange_CashAwards);

	// Set mp_playercashawards to 0 so the game isn't also trying to give money for the same actions
	if (g_Cvar_CashAwardsEnabled.IntValue != 0) {
		g_Cvar_CashAwardsEnabled.SetInt(0);

		PrintToChatAll("[SM] mp_playercashawards forced to 0 by dm_cash plugin.");
	}

	if (g_Cvar_Enabled.BoolValue) {
		HookEvents();
	}
}

void HookEvents() {
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
}
void UnhookEvents() {
	UnhookEvent("player_death", Event_PlayerDeath);
	UnhookEvent("player_spawn", Event_PlayerSpawn);
}

public void ConVarChange_Enabled(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (StringToInt(newValue) != StringToInt(oldValue)) {
		if (g_Cvar_Enabled.BoolValue) {
			HookEvents();
		}
		else {
			UnhookEvents();
		}
	}
}

public void ConVarChange_CashAwards(ConVar convar, const char[] oldValue, const char[] newValue) {
	// Notify if mp_playercashawards is changed
	if (StringToInt(newValue) != 0) {
		PrintToChatAll("[SM] mp_playercashawards should be 0 for the dm_cash plugin to work properly.");
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));

	GiveClientCash(victim, g_Cvar_CashGetKilled.IntValue);

	// All guns will give the same amount of money
	if (ClientsAreEnemies(attacker, victim)) {
		GiveClientCash(attacker, RoundToFloor(g_Cvar_CashKillEnemy.IntValue * g_Cvar_CashKillEnemyFactor.FloatValue));
	} else if (attacker != victim) {
		GiveClientCash(attacker, g_Cvar_CashKillTeammate.IntValue)
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	GiveClientCash(GetClientOfUserId(event.GetInt("userid")), g_Cvar_CashRespawn.IntValue)
}

/**
 * Gives a player money without going over the mp_maxmoney limit.
 * @param client 	Client index.
 * @param amount 	Amount of money to give.
 */
void GiveClientCash(int client, int amount) {
	int cash = GetClientCash(client);
	cash = (cash += amount) < g_Cvar_Maxmoney.IntValue ? cash : g_Cvar_Maxmoney.IntValue;
	cash = cash > 0 ? cash : 0;

	SetClientCash(client, cash);
}

/**
 * Checks whether two clients are enemies.
 * Takes into account the value of mp_teammates_are_enemies.
 *
 * @param client1 	First client index.
 * @param client2 	Second client index.
 * @return 			Whether the clients are enemies.
 */
bool ClientsAreEnemies(int client1, int client2) {
	if (client1 == client2) {
		return false;
	}

	if (g_Cvar_TeammatesAreEnemies.IntValue > 0) {
		return true;
	}

	return GetClientTeam(client1) != GetClientTeam(client2);
}

/**
 * Getter and setter for entity cash properties
 */
int GetClientCash(int client) {
	return GetEntProp(client, Prop_Send, "m_iAccount");
}
void SetClientCash(int client, int amount) {
	SetEntProp(client, Prop_Send, "m_iAccount", amount);
}
