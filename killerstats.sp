#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

public Plugin myinfo =
{
	name = "Rahoo's Idea",
	author = "kyle",
	description = "Shows killer's health upon player death",
	version = "0.9.5",
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
	g_Cvar_Enable.AddChangeHook(ConVarChange_Enable);

	EnableHooks(g_Cvar_Enable.BoolValue);
}

void EnableHooks(bool enable) {
	static bool events_hooked = false;
	PrintToChatAll("enable?");
	if (enable != events_hooked) {
		if (enable) {
			HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
		} else {
			UnhookEvent("player_death", Event_PlayerDeath);
		}
		events_hooked = enable;
	}
}

public void ConVarChange_Enable(ConVar convar, const char[] oldValue, const char[] newValue) {
	EnableHooks(g_Cvar_Enable.BoolValue);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int victim = GetClientOfUserId (event.GetInt("userid"));
	int attacker = GetClientOfUserId (event.GetInt("attacker"));
	int attackerHealth = GetEntProp(attacker, Prop_Data, "m_iHealth");
	char weapon[32];
	event.GetString("weapon", weapon, sizeof(weapon));

	char attackerName[32];
	if (victim != attacker && GetClientName(attacker, attackerName, sizeof(attackerName))) {
		PrintToChat(victim, "Killed by \x07%s \x01[HP: \x06%i\x01] [Weapon: \x06%s\x01]", attackerName, attackerHealth, weapon);
	}
}
