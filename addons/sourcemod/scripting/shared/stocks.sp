#pragma semicolon 1
#pragma newdecls required
//#pragma dynamic    131072
//Allah This plugin has so much we need to do this.

enum ParticleAttachment_t {
	PATTACH_ABSORIGIN = 0,
	PATTACH_ABSORIGIN_FOLLOW,
	PATTACH_CUSTOMORIGIN,
	PATTACH_POINT,
	PATTACH_POINT_FOLLOW,
	PATTACH_WORLDORIGIN,
	PATTACH_ROOTBONE_FOLLOW
};

enum SolidFlags_t
{
	FSOLID_CUSTOMRAYTEST		= 0x0001,	// Ignore solid type + always call into the entity for ray tests
	FSOLID_CUSTOMBOXTEST		= 0x0002,	// Ignore solid type + always call into the entity for swept box tests
	FSOLID_NOT_SOLID			= 0x0004,	// Are we currently not solid?
	FSOLID_TRIGGER				= 0x0008,	// This is something may be collideable but fires touch functions
											// even when it's not collideable (when the FSOLID_NOT_SOLID flag is set)
	FSOLID_NOT_STANDABLE		= 0x0010,	// You can't stand on this
	FSOLID_VOLUME_CONTENTS		= 0x0020,	// Contains volumetric contents (like water)
	FSOLID_FORCE_WORLD_ALIGNED	= 0x0040,	// Forces the collision rep to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
	FSOLID_USE_TRIGGER_BOUNDS	= 0x0080,	// Uses a special trigger bounds separate from the normal OBB
	FSOLID_ROOT_PARENT_ALIGNED	= 0x0100,	// Collisions are defined in root parent's local coordinate space
	FSOLID_TRIGGER_TOUCH_DEBRIS	= 0x0200,	// This trigger will touch debris objects

	FSOLID_MAX_BITS	= 10
};

stock int abs(int x)
{
	return x < 0 ? -x : x;
}

stock float fabs(float value)
{
	return value < 0 ? -value : value;
}

stock int min(int n1, int n2)
{
	return n1 < n2 ? n1 : n2;
}

stock float fmin(float n1, float n2)
{
	return n1 < n2 ? n1 : n2;
}

stock int max(int n1, int n2)
{
	return n1 > n2 ? n1 : n2;
}

stock float fmax(float n1, float n2)
{
	return n1 > n2 ? n1 : n2;
}

stock Function ValToFunc(any val)
{
	return val;
}

stock int GetSpellbook(int client)
{
	int i, entity;
	while(TF2_GetItem(client, entity, i))
	{
		static char buffer[36];
		if(GetEntityClassname(entity, buffer, sizeof(buffer)) && StrEqual(buffer, "tf_weapon_spellbook"))
			return entity;
	}
	return -1;
}

stock int GivePropAttachment(int entity, const char[] model)
{
	int prop = CreateEntityByName("prop_dynamic_override");
	if(IsValidEntity(prop))
	{
		DispatchKeyValue(prop, "model", model);
		SetEntityCollisionGroup(prop, 1);
		DispatchSpawn(prop);
		SetEntProp(prop, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_PARENT_ANIMATES);

		SetVariantString("!activator");
		AcceptEntityInput(prop, "SetParent", entity, prop);

		SetVariantString("head");
		AcceptEntityInput(prop, "SetParentAttachmentMaintainOffset"); 

		SetEntPropFloat(prop, Prop_Send, "m_fadeMinDist", MIN_FADE_DISTANCE);
		SetEntPropFloat(prop, Prop_Send, "m_fadeMaxDist", MAX_FADE_DISTANCE);

	}
	return prop;
}

stock int ParticleEffectAt(float position[3], const char[] effectName, float duration = 0.1)
{
	int particle = CreateEntityByName("info_particle_system");
	if (particle != -1)
	{
		TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "targetname", "rpg_fortress");
		DispatchKeyValue(particle, "effect_name", effectName);
		DispatchSpawn(particle);
		if(effectName[0])
		{
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");
		}
		SetEdictFlags(particle, (GetEdictFlags(particle) & ~FL_EDICT_ALWAYS));	
		if (duration > 0.0)
			CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
	}
	return particle;
}

stock int ParticleEffectAt_Parent(float position[3], char[] effectName, int iParent, const char[] szAttachment = "", float vOffsets[3] = {0.0,0.0,0.0})
{
	int particle = CreateEntityByName("info_particle_system");

	if (particle != -1)
	{
		TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "targetname", "rpg_fortress");
		DispatchKeyValue(particle, "effect_name", effectName);
		if(iParent > MAXTF2PLAYERS) //Exclude base_bosses from this, or any entity, then it has to always be rendered.
		{
			b_IsEntityAlwaysTranmitted[particle] = true;
		}
		DispatchSpawn(particle);

		SetParent(iParent, particle, szAttachment, vOffsets);

		if(effectName[0])
		{
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");
		}
		//CreateTimer(0.1, Activate_particle_late, particle, TIMER_FLAG_NO_MAPCHANGE);
	}

	return particle;
}

stock int ParticleEffectAtWithRotation(float position[3], float rotation[3], char[] effectName, float duration = 0.1)
{
	int particle = CreateEntityByName("info_particle_system");
	if (particle != -1)
	{
		TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
		SetEntPropVector(particle, Prop_Data, "m_angRotation", rotation);
		DispatchKeyValue(particle, "targetname", "rpg_fortress");
		DispatchKeyValue(particle, "effect_name", effectName);
		DispatchSpawn(particle);
		if(effectName[0])
		{
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");
		}
		SetEdictFlags(particle, (GetEdictFlags(particle) & ~FL_EDICT_ALWAYS));	
		if (duration > 0.0)
			CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
	}
	return particle;
}


stock bool FindInfoTarget(const char[] name)
{
	int entity = -1;
	while((entity=FindEntityByClassname(entity, "info_target")) != -1)
	{
		static char buffer[32];
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(StrEqual(buffer, name, false))
			return true;
	}
	return false;
}

stock bool ExcuteRelay(const char[] name, const char[] input="Trigger")
{
	bool found;
	int entity = -1;
	while((entity=FindEntityByClassname(entity, "logic_relay")) != -1)
	{
		static char buffer[32];
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(StrEqual(buffer, name, false))
		{
			AcceptEntityInput(entity, input, entity, entity);
			found = true;
		}
	}
	return found;
}

stock void CreateAttachedAnnotation(int client, int entity, float time, const char[] buffer)
{
	Event event = CreateEvent("show_annotation");
	if(event)
	{
		static float pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		event.SetFloat("worldNormalX", pos[0]);
		event.SetFloat("worldNormalY", pos[1]);
		event.SetFloat("worldNormalZ", pos[2]);
		event.SetInt("follow_entindex", entity);
		event.SetFloat("lifetime", time);
		event.SetInt("visibilityBitfield", (1<<client));
		//event.SetBool("show_effect", effect);
		event.SetString("text", buffer);
		event.SetString("play_sound", "vo/null.mp3");
		event.SetInt("id", 6000+entity); //What to enter inside? Need a way to identify annotations by entindex!
		event.Fire();
	}
}

stock bool StartFuncByPluginName(const char[] pluginname, const char[] funcname)
{
	Handle iter = GetPluginIterator();
	while(MorePlugins(iter))
	{
		Handle plugin = ReadPlugin(iter);
		static char buffer[256];
		GetPluginFilename(plugin, buffer, sizeof(buffer));
		if(StrContains(buffer, pluginname, false) != -1)
		{
			Function func = GetFunctionByName(plugin, funcname);
			if(func != INVALID_FUNCTION)
			{
				Call_StartFunction(plugin, func);
				delete iter;
				return true;
			}
			break;
		}
	}
	delete iter;
	return false;
}

stock int ExplodeStringInt(const char[] text, const char[] split, int[] buffers, int maxInts)
{
	int reloc_idx, idx, total;

	if (maxInts < 1 || !split[0])
	{
		return 0;
	}

	char buffer[16];
	while ((idx = SplitString(text[reloc_idx], split, buffer, sizeof(buffer))) != -1)
	{
		reloc_idx += idx;
		buffers[total] = StringToInt(buffer);
		if (++total == maxInts)
			return total;
	}

	buffers[total++] = StringToInt(text[reloc_idx]);
	return total;
}

stock void MergeStringInt(int[] buffers, int maxInts, const char[] split, char[] buffer, int length)
{
	IntToString(buffers[0], buffer, length);
	for(int i=1; i<maxInts; i++)
	{
		Format(buffer, length, "%s%s%d", buffer, split, buffers[i]);
	}
}

stock int ExplodeStringFloat(const char[] text, const char[] split, float[] buffers, int maxFloats)
{
	int reloc_idx, idx, total;

	if (maxFloats < 1 || !split[0])
	{
		return 0;
	}

	char buffer[16];
	while ((idx = SplitString(text[reloc_idx], split, buffer, sizeof(buffer))) != -1)
	{
		reloc_idx += idx;
		buffers[total] = StringToFloat(buffer);
		if (++total == maxFloats)
			return total;
	}

	buffers[total++] = StringToFloat(text[reloc_idx]);
	return total;
}

stock bool KvJumpToKeySymbol2(KeyValues kv, int id)
{
	if(kv.GotoFirstSubKey())
	{
		do
		{
			if(kv.JumpToKeySymbol(id))
				return true;
		} while(kv.GotoNextKey());
	}
	return false;
}

stock int GetClientPointVisible(int iClient, float flDistance = 100.0, bool ignore_allied_npc = false, bool mask_shot = false, float vecEndOrigin[3] = {0.0, 0.0, 0.0})
{
	float vecOrigin[3], vecAngles[3];
	GetClientEyePosition(iClient, vecOrigin);
	GetClientEyeAngles(iClient, vecAngles);
	
	Handle hTrace;

	//Mask shot here, reasoning being that it should be easiser to interact with buildings and npcs if they are very close to eachother or inside (This wont fully fix it, but i see not other way.)
	//This is client compensated anyways, and reviving is still via hull and not hitboxes.
	int flags = CONTENTS_SOLID;

	if(!mask_shot)
	{
		flags |= MASK_SOLID;
	}
	else
	{
		flags |= MASK_SHOT;
	}

	if(!ignore_allied_npc)
	{
		hTrace = TR_TraceRayFilterEx(vecOrigin, vecAngles, ( flags ), RayType_Infinite, Trace_DontHitEntityOrPlayer, iClient);
		TR_GetEndPosition(vecEndOrigin, hTrace);
	}
	else
	{
		hTrace = TR_TraceRayFilterEx(vecOrigin, vecAngles, ( flags ), RayType_Infinite, Trace_DontHitEntityOrPlayerOrAlliedNpc, iClient);
		TR_GetEndPosition(vecEndOrigin, hTrace);		
	}

	int iReturn = -1;
	int iHit = TR_GetEntityIndex(hTrace);
	
	if (TR_DidHit(hTrace) && iHit != iClient && GetVectorDistance(vecOrigin, vecEndOrigin, true) < (flDistance * flDistance))
		iReturn = iHit;
	
	delete hTrace;
	return iReturn;
}

stock int GetClientPointVisibleRevive(int iClient, float flDistance = 100.0)
{
	float vecOrigin[3], vecAngles[3], vecEndOrigin[3];
	GetClientEyePosition(iClient, vecOrigin);
	GetClientEyeAngles(iClient, vecAngles);
	
	Handle hTrace = TR_TraceRayFilterEx(vecOrigin, vecAngles, ( MASK_SOLID | CONTENTS_SOLID ), RayType_Infinite, Trace_DontHitAlivePlayer, iClient);
	TR_GetEndPosition(vecEndOrigin, hTrace);
	
	int iReturn = -1;
	int iHit = TR_GetEntityIndex(hTrace);
	
	if (TR_DidHit(hTrace) && iHit != iClient && GetVectorDistance(vecOrigin, vecEndOrigin, true) < (flDistance * flDistance))
		iReturn = iHit;
	
	delete hTrace;
	return iReturn;
}

stock int GetClientPointVisibleOnlyClient(int iClient, float flDistance = 100.0)
{
	float vecOrigin[3], vecAngles[3], vecEndOrigin[3];
	GetClientEyePosition(iClient, vecOrigin);
	GetClientEyeAngles(iClient, vecAngles);
	

	Handle hTrace = TR_TraceRayFilterEx(vecOrigin, vecAngles, ( MASK_SOLID | CONTENTS_SOLID ), RayType_Infinite, Trace_OnlyPlayer, iClient);
	TR_GetEndPosition(vecEndOrigin, hTrace);
	
	int iReturn = -1;
	int iHit = TR_GetEntityIndex(hTrace);
	
	if (TR_DidHit(hTrace) && iHit != iClient && GetVectorDistance(vecOrigin, vecEndOrigin, true) < (flDistance * flDistance))
		iReturn = iHit;
	
	delete hTrace;
	return iReturn;
}

stock void ShowGameText(int client, const char[] icon="leaderboard_streak", int color=0, const char[] buffer, any ...)
{
	char message[512];
	VFormat(message, sizeof(message), buffer, 5);

	BfWrite bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", client));
	if(bf)
	{
		bf.WriteString(message);
		bf.WriteString(icon);
		bf.WriteByte(color);
		EndMessage();
	}
}

stock void CreateExplosion(int owner, const float origin[3], float damage, int magnitude, int radius)
{
	int explosion = CreateEntityByName("env_explosion");
	if(IsValidEntity(explosion))
	{
		DispatchKeyValueFloat(explosion, "DamageForce", damage);
		
		SetEntProp(explosion, Prop_Data, "m_iMagnitude", magnitude);
		SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", radius);
		SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", owner);
		
		if(DispatchSpawn(explosion))
		{
			TeleportEntity(explosion, origin, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(explosion, "Explode");
			RemoveEntity(explosion);
		}
	}
}

stock TFClassType TF2_GetWeaponClass(int index, TFClassType defaul=TFClass_Unknown, int checkSlot=-1)
{
	switch(index)
	{
		case 25, 26:
			return TFClass_Engineer;
		
		case 735, 736, 810, 831, 933, 1080, 1102:
			return TFClass_Spy;
	}
	
	if(defaul != TFClass_Unknown)
	{
		int slot = TF2Econ_GetItemLoadoutSlot(index, defaul);
		if(checkSlot != -1)
		{
			if(slot == checkSlot)
				return defaul;
		}
		else if(slot>=0 && slot<6)
		{
			return defaul;
		}
	}

	TFClassType backup;
	for(TFClassType class=TFClass_Engineer; class>TFClass_Unknown; class--)
	{
		if(defaul == class)
			continue;

		int slot = TF2Econ_GetItemLoadoutSlot(index, class);
		if(checkSlot != -1)
		{
			if(slot == checkSlot)
				return class;
			
			if(!backup && slot >= 0 && slot < 6)
				backup = class;
		}
		else if(slot >= 0 && slot < 6)
		{
			return class;
		}
	}

	if(checkSlot != -1 && backup)
		return backup;
	
	return defaul;
}

stock bool TF2_GetItem(int client, int &weapon, int &pos)
{
	//Could be looped through client slots, but would cause issues with >1 weapons in same slot
	int maxWeapons = GetMaxWeapons(client);

	//Loop though all weapons (non-wearables)
	while(pos < maxWeapons)
	{
		weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", pos);
		pos++;

		if(weapon > MaxClients)
			return true;
	}
	return false;
}

stock bool TF2_GetWearable(int client, int &entity)
{
	while((entity=FindEntityByClassname(entity, "tf_wear*")) != -1)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
			return true;
	}
	return false;
}

stock int TF2_GetClassnameSlot(const char[] classname, bool econ=false)
{
	if(StrEqual(classname, "tf_weapon_scattergun") ||
	   StrEqual(classname, "tf_weapon_handgun_scout_primary") ||
	   StrEqual(classname, "tf_weapon_soda_popper") ||
	   StrEqual(classname, "tf_weapon_pep_brawler_blaster") ||
	  !StrContains(classname, "tf_weapon_rocketlauncher") ||
	   StrEqual(classname, "tf_weapon_particle_cannon") ||
	   StrEqual(classname, "tf_weapon_flamethrower") ||
	   StrEqual(classname, "tf_weapon_grenadelauncher") ||
	   StrEqual(classname, "tf_weapon_cannon") ||
	   StrEqual(classname, "tf_weapon_minigun") ||
	   StrEqual(classname, "tf_weapon_shotgun_primary") ||
	   StrEqual(classname, "tf_weapon_sentry_revenge") ||
	   StrEqual(classname, "tf_weapon_drg_pomson") ||
	   StrEqual(classname, "tf_weapon_shotgun_building_rescue") ||
	   StrEqual(classname, "tf_weapon_syringegun_medic") ||
	   StrEqual(classname, "tf_weapon_crossbow") ||
	  !StrContains(classname, "tf_weapon_sniperrifle") ||
	   StrEqual(classname, "tf_weapon_compound_bow"))
	{
		return TFWeaponSlot_Primary;
	}
	else if(!StrContains(classname, "tf_weapon_pistol") ||
	  !StrContains(classname, "tf_weapon_lunchbox") ||
	  !StrContains(classname, "tf_weapon_jar") ||
	   StrEqual(classname, "tf_weapon_handgun_scout_secondary") ||
	   StrEqual(classname, "tf_weapon_cleaver") ||
	  !StrContains(classname, "tf_weapon_shotgun") ||
	   StrEqual(classname, "tf_weapon_buff_item") ||
	   StrEqual(classname, "tf_weapon_raygun") ||
	  !StrContains(classname, "tf_weapon_flaregun") ||
	  !StrContains(classname, "tf_weapon_rocketpack") ||
	  !StrContains(classname, "tf_weapon_pipebomblauncher") ||
	   StrEqual(classname, "tf_weapon_laser_pointer") ||
	   StrEqual(classname, "tf_weapon_mechanical_arm") ||
	   StrEqual(classname, "tf_weapon_medigun") ||
	   StrEqual(classname, "tf_weapon_smg") ||
	   StrEqual(classname, "tf_weapon_charged_smg"))
	{
		return TFWeaponSlot_Secondary;
	}
	else if(!StrContains(classname, "tf_weapon_re"))	// Revolver
	{
		return econ ? TFWeaponSlot_Secondary : TFWeaponSlot_Primary;
	}
	else if(StrEqual(classname, "tf_weapon_sa"))	// Sapper
	{
		return econ ? TFWeaponSlot_Building : TFWeaponSlot_Secondary;
	}
	else if(!StrContains(classname, "tf_weapon_i") || !StrContains(classname, "tf_weapon_pda_engineer_d"))	// Invis & Destory PDA
	{
		return econ ? TFWeaponSlot_Item1 : TFWeaponSlot_Building;
	}
	else if(!StrContains(classname, "tf_weapon_p"))	// Disguise Kit & Build PDA
	{
		return econ ? TFWeaponSlot_PDA : TFWeaponSlot_Grenade;
	}
	else if(!StrContains(classname, "tf_weapon_bu"))	// Builder Box
	{
		return econ ? TFWeaponSlot_Building : TFWeaponSlot_PDA;
	}
	else if(!StrContains(classname, "tf_weapon_sp"))	 // Spellbook
	{
		return TFWeaponSlot_Item1;
	}
	return TFWeaponSlot_Melee;
}

