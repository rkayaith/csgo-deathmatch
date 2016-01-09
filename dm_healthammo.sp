#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

public Plugin myinfo = {
	name = "Deathmatch: Health/Ammo",
	author = "trog_",
	description = "Give health / ammo on kill as a factor of max values",
	version = "1.1.1",
	url = ""
};

EngineVersion g_Game;
ConVar g_Cvar_Enable;

ConVar g_Cvar_HealthFactor;
ConVar g_Cvar_HealthFactorHeadshot;
ConVar g_Cvar_AmmoFactor;
ConVar g_Cvar_AmmoFactorHeadshot;

StringMap g_MaxClipTable;

public void OnPluginStart() {

	g_Game = GetEngineVersion();
	if (g_Game != Engine_CSGO) {
		SetFailState("This plugin is for CS:GO only. It may need tweaking for other games");
	}

	g_Cvar_Enable 					= CreateConVar("dm_enable", "1", "Enable the dm_ SourceMod plugins", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_HealthFactor 			= CreateConVar("dm_health_kill", "0.5", "Health to give on kill (as a factor of max health)", FCVAR_NOTIFY, true, 0.0);
	g_Cvar_HealthFactorHeadshot		= CreateConVar("dm_health_kill_headshot", "1", "Health to give on headshot kill (as a factor of max health)", FCVAR_NOTIFY, true, 0.0);
	g_Cvar_AmmoFactor 				= CreateConVar("dm_ammo_kill", "0.5", "Ammo to give on kill (as a factor of max clip size)", FCVAR_NOTIFY, true, 0.0);
	g_Cvar_AmmoFactorHeadshot 		= CreateConVar("dm_ammo_kill_headshot", "1", "Ammo to give on headshot kill (as a factor of max clip size)", FCVAR_NOTIFY, true, 0.0);

	g_MaxClipTable = new StringMap();

	g_Cvar_Enable.AddChangeHook(ConVarChange_Enable);

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

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	bool isHeadshot = event.GetBool("headshot");
	// Give health immediately
	int healthGiven = GivePlayerHealth(attacker, isHeadshot ? g_Cvar_HealthFactorHeadshot.FloatValue : g_Cvar_HealthFactor.FloatValue);

	// Pack up event data and handle the rest after a small delay
	DataPack eventData;
	CreateDataTimer(0.1, OnPlayerDeathDelayed, eventData);
	eventData.WriteCell(attacker);
	eventData.WriteCell(isHeadshot);
	eventData.WriteCell(healthGiven);
}

public Action OnPlayerDeathDelayed(Handle timer, DataPack eventData) {

	eventData.Reset();
	int attacker = eventData.ReadCell();
	bool isHeadshot = eventData.ReadCell();
	int healthGiven = eventData.ReadCell();

	// We want to delay giving ammo so that clip values have a chance to update after the kill
	int pAmmoGiven = GiveWeaponAmmo(attacker,
									GetPlayerWeaponSlot(attacker, CS_SLOT_PRIMARY),
									isHeadshot ? g_Cvar_AmmoFactorHeadshot.FloatValue : g_Cvar_AmmoFactor.FloatValue);

	int sAmmoGiven = GiveWeaponAmmo(attacker,
									GetPlayerWeaponSlot(attacker, CS_SLOT_SECONDARY),
									isHeadshot ? g_Cvar_AmmoFactorHeadshot.FloatValue : g_Cvar_AmmoFactor.FloatValue);

	PrintToChat(attacker, "[\x06+%3i \x01HP]  [\x06+%2i\x01 / \x06+%2i\x01 ammo] for kill %s", healthGiven, pAmmoGiven, sAmmoGiven, isHeadshot ? "(headshot)" : "");
}

/**
 * Gives a player health as a factor of their max health. Won't exceed max health.
 *
 * @param client 		Client index.
 * @param factor 		Factor of max health to give.
 * @return 				How much health was given (including excess).
 */
int GivePlayerHealth(int client, float factor) {
	int clientHealth = GetEntHealth(client);
	int clientMaxHealth = GetClientMaxHealth(client);
	int healthToGive = RoundToFloor(clientMaxHealth * factor);

	clientHealth = (clientHealth += healthToGive) < clientMaxHealth ? clientHealth : clientMaxHealth;
	SetEntHealth(client, clientHealth);

	return healthToGive;
}

/**
 * Finds the max health of a player and caches result.
 * Assumes all players have the same max health.
 *
 * @param client 		Client index.
 * @return 				Client max health.
 */
int GetClientMaxHealth(int client) {
	static int max_health = -1;
	if (max_health == -1) {
		max_health = GetEntMaxHealth(client);
	}

	return max_health;
}

/**
 * Gives a player's weapon ammo as a factor of the weapon's max clip size.
 * Won't exceed weapon's max clip size.
 *
 * @param client 		Client index.
 * @param factor 		Factor of max clip size to give.
 * @return 				How much ammo was given (including excess).
 */
int GiveWeaponAmmo(int client, int weapon, float factor) {

	if (weapon == -1) {
		return 0;
	}

	int weaponClip = GetWeaponClip(weapon);
	int weaponMaxClip = GetWeaponMaxClip(client, weapon);
	int ammoToGive = RoundToFloor(weaponMaxClip * factor);

	weaponClip = (weaponClip += ammoToGive) < weaponMaxClip ? weaponClip : weaponMaxClip;
	SetWeaponClip(weapon, weaponClip);

	return ammoToGive;
}

/**
 * Finds the max clip size of a weapon.
 * Caches result for weapons of the same classname.
 * The weapon entity and ammo counts may be changed.
 *
 * @param client 		Client index.
 * @param weapon 		Weapon entity.
 * @return 				Weapon max clip size.
 */
int GetWeaponMaxClip(int client, int &weapon) {

	char weaponClassname[64];
	GetEntityClassname(weapon, weaponClassname, sizeof(weaponClassname));

	int maxClip;
	if (!g_MaxClipTable.GetValue(weaponClassname, maxClip)) {
		// We didn't have a value cached
		// We'll find it by giving the player a new weapon entity and checking its clip size

		// Save active weapon to switch back to later
		int activeWeapon = GetClientActiveWeapon(client);
		if (activeWeapon == weapon) { activeWeapon = -1; }

		RemovePlayerItem(client, weapon);
		weapon = GivePlayerItem(client, weaponClassname);

		// Switch back to active weapon (plays weapon switch animation. meh...)
		SetClientActiveWeapon(client, activeWeapon > -1 ? activeWeapon : weapon);

		maxClip = GetWeaponClip(weapon);
		g_MaxClipTable.SetValue(weaponClassname, maxClip);

		PrintToChatAll("[SM] Cached default clip value for: %s (%i)", weaponClassname, maxClip);
	}

	return maxClip;
}


/**
 * Getters and setters for some entity properties.
 */

// Entity health
int GetEntMaxHealth(int client) {
	return GetEntProp(client, Prop_Data, "m_iMaxHealth");
}
int GetEntHealth(int entity) {
	return GetEntProp(entity, Prop_Data, "m_iHealth");
}
void SetEntHealth(int entity, int health) {
	SetEntProp(entity, Prop_Data, "m_iHealth", health);
}

// Weapon clip
int GetWeaponClip(int weapon) {
	return GetEntProp(weapon, Prop_Send, "m_iClip1");
}
void SetWeaponClip(int weapon, int value) {
	SetEntProp(weapon, Prop_Send, "m_iClip1", value);
}

// Client active weapon
int GetClientActiveWeapon(int client) {
	return GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
}
void SetClientActiveWeapon(int client, int weapon) {
	SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", weapon);
}
