#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1

public Plugin myinfo = {
	name = "Keep Weapon",
	author = "Kyle",
	description = "Spawn with the same weapons you had before death",
	version = "1.0",
	url = ""
};


public void OnPluginStart () {
	HookEvent("playerhurt", Event_PlayerHurt);
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast) {
	int player = GetClientOfUserId(event.GetInt("userid"));
	int playerHealth = GetEntProp(player, Prop_Data, "m_iHealth");
	int primaryAlive = getWeaponOne(player);
	int secondaryAlive = getWeaponTwo(player);

	if (playerHealth <= 0) {
		DataPack eventData;
		CreateDataTimer(5.0, loadWeapon, eventData);
		eventData.WriteCell(player);
		eventData.WriteCell(primaryAlive);
		eventData.WriteCell(secondaryAlive);
	}
}

public Action loadWeapon(Handle timer, DataPack eventData){
	eventData.Reset();
	int player = eventData.ReadCell();
	int primaryAlive = eventData.ReadCell();
	int secondaryAlive = eventData.ReadCell();

	int primaryDead = getWeaponOne(player);
	int secondaryDead = getWeaponTwo(player);
	if (primaryAlive != primaryDead || secondaryAlive != secondaryDead){
		EquipPlayerWeapon(player, primaryAlive);
		EquipPlayerWeapon(player, secondaryAlive);
		PrintToChat (player, "hello");
	}
}

int getWeaponOne(int client) {
	return GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
}
int getWeaponTwo(int client) {
	return GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
}