stock int GetAmmo(int client, int type)
{
	int ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, type);
	if(ammo < 0)
		ammo = 0;

	return ammo;
}

stock void SetAmmo(int client, int type, int ammo)
{
	SetEntProp(client, Prop_Data, "m_iAmmo", ammo, _, type);
}

stock int SpawnWeapon(int client, char[] name, int index, int level, int qual, const int[] attrib, const float[] value, int count)
{
	// TODO: THIS IS BAD PERFORMANCE
	// We spawn a weapon, give attributes, remove attributes, give attributes
	int weapon = SpawnWeaponBase(client, name, index, level, qual, attrib, value, count);
	if(IsValidEntity(weapon))
	{
		HandleAttributes(weapon, attrib, value, count, index, client); //Thanks suza! i love my min models
	}
	return weapon;
}

stock int SpawnWeaponBase(int client, char[] name, int index, int level, int qual, const int[] attrib, const float[] value, int count)
{
	Handle weapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION|PRESERVE_ATTRIBUTES);
	if(weapon == INVALID_HANDLE)
		return -1;
	
	TF2Items_SetClassname(weapon, name);
	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, qual);
	TF2Items_SetNumAttributes(weapon, 0);

	TF2_SetPlayerClass(client, TF2_GetWeaponClass(index, CurrentClass[client], TF2_GetClassnameSlot(name, true)), _, false);
	
	int entity = TF2Items_GiveNamedItem(client, weapon);
	delete weapon;
	if(entity > MaxClients)
	{
		Attributes_EntityDestroyed(entity);

		for(int i; i < count; i++)
		{
#if defined RPG
			if(attrib[i] < 0)
			{
				Stats_GetCustomStats(entity, attrib[i], value[i]);
			}
			else
#endif
			{
				Attributes_Set(entity, attrib[i], value[i]);
			}
		}
		
		if(StrEqual(name, "tf_weapon_sapper"))
		{
			SetEntProp(entity, Prop_Send, "m_iObjectType", 3);
			SetEntProp(entity, Prop_Data, "m_iSubType", 3);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 0);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 1);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 2);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", true, _, 3);
		}
		else if(StrEqual(name, "tf_weapon_builder"))
		{
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", true, _, 0);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", true, _, 1);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", true, _, 2);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 3);
		}

		EquipPlayerWeapon(client, entity);
		SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
		SetEntProp(entity, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
	}

	TF2_SetPlayerClass(client, CurrentClass[client], _, false);
	return entity;
}
//										 info.Attribs, info.Value, info.Attribs);
public void HandleAttributes(int weapon, const int[] attributes, const float[] values, int count, int index, int client)
{
	RemoveAllDefaultAttribsExceptStrings(weapon, index, client);
	
	for(int i = 0; i < count; i++) 
	{
		Attributes_Set(weapon, attributes[i], values[i]);
	}
}

void RemoveAllDefaultAttribsExceptStrings(int entity, int index, int client)
{
	Attributes_RemoveAll(entity);
	
	char valueType[2];
	char valueFormat[64];
	
	int currentAttrib;
	
	ArrayList staticAttribs = TF2Econ_GetItemStaticAttributes(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"));
	char Weaponname[64];
	GetEntityClassname(entity, Weaponname, sizeof(Weaponname));
	TF2Items_OnGiveNamedItem_Post_SDK(client, Weaponname, index, 5, 6, entity);
	
	for(int i = 0; i < staticAttribs.Length; i++)
	{
		currentAttrib = staticAttribs.Get(i, .block = 0);
	
		// Probably overkill
		if(currentAttrib == 796 || currentAttrib == 724 || currentAttrib == 817 || currentAttrib == 834 
			|| currentAttrib == 745 || currentAttrib == 731 || currentAttrib == 746)
			continue;
	
		// "stored_as_integer" is absent from the attribute schema if its type is "string".
		// TF2ED_GetAttributeDefinitionString returns false if it can't find the given string.
		if(!TF2Econ_GetAttributeDefinitionString(currentAttrib, "stored_as_integer", valueType, sizeof(valueType)))
			continue;
	
		TF2Econ_GetAttributeDefinitionString(currentAttrib, "description_format", valueFormat, sizeof(valueFormat));
	
		// Since we already know what we're working with and what we're looking for, we can manually handpick
		// the most significative chars to check if they match. Eons faster than doing StrEqual or StrContains.
	
		
		if(valueFormat[9] == 'a' && valueFormat[10] == 'd') // value_is_additive & value_is_additive_percentage
		{
			Attributes_Set(entity, currentAttrib, 0.0);
		}
		else if((valueFormat[9] == 'i' && valueFormat[18] == 'p')
			|| (valueFormat[9] == 'p' && valueFormat[10] == 'e')) // value_is_percentage & value_is_inverted_percentage
		{
			Attributes_Set(entity, currentAttrib, 1.0);
		}
		else if(valueFormat[9] == 'o' && valueFormat[10] == 'r') // value_is_or
		{
			Attributes_Set(entity, currentAttrib, 0.0);
		}
		
		NullifySpecificAttributes(entity,currentAttrib);
	}
	
	delete staticAttribs;	
}

stock void NullifySpecificAttributes(int entity, int attribute)
{
	switch(attribute)
	{
		case 781: //Is sword
		{
			Attributes_Set(entity, attribute, 0.0);	
		}
		case 128: //Provide on active
		{
			Attributes_Set(entity, attribute, 0.0);	
		}
	}
	
}

stock void TF2_RemoveItem(int client, int weapon)
{
	/*if(TF2_IsWearable(weapon))
	{
		TF2_RemoveWearable(client, weapon);
		return;
	}*/

	int entity = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearable");
	if(entity != -1)
		TF2_RemoveWearable(client, entity);

	entity = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearableViewModel");
	if(entity != -1)
		TF2_RemoveWearable(client, entity);

	RemovePlayerItem(client, weapon);
	RemoveEntity(weapon);
}

stock int GetMaxWeapons(int client)
{
	static int maxweps;
	if(!maxweps)
		maxweps = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");

	return maxweps;
}

stock float ClassHealth(TFClassType class)
{
	switch(class)
	{
		case TFClass_Soldier:
			return 200.0;

		case TFClass_Pyro, TFClass_DemoMan:
			return 175.0;

		case TFClass_Heavy:
			return 300.0;

		case TFClass_Medic:
			return 150.0;
	}
	
	return 125.0;
}

stock float RemoveExtraHealth(TFClassType class, float value)
{
	return value - ClassHealth(class);
}

stock float RemoveExtraSpeed(TFClassType class, float value)
{
	switch(class)
	{
		case TFClass_Scout:
			return value / 400.0;

		case TFClass_Soldier:
			return value / 240.0;

		case TFClass_DemoMan:
			return value / 280.0;

		case TFClass_Heavy:
			return value / 230.0;

		case TFClass_Medic, TFClass_Spy:
			return value / 320.0;

		default:
			return value / 300.0;
	}
}

void RequestFrames(RequestFrameCallback func, int frames, any data=0)
{
	DataPack pack = new DataPack();
	pack.WriteCell(frames);
	pack.WriteFunction(func);
	pack.WriteCell(data);
	RequestFrame(RequestFramesCallback, pack);
}

public void RequestFramesCallback(DataPack pack)
{
	pack.Reset();

	int frames = pack.ReadCell();
	if(frames < 1)
	{
		Function func = pack.ReadFunction();
		any data = pack.ReadCell();
		delete pack;
		
		Call_StartFunction(null, func);
		Call_PushCell(data);
		Call_Finish();
	}
	else
	{
		pack.Position--;
		pack.WriteCell(frames-1, false);
		RequestFrame(RequestFramesCallback, pack);
	}
}

/*
int TF2_CreateGlow(int entity, const char[] model, int owner, int color[4])
{
	int prop = CreateEntityByName("tf_taunt_prop");
	if(IsValidEntity(prop))
	{
		DispatchSpawn(prop);

		SetEntityModel(prop, model);
		SetEntPropEnt(prop, Prop_Data, "m_hEffectEntity", owner);
		SetEntProp(prop, Prop_Send, "m_bGlowEnabled", true);
		SetEntProp(prop, Prop_Send, "m_fEffects", GetEntProp(prop, Prop_Send, "m_fEffects")|EF_BONEMERGE|EF_NOSHADOW|EF_NOINTERP);

		SetVariantString("!activator");
		AcceptEntityInput(prop, "SetParent", entity);

		SetEntityRenderMode(prop, RENDER_TRANSCOLOR);
		SetEntityRenderColor(prop, color[0], color[1], color[2], color[3]);
		SDKHook(prop, SDKHook_SetTransmit, GlowTransmit);
	}
	return prop;
}

public Action GlowTransmit(int entity, int target)
{
	if(GetEntPropEnt(entity, Prop_Data, "m_hEffectEntity") == target)
		return Plugin_Continue;

	return Plugin_Handled;
}
*/

stock int TF2_CreateGlow(int iEnt)
{
	char oldEntName[64];
	GetEntPropString(iEnt, Prop_Data, "m_iName", oldEntName, sizeof(oldEntName));

	char strName[126], strClass[64];
	GetEntityClassname(iEnt, strClass, sizeof(strClass));
	Format(strName, sizeof(strName), "%s%i", strClass, iEnt);
	DispatchKeyValue(iEnt, "targetname", strName);
	
	int ent = CreateEntityByName("tf_glow");
	DispatchKeyValue(ent, "targetname", "RainbowGlow");
	DispatchKeyValue(ent, "target", strName);
	DispatchKeyValue(ent, "Mode", "2");
	DispatchSpawn(ent);
	
	AcceptEntityInput(ent, "Enable");
	
	//Change name back to old name because we don't need it anymore.
	SetEntPropString(iEnt, Prop_Data, "m_iName", oldEntName);

	return ent;
}

stock int TF2_CreateGlow_White(int iEnt, const char[] model, int parentTo, float modelsize)
{
	int entity = CreateEntityByName("tf_taunt_prop");
	if(IsValidEntity(entity))
	{
		DispatchSpawn(entity);
		SetEntityModel(entity, model);

		ActivateEntity(entity);

		SetEntProp(entity, Prop_Send, "m_iTeamNum", GetEntProp(parentTo, Prop_Send, "m_iTeamNum"));

		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", modelsize);
		SetEntPropEnt(entity, Prop_Data, "m_hEffectEntity", parentTo);
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", parentTo);
		SetEntProp(entity, Prop_Send, "m_bGlowEnabled", true);
		int iFlags = GetEntProp(entity, Prop_Send, "m_fEffects");
			
		SetEntProp(entity, Prop_Send, "m_fEffects",
				iFlags |EF_BONEMERGE|EF_NOSHADOW|EF_NORECEIVESHADOW);

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", parentTo);

		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 255, 255, 255, 255);
	}
	return entity;
}

stock void SetParent(int iParent, int iChild, const char[] szAttachment = "", const float vOffsets[3] = {0.0,0.0,0.0}, bool maintain_anyways = false)
{
	SetVariantString("!activator");
	AcceptEntityInput(iChild, "SetParent", iParent, iChild);
	
	if (szAttachment[0] != '\0') // Use at least a 0.01 second delay between SetParent and SetParentAttachment inputs.
	{
		if (szAttachment[0]) // do i even have anything?
		{
			SetVariantString(szAttachment); // "head"

			if (maintain_anyways || !AreVectorsEqual(vOffsets, view_as<float>({0.0,0.0,0.0}))) // NULL_VECTOR
			{
				if(!maintain_anyways)
				{
					float Vecpos[3];

					Vecpos = vOffsets;
					SDKCall_SetLocalOrigin(iChild,Vecpos);
				}
				AcceptEntityInput(iChild, "SetParentAttachmentMaintainOffset", iParent, iChild);
			}
			else
			{
				AcceptEntityInput(iChild, "SetParentAttachment", iParent, iChild);
			}
		}
	}
}

stock int GiveWearable(int client, int index)
{
	int entity = CreateEntityByName("tf_wearable");
	if(entity > MaxClients)	// Weapon viewmodel
	{
		if(index != 0)
		{
			SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", index);
			SetEntProp(entity, Prop_Send, "m_bInitialized", true);
		}
		SetEntProp(entity, Prop_Send, "m_iEntityQuality", 1);
		SetEntProp(entity, Prop_Send, "m_iEntityLevel", 1);
		SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
		
		DispatchSpawn(entity);
		SDKCall_EquipWearable(client, entity);
		
		return entity;
	}
	return -1;
}

stock bool AreVectorsEqual(const float vVec1[3], const float vVec2[3])
{
	return (vVec1[0] == vVec2[0] && vVec1[1] == vVec2[1] && vVec1[2] == vVec2[2]);
} 

public Action Timer_RemoveEntity(Handle timer, any entid)
{
	int entity = EntRefToEntIndex(entid);
	if(IsValidEntity(entity))
	{
		RemoveEntity(entity);
	}
	return Plugin_Stop;
}

public Action Timer_RemoveEntity_CustomProjectile(Handle timer, DataPack pack)
{
	pack.Reset();
	int iCarrier = EntRefToEntIndex(pack.ReadCell());
	int particle = EntRefToEntIndex(pack.ReadCell());
	int iRot = EntRefToEntIndex(pack.ReadCell());
	if(IsValidEntity(particle) && particle>MaxClients)
	{
		RemoveEntity(particle);
	}
	if(IsValidEntity(iCarrier) && iCarrier>MaxClients)
	{
		RemoveEntity(iCarrier);
	}
	if(IsValidEntity(iRot) && iRot>MaxClients)
	{
		RemoveEntity(iRot);
	}
	return Plugin_Stop; 
}

public Action Timer_DisableMotion(Handle timer, any entid)
{
	int entity = EntRefToEntIndex(entid);
	if(IsValidEntity(entity) && entity>MaxClients)
		AcceptEntityInput(entity, "DisableMotion");
	return Plugin_Stop;
}

