#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

public Plugin myinfo =
{
	name = "Rahoo's Idea",
	author = "kyle",
	description = "Shows killer's health upon player death",
	version = "0.9.2",
	url = ""
};

public void OnPluginStart() {
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
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
