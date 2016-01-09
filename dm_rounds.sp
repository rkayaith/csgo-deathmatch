#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

public Plugin myinfo = {
	name = "Deathmatch: Rounds",
	author = "trog_",
	description = "Tracks kills per team using round scores",
	version = "1.0.1",
	url = ""
};

EngineVersion g_Game;
ConVar g_Cvar_Enabled;

ConVar g_Cvar_Fraglimit;
ConVar g_Cvar_Maxrounds;
ConVar g_Cvar_TeammatesAreEnemies;
ConVar g_Cvar_WinPanelDisplayTime;

int g_TeamScores[4]; // CS has 4 teams

public void OnPluginStart() {

	g_Game = GetEngineVersion();
	if (g_Game != Engine_CSGO) {
		SetFailState("This plugin is for CS:GO only. It may need tweaking for other games");
	}

	g_Cvar_Enabled 				= CreateConVar("dm_enabled", "1", "Enable the dm_ SourceMod plugins", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_Fraglimit 			= CreateConVar("dm_rounds_fraglimit", "0", "Score a team has to get to win", FCVAR_NOTIFY);
	g_Cvar_Maxrounds 			= FindConVar("mp_maxrounds");
	g_Cvar_TeammatesAreEnemies 	= FindConVar("mp_teammates_are_enemies");
	g_Cvar_WinPanelDisplayTime 	= FindConVar("mp_win_panel_display_time");

	g_Cvar_Enabled.AddChangeHook(ConVarChange_Enabled);
	g_Cvar_Fraglimit.AddChangeHook(ConVarChange_Fraglimit);

	EnableHooks(g_Cvar_Enabled.BoolValue);
}

void EnableHooks(bool enable) {
	static bool events_hooked = false;
	if (enable != events_hooked) {
		if (enable) {
			HookEvent("player_death", Event_PlayerDeath);
			HookEvent("round_start", Event_RoundStart);
		} else {
			UnhookEvent("player_death", Event_PlayerDeath);
			UnhookEvent("round_start`", Event_RoundStart);
		}
		events_hooked = enable;
	}
}

public void ConVarChange_Enabled(ConVar convar, const char[] oldValue, const char[] newValue) {
	EnableHooks(g_Cvar_Enabled.BoolValue);
}

public void ConVarChange_Fraglimit(ConVar convar, const char[] oldValue, const char[] newValue) {
	// Make sure mp_maxrounds doesn't end the game early
	if (g_Cvar_Fraglimit.IntValue * 2 < g_Cvar_Maxrounds.IntValue) {
		g_Cvar_Maxrounds.SetInt(g_Cvar_Fraglimit.IntValue * 2);
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	// Increment team score if attacker was on a playing team (not spectator or something)
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int team = GetClientTeam(attacker);
	if ( (team == CS_TEAM_T || team == CS_TEAM_CT) && ClientsAreEnemies(attacker, victim)) {
		g_TeamScores[team]++;
	}

	UpdateTeamScores();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	// Reset all team scores to 0
	for (int i = 0; i < sizeof(g_TeamScores); i++) {
		g_TeamScores[i] = 0;
	}
	UpdateTeamScores();
}

bool ClientsAreEnemies(int client1, int client2) {
	if (client1 == client2) {
		return false;
	}

	if (g_Cvar_TeammatesAreEnemies.IntValue > 0) {
		return true;
	}

	return GetClientTeam(client1) != GetClientTeam(client2);
}

void UpdateTeamScores() {
	// Have to do both to display the score properly
	CS_SetTeamScore(CS_TEAM_T, g_TeamScores[CS_TEAM_T]);
	SetTeamScore(CS_TEAM_T, g_TeamScores[CS_TEAM_T]);

	CS_SetTeamScore(CS_TEAM_CT, g_TeamScores[CS_TEAM_CT]);
	SetTeamScore(CS_TEAM_CT, g_TeamScores[CS_TEAM_CT]);

	for (int i = 0; i < sizeof(g_TeamScores); i++) {
		if (g_TeamScores[i] >= g_Cvar_Fraglimit.IntValue && g_Cvar_Fraglimit.IntValue > 0) {
			SetRoundWinner(i);
			break;
		}
	}
}

/**
 * End the round with an appropriate CSRoundEndReason.
 * @param int team 	The team to set as the winner.
 */
void SetRoundWinner(int team) {
	CSRoundEndReason reason = CSRoundEnd_Draw;
	if (team == CS_TEAM_T) {
		reason = CSRoundEnd_TerroristWin;
	} else if (team == CS_TEAM_CT) {
		reason = CSRoundEnd_CTWin;
	}

	CS_TerminateRound(g_Cvar_WinPanelDisplayTime.FloatValue, reason);
}