void StartBleedingTimer_Against_Client(int client, int entity, float damage, int amount)
{
	BleedAmountCountStack[client] += 1;
	DataPack pack;
	CreateDataTimer(0.5, Timer_Bleeding_Against_Client, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(EntIndexToEntRef(client));
	pack.WriteCell(client);
	pack.WriteCell(EntIndexToEntRef(entity));
	pack.WriteFloat(damage);
	pack.WriteCell(amount);
}

public Action Timer_Bleeding_Against_Client(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = EntRefToEntIndex(pack.ReadCell());
	int OriginalIndex = pack.ReadCell();
	if(!IsValidClient(client))
	{
		BleedAmountCountStack[OriginalIndex] -= 1;
		return Plugin_Stop;
	}
		
	int entity = EntRefToEntIndex(pack.ReadCell());
	if(entity == -1)
		entity = 0;

	float pos[3], ang[3];
	
	pos = WorldSpaceCenter(client);
	
	GetClientEyeAngles(client, ang);
	SDKHooks_TakeDamage(client, entity, entity, pack.ReadFloat(), DMG_SLASH | DMG_PREVENT_PHYSICS_FORCE, _, _, pos, false, ZR_DAMAGE_DO_NOT_APPLY_BURN_OR_BLEED);

	int bleed_count = pack.ReadCell();
	if(bleed_count < 1)
	{
		BleedAmountCountStack[OriginalIndex] -= 1;
		return Plugin_Stop;
	}

	pack.Position--;
	pack.WriteCell(bleed_count-1, false);
	return Plugin_Continue;
}

void StartBleedingTimer(int entity, int client, float damage, int amount, int weapon, int damagetype)
{
	if(IsValidEntity(entity) && IsValidEntity(weapon) && IsValidEntity(client))
	{
		BleedAmountCountStack[entity] += 1;
		DataPack pack;
		CreateDataTimer(0.5, Timer_Bleeding, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(EntIndexToEntRef(entity));
		pack.WriteCell(entity);
		pack.WriteCell(EntIndexToEntRef(weapon));
		pack.WriteCell(GetClientUserId(client));
		pack.WriteCell(damagetype);
		pack.WriteFloat(damage);
		pack.WriteCell(amount);
	}
}

public Action Timer_Bleeding(Handle timer, DataPack pack)
{
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
	int OriginalIndex = pack.ReadCell();
	if(entity<=MaxClients || !IsValidEntity(entity) || b_NpcHasDied[entity])
	{
		BleedAmountCountStack[OriginalIndex] -= 1;
		return Plugin_Stop;
	}
		
	int weapon = EntRefToEntIndex(pack.ReadCell());
	if(weapon<=MaxClients || !IsValidEntity(weapon))
	{
		BleedAmountCountStack[OriginalIndex] -= 1;
		return Plugin_Stop;
	}

	int client = GetClientOfUserId(pack.ReadCell());
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		BleedAmountCountStack[OriginalIndex] -= 1;
		return Plugin_Stop;
	}

	if(f_NpcImmuneToBleed[entity] > GetGameTime())
	{
		BleedAmountCountStack[OriginalIndex] -= 1;
		return Plugin_Stop;
	}

	float pos[3], ang[3];
	
	pos = WorldSpaceCenter(entity);
	int damagetype = pack.ReadCell(); //Same damagetype as the weapon.
	
	GetClientEyeAngles(client, ang);
	SDKHooks_TakeDamage(entity, client, client, pack.ReadFloat(), damagetype, weapon, _, pos, false, ZR_DAMAGE_DO_NOT_APPLY_BURN_OR_BLEED);

	entity = pack.ReadCell();
	if(entity < 1)
	{
		BleedAmountCountStack[OriginalIndex] -= 1;
		return Plugin_Stop;
	}

	pack.Position--;
	pack.WriteCell(entity-1, false);
	return Plugin_Continue;
}

void StartHealingTimer(int entity, float delay, float health, int amount=0, bool maxhealth=true)
{
	DataPack pack;
	CreateDataTimer(delay, Timer_Healing, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(EntIndexToEntRef(entity));
	if(b_HealthyEssence) //see rouge.sp
	{
		health *= 1.25;
	}
	pack.WriteFloat(health);
	pack.WriteCell(maxhealth);
	pack.WriteCell(amount);
}

static float f_IncrementalSmallHeal[MAXENTITIES];

public Action Timer_Healing(Handle timer, DataPack pack)
{
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
	if(entity <= MaxClients)
	{
		
#if defined ZR
		if(entity < 1 || !IsClientInGame(entity) || !IsPlayerAlive(entity) || dieingstate[entity] > 0)
#else
		if(entity < 1 || !IsClientInGame(entity) || !IsPlayerAlive(entity))
#endif
		
		{
			return Plugin_Stop;
		}
	}
	else if(!IsValidEntity(entity))
	{
		return Plugin_Stop;
	}

	int lastHealth;
	if(entity > MaxClients)
	{
		lastHealth = GetEntProp(entity, Prop_Data, "m_iHealth");
	}
	else
	{
		lastHealth = GetClientHealth(entity);
	}

	// Our Current Health + Leftover Float Health + New Health Gained
	float newHealth = float(lastHealth) + f_IncrementalSmallHeal[entity] + pack.ReadFloat();
	
	if(pack.ReadCell() && newHealth > 0.0)	// Max Health Cap
	{
		float maxHealth;
		if(entity > MaxClients)
		{
			maxHealth = float(GetEntProp(entity, Prop_Data, "m_iMaxHealth"));
		}
		else
		{
			maxHealth = float(SDKCall_GetMaxHealth(entity));
		}
		
		if(newHealth > maxHealth)
			newHealth = maxHealth;
	}

	if(newHealth >= 1.0)
	{
		float maxHealth;

		if(entity > MaxClients)
		{
			maxHealth = float(GetEntProp(entity, Prop_Data, "m_iMaxHealth"));
		}
		else
		{
			maxHealth = float(SDKCall_GetMaxHealth(entity));
		}
		//TARGET HEAL
		if(lastHealth < maxHealth)
		{
			if(newHealth >= maxHealth)
			{
				newHealth = maxHealth;
			}

			int setHealth = RoundToFloor(newHealth);	// Health to set

			f_IncrementalSmallHeal[entity] = newHealth - float(setHealth);	// New extra health
			
			if(entity > MaxClients)
			{
				SetEntProp(entity, Prop_Data, "m_iHealth", setHealth);
			}
			else
			{
				SetEntityHealth(entity, setHealth);

				int difference = setHealth - lastHealth;
				if(difference != -1)
					ApplyHealEvent(entity, difference);	// Show healing number
			}
		}
	}
	else
	{
		SDKHooks_TakeDamage(entity, 0, 0, 100.0 - newHealth);
	}
	
	/*
	int i_TargetHealAmount;
	//The healing is less then 1 ? Do own logic.
					
	if (healing_Amount <= 1.0)
	{
		f_IncrementalSmallHeal[healTarget] += healing_Amount;
						
		if(f_IncrementalSmallHeal[healTarget] >= 1.0)
		{
			f_IncrementalSmallHeal[healTarget] -= 1.0;
			i_TargetHealAmount = 1;
		}
	}
	else
	{
		i_TargetHealAmount = RoundToFloor(healing_Amount);
						
		float Decimal_healing = FloatFraction(healing_Amount);
						
		f_IncrementalSmallHeal[healTarget] += Decimal_healing;
						
		if(f_IncrementalSmallHeal[healTarget] >= 1.0)
		{
			f_IncrementalSmallHeal[healTarget] -= 1.0;
			i_TargetHealAmount += 1;
		}
	}
	*/

	int current = pack.ReadCell();
	if(current < 2)
		return Plugin_Stop;

	pack.Position--;
	pack.WriteCell(current-1, false);
	return Plugin_Continue;
}

//doing this litterally every heal spams it, so we make a 0.5 second delay, and thus, will stack it, and then show it all at once.
Handle h_Timer_HealEventApply[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
static int i_HealsDone_Event[MAXENTITIES]={0, ...};

stock void ApplyHealEvent(int entindex, int amount)
{
	if(IsValidClient(entindex))
	{
		i_HealsDone_Event[entindex] += amount;
		if (h_Timer_HealEventApply[entindex] == INVALID_HANDLE)
		{
			DataPack pack;
			h_Timer_HealEventApply[entindex] = CreateDataTimer(0.5, Timer_HealEventApply, pack, _);
			pack.WriteCell(entindex);
			pack.WriteCell(EntIndexToEntRef(entindex));
		}
	}
}

public Action Timer_HealEventApply(Handle timer, DataPack pack)
{
	pack.Reset();
	int clientOriginalIndex = pack.ReadCell();
	int client = EntRefToEntIndex(pack.ReadCell());

	if (!IsValidMulti(client))
	{
		ApplyHealEvent_TimerDeleter(clientOriginalIndex);
		return Plugin_Continue;
	}

	Event event = CreateEvent("player_healonhit", true);
	event.SetInt("entindex", client);
	event.SetInt("amount", i_HealsDone_Event[clientOriginalIndex]);
	event.Fire();

	ApplyHealEvent_TimerDeleter(clientOriginalIndex);
	return Plugin_Continue;
}

void ApplyHealEvent_TimerDeleter(int client) //This is on disconnect/connect
{
	if (h_Timer_HealEventApply[client] != INVALID_HANDLE)
	{
		KillTimer(h_Timer_HealEventApply[client]);
	}	
	i_HealsDone_Event[client] = 0;
	h_Timer_HealEventApply[client] = INVALID_HANDLE;
}


public bool Trace_DontHitEntity(int entity, int mask, any data)
{
	return entity!=data;
}

public bool Trace_OnlyPlayer(int entity, int mask, any data)
{
	if(entity > MaxClients || entity == 0)
	{
		return false;
	}
	
#if defined ZR
	else if(TeutonType[entity] != TEUTON_NONE)
	{
		return false;
	}
#endif
	
	return entity!=data;
}

public bool Trace_DontHitEntityOrPlayerOrAlliedNpc(int entity, int mask, any data)
{
	if(entity <= MaxClients)
	{
		
#if defined ZR
		if(entity != data) //make sure that they are not dead, if they are then just ignore them/give special shit
		{
			int Building_Index = EntRefToEntIndex(Building_Mounted[entity]);
			if(dieingstate[entity] > 0)
			{
				if(!b_LeftForDead[entity])
				{
					return entity!=data;
				}
				else
				{
					return false;	
				}
			}
			else if(Building_Index == 0 || !IsValidEntity(Building_Index))
			{
				return false;
			}
			return Building_Index!=data;
		}
#else
		return false;
#endif
		
	}
	if(entity > MaxClients && b_IsAlliedNpc[entity])
	{
		return false;
	}
	
	return entity!=data;
}

public bool Trace_DontHitEntityOrPlayer(int entity, int mask, any data)
{
	if(entity <= MaxClients)
	{
#if defined ZR
		if(entity != data) //make sure that they are not dead, if they are then just ignore them/give special shit
		{
			int Building_Index = EntRefToEntIndex(Building_Mounted[entity]);
			if(dieingstate[entity] > 0)
			{
				if(!b_LeftForDead[entity])
				{
					return entity!=data;
				}
				else
				{
					return false;	
				}
			}
			else if(Building_Index == 0 || !IsValidEntity(Building_Index))
			{
				return false;
			}
			return Building_Index!=data;
		}
#else
		return false;
#endif		
	}
#if defined RPG
	else if(entity > MaxClients && entity < MAXENTITIES)
	{
		if(b_is_a_brush[entity])//THIS is for brushes that act as collision boxes for NPCS inside quests.sp
		{
			int entityfrombrush = BrushToEntity(entity);
			if(entityfrombrush != -1)
			{
				return entityfrombrush!=data;
			}
		}
		if(Textstore_CanSeeItem(entity, data))
		{
			return entity!=data;
		}
		else if(b_IsAlliedNpc[entity])
		{
			return entity!=data;
		}
		else
		{
			return false;
		}
	}
#endif	
	return entity!=data;
}


public bool Trace_DontHitAlivePlayer(int entity, int mask, any data)
{
	if(entity <= MaxClients)
	{
		if(entity != data)
		{
#if defined ZR
			if(dieingstate[entity] <= 0)
			{
				return false;
			}
			if(b_LeftForDead[entity])
#endif
			{
				return false;
			}
		}
	}
	
#if defined ZR
	else if(!Citizen_ThatIsDowned(entity))
#else
	else
#endif
	
	{
		return false;
	}
	
	return entity!=data;
}

stock float[] GetAbsOrigin(int client)
{
	float v[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", v);
	return v;
}

public void DeleteHandle(Handle handle)
{
	delete handle;
}

stock bool IsValidClient( int client)
{	
	if ( client <= 0 || client > MaxClients )
		return false; 
	if ( !IsClientInGame( client ) ) 
		return false; 
		
	return true; 
}

stock float[] GetWorldSpaceCenter(int client)
{
	float v[3]; v = GetAbsOrigin(client);
	
	float max_space[3];
	GetEntPropVector(client, Prop_Data, "m_vecMaxs", max_space);
	v[2] += max_space[2] / 2;
	
	return v;
}

bool IsBehindAndFacingTarget(int owner, int target)
{
	float vecToTarget[3];
	SubtractVectors(GetWorldSpaceCenter(target), GetWorldSpaceCenter(owner), vecToTarget);

	vecToTarget[2] = 0.0;
	NormalizeVector(vecToTarget, vecToTarget);
	
	float vecEyeAngles[3];
	
	if(owner <= MaxClients)
		GetClientEyeAngles(owner, vecEyeAngles);
	else
		GetEntPropVector(owner, Prop_Data, "m_angRotation", vecEyeAngles);
		
	float vecOwnerForward[3];
	GetAngleVectors(vecEyeAngles, vecOwnerForward, NULL_VECTOR, NULL_VECTOR);
	vecOwnerForward[2] = 0.0;
	NormalizeVector(vecOwnerForward, vecOwnerForward);
	
	if(target <= MaxClients)
		GetClientEyeAngles(target, vecEyeAngles);
	else
		GetEntPropVector(target, Prop_Data, "m_angRotation", vecEyeAngles);

	float vecTargetForward[3];
	GetAngleVectors(vecEyeAngles, vecTargetForward, NULL_VECTOR, NULL_VECTOR);
	vecTargetForward[2] = 0.0;
	NormalizeVector(vecTargetForward, vecTargetForward);
	
	float flPosVsTargetViewDot = GetVectorDotProduct(vecToTarget, vecTargetForward);
	float flPosVsOwnerViewDot = GetVectorDotProduct(vecToTarget, vecOwnerForward);
	float flViewAnglesDot = GetVectorDotProduct(vecTargetForward, vecOwnerForward);
	
	return ( flPosVsTargetViewDot > 0.0 && flPosVsOwnerViewDot > 0.5 && flViewAnglesDot > -0.3 );
}

stock float AngleDiff(float firstAngle, float secondAngle)
{
	float diff = secondAngle - firstAngle;
	return AngleNormalize(diff);
}

stock float AngleNormalize(float angle)
{
	while (angle > 180.0) angle -= 360.0;
	while (angle < -180.0) angle += 360.0;
	return angle;
}

void DoOverlay(int client, const char[] overlay)
{
	//int flags = GetCommandFlags("r_screenoverlay");
	//SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
	//if(overlay[0])
	//{
		SetEntPropString(client, Prop_Send, "m_szScriptOverlayMaterial", overlay);
	//	ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	//}
	//else
	//{
	//	ClientCommand(client, "r_screenoverlay off");
	//}
	//SetCommandFlags("r_screenoverlay", flags);
}

public bool PlayersOnly(int entity, int contentsMask, any iExclude)
{
	if(entity > MAXPLAYERS)
	{
		return false;
	}
	
	else if(GetEntProp(iExclude, Prop_Send, "m_iTeamNum") != GetEntProp(entity, Prop_Send, "m_iTeamNum"))
		return false;
		
	
	return !(entity == iExclude);
}

stock bool Client_Shake(int client, int command=SHAKE_START, float amplitude=50.0, float frequency=150.0, float duration=3.0)
{
	//allow settings for the sick who cant handle screenshake.
	//can cause headaches.
	if(!b_HudScreenShake[client])
	{
		return false;
	}
	if (command == SHAKE_STOP) {
		amplitude = 0.0;
	}
	else if (amplitude <= 0.0) {
		return false;
	}

	Handle userMessage = StartMessageOne("Shake", client);

	if (userMessage == INVALID_HANDLE) {
		return false;
	}

	if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available
		&& GetUserMessageType() == UM_Protobuf) {

		PbSetInt(userMessage,   "command",		 command);
		PbSetFloat(userMessage, "local_amplitude", amplitude);
		PbSetFloat(userMessage, "frequency",	   frequency);
		PbSetFloat(userMessage, "duration",		duration);
	}
	else {
		BfWriteByte(userMessage,	command);	// Shake Command
		BfWriteFloat(userMessage,	amplitude);	// shake magnitude/amplitude
		BfWriteFloat(userMessage,	frequency);	// shake noise frequency
		BfWriteFloat(userMessage,	duration);	// shake lasts this long
	}

	EndMessage();

	return true;
}


stock void PrintKeyHintText(int client, const char[] format, any ...)
{
	char buffer[254]; //maybe 255 is the limit.
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);

	Handle userMessage = StartMessageOne("KeyHintText", client);
	if(userMessage == INVALID_HANDLE)
		return;

	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType")==FeatureStatus_Available && GetUserMessageType()==UM_Protobuf)
	{
		PbSetString(userMessage, "hints", buffer);
	}
	else
	{
		BfWriteByte(userMessage, 1); 
		BfWriteString(userMessage, buffer); 
	}
	
	EndMessage();
}

stock int FindEntityByClassname2(int startEnt, const char[] classname)
{
	while(startEnt>-1 && !IsValidEntity(startEnt))
	{
		startEnt--;
	}
	return FindEntityByClassname(startEnt, classname);
}

stock bool IsEven( int iNum )
{
	return iNum % 2 == 0;
} 

stock bool IsInvuln(int client) //Borrowed from Batfoxkid
{
	if(!IsValidClient(client))
		return true;

	return (TF2_IsPlayerInCondition(client, TFCond_Ubercharged) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInCondition(client, TFCond_Bonked) ||
		TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode) ||
		//TF2_IsPlayerInCondition(client, TFCond_MegaHeal) ||
		!GetEntProp(client, Prop_Data, "m_takedamage"));
}

stock void ModelIndexToString(int index, char[] model, int size)
{
	int table = FindStringTable("modelprecache");
	ReadStringTable(table, index, model, size);
}

stock int ParseColor(char[] colorStr)
{
	int ret = 0;
	ret |= charToHex(colorStr[0])<<20;
	ret |= charToHex(colorStr[1])<<16;
	ret |= charToHex(colorStr[2])<<12;
	ret |= charToHex(colorStr[3])<<8;
	ret |= charToHex(colorStr[4])<<4;
	ret |= charToHex(colorStr[5]);
	return ret;
}

stock void VectorRotate(float inPoint[3], float angles[3], float outPoint[3])
{
	float matRotate[3][4];
	AngleMatrix(angles, matRotate);
	VectorRotate2(inPoint, matRotate, outPoint);
}


stock void VectorRotate2(float in1[3], float in2[3][4], float out[3])
{
	out[0] = DotProduct(in1, in2[0]);
	out[1] = DotProduct(in1, in2[1]);
	out[2] = DotProduct(in1, in2[2]);
}

stock float ClampBeamWidth(float w) { return w > 128.0 ? 128.0 : w; }
stock int GetR(int c) { return abs((c>>16)&0xff); }
stock int GetG(int c) { return abs((c>>8 )&0xff); }
stock int GetB(int c) { return abs((c	)&0xff); }



stock void ConformLineDistance(float result[3], const float src[3], const float dst[3], float maxDistance, bool canExtend = false)
{
	float distance = GetVectorDistance(src, dst);
	if (distance <= maxDistance && !canExtend)
	{
		// everything's okay.
		result[0] = dst[0];
		result[1] = dst[1];
		result[2] = dst[2];
	}
	else
	{
		// need to find a point at roughly maxdistance. (FP irregularities aside)
		float distCorrectionFactor = maxDistance / distance;
		result[0] = ConformAxisValue(src[0], dst[0], distCorrectionFactor);
		result[1] = ConformAxisValue(src[1], dst[1], distCorrectionFactor);
		result[2] = ConformAxisValue(src[2], dst[2], distCorrectionFactor);
	}
}


stock void SetColorRGBA(int color[4], int r, int g, int b, int a)
{
	color[0] = abs(r)%256;
	color[1] = abs(g)%256;
	color[2] = abs(b)%256;
	color[3] = abs(a)%256;
}


/*stock float DEG2RAD(float n)
{
	return n * 0.017453;
}*/

stock float DotProduct(float v1[3], float v2[4])
{
	return v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2];
}

stock int charToHex(int c)
{
	if (c >= '0' && c <= '9')
		return c - '0';
	else if (c >= 'a' && c <= 'f')
		return c - 'a' + 10;
	else if (c >= 'A' && c <= 'F')
		return c - 'A' + 10;
	
	// this is a user error, so print this out (it won't spam)
	PrintToConsoleAll("Invalid hex character, probably while parsing something's color. Please only use 0-9 and A-F in your color. c=%d", c);
	return 0;
}
stock float ConformAxisValue(float src, float dst, float distCorrectionFactor)
{
	return src - ((src - dst) * distCorrectionFactor);
}

stock void AngleMatrix(float angles[3], float matrix[3][4])
{
	float sr = 0.0;
	float sp = 0.0;
	float sy = 0.0;
	float cr = 0.0;
	float cp = 0.0;
	float cy = 0.0;
	sy = Sine(DEG2RAD(angles[1]));
	cy = Cosine(DEG2RAD(angles[1]));
	sp = Sine(DEG2RAD(angles[0]));
	cp = Cosine(DEG2RAD(angles[0]));
	sr = Sine(DEG2RAD(angles[2]));
	cr = Cosine(DEG2RAD(angles[2]));
	matrix[0][0] = cp * cy;
	matrix[1][0] = cp * sy;
	matrix[2][0] = -sp;
	float crcy = cr * cy;
	float crsy = cr * sy;
	float srcy = sr * cy;
	float srsy = sr * sy;
	matrix[0][1] = sp * srcy - crsy;
	matrix[1][1] = sp * srsy + crcy;
	matrix[2][1] = sr * cp;
	matrix[0][2] = sp * crcy + srsy;
	matrix[1][2] = sp * crsy - srcy;
	matrix[2][2] = cr * cp;
	matrix[0][3] = 0.0;
	matrix[1][3] = 0.0;
	matrix[2][3] = 0.0;
}

public bool Base_Boss_Hit(int entity, int contentsMask, any iExclude)
{
	char class[64];
	GetEntityClassname(entity, class, sizeof(class));
	
	if(entity != iExclude && (StrEqual(class, "obj_dispenser") || StrEqual(class, "obj_teleporter") || StrEqual(class, "obj_sentrygun")))
	{
		if(GetEntProp(iExclude, Prop_Send, "m_iTeamNum") == GetEntProp(entity, Prop_Send, "m_iTeamNum"))
		{
			return true;
		}
		
		else if(GetEntPropFloat(entity, Prop_Send, "m_flPercentageConstructed") >= 0.1)
		{
			return false;
		}
		else
		{
			return true;
		}
	}
		
	
	return !(entity == iExclude);
}

public bool IngorePlayersAndBuildings(int entity, int contentsMask, any iExclude)
{
	char class[64];
	GetEntityClassname(entity, class, sizeof(class));
	if(entity <= MaxClients) //just ignore players entirely, there will be no pvp.
	{
		return false;
	}
	if(StrEqual(class, "prop_physics") || StrEqual(class, "prop_physics_multiplayer"))
	{
		return false;
	}
	if(entity != iExclude && (StrEqual(class, "obj_dispenser") || StrEqual(class, "obj_teleporter") || StrEqual(class, "obj_sentrygun") || StrEqual(class, "zr_base_npc"))) //include baseboss so it goesthru
	{
		if(GetEntProp(iExclude, Prop_Send, "m_iTeamNum") == GetEntProp(entity, Prop_Send, "m_iTeamNum"))
		{
			return false;
		}
		else
		{
			return true;
		}
	}
		
	
	return !(entity == iExclude);
}

