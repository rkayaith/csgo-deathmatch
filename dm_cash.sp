#include <sourcemod>
#include <sdktools>
#include <cstrike>

EngineVersion g_Game;
ConVar g_Enabled;

ConVar g_cashAwardsEnabled;
ConVar g_teammatesAreEnemies;
ConVar g_cashLimit;

ConVar g_cashKillEnemy;
ConVar g_cashKillEnemyFactor;
ConVar g_cashKillTeammate;
ConVar g_cashGetKilled;
ConVar g_cashRespawn;


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

	g_cashAwardsEnabled		= FindConVar("mp_playercashawards");
	g_teammatesAreEnemies 	= FindConVar("mp_teammates_are_enemies");
	g_cashLimit 			= FindConVar("mp_maxmoney");

	g_cashKillEnemy 		= FindConVar("cash_player_killed_enemy_default");
	g_cashKillEnemyFactor 	= FindConVar("cash_player_killed_enemy_factor");
	g_cashKillTeammate 		= FindConVar("cash_player_killed_teammate");
	g_cashGetKilled 		= FindConVar("cash_player_get_killed");
	g_cashRespawn 			= FindConVar("cash_player_respawn_amount");

	// Set mp_playercashawards to 0 so the game isn't also trying to give money for the same actions
	if (g_cashAwardsEnabled.IntValue != 0) {
		g_cashAwardsEnabled.SetInt(0);

		PrintToChatAll("[SM] mp_playercashawards forced to 0 by dm_cash plugin.");
	}
	g_cashAwardsEnabled.AddChangeHook(OnCashEnabledChange);

	g_Enabled = CreateConVar("dm_enabled", "1", "Enable the dm_ SourceMod plugins", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Enabled.AddChangeHook(OnEnabledChanged);
	if (g_Enabled.BoolValue) {
		HookEvents();
	}
}

public void OnEnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (StringToInt(newValue) != StringToInt(oldValue)) {
		if (g_Enabled.BoolValue) {
			HookEvents();
		}
		else {
			UnhookEvents();
		}
	}
}

void HookEvents() {
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_spawn", OnPlayerSpawn);
}
void UnhookEvents() {
	UnhookEvent("player_death", OnPlayerDeath);
	UnhookEvent("player_spawn", OnPlayerSpawn);
}

public void OnCashEnabledChange(ConVar convar, const char[] oldValue, const char[] newValue) {
	// Notify if mp_playercashawards is changed
	if (StringToInt(newValue) != 0) {
		PrintToChatAll("[SM] mp_playercashawards should be 0 for the dm_cash plugin to work properly.");
	}
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));

	GiveClientCash(victim, g_cashGetKilled.IntValue);

	// All guns will give the same amount of money
	if (ClientsAreEnemies(attacker, victim)) {
		GiveClientCash(attacker, RoundToFloor(g_cashKillEnemy.IntValue * g_cashKillEnemyFactor.FloatValue));
	} else if (attacker != victim) {
		GiveClientCash(attacker, g_cashKillTeammate.IntValue)
	}
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	GiveClientCash(GetClientOfUserId(event.GetInt("userid")), g_cashRespawn.IntValue)
}

/**
 * Gives a player money without going over the mp_maxmoney limit.
 * @param client 	Client index.
 * @param amount 	Amount of money to give.
 */
void GiveClientCash(int client, int amount) {
	int cash = GetClientCash(client);
	cash = (cash += amount) < g_cashLimit.IntValue ? cash : g_cashLimit.IntValue;
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

	if (g_teammatesAreEnemies.IntValue > 0) {
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
