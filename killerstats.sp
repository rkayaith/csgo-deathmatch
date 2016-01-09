#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

public Plugin myinfo =
{
	name = "Rahoo's Idea",
	author = "kyle",
	description = "Shows killer's health upon player death",
	version = "1.0",
	url = ""
};

public void OnPluginStart() {
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);

}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int DeadGuy = GetClientOfUserId (event.GetInt("userid"));
	int Killer = GetClientOfUserId (event.GetInt("attacker"));
	int KillerHealth = GetEntProp(Killer, Prop_Data, "m_iHealth");
	char weapon[32];
	event.GetString("weapon", weapon, sizeof(weapon));

	decl String:KillerName[32];
	if (DeadGuy == Killer) {
		PrintToChat (DeadGuy, "\x06The God of CsGo, Rahul, has taken your life");
	}
	else if (GetClientName(Killer, KillerName, sizeof(KillerName))) {
		PrintToChat(DeadGuy, "%s Health: \x06%d", KillerName, KillerHealth);
		PrintToChat(DeadGuy, "Weapon: \x06%s", weapon);
	}
}