public bool Detect_BaseBoss(int entity, int contentsMask, any iExclude)
{
	char class[64];
	GetEntityClassname(entity, class, sizeof(class));
	
	if(!StrEqual(class, "zr_base_npc"))
	{
		return false;
	}
	
	if(entity != iExclude && StrEqual(class, "zr_base_npc"))
	{
		if(GetEntProp(iExclude, Prop_Send, "m_iTeamNum") == GetEntProp(entity, Prop_Send, "m_iTeamNum"))
		{
			return false;
		}
		else
		{
			return true;
		}
	}
		
	
	return !(entity == iExclude);
}

stock int GetClosestTarget_BaseBoss(int entity)
{
	float TargetDistance = 0.0; 
	int ClosestTarget = -1; 
	int i = MaxClients + 1;
	while ((i = FindEntityByClassname(i, "zr_base_npc")) != -1)
	{
		if (GetEntProp(entity, Prop_Send, "m_iTeamNum")!=GetEntProp(i, Prop_Send, "m_iTeamNum") && !b_NpcHasDied[i]) 
		{
			float EntityLocation[3], TargetLocation[3]; 
			GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", EntityLocation ); 
			GetEntPropVector( i, Prop_Data, "m_vecAbsOrigin", TargetLocation ); 
				
				
			float distance = GetVectorDistance( EntityLocation, TargetLocation, true ); 
			if( TargetDistance ) 
			{
				if( distance < TargetDistance ) 
				{
					ClosestTarget = i; 
					TargetDistance = distance;		  
				}
			} 
			else 
			{
				ClosestTarget = i; 
				TargetDistance = distance;
			}				
		}
	}
	return ClosestTarget; 
}

bool b_WasAlreadyCalculatedToBeClosest[MAXENTITIES]; //should be false by default...

stock int GetClosestTarget_BaseBoss_Pos(float pos[3],int entity)
{
	float TargetDistance = 0.0; 
	int ClosestTarget = -1; 
	for(int entitycount; entitycount<i_MaxcountNpc; entitycount++)
	{
		int baseboss_index = EntRefToEntIndex(i_ObjectsNpcs[entitycount]);
		if (IsValidEntity(baseboss_index) && !b_WasAlreadyCalculatedToBeClosest[baseboss_index])
		{
			if(!b_NpcHasDied[baseboss_index])
			{
				if (GetEntProp(entity, Prop_Send, "m_iTeamNum")!=GetEntProp(baseboss_index, Prop_Send, "m_iTeamNum")) 
				{
					float TargetLocation[3]; 
					GetEntPropVector( baseboss_index, Prop_Data, "m_vecAbsOrigin", TargetLocation ); 
					
					float distance = GetVectorDistance( pos, TargetLocation, true ); 
					if( TargetDistance ) 
					{
						if( distance < TargetDistance ) 
						{
							ClosestTarget = baseboss_index; 
							TargetDistance = distance;		  
						}
					} 
					else 
					{
						ClosestTarget = baseboss_index; 
						TargetDistance = distance;
					}				
				}
			}
		}
	}
	for(int entitycount; entitycount<i_MaxcountBreakable; entitycount++)
	{
		int breakable_entity = EntRefToEntIndex(i_ObjectsBreakable[entitycount]);
		if(IsValidEntity(breakable_entity))
		{
			if (GetEntProp(breakable_entity, Prop_Send, "m_iTeamNum")!=GetEntProp(breakable_entity, Prop_Send, "m_iTeamNum")) 
			{
				float TargetLocation[3]; 
				GetEntPropVector( breakable_entity, Prop_Data, "m_vecAbsOrigin", TargetLocation ); 
				
				float distance = GetVectorDistance( pos, TargetLocation, true ); 
				if( TargetDistance ) 
				{
					if( distance < TargetDistance ) 
					{
						ClosestTarget = breakable_entity; 
						TargetDistance = distance;		  
					}
				} 
				else 
				{
					ClosestTarget = breakable_entity; 
					TargetDistance = distance;
				}				
			}
		}
	}
	if(IsValidEntity(ClosestTarget))
	{
		b_WasAlreadyCalculatedToBeClosest[ClosestTarget] = true;
	}
	return ClosestTarget; 
}

stock void AnglesToVelocity(const float ang[3], float vel[3], float speed=1.0)
{
	vel[0] = Cosine(DegToRad(ang[1]));
	vel[1] = Sine(DegToRad(ang[1]));
	vel[2] = Sine(DegToRad(ang[0])) * -1.0;
	
	NormalizeVector(vel, vel);
	
	ScaleVector(vel, speed);
}

stock bool ObstactleBetweenEntities(int entity1, int entity2)
{
	static float pos1[3], pos2[3];
	if(IsValidClient(entity1))
	{
		GetClientEyePosition(entity1, pos1);
	}
	else
	{
		GetEntPropVector(entity1, Prop_Send, "m_vecOrigin", pos1);
	}

	GetEntPropVector(entity2, Prop_Send, "m_vecOrigin", pos2);

	Handle trace = TR_TraceRayFilterEx(pos1, pos2, MASK_ALL, RayType_EndPoint, Trace_DontHitEntity, entity1);

	bool hit = TR_DidHit(trace);
	int index = TR_GetEntityIndex(trace);
	delete trace;

	if(!hit || index!=entity2)
		return true;

	return false;
}

stock bool IsEntityStuck(int entity)
{
	static float minn[3], maxx[3], pos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecMins", minn);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxx);
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
	
	TR_TraceHullFilter(pos, pos, minn, maxx, MASK_SOLID, Trace_DontHitEntity, entity);
	return (TR_DidHit());
}


stock int SpawnWeapon_Special(int client, char[] name, int index, int level, int qual, const char[] att, bool visible=true)
{
	if(StrEqual(name, "saxxy", false))	// if "saxxy" is specified as the name, replace with appropiate name
	{ 
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Scout:	ReplaceString(name, 64, "saxxy", "tf_weapon_bat", false);
			case TFClass_Pyro:	ReplaceString(name, 64, "saxxy", "tf_weapon_fireaxe", false);
			case TFClass_DemoMan:	ReplaceString(name, 64, "saxxy", "tf_weapon_bottle", false);
			case TFClass_Heavy:	ReplaceString(name, 64, "saxxy", "tf_weapon_fists", false);
			case TFClass_Engineer:	ReplaceString(name, 64, "saxxy", "tf_weapon_wrench", false);
			case TFClass_Medic:	ReplaceString(name, 64, "saxxy", "tf_weapon_bonesaw", false);
			case TFClass_Sniper:	ReplaceString(name, 64, "saxxy", "tf_weapon_club", false);
			case TFClass_Spy:	ReplaceString(name, 64, "saxxy", "tf_weapon_knife", false);
			default:		ReplaceString(name, 64, "saxxy", "tf_weapon_shovel", false);
		}
	}
	else if(StrEqual(name, "tf_weapon_shotgun", false))	// If using tf_weapon_shotgun for Soldier/Pyro/Heavy/Engineer
	{
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Pyro:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_pyro", false);
			case TFClass_Heavy:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_hwg", false);
			case TFClass_Engineer:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_primary", false);
			default:		ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_soldier", false);
		}
	}

	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if(hWeapon == INVALID_HANDLE)
		return -1;

	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	TF2Items_SetNumAttributes(hWeapon, 0);

	int entity = TF2Items_GiveNamedItem(client, hWeapon);
	delete hWeapon;
	if(entity == -1)
		return -1;
	
	Attributes_EntityDestroyed(entity);
	
	char atts[32][32];
	int count = ExplodeString(att, ";", atts, 32, 32);

	if(count % 2)
		--count;
	
	for(int i; i < count; i += 2)
	{
		int attrib = StringToInt(atts[i]);
		if(attrib)
		{
			Attributes_Set(entity, attrib, StringToFloat(atts[i+1]));
		}
	}

	EquipPlayerWeapon(client, entity);

	if(visible)
	{
		SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", 1);
	}
	else
	{
		SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
	}
	return entity;
}

stock void GetRayAngles(float startPoint[3], float endPoint[3], float angle[3])
{
	static float tmpVec[3];
	tmpVec[0] = endPoint[0] - startPoint[0];
	tmpVec[1] = endPoint[1] - startPoint[1];
	tmpVec[2] = endPoint[2] - startPoint[2];
	GetVectorAngles(tmpVec, angle);
}

public bool RW_IsValidHomingTarget(int target, int owner)
{
	if(!IsValidEntity(target))
		return false;
	
	if(b_NpcHasDied[target])
		return false;
	
	if(b_IsCamoNPC[target])
		return false;
		
	return true;
}

public bool TraceWallsOnly(int entity, int contentsMask)
{
	return false;
}

stock bool AngleWithinTolerance(float entityAngles[3], float targetAngles[3], float tolerance)
{
	static bool tests[2];
	
	for (int i = 0; i < 2; i++)
		tests[i] = fabs(entityAngles[i] - targetAngles[i]) <= tolerance || fabs(entityAngles[i] - targetAngles[i]) >= 360.0 - tolerance;
	
	return tests[0] && tests[1];
}

stock float fixAngle(float angle)
{
	int sanity = 0;
	while (angle < -180.0 && (sanity++) <= 10)
		angle = angle + 360.0;
	while (angle > 180.0 && (sanity++) <= 10)
		angle = angle - 360.0;
		
	return angle;
}

stock int Spawn_Buildable(int client, int AllowBuilding = -1)
{
	int entity = SpawnWeapon(client, "tf_weapon_builder", 28, 1, 0, view_as<int>({148}), view_as<float>({1.0}), 1); 
	if(entity > MaxClients)
	{
		SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
		SetEntProp(entity, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		Attributes_Set(entity, 148, 0.0);
		
		if(AllowBuilding == -1)
		{
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 0); //Dispenser
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 1); //Teleporter
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 2); //Sentry
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 3);
		}
		else if(AllowBuilding == 0)
		{
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", true, _, 0); //Dispenser
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 1); //Teleporter
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 2); //Sentry
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 3);
		}
		else if(AllowBuilding == 2)
		{
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 0); //Dispenser
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 1); //Teleporter
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", true, _, 2); //Sentry
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 3);
		}
		else
		{
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 0); //Dispenser
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 1); //Teleporter
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 2); //Sentry
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 3);
		}
		
	//	PrintToChatAll("%i",GetEntPropEnt(entity, Prop_Send, "m_hOwner"));
		
		Attributes_Set(client, 353, 1.0);
		
		Attributes_Set(entity, 292, 3.0);
		Attributes_Set(entity, 293, 59.0);
		Attributes_Set(entity, 495, 60.0); //Kill eater score shit, i dont know.
	//	TF2_SetPlayerClass(client, TFClass_Engineer);
		return entity;
	}	
	return -1;
}

public void CreateEarthquake(float position[3], float duration, float radius, float amplitude, float frequency)
{
	int earthquake = CreateEntityByName("env_shake");
	if (IsValidEntity(earthquake))
	{
	
		DispatchKeyValueFloat(earthquake, "amplitude", amplitude);
		DispatchKeyValueFloat(earthquake, "radius", radius * 2);
		DispatchKeyValueFloat(earthquake, "duration", duration + 1.0);
		DispatchKeyValueFloat(earthquake, "frequency", frequency);

		SetVariantString("spawnflags 4"); // no physics (physics is 8), affects people in air (4)
		AcceptEntityInput(earthquake, "AddOutput");

		// create
		DispatchSpawn(earthquake);
		TeleportEntity(earthquake, position, NULL_VECTOR, NULL_VECTOR);

		AcceptEntityInput(earthquake, "StartShake", 0);
		CreateTimer(duration + 0.1, Timer_RemoveEntity, EntIndexToEntRef(earthquake), TIMER_FLAG_NO_MAPCHANGE);
	}
}


public bool TF2U_GetWearable(int client, int &entity, int &index)
{
	/*#if defined __nosoop_tf2_utils_included
	if(Loaded)
	{
		int length = TF2Util_GetPlayerWearableCount(client);
		while(index < length)
		{
			entity = TF2Util_GetPlayerWearable(client, index++);
			if(entity > MaxClients)
				return true;
		}
	}
	else
	#endif*/
	{
		if(index >= -1 && index <= MaxClients)
			index = MaxClients + 1;
		
		if(index > -2)
		{
			while((index=FindEntityByClassname(index, "tf_wear*")) != -1)
			{
				if(GetEntPropEnt(index, Prop_Send, "m_hOwnerEntity") == client)
				{
					entity = index;
					return true;
				}
			}
			
			index = -(MaxClients + 1);
		}
		
		entity = -index;
		while((entity=FindEntityByClassname(entity, "tf_powerup_bottle")) != -1)
		{
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
			{
				index = -entity;
				return true;
			}
		}
	}
	return false;
}

stock void spawnRing(int client, float range, float modif_X, float modif_Y, float modif_Z, char sprite[255], int r, int g, int b, int alpha, int fps, float life, float width, float amp, int speed, float endRange = -69.0) //Spawns a TE beam ring at a client's/entity's location
{
	if (IsValidEntity(client))
	{
		float center[3];
		
		if (IsValidMulti(client, true, true, false)) //If our entity is a living player, grab their abs origin
		{
			GetClientAbsOrigin(client, center);
		}
		else if (client > MaxClients) //If our entity is just an entity, grab its m_vecOrigin
		{
			if (HasEntProp(client, Prop_Send, "m_vecOrigin"))
			{
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", center);
			}
		}
		
		if (IsValidMulti(client, true, false, false)) //If the entity is a dead player, abort
		{
			return;
		}
		
		center[0] += modif_X;
		center[1] += modif_Y;
		center[2] += modif_Z;
		
		
		int ICE_INT = PrecacheModel(sprite);
		
		int color[4];
		color[0] = r;
		color[1] = g;
		color[2] = b;
		color[3] = alpha;
		
		if (endRange == -69.0)
		{
			endRange = range + 0.5;
		}
		
		TE_SetupBeamRingPoint(center, range, endRange, ICE_INT, ICE_INT, 0, fps, life, width, amp, color, speed, 0);
		TE_SendToAll();
	}
}

stock bool IsSpaceOccupiedIgnorePlayersOnlyNpc(const float pos[3], const float mins[3], const float maxs[3],int entity=-1,int &ref=-1)
{
	Handle hTrace = TR_TraceHullFilterEx(pos, pos, mins, maxs, MASK_NPCSOLID, TraceRayOnlyNpc, entity);
	bool bHit = TR_DidHit(hTrace);
	ref = TR_GetEntityIndex(hTrace);
	delete hTrace;
	return bHit;
}

public bool TraceEntityFilterPlayer(int entity, any contentsMask) //Borrowed from Apocalips
{
	return entity > MaxClients;
}

public bool TraceRayOnlyNpc(int entity, any contentsMask, any data)
{
	static char class[12];
	GetEntityClassname(entity, class, sizeof(class));
	
	if(StrEqual(class, "zr_base_npc")) return true;
	
	return !(entity == data);
}

stock bool IsValidMulti(int client, bool checkAlive=true, bool isAlive=true, bool checkTeam=false, TFTeam team=TFTeam_Red, bool send=false) //An extension of IsValidClient that also checks for boss status, alive-ness, and optionally a team. Send is used for debug purposes to inform the programmer when and why this stock returns false.
{
	if (!IsValidClient(client)) //Self-explanatory
	{
		return false;
	}
	
	if (checkAlive) //Do we want to check if the player is alive?
	{
		if (isAlive && !IsPlayerAlive(client)) //If we need the player to be alive, but they're dead, return false.
		{
			return false;
		}
		if (!isAlive && IsPlayerAlive(client)) //If we need the player to be dead, but they're alive, return false.
		{
			return false;
		}
	}
	
	if (checkTeam) //Do we want to check the client's team?
	{
		if (TF2_GetClientTeam(client) != team) //If they aren't on the desired team, return false.
		{
			return false;
		}
	}
	return true; //If all desired conditions are met, return true.
}

public bool AntiTraceEntityFilterPlayer(int entity, any contentsMask) //Borrowed from Apocalips
{
	return entity <= MaxClients;
}

#define EXPLOSION_PARTICLE_SMALL_1 "ExplosionCore_MidAir"
#define EXPLOSION_PARTICLE_SMALL_2 "ExplosionCore_buildings"
#define EXPLOSION_PARTICLE_SMALL_3 "ExplosionCore_Wall"
#define EXPLOSION_PARTICLE_SMALL_4 "rd_robot_explosion"

public void SpawnSmallExplosion(float DetLoc[3])
{
	float pos[3];
	pos[0] += DetLoc[0] + GetRandomFloat(-80.0, 80.0);
	pos[1] += DetLoc[1] + GetRandomFloat(-80.0, 80.0);
	pos[2] += DetLoc[2] + GetRandomFloat(0.0, 80.0);
	
	TE_Particle(EXPLOSION_PARTICLE_SMALL_1, pos, NULL_VECTOR, NULL_VECTOR, _, _, _, _, _, _, _, _, _, _, 0.0);
}

public void SpawnSmallExplosionNotRandom(float DetLoc[3])
{
	TE_Particle(EXPLOSION_PARTICLE_SMALL_1, DetLoc, NULL_VECTOR, NULL_VECTOR, _, _, _, _, _, _, _, _, _, _, 0.0);
}

stock void GetVectorAnglesTwoPoints(const float startPos[3], const float endPos[3], float angles[3])
{
	static float tmpVec[3];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
}


stock int TracePlayerHulls(const float pos[3], const float mins[3], const float maxs[3],int entity=-1,int &ref=-1)
{
	Handle hTrace = TR_TraceHullFilterEx(pos, pos, mins, maxs, MASK_ALL, IngorePlayersAndBuildings, entity);
	bool bHit = TR_DidHit(hTrace);
	ref = TR_GetEntityIndex(hTrace);
	delete hTrace;
	return bHit;
}

