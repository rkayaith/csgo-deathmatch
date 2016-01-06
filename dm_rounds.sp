#include <sourcemod>
#include <sdktools>
#include <cstrike>

EngineVersion g_Game;
ConVar g_Enabled;

ConVar g_scorelimit;
ConVar g_teammatesAreEnemies;
ConVar g_winPanelDisplayTime;

int g_teamScores[4]; // CS has 4 teams

public Plugin myinfo = {
	name = "Deathmatch: control stuff about rounds",
	author = "trog_",
	description = "sets round score n shit",
	version = "0.9.0",
	url = ""
};

public void OnPluginStart() {

	g_Game = GetEngineVersion();
	if (g_Game != Engine_CSGO) {
		SetFailState("This plugin is for CS:GO only. It may need tweaking for other games");
	}

	g_scorelimit = CreateConVar("dm_rounds_scorelimit", "0", "Score a team has to get to win", FCVAR_NOTIFY);
	g_teammatesAreEnemies = FindConVar("mp_teammates_are_enemies");
	g_winPanelDisplayTime = FindConVar("mp_win_panel_display_time");

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
	HookEvent("round_start", OnRoundStart);
}
void UnhookEvents() {
	UnhookEvent("player_death", OnPlayerDeath);
	UnhookEvent("round_start", OnRoundStart);
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	// Increment team score if attacker was on a playing team (not spectator or something)
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int team = GetClientTeam(attacker);
	if ( (team == CS_TEAM_T || team == CS_TEAM_CT) && ClientsAreEnemies(attacker, victim)) {
		g_teamScores[team]++;
	}

	UpdateTeamScores();
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	// Reset all team scores to 0
	for (int i = 0; i < sizeof(g_teamScores); i++) {
		g_teamScores[i] = 0;
	}
	UpdateTeamScores();
}

bool ClientsAreEnemies(int client1, int client2) {
	if (client1 == client2) {
		return false;
	}

	if (g_teammatesAreEnemies.IntValue > 0) {
		return true;
	}

	return GetClientTeam(client1) != GetClientTeam(client2);
}

void UpdateTeamScores() {
	// Have to do both to display the score properly
	CS_SetTeamScore(CS_TEAM_T, g_teamScores[CS_TEAM_T])
	SetTeamScore(CS_TEAM_T, g_teamScores[CS_TEAM_T]);

	CS_SetTeamScore(CS_TEAM_CT, g_teamScores[CS_TEAM_CT])
	SetTeamScore(CS_TEAM_CT, g_teamScores[CS_TEAM_CT]);

	for (int i = 0; i < sizeof(g_teamScores); i++) {
		if (g_teamScores[i] >= g_scorelimit.IntValue && g_scorelimit.IntValue > 0) {
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

	CS_TerminateRound(g_winPanelDisplayTime.FloatValue, reason);
}