void TE_DrawBox(int client, float m_vecOrigin[3], float m_vecMins[3], float m_vecMaxs[3], float flDur = 0.1, const int color[4])
{
	//Trace top down
	/*
	float tStart[3]; tStart = m_vecOrigin;
	
	tStart[2] = (tStart[2] + m_vecMaxs[2]);
	*/
//	TE_ShowPole(tStart, view_as<int>( { 255, 0, 255, 255 } ));
//	TE_ShowPole(tEnd, view_as<int>( { 0, 255, 255, 255 } ));
	/*
	Handle trace = TR_TraceHullFilterEx(tStart, tEnd, m_vecMins, m_vecMaxs, MASK_SHOT|CONTENTS_GRATE, IngorePlayersAndBuildingsHull, client);
	bool bDidHit = TR_DidHit(trace);
	*/
	/*
	if( m_vecMins[0] == m_vecMaxs[0] && m_vecMins[1] == m_vecMaxs[1] && m_vecMins[2] == m_vecMaxs[2] )
	{
		m_vecMins = view_as<float>({-15.0, -15.0, -15.0});
		m_vecMaxs = view_as<float>({15.0, 15.0, 15.0});
	}
	else
	{
		*/
	AddVectors(m_vecOrigin, m_vecMaxs, m_vecMaxs);
	AddVectors(m_vecOrigin, m_vecMins, m_vecMins);
//	}
	
	float vPos1[3], vPos2[3], vPos3[3], vPos4[3], vPos5[3], vPos6[3];
	vPos1 = m_vecMaxs;
	vPos1[0] = m_vecMins[0];
	vPos2 = m_vecMaxs;
	vPos2[1] = m_vecMins[1];
	vPos3 = m_vecMaxs;
	vPos3[2] = m_vecMins[2];
	vPos4 = m_vecMins;
	vPos4[0] = m_vecMaxs[0];
	vPos5 = m_vecMins;
	vPos5[1] = m_vecMaxs[1];
	vPos6 = m_vecMins;
	vPos6[2] = m_vecMaxs[2];

	TE_SendBeam(client, m_vecMaxs, vPos1, flDur, color);
	TE_SendBeam(client, m_vecMaxs, vPos2, flDur, color);
	TE_SendBeam(client, m_vecMaxs, vPos3, flDur, color);
	TE_SendBeam(client, vPos6, vPos1, flDur, color);
	TE_SendBeam(client, vPos6, vPos2, flDur, color);
	TE_SendBeam(client, vPos6, m_vecMins, flDur, color);
	TE_SendBeam(client, vPos4, m_vecMins, flDur, color);
	TE_SendBeam(client, vPos5, m_vecMins, flDur, color);
	TE_SendBeam(client, vPos5, vPos1, flDur, color);
	TE_SendBeam(client, vPos5, vPos3, flDur, color);
	TE_SendBeam(client, vPos4, vPos3, flDur, color);
	TE_SendBeam(client, vPos4, vPos2, flDur, color);
	/*
	for( int i = 0; i < 3; i++ ) 
	{
	//	tStart[i] = 0.0;
		vPos1[i] = 0.0;
		vPos2[i] = 0.0;
		vPos3[i] = 0.0;
		vPos4[i] = 0.0;
		vPos5[i] = 0.0;
		vPos6[i] = 0.0;
		m_vecMaxs[i] = 0.0;
		m_vecMins[i] = 0.0;
	}
	*/
//	delete trace;
	
//	return true;
}

void TE_SendBeam(int client, float m_vecMins[3], float m_vecMaxs[3], float flDur = 0.1, const int color[4])
{
	TE_SetupBeamPoints(m_vecMins, m_vecMaxs, g_iLaserMaterial_Trace, g_iHaloMaterial_Trace, 0, 0, flDur, 1.0, 1.0, 1, 0.0, color, 0);
	TE_SendToClient(client);
}

/*
float[] CalculateBulletDamageForce( const float vecBulletDir[3], float flScale )
{
	float vecForce[3]; vecForce = vecBulletDir;
	NormalizeVector( vecForce, vecForce );
	ScaleVector(vecForce, FindConVar("phys_pushscale").FloatValue);
	ScaleVector(vecForce, flScale);
	return vecForce;
}
*/

int Target_Hit_Wand_Detection(int owner_projectile, int other_entity)
{
	if(owner_projectile < 1)
	{
		return -1; //I dont exist?
	}
	else if(other_entity == 0)
	{
		return 0;
	}
	else if(b_ThisEntityIsAProjectileForUpdateContraints[owner_projectile] && b_ThisEntityIsAProjectileForUpdateContraints[other_entity])
	{
		return -1;
	}
	else if(i_IsABuilding[other_entity])
	{
		return -1;
	}
	else if(b_IsAlliedNpc[other_entity])
	{
		return -1;
	}
	else if(other_entity <= MaxClients)
	{
		return -1;
	}
//	else if(IsValidEnemy(owner_projectile, other_entity, true, true))
	else if(!b_NpcHasDied[other_entity]) //way less cheap, lets see how that goes.
	{
		return other_entity;
	}
	return 0;
}

float[] CalculateDamageForce( const float vecBulletDir[3], float flScale )
{
	float vecForce[3]; vecForce = vecBulletDir;
	NormalizeVector( vecForce, vecForce );
	ScaleVector(vecForce, FindConVar("phys_pushscale").FloatValue);
	ScaleVector(vecForce, flScale);
	return vecForce;
}

float[] CalculateDamageForceSelfCalculated(int client, float flScale )
{
	float vecSwingForward[3];
	float ang[3];
	GetClientEyeAngles(client, ang);
	
	GetAngleVectors(ang, vecSwingForward, NULL_VECTOR, NULL_VECTOR);
	
	return CalculateDamageForce(vecSwingForward, flScale);
}

float ImpulseScale( float flTargetMass, float flDesiredSpeed )
{
	return (flTargetMass * flDesiredSpeed);
}
/*
float[] CalculateExplosiveDamageForce( const float vecForceOrigin[3],const float vecDir[3], float flScale )
{
	info->SetDamagePosition( vecForceOrigin );

	float flClampForce = ImpulseScale( 75, 400 );

	// Calculate an impulse large enough to push a 75kg man 4 in/sec per point of damage
	float flForceScale = info->GetBaseDamage() * ImpulseScale( 75, 4 );

	if( flForceScale > flClampForce )
		flForceScale = flClampForce;

	// Fudge blast forces a little bit, so that each
	// victim gets a slightly different trajectory. 
	// This simulates features that usually vary from
	// person-to-person variables such as bodyweight,
	// which are all indentical for characters using the same model.
	flForceScale *= random->RandomFloat( 0.85, 1.15 );

	// Calculate the vector and stuff it into the takedamageinfo
	Vector vecForce = vecDir;
	VectorNormalize( vecForce );
	vecForce *= flForceScale;
	vecForce *= phys_pushscale.GetFloat();
	vecForce *= flScale;
	info->SetDamageForce( vecForce );
}*/
#define INNER_RADIUS_FRACTION 0.25

float[] CalculateExplosiveDamageForce(const float vec_Explosive[3], const float vecEndPosition[3], float damage_Radius)
{
	float flClampForce = ImpulseScale( 75.0, 400.0 );

	// Calculate an impulse large enough to push a 75kg man 4 in/sec per point of damage
	float flForceScale = 100.0 * ImpulseScale( 75.0, 4.0 );

	if( flForceScale > flClampForce )
		flForceScale = flClampForce;

	// Fudge blast forces a little bit, so that each
	// victim gets a slightly different trajectory. 
	// This simulates features that usually vary from
	// person-to-person variables such as bodyweight,
	// which are all indentical for characters using the same model.
	flForceScale *= GetRandomFloat( 0.85, 1.15 );
	
	float vecSegment[3];
	float Ignore[3];
	SubtractVectors( vec_Explosive, vecEndPosition, vecSegment ); 
	float flDistance;
	
	flDistance = NormalizeVector( vecSegment, Ignore );
		
	float flFactor = 1.0 / ( damage_Radius * (INNER_RADIUS_FRACTION - 1.0) );
	float flFactor_Post = flFactor * flFactor;
	float flScale = flDistance - damage_Radius;
	float flScale_Post = flScale * flScale * flFactor_Post;
	
	if ( flScale_Post > 1.0 ) 
	{ 
		flScale_Post = 1.0; 
	}
	else if ( flScale_Post < 0.35 ) 
	{ 
		flScale_Post = 0.35; 
	}
		
	// Calculate the vector and stuff it into the takedamageinfo
	float vecForce[3]; vecForce = vecSegment;
	NormalizeVector( vecForce, vecForce );
	ScaleVector(vecForce, flForceScale);
	ScaleVector(vecForce, FindConVar("phys_pushscale").FloatValue);
	ScaleVector(vecForce, flScale_Post);
	
	vecForce[0] *= -1.0;
	vecForce[1] *= -1.0;
	vecForce[2] *= -1.0;
	return vecForce;
}

public void Give_Assist_Points(int target, int assister)
{
	i_assist_heal_player[target] = assister;
	f_assist_heal_player_time[target] = GetGameTime() + 10.0;	
}

int CountPlayersOnRed(bool alive = false)
{
	int amount;
	for(int client=1; client<=MaxClients; client++)
	{
#if defined ZR
		if(b_HasBeenHereSinceStartOfWave[client] && IsClientInGame(client) && GetClientTeam(client)==2 && TeutonType[client] != TEUTON_WAITING && (!alive || (TeutonType[client] != TEUTON_NONE && dieingstate[client] > 0)))
#else
		if(IsClientInGame(client) && GetClientTeam(client) == 2 && (!alive || IsPlayerAlive(client)))
#endif
			amount++;
	}
	
	return amount;
	
}

int CountPlayersOnServer()
{
	int amount;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientConnected(client))
		{
			if(!IsFakeClient(client))
				amount++;
		}
	}
	
	return amount;
	
}

int HitEntitiesSphereExplosionTrace[MAXENTITIES][MAXENTITIES];

stock void Explode_Logic_Custom(float damage,
int client,
int entity,
int weapon,
float spawnLoc[3] = {0.0,0.0,0.0},
float explosionRadius = EXPLOSION_RADIUS,
float ExplosionDmgMultihitFalloff = EXPLOSION_AOE_DAMAGE_FALLOFF,
float explosion_range_dmg_falloff = EXPLOSION_RANGE_FALLOFF,
bool FromBlueNpc = false,
int maxtargetshit = 10,
bool ignite = false,
float dmg_against_entity_multiplier = 3.0,
Function FunctionToCallOnHit = INVALID_FUNCTION,
Function FunctionToCallBeforeHit = INVALID_FUNCTION)
{

	float damage_reduction = 1.0;
	if(IsValidEntity(weapon))
	{
		float value = Attributes_FindOnWeapon(client, weapon, 99, true, 1.0);//increaced blast radius attribute (Check weapon only)
		explosionRadius *= value;
	}
	//this should make explosives during raids more usefull.
#if defined ZR
	if(IsValidEntity(EntRefToEntIndex(RaidBossActive)))
	{
		damage *= 1.15;
	}
#endif
	if(!FromBlueNpc) //make sure that there even is any valid npc before we do these huge calcs.
	{ 
		if(spawnLoc[0] == 0.0)
		{
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", spawnLoc);
		}
	}
	else //only nerf blue npc radius!
	{
		explosionRadius *= 0.75;
		if(spawnLoc[0] == 0.0) //only get position if thhey got notin
		{
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", spawnLoc);
		} 
	}
	
	int damage_flags = 0;
	int custom_flags = 0;
	if((i_ExplosiveProjectileHexArray[entity] & EP_DEALS_SLASH_DAMAGE))
	{
		damage_flags |= DMG_SLASH;
	}
	else if((i_ExplosiveProjectileHexArray[entity] & EP_DEALS_CLUB_DAMAGE))
	{
		damage_flags |= DMG_CLUB;
	}
	else if((i_ExplosiveProjectileHexArray[entity] & EP_DEALS_PLASMA_DAMAGE))
	{
		damage_flags |= DMG_PLASMA;
	}
	else if((i_ExplosiveProjectileHexArray[entity] & EP_DEALS_DROWN_DAMAGE))
	{
		damage_flags |= DMG_DROWN;
	}
	else
	{
		damage_flags |= DMG_BLAST;
	}

	if((i_ExplosiveProjectileHexArray[entity] & EP_GIBS_REGARDLESS))
	{
		custom_flags |= ZR_DAMAGE_GIB_REGARDLESS;
	}
	if((i_ExplosiveProjectileHexArray[entity] & EP_IS_ICE_DAMAGE))
	{
		custom_flags |= ZR_DAMAGE_ICE;
	}
	
	if((i_ExplosiveProjectileHexArray[entity] & EP_NO_KNOCKBACK))
	{
		damage_flags |= DMG_PREVENT_PHYSICS_FORCE;
	}
	int entityToEvaluateFrom = 0;

	if(IsValidEntity(client))
	{
		entityToEvaluateFrom = client;
	}
	else
	{
		entityToEvaluateFrom = entity;
	}
	if(entityToEvaluateFrom < 1)
	{
		//something went wrong, evacuate.
		LogError("something went wrong, entity was : [%i] | Client if any: [%i]",entityToEvaluateFrom, client);
		return;
	}
	//I exploded, do custom logic additionally if neccecary.
	if(i_ProjectileExtraFunction[entity] != INVALID_FUNCTION)
	{
		Call_StartFunction(null, i_ProjectileExtraFunction[entity]);
		Call_PushCell(entity);
		Call_PushFloat(damage);
		Call_PushArray(spawnLoc, sizeof(spawnLoc));
		Call_Finish();
		//info to give:
		/*
			Who the originator is
			Whats the original damage
			where did i explode
		*/
	}
	DoExlosionTraceCheck(spawnLoc, explosionRadius, entityToEvaluateFrom);
	/*
	This trace does not filter on what is hit first, thats kinda bad, it filters by what entity number is smaller.
	solution: Trace all entities, get all their distances, and do a rating, with this we get what entity is the closest
	and then  do the rest from there
	downside: still no solution to the fucking distance checks, but it is still 10x better then doing 4k checks all the time
	*/

	//This will sort the entity in order, first entity is the first to be hit there etc.
	static float distance[MAXENTITIES];
	static float VicPos[MAXENTITIES][3];

	if(FromBlueNpc && maxtargetshit == 10) //Npcs do not have damage falloff, dodge.
	{
		maxtargetshit = 20; //we do not care.
	}
	for (int entity_traced = 0; entity_traced < MAXENTITIES; entity_traced++)
	{
		if(!HitEntitiesSphereExplosionTrace[entity_traced][entityToEvaluateFrom])
			break;
		
		VicPos[HitEntitiesSphereExplosionTrace[entity_traced][entityToEvaluateFrom]] = WorldSpaceCenter(HitEntitiesSphereExplosionTrace[entity_traced][entityToEvaluateFrom]);
		distance[HitEntitiesSphereExplosionTrace[entity_traced][entityToEvaluateFrom]] = GetVectorDistance(VicPos[HitEntitiesSphereExplosionTrace[entity_traced][entityToEvaluateFrom]], spawnLoc, true);
		//Save their distances.
	}
	//do another check, this time we only need the amount of entities we actually hit.
	//Im lazy and dumb, i dont know a better way.
	for (int repeatloop = 0; repeatloop <= maxtargetshit; repeatloop++)
	{
		int ClosestTarget;
		float ClosestDistance;
		int indexTraced;
		for (int entity_traced = 0; entity_traced < MAXENTITIES; entity_traced++)
		{
			if (HitEntitiesSphereExplosionTrace[entity_traced][entityToEvaluateFrom])
			{
				if( ClosestDistance ) 
				{
					if( distance[HitEntitiesSphereExplosionTrace[entity_traced][entityToEvaluateFrom]] < ClosestDistance ) 
					{
						indexTraced = entity_traced;
						ClosestTarget = HitEntitiesSphereExplosionTrace[entity_traced][entityToEvaluateFrom]; 
						ClosestDistance = distance[HitEntitiesSphereExplosionTrace[entity_traced][entityToEvaluateFrom]];  
					}
				} 
				else 
				{
					indexTraced = entity_traced;
					ClosestTarget = HitEntitiesSphereExplosionTrace[entity_traced][entityToEvaluateFrom]; 
					ClosestDistance = distance[HitEntitiesSphereExplosionTrace[entity_traced][entityToEvaluateFrom]];
				}	
			}
			else
			{
				break;
			}
		}
		/*
		We will filter out each entity and them damage them accordingly.
		*/
		if(IsValidEntity(ClosestTarget))
		{	
			static float vicpos[3];
			vicpos = VicPos[ClosestTarget];
			//if its a blue npc, then we want to do a trace to see if we even hit them.
			if(FromBlueNpc)
			{
				Handle trace; 
				trace = TR_TraceRayFilterEx(spawnLoc, vicpos, ( MASK_SOLID | CONTENTS_SOLID ), RayType_EndPoint, HitOnlyTargetOrWorld, ClosestTarget);
				int Traced_Target;
									
				Traced_Target = TR_GetEntityIndex(trace);
				delete trace;
									
				if(Traced_Target != ClosestTarget)
				{	
					return;
				}
			}
			if(ignite)
			{
				if(ClosestTarget > MaxClients)
				{
					NPC_Ignite(ClosestTarget, entityToEvaluateFrom, 5.0, weapon);
				}
				else
				{
					TF2_AddCondition(ClosestTarget, TFCond_Gas, 1.5);
					StartBleedingTimer_Against_Client(ClosestTarget, entityToEvaluateFrom, 4.0, 20);
				}
			}
			static float damage_1;
			damage_1 = damage;

			if(FromBlueNpc && ShouldNpcDealBonusDamage(ClosestTarget))
			{
				damage_1 *= dmg_against_entity_multiplier; //enemy is an entityt that takes bonus dmg, and i am an npc.
			}
			//against raids, any aoe ability should be better as they are usually alone or its only two.
			if(b_thisNpcIsARaid[ClosestTarget])
			{
				damage_1 *= 1.3;
			}
			damage_1 *= f_ExplodeDamageVulnerabilityNpc[ClosestTarget];
			float GetBeforeDamage;
			if(FunctionToCallBeforeHit != INVALID_FUNCTION)
			{
				Call_StartFunction(null, FunctionToCallBeforeHit);
				Call_PushCell(entityToEvaluateFrom);
				Call_PushCell(ClosestTarget);
				Call_PushFloat(damage_1 / damage_reduction);
				Call_PushCell(weapon);
				Call_Finish(GetBeforeDamage);
			}
			if(damage > 0.0)
			{
				//npcs do not take damage from drown damage, so what we will do instead
				//is to make it do slash damage, slash damage ignores most resistances like drown does.
				if(ClosestTarget > MaxClients)
				{
					if((damage_flags & DMG_DROWN))
					{
						damage_flags &= ~DMG_DROWN;
						damage_flags |= DMG_SLASH; 
					}
				}
				damage_1 += GetBeforeDamage;
				SDKHooks_TakeDamage(ClosestTarget, entityToEvaluateFrom, entityToEvaluateFrom, damage_1 / damage_reduction, damage_flags, weapon, CalculateExplosiveDamageForce(spawnLoc, vicpos, explosionRadius), vicpos, false, custom_flags);	
			}
			if(FunctionToCallOnHit != INVALID_FUNCTION)
			{
				Call_StartFunction(null, FunctionToCallOnHit);
				Call_PushCell(entityToEvaluateFrom);
				Call_PushCell(ClosestTarget);
				//do not allow division by 0
				if(damage_1 == 0.0)
					Call_PushFloat(damage_1);
				else
					Call_PushFloat(damage_1 / damage_reduction);
					
				Call_PushCell(weapon);
				Call_Finish();
			}
			//i want owner entity and hit entity
			if(!FromBlueNpc) //Npcs do not have damage falloff, dodge.
			{
				damage_reduction *= ExplosionDmgMultihitFalloff;
			}
		}
		HitEntitiesSphereExplosionTrace[indexTraced][entityToEvaluateFrom] = false; //we will need to filter them out entirely now, we did dmg, and thus, its done!

		indexTraced++;
		for(; indexTraced < MAXENTITIES; indexTraced++)
		{
			HitEntitiesSphereExplosionTrace[indexTraced - 1][entityToEvaluateFrom] = HitEntitiesSphereExplosionTrace[indexTraced][entityToEvaluateFrom];
			
			if(!HitEntitiesSphereExplosionTrace[indexTraced][entityToEvaluateFrom])
				break;
		}
	
		ClosestTarget = false;
		ClosestDistance = 0.0;
		indexTraced = 0;
	}
}

//#define PARTITION_SOLID_EDICTS        (1 << 1) /**< every edict_t that isn't SOLID_TRIGGER or SOLID_NOT (and static props) */
//#define PARTITION_TRIGGER_EDICTS      (1 << 2) /**< every edict_t that IS SOLID_TRIGGER */
//#define PARTITION_NON_STATIC_EDICTS   (1 << 5) /**< everything in solid & trigger except the static props, includes SOLID_NOTs */
//#define PARTITION_STATIC_PROPS        (1 << 7)

void DoExlosionTraceCheck(const float pos1[3], float radius, int entity)
{
	for(int i=0; i < MAXENTITIES; i++)
	{
		HitEntitiesSphereExplosionTrace[i][entity] = false;
	}
	TR_EnumerateEntitiesSphere(pos1, radius, PARTITION_NON_STATIC_EDICTS, TraceEntityEnumerator_EnumerateEntitiesInRange, entity);
	//It does all needed logic here.
}

public bool TraceEntityEnumerator_EnumerateEntitiesInRange(int entity, int filterentity)
{
	if(IsValidEnemy(filterentity, entity, true, true)) //Must detect camo.
	{
		//This will automatically take care of all the checks, very handy. force it to also target invul enemies.
		for(int i=0; i < MAXENTITIES; i++)
		{
			if(!HitEntitiesSphereExplosionTrace[i][filterentity])
			{
				HitEntitiesSphereExplosionTrace[i][filterentity] = entity;
				break;
			}
		}
	}
	//always keep going!
	return true;
}

stock void DisplayCritAboveNpc(int victim = -1, int client, bool sound, float position[3] = {0.0,0.0,0.0}, int ParticleIndex = -1)
{
	float chargerPos[3];
	if(victim != -1)
	{
		GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", chargerPos);
		if(b_BoundingBoxVariant[victim] == 1)
		{
			chargerPos[2] += 120.0;
		}
		else
		{
			chargerPos[2] += 82.0;
		}
	}
	else
	{
		chargerPos = position;
	}

	if(sound)
	{
		switch(GetRandomInt(1,5))
		{
			case 1:
			{
				EmitSoundToClient(client, "player/crit_hit.wav", _, _, 80, _, 0.8, 100);
			}
			case 2:
			{
				EmitSoundToClient(client, "player/crit_hit2.wav", _, _, 80, _, 0.8, 100);
			}
			case 3:
			{
				EmitSoundToClient(client, "player/crit_hit3.wav", _, _, 80, _, 0.8, 100);
			}
			case 4:
			{
				EmitSoundToClient(client, "player/crit_hit4.wav", _, _, 80, _, 0.8, 100);
			}
			case 5:
			{
				EmitSoundToClient(client, "player/crit_hit5.wav", _, _, 80, _, 0.8, 100);
			}
			
		}
	}
	if(ParticleIndex != -1)
	{
		TE_ParticleInt(ParticleIndex, chargerPos);
		TE_SendToClient(client);	
	}
	else
	{
		TE_ParticleInt(g_particleCritText, chargerPos);
		TE_SendToClient(client);		
	}
}

public bool HitOnlyTargetOrWorld(int entity, int contentsMask, any iExclude)
{
	if(entity == 0)
	{
		return true;
	}
	if(entity == iExclude)
	{
		return true;
	}
		
	
	return false;
}


public bool HitOnlyWorld(int entity, int contentsMask, any iExclude)
{
	if(entity == 0)
	{
		return true;
	}	
	
	return false;
}

public void CauseDamageLaterSDKHooks_Takedamage(DataPack pack)
{
	pack.Reset();
	int Victim = EntRefToEntIndex(pack.ReadCell());
	int client = EntRefToEntIndex(pack.ReadCell());
	int inflictor = EntRefToEntIndex(pack.ReadCell());
	float damage = pack.ReadFloat();
	int damage_type = pack.ReadCell();
	int weapon = EntRefToEntIndex(pack.ReadCell());
	float damage_force[3];
	damage_force[0] = pack.ReadFloat();
	damage_force[1] = pack.ReadFloat();
	damage_force[2] = pack.ReadFloat();
	float playerPos[3];
	playerPos[0] = pack.ReadFloat();
	playerPos[1] = pack.ReadFloat();
	playerPos[2] = pack.ReadFloat();
	
	if(IsValidEntity(Victim) && IsValidEntity(client) && IsValidEntity(weapon) && IsValidEntity(inflictor))
	{
		SDKHooks_TakeDamage(Victim, client, inflictor, damage, damage_type, weapon, damage_force, playerPos);
	}

//	pack.delete;
	delete pack;
}

stock void LookAtTarget(int client, int target)
{
	float angles[3];
	float clientEyes[3];
	float targetEyes[3];
	float resultant[3]; 
		
	GetClientEyePosition(client, clientEyes);
	if(target > 0 && target <= MaxClients && IsClientInGame(target))
	{
		GetClientEyePosition(target, targetEyes);
	}
	else
	{
		targetEyes = WorldSpaceCenter(target);
	}
	MakeVectorFromPoints(targetEyes, clientEyes, resultant); 
	GetVectorAngles(resultant, angles); 
	if(angles[0] >= 270){ 
		angles[0] -= 270; 
		angles[0] = (90-angles[0]); 
	}else{ 
		if(angles[0] <= 90){ 
			angles[0] *= -1; 
		} 
	} 
	angles[1] -= 180; 
	SnapEyeAngles(client, angles);
} 


int Trail_Attach(int entity, char[] trail, int alpha, float lifetime=1.0, float startwidth=22.0, float endwidth=0.0, int rendermode)
{
	int entIndex = CreateEntityByName("env_spritetrail");
	if (entIndex > 0 && IsValidEntity(entIndex))
	{
		char strTargetName[MAX_NAME_LENGTH];

		DispatchKeyValue(entity, "targetname", strTargetName);
		Format(strTargetName,sizeof(strTargetName),"trail%d",EntIndexToEntRef(entity));
		DispatchKeyValue(entity, "targetname", strTargetName);
		DispatchKeyValue(entIndex, "parentname", strTargetName);
		

		DispatchKeyValue(entIndex, "spritename", trail);
		SetEntPropFloat(entIndex, Prop_Send, "m_flTextureRes", 1.0);
			
		char sTemp[5];
		IntToString(alpha, sTemp, sizeof(sTemp));
		DispatchKeyValue(entIndex, "renderamt", sTemp);
			
		DispatchKeyValueFloat(entIndex, "lifetime", lifetime);
		DispatchKeyValueFloat(entIndex, "startwidth", startwidth);
		DispatchKeyValueFloat(entIndex, "endwidth", endwidth);
		
		IntToString(rendermode, sTemp, sizeof(sTemp));
		DispatchKeyValue(entIndex, "rendermode", sTemp);
			
		DispatchSpawn(entIndex);
		float f_origin[3];
		f_origin = GetAbsOrigin(entity);
		TeleportEntity(entIndex, f_origin, NULL_VECTOR, NULL_VECTOR);
		SetVariantString(strTargetName);
		AcceptEntityInput(entIndex, "SetParent");
		return entIndex;
	}	
	return -1;
}

stock void ConstrainDistance(const float[] startPoint, float[] endPoint, float distance, float maxDistance, bool do2)
{
	float constrainFactor = maxDistance / distance;
	endPoint[0] = ((endPoint[0] - startPoint[0]) * constrainFactor) + startPoint[0];
	endPoint[1] = ((endPoint[1] - startPoint[1]) * constrainFactor) + startPoint[1];
	if(do2)
		endPoint[2] = ((endPoint[2] - startPoint[2]) * constrainFactor) + startPoint[2];
}

public void MakeExplosionFrameLater(DataPack pack)
{
	pack.Reset();
	float vec_pos[3];
	vec_pos[0] = pack.ReadFloat();
	vec_pos[1] = pack.ReadFloat();
	vec_pos[2] = pack.ReadFloat();
	int Do_Sound = pack.ReadCell();
	
	int ent = CreateEntityByName("env_explosion");
	if(ent != -1)
	{
	//	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
		
		if(Do_Sound == 1)
		{		
			EmitAmbientSound("ambient/explosions/explode_3.wav", vec_pos, _, 75, _,0.7, GetRandomInt(75, 110));
		}
		
		DispatchKeyValueVector(ent, "origin", vec_pos);
		DispatchKeyValue(ent, "spawnflags", "581");
						
		DispatchKeyValue(ent, "rendermode", "0");
		DispatchKeyValue(ent, "fireballsprite", spirite);
										
		DispatchKeyValueFloat(ent, "DamageForce", 0.0);								
		SetEntProp(ent, Prop_Data, "m_iMagnitude", 0); 
		SetEntProp(ent, Prop_Data, "m_iRadiusOverride", 0); 
									
		DispatchSpawn(ent);
		ActivateEntity(ent);
									
		AcceptEntityInput(ent, "explode");
		AcceptEntityInput(ent, "kill");
	}		
	SpawnSmallExplosionNotRandom(vec_pos);
	delete pack;
}


stock void DHook_CreateDetour(GameData gamedata, const char[] name, DHookCallback preCallback = INVALID_FUNCTION, DHookCallback postCallback = INVALID_FUNCTION)
{
	DynamicDetour detour = DynamicDetour.FromConf(gamedata, name);
	if(detour)
	{
		if(preCallback!=INVALID_FUNCTION && !DHookEnableDetour(detour, false, preCallback))
			LogError("[Gamedata] Failed to enable pre detour: %s", name);

		if(postCallback!=INVALID_FUNCTION && !DHookEnableDetour(detour, true, postCallback))
			LogError("[Gamedata] Failed to enable post detour: %s", name);

		delete detour;
	}
	else
	{
		LogError("[Gamedata] Could not find %s", name);
	}
}

#define ANNOTATION_REFRESH_RATE 0.1
#define ANNOTATION_OFFSET 8750

stock void ShowAnnotationToPlayer(int client, float pos[3], const char[] Text, float lifetime, int follow_who)
{
	Handle event = CreateEvent("show_annotation");
	if (event == INVALID_HANDLE) return;
	
	if(follow_who != -1)
	{
		SetEventInt(event, "follow_entindex", follow_who);
	}
	SetEventFloat(event, "worldPosX", pos[0]);
	SetEventFloat(event, "worldPosY", pos[1]);
	SetEventFloat(event, "worldPosZ", pos[2]);
	SetEventFloat(event, "lifetime", lifetime);
//	SetEventInt(event, "id", annotation_id*MAXPLAYERS + client + ANNOTATION_OFFSET);
	SetEventString(event, "text", Text);
	SetEventString(event, "play_sound", "vo/null.wav");
	SetEventInt(event, "visibilityBitfield", (1 << client));
	FireEvent(event);
	
}

public void GiveCompleteInvul(int client, float time)
{
	f_ClientInvul[client] = GetGameTime() + time;
	TF2_AddCondition(client, TFCond_UberchargedCanteen, time);
	TF2_AddCondition(client, TFCond_MegaHeal, time);
}

stock int SpawnFormattedWorldText(const char[] format, float origin[3], int textSize = 10, const int colour[4] = {255,255,255,255}, int entity_parent = -1, bool rainbow = false, bool teleport = false)
{
	int worldtext = CreateEntityByName("point_worldtext");
	if(IsValidEntity(worldtext))
	{
		DispatchKeyValue(worldtext, "targetname", "rpg_fortress");
		DispatchKeyValue(worldtext, "message", format);
		char intstring[8];
		IntToString(textSize, intstring, sizeof(intstring));
		DispatchKeyValue(worldtext, "textsize", intstring);

		char sColor[32];
		Format(sColor, sizeof(sColor), " %d %d %d %d ", colour[0], colour[1], colour[2], colour[3]);
		DispatchKeyValue(worldtext,     "color", sColor);

		DispatchSpawn(worldtext);
		SetEdictFlags(worldtext, (GetEdictFlags(worldtext) & ~FL_EDICT_ALWAYS));	
		DispatchKeyValue(worldtext, "orientation", "1");
		if(rainbow)
			DispatchKeyValue(worldtext, "rainbow", "1");
		
		if(entity_parent != -1 && !teleport)
		{
			float vector[3];

			vector = GetAbsOrigin(entity_parent);
			
			vector[0] += origin[0];
			vector[1] += origin[1];
			vector[2] += origin[2];

			TeleportEntity(worldtext, vector, NULL_VECTOR, NULL_VECTOR);
			SetParent(entity_parent, worldtext, "", origin);
		}
		else
		{
			if(teleport)
			{
				DataPack pack;
				CreateDataTimer(0.1, TeleportTextTimer, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				pack.WriteCell(EntIndexToEntRef(worldtext));
				pack.WriteCell(EntIndexToEntRef(entity_parent));
				pack.WriteFloat(origin[0]);
				pack.WriteFloat(origin[1]);
				pack.WriteFloat(origin[2]);
			}
			SDKCall_SetLocalOrigin(worldtext, origin);
		}	
	}
	return worldtext;
}

public Action TeleportTextTimer(Handle timer, DataPack pack)
{
	pack.Reset();
	int text_entity = EntRefToEntIndex(pack.ReadCell());
	int parented_entity = EntRefToEntIndex(pack.ReadCell());
	float vector_offset[3];
	vector_offset[0] = pack.ReadFloat();
	vector_offset[1] = pack.ReadFloat();
	vector_offset[2] = pack.ReadFloat();
	if(IsValidEntity(text_entity) && IsValidEntity(parented_entity))
	{
		float vector[3];
		vector = GetAbsOrigin(parented_entity);
		
		vector[0] += vector_offset[0];
		vector[1] += vector_offset[1];
		vector[2] += vector_offset[2];

		SDKCall_SetLocalOrigin(text_entity,vector);
		return Plugin_Continue;
	}
	else
	{
		return Plugin_Stop;
	}
	
}


stock int SpawnSeperateCollisionBox(int entity, float Mins[3] = {-24.0,-24.0,0.0}, float Maxs[3] = {24.0,24.0,82.0})
{
	static bool precached;

	if(!precached)
	{
		precached = true;
		PrecacheModel("models/error.mdl");
	}

	float vector[3];

	vector = GetAbsOrigin(entity);

	int brush = CreateEntityByName("func_brush");
        
	if (brush != -1)
	{
		DispatchKeyValueVector(brush, "origin", vector);
		DispatchKeyValue(brush, "spawnflags", "64");
		DispatchKeyValue(brush, "targetname", "rpg_fortress");

		DispatchSpawn(brush);
		ActivateEntity(brush);    

		SetEntityModel(brush, "models/error.mdl");
	//	SetEntityModel(brush, "models/error.mdl");
		SetEntProp(brush, Prop_Send, "m_nSolidType", 2);
		SetEntityCollisionGroup(brush, 5);
							
		SetEntPropVector(brush, Prop_Send, "m_vecMinsPreScaled", Mins);
							
		SetEntPropVector(brush, Prop_Send, "m_vecMaxsPreScaled", Maxs);
			
		SetEntPropVector(brush, Prop_Send, "m_vecMins", Mins);
		SetEntPropVector(brush, Prop_Send, "m_vecMaxs", Maxs);

		CClotBody npc = view_as<CClotBody>(brush);
		npc.UpdateCollisionBox();	
            
		SetEntProp(brush, Prop_Send, "m_fEffects", GetEntProp(brush, Prop_Send, "m_fEffects") | EF_NODRAW); 
		TeleportEntity(entity, vector, NULL_VECTOR, NULL_VECTOR);
		return brush;
	} 
	else
	{
		return -1;
	}
}


//static int b_TextEntityToOwner[MAXPLAYERS];
#if defined RPG

int BrushToEntity(int brush)
{
	int entity = EntRefToEntIndex(b_BrushToOwner[brush]);
	if(IsValidEntity(entity))
	{
		return entity;
	}
	return -1;
}

stock void UpdateLevelAbovePlayerText(int client, bool deleteText = false)
{
	int textentity = EntRefToEntIndex(i_TextEntity[client][0]);
	int textentity2 = EntRefToEntIndex(i_TextEntity[client][1]);
	if(deleteText)
	{
		if(IsValidEntity(textentity))
		{
			RemoveEntity(textentity);
		}
		if(IsValidEntity(textentity2))
		{
			RemoveEntity(textentity2);
		}
	}
	if(deleteText)
		return;
		
	if(IsValidEntity(textentity))
	{
		static char buffer[128];
		if(Tier[client])
		{
			Format(buffer, sizeof(buffer), "Elite %d Level %d", Tier[client], Level[client] - GetLevelCap(Tier[client] - 1));
		}
		else
		{
			Format(buffer, sizeof(buffer), "Level %d", Level[client]);
		}
		DispatchKeyValue(textentity, "message", buffer);
	}
	else
	{
		float OffsetFromHead[3];

		OffsetFromHead[2] = 120.0;
		static char buffer[128];
		if(Tier[client])
		{
			Format(buffer, sizeof(buffer), "Elite %d Level %d", Tier[client], Level[client] - GetLevelCap(Tier[client] - 1));
		}
		else
		{
			Format(buffer, sizeof(buffer), "Level %d", Level[client]);
		}
		int textentityMade = SpawnFormattedWorldText(buffer, OffsetFromHead, 10, {255,255,255,255}, client);
		i_TextEntity[client][0] = EntIndexToEntRef(textentityMade);
	//	b_TextEntityToOwner[textentityMade] = client;
	//	SetEdictFlags(textentityMade, GetEdictFlags(textentityMade) &~ FL_EDICT_ALWAYS);
	//	SDKHook(textentityMade, SDKHook_SetTransmit, SDKHook_Settransmit_TextParentedToPlayer);
	}
	if(IsValidEntity(textentity2))
	{
		DispatchKeyValue(textentity2, "message", c_TagName[client]);
		char sColor[32];
		Format(sColor, sizeof(sColor), " %d %d %d %d ", i_TagColor[client][0], i_TagColor[client][1], i_TagColor[client][2], i_TagColor[client][3]);
		DispatchKeyValue(textentity2,     "color", sColor);
		if(i_TagColor[client][0] == 254)
		{
			DispatchKeyValue(textentity2, "rainbow", "1");
		}
		else
		{
			DispatchKeyValue(textentity2, "rainbow", "0");
		}
	}
	else
	{
		float OffsetFromHead[3];

		OffsetFromHead[2] = 110.0;
		static char buffer[128];
		Format(buffer, sizeof(buffer), c_TagName[client]);
		int textentityMade = SpawnFormattedWorldText(buffer, OffsetFromHead, 10, i_TagColor[client], client, false);
		
		if(i_TagColor[client][0] == 254)
		{
			DispatchKeyValue(textentityMade, "rainbow", "1");
		}
		else
		{
			DispatchKeyValue(textentityMade, "rainbow", "0");
		}
		
		i_TextEntity[client][1] = EntIndexToEntRef(textentityMade);
	}
}
/*
public Action SDKHook_Settransmit_TextParentedToPlayer(int entity, int client)
{
	SetEdictFlags(entity, GetEdictFlags(entity) &~ FL_EDICT_ALWAYS);
	if(client == b_TextEntityToOwner[entity])
	{
		PrintToChatAll("bruh");
		return Plugin_Handled;
	}
	PrintToChatAll("bruh1");
	return Plugin_Continue;
}
*/
#endif


stock void spawnRing_Vectors(float center[3],
 float range,
  float modif_X,
  float modif_Y,
   float modif_Z,
    char sprite[255],
	 int r,
	  int g,
	   int b,
	    int alpha,
		 int fps,
		  float life,
		   float width,
		    float amp,
			 int speed,
			  float endRange = -69.0) //Spawns a TE beam ring at a client's/entity's location
{
	float Center_Internal[3];
	Center_Internal = center;
	Center_Internal[0] += modif_X;
	Center_Internal[1] += modif_Y;
	Center_Internal[2] += modif_Z;
			
	int ICE_INT = PrecacheModel(sprite);
		
	int color[4];
	color[0] = r;
	color[1] = g;
	color[2] = b;
	color[3] = alpha;
		
	if (endRange == -69.0)
	{
		endRange = range + 0.5;
	}
	
	TE_SetupBeamRingPoint(Center_Internal, range, endRange, ICE_INT, ICE_INT, 0, fps, life, width, amp, color, speed, 0);
	TE_SendToAll();
}

stock char[] CharInt(int value)
{
	static char buffer[16];
	IntToString(value, buffer, sizeof(buffer));
	if(value > 0)
	{
		for(int i = sizeof(buffer) - 1; i > 0; i--)
		{
			buffer[i] = buffer[i-1];
		}

		buffer[0] = '+';
	}
	return buffer;
}

stock char[] CharPercent(float value)
{
	static char buffer[16];
	if(value < 1.0)
	{
		Format(buffer, sizeof(buffer), "%d%%", 100 - RoundFloat((1.0 / value) * 100.0));
	}
	else
	{
		Format(buffer, sizeof(buffer), "+%d%%", RoundFloat((value - 1.0) * 100.0));
	}
	return buffer;
} 

#if defined ZR

stock bool AmmoBlacklist(int Ammotype)
{
	if(Ammotype == -1 || Ammotype >= Ammo_Hand_Grenade)
	{
		return false;
	}
	return true;
} 


#endif

stock void GetBeamDrawStartPoint_Stock(int client, float startPoint[3], float Beamoffset[3] = {0.0,0.0,0.0})
{
	GetClientEyePosition(client, startPoint);
	float angles[3];
	GetClientEyeAngles(client, angles);
	startPoint[2] -= 25.0;
	if (0.0 == Beamoffset[0] && 0.0 == Beamoffset[1] && 0.0 == Beamoffset[2])
	{
		return;
	}
	float tmp[3];
	float actualBeamOffset[3];
	tmp[0] = Beamoffset[0];
	tmp[1] = Beamoffset[1];
	tmp[2] = 0.0;
	VectorRotate(tmp, angles, actualBeamOffset);
	actualBeamOffset[2] = Beamoffset[2];
	startPoint[0] += actualBeamOffset[0];
	startPoint[1] += actualBeamOffset[1];
	startPoint[2] += actualBeamOffset[2];
}

// Thank you miku:)
// https://github.com/Mikusch/PropHunt/blob/985808f13d8738945a2c9980db0b75865a20c99c/addons/sourcemod/scripting/prophunt.sp#L332

#if defined ZR
static bool HazardResult;

bool IsPointHazard(const float pos1[3])
{
	HazardResult = false;
	TR_EnumerateEntities(pos1, pos1, PARTITION_TRIGGER_EDICTS, RayType_EndPoint, TraceEntityEnumerator_EnumerateTriggers);
	return HazardResult;
}
public bool TraceEntityEnumerator_EnumerateTriggers(int entity, int client)
{
	char classname[16];
	if(GetEntityClassname(entity, classname, sizeof(classname)) && !StrContains(classname, "trigger_hurt"))
	{
		if(!GetEntProp(entity, Prop_Data, "m_bDisabled"))
		{
			Handle trace = TR_ClipCurrentRayToEntityEx(MASK_ALL, entity);
			bool didHit = TR_DidHit(trace);
			delete trace;
			
			if (didHit)
			{
				HazardResult = true;
				return false;
			}
		}
	}
	
	return true;
}

bool IsPointNoBuild(const float pos1[3])
{
	HazardResult = false;
	TR_EnumerateEntities(pos1, pos1, PARTITION_TRIGGER_EDICTS, RayType_EndPoint, TraceEntityEnumerator_EnumerateTriggers_noBuilds);
	return HazardResult;
}

public bool TraceEntityEnumerator_EnumerateTriggers_noBuilds(int entity, int client)
{
	char classname[16];
	if(GetEntityClassname(entity, classname, sizeof(classname)) && (!StrContains(classname, "trigger_hurt") ||!StrContains(classname, "func_nobuild")))
	{
		if(!GetEntProp(entity, Prop_Data, "m_bDisabled"))
		{
			Handle trace = TR_ClipCurrentRayToEntityEx(MASK_ALL, entity);
			bool didHit = TR_DidHit(trace);
			delete trace;
			
			if (didHit)
			{
				HazardResult = true;
				return false;
			}
		}
	}
	
	return true;
}
#endif	// ZR

stock void SetDefaultHudPosition(int client, int red = 34, int green = 139, int blue = 34, float duration = 1.01)
{

	float HudY = 0.75;
	float HudX = -1.0;
	HudX += f_NotifHudOffsetY[client];
	HudY += f_NotifHudOffsetX[client];
	SetHudTextParams(HudX, HudY, duration, red, green, blue, 255);
}

stock void ApplyTempAttrib(int entity, int index, float multi, float duration = 0.3)
{
	if(Attributes_Has(entity,index))
	{
		Attributes_SetMulti(entity, index, multi);
		//Attributes_Get(weapon, 466, 1.0);

		DataPack pack;
		CreateDataTimer(duration, StreetFighter_RestoreAttrib, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(EntIndexToEntRef(entity));
		pack.WriteCell(index);
		pack.WriteFloat(multi);
	}
}

/*
	float damage = 65.0;
	
	damage *= Attributes_Get(weapon, 1, 1.0);

	damage *= Attributes_Get(weapon, 2, 1.0);
			
	float speed = 1100.0;
	speed *= Attributes_Get(weapon, 103, 1.0);
	
	speed *= Attributes_Get(weapon, 104, 1.0);
	
	speed *= Attributes_Get(weapon, 475, 1.0);
	
	float time = 500.0 / speed;
	time *= Attributes_Get(weapon, 101, 1.0);
	
	time *= Attributes_Get(weapon, 102, 1.0);
	*/
public Action StreetFighter_RestoreAttrib(Handle timer, DataPack pack)
{
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
	if(entity != INVALID_ENT_REFERENCE)
	{
		int index = pack.ReadCell();
		Attributes_SetMulti(entity, index, 1.0 / pack.ReadFloat());
	}
	return Plugin_Stop;
}
/*
void PlayFakeDeathSound(int client)
{
	int victim;
	for(int bot=1; bot<MaxClients; bot++)
	{
		if(IsValidClient(bot) && b_IsPlayerABot[bot])
		{
			victim = bot;
			break;
		}
	}
	if(victim == 0)
	{
		return;
	}
	PrintToChatAll("%i",victim);

	Event event = CreateEvent("player_hurt", true);
	event.SetInt("userid", GetClientUserId(victim));
	event.SetInt("health", -25);
	event.SetInt("attacker", GetClientUserId(client));
	event.SetInt("damageamount", 99);
	event.SetBool("crit", false);
	event.FireToClient(client);
	delete event;
}
*/

stock bool ShouldNpcDealBonusDamage(int entity, int attacker = -1)
{
	if(entity < 1)
	{
		return false;
	}
	if(i_NpcIsABuilding[entity])
	{
		return true;
	}
	return i_IsABuilding[entity];
}

stock int ConnectWithBeamClient(int iEnt, int iEnt2, int iRed=255, int iGreen=255, int iBlue=255,
							float fStartWidth=0.8, float fEndWidth=0.8, float fAmp=1.35, char[] Model = "sprites/laserbeam.vmt")
{
	int iBeam = CreateEntityByName("env_beam");
	if(iBeam <= MaxClients)
		return -1;

	if(!IsValidEntity(iBeam))
		return -1;

	SetEntityModel(iBeam, Model);
	char sColor[16];
	Format(sColor, sizeof(sColor), "%d %d %d", iRed, iGreen, iBlue);

	DispatchKeyValue(iBeam, "rendercolor", sColor);
	DispatchKeyValue(iBeam, "life", "0");

	DispatchSpawn(iBeam);

	SetEntPropEnt(iBeam, Prop_Send, "m_hAttachEntity", EntIndexToEntRef(iEnt));

	SetEntPropEnt(iBeam, Prop_Send, "m_hAttachEntity", EntIndexToEntRef(iEnt2), 1);

	SetEntProp(iBeam, Prop_Send, "m_nNumBeamEnts", 2);
	SetEntProp(iBeam, Prop_Send, "m_nBeamType", 2);

	SetEntPropFloat(iBeam, Prop_Data, "m_fWidth", fStartWidth);
	SetEntPropFloat(iBeam, Prop_Data, "m_fEndWidth", fEndWidth);

	SetEntPropFloat(iBeam, Prop_Data, "m_fAmplitude", fAmp);

	SetVariantFloat(32.0);
	AcceptEntityInput(iBeam, "Amplitude");
	AcceptEntityInput(iBeam, "TurnOn");

	SetVariantInt(0);
	AcceptEntityInput(iBeam, "TouchType");
	//its delayed by a frame to avoid it not rendering at all.
//	RequestFrames(ApplyBeamThinkRemoval, 15, EntIndexToEntRef(iBeam));

	return iBeam;
}

#if defined ZR
//bool identified if it went above max health or not.

//No need to delele it, its just 1 ho difference, wow so huge.
int HealEntityViaFloat(int entity, float healing_Amount, float MaxHealthOverMulti = 1.0)
{
//	bool isNotClient = false;
	int flHealth = GetEntProp(entity, Prop_Data, "m_iHealth");
	int flMaxHealth;
	if(entity > MaxClients)
	{
		flMaxHealth = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
	}
	else
	{
		flMaxHealth = SDKCall_GetMaxHealth(entity);
	}

	int i_TargetHealAmount; //Health to actaully apply

	if (healing_Amount <= 1.0)
	{
		f_IncrementalSmallHeal[entity] += healing_Amount;
			
		if(f_IncrementalSmallHeal[entity] >= 1.0)
		{
			f_IncrementalSmallHeal[entity] -= 1.0;
			i_TargetHealAmount = 1;
		}
	}
	else
	{
		i_TargetHealAmount = RoundToFloor(healing_Amount);
							
		float Decimal_healing = FloatFraction(healing_Amount);
							
							
		f_IncrementalSmallHeal[entity] += Decimal_healing;
							
		while(f_IncrementalSmallHeal[entity] >= 1.0)
		{
			f_IncrementalSmallHeal[entity] -= 1.0;
			i_TargetHealAmount += 1;
		}
	}
	int newHealth = flHealth + i_TargetHealAmount;
	int HealAmount = 0;
	int MaxHeal = RoundToNearest(float(flMaxHealth) * MaxHealthOverMulti);
	if(MaxHeal >= newHealth) //allow 1 tick of overheal.
	{
		if(newHealth >= MaxHeal)
		{
			SetEntProp(entity, Prop_Data, "m_iHealth", MaxHeal);
			newHealth = MaxHeal;
		}
		else
		{
			SetEntProp(entity, Prop_Data, "m_iHealth", newHealth);
		}
		
		HealAmount = newHealth - flHealth;
	}
	return HealAmount;
}

static const char g_ScoutDownedResponse[][] = {
	"vo/scout_paincrticialdeath01.mp3",
	"vo/scout_paincrticialdeath02.mp3",
	"vo/scout_paincrticialdeath03.mp3",
};

static const char g_SoldierDownedResponse[][] = {
	"vo/soldier_paincrticialdeath01.mp3",
	"vo/soldier_paincrticialdeath02.mp3",
	"vo/soldier_paincrticialdeath03.mp3",
	"vo/soldier_paincrticialdeath04.mp3",
};

static const char g_SniperDownedResponse[][] = {
	"vo/sniper_paincrticialdeath01.mp3",
	"vo/sniper_paincrticialdeath02.mp3",
	"vo/sniper_paincrticialdeath03.mp3",
	"vo/sniper_paincrticialdeath04.mp3",
};

static const char g_DemomanDownedResponse[][] = {
	"vo/demoman_paincrticialdeath01.mp3",
	"vo/demoman_paincrticialdeath02.mp3",
	"vo/demoman_paincrticialdeath03.mp3",
	"vo/demoman_paincrticialdeath04.mp3",
	"vo/demoman_paincrticialdeath05.mp3",
};

static const char g_MedicDownedResponse[][] = {
	"vo/medic_paincrticialdeath01.mp3",
	"vo/medic_paincrticialdeath02.mp3",
	"vo/medic_paincrticialdeath03.mp3",
	"vo/medic_paincrticialdeath04.mp3",
};

static const char g_PyroDownedResponse[][] = {
	"vo/pyro_paincrticialdeath01.mp3",
	"vo/pyro_paincrticialdeath02.mp3",
	"vo/pyro_paincrticialdeath03.mp3",
};
static const char g_HeavyDownedResponse[][] = {
	"vo/heavy_paincrticialdeath01.mp3",
	"vo/heavy_paincrticialdeath02.mp3",
	"vo/heavy_paincrticialdeath03.mp3",
};

static const char g_SpyDownedResponse[][] = {
	"vo/spy_paincrticialdeath01.mp3",
	"vo/spy_paincrticialdeath02.mp3",
	"vo/spy_paincrticialdeath03.mp3",
};

static const char g_EngineerDownedResponse[][] = {
	"vo/engineer_paincrticialdeath01.mp3",
	"vo/engineer_paincrticialdeath02.mp3",
	"vo/engineer_paincrticialdeath03.mp3",
	"vo/engineer_paincrticialdeath04.mp3",
	"vo/engineer_paincrticialdeath05.mp3",
	"vo/engineer_paincrticialdeath06.mp3",
};

//revive!

static const char g_ScoutReviveResponse[][] = {
	"vo/scout_mvm_resurrect01.mp3",
	"vo/scout_mvm_resurrect02.mp3",
	"vo/scout_mvm_resurrect03.mp3",
	"vo/scout_mvm_resurrect04.mp3",
	"vo/scout_mvm_resurrect05.mp3",
	"vo/scout_mvm_resurrect06.mp3",
	"vo/scout_mvm_resurrect07.mp3",
	"vo/scout_mvm_resurrect08.mp3",
};

static const char g_SoldierReviveResponse[][] = {
	"vo/soldier_mvm_resurrect01.mp3",
	"vo/soldier_mvm_resurrect02.mp3",
	"vo/soldier_mvm_resurrect03.mp3",
	"vo/soldier_mvm_resurrect04.mp3",
	"vo/soldier_mvm_resurrect05.mp3",
	"vo/soldier_mvm_resurrect06.mp3",
};

static const char g_SniperReviveResponse[][] = {
	"vo/sniper_mvm_resurrect01.mp3",
	"vo/sniper_mvm_resurrect02.mp3",
	"vo/sniper_mvm_resurrect03.mp3",
	"vo/sniper_mvm_resurrect04.mp3",
};

static const char g_DemomanReviveResponse[][] = {
	"vo/demoman_mvm_resurrect01.mp3",
	"vo/demoman_mvm_resurrect02.mp3",
	"vo/demoman_mvm_resurrect03.mp3",
	"vo/demoman_mvm_resurrect04.mp3",
	"vo/demoman_mvm_resurrect05.mp3",
	"vo/demoman_mvm_resurrect06.mp3",
	"vo/demoman_mvm_resurrect07.mp3",
	"vo/demoman_mvm_resurrect08.mp3",
	"vo/demoman_mvm_resurrect09.mp3",
	"vo/demoman_mvm_resurrect10.mp3",
	"vo/demoman_mvm_resurrect11.mp3",
};

static const char g_MedicReviveResponse[][] = {
	"vo/medic_mvm_resurrect01.mp3",
	"vo/medic_mvm_resurrect02.mp3",
	"vo/medic_mvm_resurrect03.mp3",
};

static const char g_PyroReviveResponse[][] = {
	"vo/pyro_laughhappy01.mp3",
};
static const char g_HeavyReviveResponse[][] = {
	"vo/heavy_mvm_resurrect01.mp3",
	"vo/heavy_mvm_resurrect02.mp3",
	"vo/heavy_mvm_resurrect03.mp3",
	"vo/heavy_mvm_resurrect04.mp3",
	"vo/heavy_mvm_resurrect05.mp3",
	"vo/heavy_mvm_resurrect06.mp3",
	"vo/heavy_mvm_resurrect07.mp3",
};

static const char g_SpyReviveResponse[][] = {
	"vo/spy_mvm_resurrect01.mp3",
	"vo/spy_mvm_resurrect02.mp3",
	"vo/spy_mvm_resurrect03.mp3",
	"vo/spy_mvm_resurrect04.mp3",
	"vo/spy_mvm_resurrect05.mp3",
	"vo/spy_mvm_resurrect06.mp3",
	"vo/spy_mvm_resurrect07.mp3",
	"vo/spy_mvm_resurrect08.mp3",
	"vo/spy_mvm_resurrect09.mp3",
};

static const char g_EngineerReviveResponse[][] = {
	"vo/engineer_mvm_resurrect01.mp3",
	"vo/engineer_mvm_resurrect02.mp3",
	"vo/engineer_mvm_resurrect03.mp3",
};


//Saga Ability!

static const char g_ScoutSagaResponse[][] = {
	"vo/scout_stunballhit01.mp3",
	"vo/scout_stunballhit02.mp3",
	"vo/scout_stunballhit04.mp3",
	"vo/scout_stunballhit05.mp3",
	"vo/scout_stunballhit07.mp3",
	"vo/scout_stunballhit09.mp3",
	"vo/scout_stunballhit11.mp3",
	"vo/scout_stunballhit12.mp3",
	"vo/scout_stunballhit15.mp3",
};

static const char g_SoldierSagaResponse[][] = {
	"vo/taunts/soldier_taunts14.mp3",
	"vo/taunts/soldier_taunts17.mp3",
	"vo/soldier_specialcompleted02.mp3",
	"vo/soldier_specialcompleted05.mp3",
};

static const char g_SniperSagaResponse[][] = {
	"vo/sniper_battlecry03.mp3",
	"vo/sniper_cheers08.mp3",
	"vo/sniper_cheers02.mp3",
	"vo/sniper_cheers03.mp3",
	"vo/sniper_cheers01.mp3",
};

static const char g_DemomanSagaResponse[][] = {
	"vo/demoman_battlecry01.mp3",
	"vo/demoman_battlecry03.mp3",
	"vo/demoman_battlecry04.mp3",
	"vo/demoman_battlecry07.mp3",
};

static const char g_MedicSagaResponse[][] = {
	"vo/medic_battlecry04.mp3",
	"vo/medic_battlecry05.mp3",
	"vo/medic_battlecry02.mp3",
};

static const char g_PyroSagaResponse[][] = {
	"vo/pyro_battlecry01.mp3",
	"vo/pyro_battlecry02.mp3",
};
static const char g_HeavySagaResponse[][] = {
	"vo/heavy_battlecry06.mp3",
	"vo/heavy_battlecry05.mp3",
	"vo/heavy_battlecry04.mp3",
	"vo/heavy_battlecry03.mp3",
	"vo/heavy_battlecry01.mp3",
};

static const char g_SpySagaResponse[][] = {
	"vo/spy_stabtaunt04.mp3",
	"vo/spy_stabtaunt05.mp3",
	"vo/spy_stabtaunt06.mp3",
	"vo/spy_stabtaunt08.mp3",
	"vo/spy_stabtaunt12.mp3",
	"vo/spy_stabtaunt12.mp3",
};

static const char g_EngineerSagaResponse[][] = {
	"vo/engineer_battlecry01.mp3",
	"vo/engineer_battlecry03.mp3",
	"vo/engineer_battlecry04.mp3",
};


#define VOICERESPONSESOUNDAREA 90
void PrecachePlayerGiveGiveResponseVoice()
{
	PrecacheSound("vo/taunts/scout_taunts06.mp3");
	PrecacheSound("vo/taunts/soldier_taunts17.mp3");
	PrecacheSound("vo/taunts/sniper_taunts22.mp3");
	PrecacheSound("vo/taunts/demoman_taunts11.mp3");
	PrecacheSound("vo/taunts/medic_taunts13.mp3");
	PrecacheSound("vo/pyro_laughevil01.mp3");
	PrecacheSound("vo/taunts/heavy_taunts16.mp3");
	PrecacheSound("vo/taunts/spy_taunts12.mp3");
	PrecacheSound("vo/taunts/engineer_taunts04.mp3");

	for (int i = 0; i < (sizeof(g_ScoutDownedResponse));	   i++) { PrecacheSound(g_ScoutDownedResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_SoldierDownedResponse));	   i++) { PrecacheSound(g_SoldierDownedResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_SniperDownedResponse));	   i++) { PrecacheSound(g_SniperDownedResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_DemomanDownedResponse));	   i++) { PrecacheSound(g_DemomanDownedResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_PyroDownedResponse));	   i++) { PrecacheSound(g_PyroDownedResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_HeavyDownedResponse));	   i++) { PrecacheSound(g_HeavyDownedResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_SpyDownedResponse));	   i++) { PrecacheSound(g_SpyDownedResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_EngineerDownedResponse));	   i++) { PrecacheSound(g_EngineerDownedResponse[i]);	   }


	for (int i = 0; i < (sizeof(g_ScoutReviveResponse));	   i++) { PrecacheSound(g_ScoutReviveResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_SoldierReviveResponse));	   i++) { PrecacheSound(g_SoldierReviveResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_SniperReviveResponse));	   i++) { PrecacheSound(g_SniperReviveResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_DemomanReviveResponse));	   i++) { PrecacheSound(g_DemomanReviveResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_PyroReviveResponse));	   i++) { PrecacheSound(g_PyroReviveResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_HeavyReviveResponse));	   i++) { PrecacheSound(g_HeavyReviveResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_SpyReviveResponse));	   i++) { PrecacheSound(g_SpyReviveResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_EngineerReviveResponse));	   i++) { PrecacheSound(g_EngineerReviveResponse[i]);	   }


	for (int i = 0; i < (sizeof(g_ScoutSagaResponse));	   i++) { PrecacheSound(g_ScoutSagaResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_SoldierSagaResponse));	   i++) { PrecacheSound(g_SoldierSagaResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_SniperSagaResponse));	   i++) { PrecacheSound(g_SniperSagaResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_DemomanSagaResponse));	   i++) { PrecacheSound(g_DemomanSagaResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_PyroSagaResponse));	   i++) { PrecacheSound(g_PyroSagaResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_HeavySagaResponse));	   i++) { PrecacheSound(g_HeavySagaResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_SpySagaResponse));	   i++) { PrecacheSound(g_SpySagaResponse[i]);	   }
	for (int i = 0; i < (sizeof(g_EngineerSagaResponse));	   i++) { PrecacheSound(g_EngineerSagaResponse[i]);	   }
}


void MakePlayerGiveResponseVoice(int client, int status)
{
	if(b_IsPlayerNiko[client])
		return;
	
	int ClassShown = view_as<int>(CurrentClass[client]);

	switch(status)
	{	
		case 1: //Irene cocky talk
		{
			switch(ClassShown)
			{
				case 1:
				{
					EmitSoundToAll("vo/taunts/scout_taunts06.mp3", client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 2:
				{
					EmitSoundToAll("vo/taunts/sniper_taunts22.mp3", client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 3:
				{
					EmitSoundToAll("vo/taunts/soldier_taunts17.mp3", client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 4:
				{
					EmitSoundToAll("vo/taunts/demoman_taunts11.mp3", client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 5:
				{
					EmitSoundToAll("vo/taunts/medic_taunts13.mp3", client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 6:
				{
					EmitSoundToAll("vo/taunts/heavy_taunts16.mp3", client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 7:
				{
					EmitSoundToAll("vo/pyro_laughevil01.mp3", client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 8:
				{
					EmitSoundToAll("vo/taunts/spy_taunts12.mp3", client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 9:
				{
					EmitSoundToAll("vo/taunts/engineer_taunts04.mp3", client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
			}
		}
		case 2: //downed, help!
		{
			switch(ClassShown)
			{
				case 1:
				{
					EmitSoundToAll(g_ScoutDownedResponse[GetRandomInt(0, sizeof(g_ScoutDownedResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 2:
				{
					EmitSoundToAll(g_SniperDownedResponse[GetRandomInt(0, sizeof(g_SniperDownedResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 3:
				{
					EmitSoundToAll(g_SoldierDownedResponse[GetRandomInt(0, sizeof(g_SoldierDownedResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 4:
				{
					EmitSoundToAll(g_DemomanDownedResponse[GetRandomInt(0, sizeof(g_DemomanDownedResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 5:
				{
					EmitSoundToAll(g_MedicDownedResponse[GetRandomInt(0, sizeof(g_MedicDownedResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 6:
				{
					EmitSoundToAll(g_HeavyDownedResponse[GetRandomInt(0, sizeof(g_HeavyDownedResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 7:
				{
					EmitSoundToAll(g_PyroDownedResponse[GetRandomInt(0, sizeof(g_PyroDownedResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 8:
				{
					EmitSoundToAll(g_SpyDownedResponse[GetRandomInt(0, sizeof(g_SpyDownedResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 9:
				{
					EmitSoundToAll(g_EngineerDownedResponse[GetRandomInt(0, sizeof(g_EngineerDownedResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
			}
		}
		case 3: //back from the dead!
		{
			switch(ClassShown)
			{
				case 1:
				{
					EmitSoundToAll(g_ScoutReviveResponse[GetRandomInt(0, sizeof(g_ScoutReviveResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 2:
				{
					EmitSoundToAll(g_SniperReviveResponse[GetRandomInt(0, sizeof(g_SniperReviveResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 3:
				{
					EmitSoundToAll(g_SoldierReviveResponse[GetRandomInt(0, sizeof(g_SoldierReviveResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 4:
				{
					EmitSoundToAll(g_DemomanReviveResponse[GetRandomInt(0, sizeof(g_DemomanReviveResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 5:
				{
					EmitSoundToAll(g_MedicReviveResponse[GetRandomInt(0, sizeof(g_MedicReviveResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 6:
				{
					EmitSoundToAll(g_HeavyReviveResponse[GetRandomInt(0, sizeof(g_HeavyReviveResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 7:
				{
					EmitSoundToAll(g_PyroReviveResponse[GetRandomInt(0, sizeof(g_PyroReviveResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 8:
				{
					EmitSoundToAll(g_SpyReviveResponse[GetRandomInt(0, sizeof(g_SpyReviveResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 9:
				{
					EmitSoundToAll(g_EngineerReviveResponse[GetRandomInt(0, sizeof(g_EngineerReviveResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
			}
		}
		case 4: //Saga Scream!
		{
			switch(ClassShown)
			{
				case 1:
				{
					EmitSoundToAll(g_ScoutSagaResponse[GetRandomInt(0, sizeof(g_ScoutSagaResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 2:
				{
					EmitSoundToAll(g_SniperSagaResponse[GetRandomInt(0, sizeof(g_SniperSagaResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 3:
				{
					EmitSoundToAll(g_SoldierSagaResponse[GetRandomInt(0, sizeof(g_SoldierSagaResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 4:
				{
					EmitSoundToAll(g_DemomanSagaResponse[GetRandomInt(0, sizeof(g_DemomanSagaResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 5:
				{
					EmitSoundToAll(g_MedicSagaResponse[GetRandomInt(0, sizeof(g_MedicSagaResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 6:
				{
					EmitSoundToAll(g_HeavySagaResponse[GetRandomInt(0, sizeof(g_HeavySagaResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 7:
				{
					EmitSoundToAll(g_PyroSagaResponse[GetRandomInt(0, sizeof(g_PyroSagaResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 8:
				{
					EmitSoundToAll(g_SpySagaResponse[GetRandomInt(0, sizeof(g_SpySagaResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
				case 9:
				{
					EmitSoundToAll(g_EngineerSagaResponse[GetRandomInt(0, sizeof(g_EngineerSagaResponse) - 1)], client, SNDCHAN_VOICE, VOICERESPONSESOUNDAREA, _, 1.0);
				}
			}
		}
	}
}

void KillDyingGlowEffect(int client)
{
	int entity = EntRefToEntIndex(i_DyingParticleIndication[client][0]);
	if(entity > MaxClients)
		RemoveEntity(entity);

	entity = EntRefToEntIndex(i_DyingParticleIndication[client][1]);
	if(entity > MaxClients)
		RemoveEntity(entity);
}
#endif	// ZR

enum g_Collision_Group
{
    COLLISION_GROUP_NONE  = 0,
    COLLISION_GROUP_DEBRIS,            // Collides with nothing but world and static stuff
    COLLISION_GROUP_DEBRIS_TRIGGER,        // Same as debris, but hits triggers
    COLLISION_GROUP_INTERACTIVE_DEBRIS,    // Collides with everything except other interactive debris or debris
    COLLISION_GROUP_INTERACTIVE,        // Collides with everything except interactive debris or debris    Can be hit by bullets, explosions, players, projectiles, melee
    COLLISION_GROUP_PLAYER,            // Can be hit by bullets, explosions, players, projectiles, melee
    COLLISION_GROUP_BREAKABLE_GLASS,
    COLLISION_GROUP_VEHICLE,
    COLLISION_GROUP_PLAYER_MOVEMENT,    // For HL2, same as Collision_Group_Player, for TF2, this filters out other players and CBaseObjects

    COLLISION_GROUP_NPC,        // Generic NPC group
    COLLISION_GROUP_IN_VEHICLE,    // for any entity inside a vehicle    Can be hit by explosions. Melee unknown.
    COLLISION_GROUP_WEAPON,        // for any weapons that need collision detection
    COLLISION_GROUP_VEHICLE_CLIP,    // vehicle clip brush to restrict vehicle movement
    COLLISION_GROUP_PROJECTILE,    // Projectiles!
    COLLISION_GROUP_DOOR_BLOCKER,    // Blocks entities not permitted to get near moving doors
    COLLISION_GROUP_PASSABLE_DOOR,    // ** sarysa TF2 note: Must be scripted, not passable on physics prop (Doors that the player shouldn't collide with)
    COLLISION_GROUP_DISSOLVING,    // Things that are dissolving are in this group
    COLLISION_GROUP_PUSHAWAY,    // ** sarysa TF2 note: I could swear the collision detection is better for this than NONE. (Nonsolid on client and server, pushaway in player code) // Can be hit by bullets, explosions, projectiles, melee
    COLLISION_GROUP_NPC_ACTOR,        // Used so NPCs in scripts ignore the player.
    COLLISION_GROUP_NPC_SCRIPTED = 19,    // Used for NPCs in scripts that should not collide with each other.

    LAST_SHARED_COLLISION_GROUP,

    TF_COLLISIONGROUP_GRENADE = 20,
    TFCOLLISION_GROUP_OBJECT,
    TFCOLLISION_GROUP_OBJECT_SOLIDTOPLAYERMOVEMENT,
    TFCOLLISION_GROUP_COMBATOBJECT,
    TFCOLLISION_GROUP_ROCKETS,        // Solid to players, but not player movement. ensures touch calls are originating from rocket
    TFCOLLISION_GROUP_RESPAWNROOMS,
    TFCOLLISION_GROUP_TANK,
    TFCOLLISION_GROUP_ROCKET_BUT_NOT_WITH_OTHER_ROCKETS
	
};

float f_HitmarkerSameFrame[MAXTF2PLAYERS];

void DoClientHitmarker(int client)
{
	if(b_HudHitMarker[client] && f_HitmarkerSameFrame[client] != GetGameTime())
	{
		EmitCustomToClient(client, "zombiesurvival/hm.mp3", _, _, 90, _, 0.75, 100);
		SetHudTextParams(-1.0, -1.0, 0.01, 125, 125, 125, 65);
		ShowHudText(client, 10, "X"); //we use 10
		f_HitmarkerSameFrame[client] = GetGameTime();	
	}
}


/*
	taken from 
	https://github.com/Daisreich/customguns-tf/blob/4b7b0eed2b2847052e11e7cb015b4ad05df5b2d6/scripting/include/customguns/stocks.inc#L503

*/

stock void UTIL_ImpactTrace(int  client , const float start[3], int iDamageType, const char[] pCustomImpactName = "Impact")
{
	if(TR_GetEntityIndex() == -1 || TR_GetFraction() == 1.0)
	{ 
		//+check sky
		return;
	}
	float origin[3]; TR_GetEndPosition(origin);

	TE_SetupEffectDispatch(origin, start, NULL_VECTOR, NULL_VECTOR, 0, 0.0, 1.0, 0, 0,
		getEffectDispatchStringTableIndex(pCustomImpactName), 0, iDamageType, TR_GetHitGroup(), TR_GetEntityIndex(), 0, 0.0, false,
		NULL_VECTOR, NULL_VECTOR, false, 0, NULL_VECTOR);
	TE_SendToAll();
}


stock void TE_SetupEffectDispatch(const float origin[3], const float start[3], const float angles[3], const float normal[3],
	int flags, float magnitude, float scale, int attachmentIndex, int surfaceProp, int effectName, int material, int damageType,
	int hitbox, int entindex, int color, float radius, bool customColors, const float customColor1[3], const float customColor2[3],
	bool controlPoint1, int cp1ParticleAttachment, const float cp1Offset[3])
{
	TE_Start("EffectDispatch");
	TE_WriteFloat("m_vOrigin[0]", origin[0]);
	TE_WriteFloat("m_vOrigin[1]", origin[1]);
	TE_WriteFloat("m_vOrigin[2]", origin[2]);
	TE_WriteFloat("m_vStart[0]", start[0]);
	TE_WriteFloat("m_vStart[1]", start[1]);
	TE_WriteFloat("m_vStart[2]", start[2]);
	TE_WriteVector("m_vAngles", angles);
	TE_WriteVector("m_vNormal", normal);
	TE_WriteNum("m_fFlags", flags);
	TE_WriteFloat("m_flMagnitude", magnitude);
	TE_WriteFloat("m_flScale", scale);
	TE_WriteNum("m_nAttachmentIndex", attachmentIndex);
	TE_WriteNum("m_nSurfaceProp", surfaceProp);
	TE_WriteNum("m_iEffectName", effectName);
	TE_WriteNum("m_nMaterial", material);
	TE_WriteNum("m_nDamageType", damageType);
	TE_WriteNum("m_nHitBox", hitbox);
	TE_WriteNum("entindex", entindex);
	TE_WriteNum("m_nColor", color);
	TE_WriteFloat("m_flRadius", radius);
	TE_WriteNum("m_bCustomColors", customColors);
	//TE_WriteVector("m_CustomColors.m_vecColor1", customColor1);
	//TE_WriteVector("m_CustomColors.m_vecColor2", customColor2);
	TE_WriteNum("m_bControlPoint1", controlPoint1);
	TE_WriteNum("m_ControlPoint1.m_eParticleAttachment", cp1ParticleAttachment);
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[0]", cp1Offset[0]);
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[1]", cp1Offset[1]);
	TE_WriteFloat("m_ControlPoint1.m_vecOffset[2]", cp1Offset[2]);
}

stock int getEffectDispatchStringTableIndex(const char[] effectName){
	static int table = INVALID_STRING_TABLE;
	if(table == INVALID_STRING_TABLE){
		table = FindStringTable("EffectDispatch");
	}
	int index;
	if( (index = FindStringIndex(table, effectName)) != INVALID_STRING_INDEX)
		return index;
	AddToStringTable(table, effectName);
	return FindStringIndex(table, effectName);
}

stock void SpawnTimer(float time)
{
	int timer = -1;
	while((timer = FindEntityByClassname(timer, "team_round_timer")) != -1)
	{
		SetVariantInt(0);
		AcceptEntityInput(timer, "ShowInHUD");
	}

	timer = CreateEntityByName("team_round_timer");
	DispatchKeyValue(timer, "show_in_hud", "1");
	DispatchSpawn(timer);
	
	SetVariantInt(RoundToCeil(time));
	AcceptEntityInput(timer, "SetTime");
	AcceptEntityInput(timer, "Resume");
	AcceptEntityInput(timer, "Enable");
	SetEntProp(timer, Prop_Send, "m_bAutoCountdown", false);
	
	GameRules_SetPropFloat("m_flStateTransitionTime", GetGameTime() + time);
	CreateTimer(time, Timer_RemoveEntity, EntIndexToEntRef(timer));
	
	Event event = CreateEvent("teamplay_update_timer", true);
	event.Fire();
}

stock int GetOwnerLoop(int entity)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(owner > 0 && owner != entity)
		return GetOwnerLoop(owner);
	else
		return entity;
}
