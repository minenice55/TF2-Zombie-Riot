#pragma semicolon 1
#pragma newdecls required

static char g_DeathSounds[][] =
{
	"vo/sniper_paincrticialdeath01.mp3",
	"vo/sniper_paincrticialdeath02.mp3",
	"vo/sniper_paincrticialdeath03.mp3"
};

static char g_HurtSounds[][] =
{
	"vo/sniper_painsharp01.mp3",
	"vo/sniper_painsharp02.mp3",
	"vo/sniper_painsharp03.mp3",
	"vo/sniper_painsharp04.mp3"
};

static char g_MeleeHitSounds[][] =
{
	"weapons/cbar_hitbod1.wav",
	"weapons/cbar_hitbod2.wav",
	"weapons/cbar_hitbod3.wav"
};

static char g_MeleeAttackSounds[][] =
{
	"weapons/machete_swing.wav"
};

static char g_RangedAttackSounds[][] =
{
	"weapons/sniper_railgun_single_01.wav",
	"weapons/sniper_railgun_single_02.wav"
};

static char g_RangedSpecialAttackSounds[][] =
{
	"mvm/sentrybuster/mvm_sentrybuster_spin.wav"
};

static char g_BoomSounds[][] =
{
	"mvm/mvm_tank_explode.wav"
};

static char g_SMGAttackSounds[][] =
{
	"weapons/doom_sniper_smg.wav"
};

static char g_BuffSounds[][] =
{
	"player/invuln_off_vaccinator.wav"
};

static char g_AngerSounds[][] =
{
	"vo/taunts/sniper_taunts05.mp3",
	"vo/taunts/sniper_taunts06.mp3",
	"vo/taunts/sniper_taunts08.mp3",
	"vo/taunts/sniper_taunts11.mp3",
	"vo/taunts/sniper_taunts12.mp3",
	"vo/taunts/sniper_taunts14.mp3"
};

static char g_HappySounds[][] =
{
	"vo/taunts/sniper/sniper_taunt_admire_02.mp3",
	"vo/compmode/cm_sniper_pregamefirst_6s_05.mp3",
	"vo/compmode/cm_sniper_matchwon_02.mp3",
	"vo/compmode/cm_sniper_matchwon_07.mp3",
	"vo/compmode/cm_sniper_matchwon_10.mp3",
	"vo/compmode/cm_sniper_matchwon_11.mp3",
	"vo/compmode/cm_sniper_matchwon_14.mp3"
};


int i_NemesisEntitiesHitAoeSwing[MAXENTITIES];	//Who got hit
float f_NemesisEnemyHitCooldown[MAXENTITIES];

float f_NemesisHitBoxStart[MAXENTITIES];
float f_NemesisHitBoxEnd[MAXENTITIES];
static int i_GrabbedThis[MAXENTITIES];
static float fl_RegainWalkAnim[MAXENTITIES];
static float fl_OverrideWalkDest[MAXENTITIES];
static float fl_StopDodge[MAXENTITIES];
static float fl_StopDodgeCD[MAXENTITIES];

static float f3_LastValidPosition[MAXENTITIES][3]; //Before grab to be exact
static int i_TankAntiStuck[MAXENTITIES];
static int i_GunMode[MAXENTITIES];
static int i_GunAmmo[MAXENTITIES];

void RaidbossNemesis_OnMapStart()
{
	PrecacheModel("models/zombie_riot/bosses/nemesis_ft1_v4.mdl");
}

methodmap RaidbossNemesis < CClotBody
{
	public void PlayHurtSound()
	{
		int sound = GetRandomInt(0, sizeof(g_HurtSounds) - 1);

		EmitSoundToAll(g_HurtSounds[sound], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
		this.m_flNextHurtSound = GetGameTime(this.index) + GetRandomFloat(0.6, 1.6);
	}
	public void PlayDeathSound()
	{
		int sound = GetRandomInt(0, sizeof(g_DeathSounds) - 1);
		
		EmitSoundToAll(g_DeathSounds[sound], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayMeleeSound()
	{
		EmitSoundToAll(g_MeleeAttackSounds[GetRandomInt(0, sizeof(g_MeleeAttackSounds) - 1)], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlaySMGSound()
	{
		EmitSoundToAll(g_SMGAttackSounds[GetRandomInt(0, sizeof(g_SMGAttackSounds) - 1)], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayRangedSound()
	{
		EmitSoundToAll(g_RangedAttackSounds[GetRandomInt(0, sizeof(g_RangedAttackSounds) - 1)], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayRangedSpecialSound()
	{
		EmitSoundToAll(g_RangedSpecialAttackSounds[GetRandomInt(0, sizeof(g_RangedSpecialAttackSounds) - 1)], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayBoomSound()
	{
		EmitSoundToAll(g_BoomSounds[GetRandomInt(0, sizeof(g_BoomSounds) - 1)], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayAngerSound()
	{
		int sound = GetRandomInt(0, sizeof(g_AngerSounds) - 1);
		EmitSoundToAll(g_AngerSounds[sound], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayRevengeSound()
	{
		char buffer[64];
		FormatEx(buffer, sizeof(buffer), "vo/sniper_revenge%02d.mp3", (GetURandomInt() % 25) + 1);
		EmitSoundToAll(buffer, this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayHappySound()
	{
		EmitSoundToAll(g_HappySounds[GetRandomInt(0, sizeof(g_HappySounds) - 1)], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayMeleeHitSound()
	{
		EmitSoundToAll(g_MeleeHitSounds[GetRandomInt(0, sizeof(g_MeleeHitSounds) - 1)], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public void PlayBuffSound()
	{
		EmitSoundToAll(g_BuffSounds[GetRandomInt(0, sizeof(g_BuffSounds) - 1)], this.index, SNDCHAN_STATIC, RAIDBOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}
	public RaidbossNemesis(int client, float vecPos[3], float vecAng[3], bool ally)
	{
		RaidbossNemesis npc = view_as<RaidbossNemesis>(CClotBody(vecPos, vecAng, "models/zombie_riot/bosses/nemesis_ft1_v4.mdl", "1.75", "25000", ally, false, true, true,true)); //giant!
		
		//model originally from Roach, https://steamcommunity.com/sharedfiles/filedetails/?id=2053348633&searchtext=nemesis

		//wave 75 xeno raidboss,should be extreamly hard, but still fair, that will be hard to do.

		i_NpcInternalId[npc.index] = XENO_RAIDBOSS_NEMESIS;
		
		FormatEx(c_HeadPlaceAttachmentGibName[npc.index], sizeof(c_HeadPlaceAttachmentGibName[]), "head");
		
		int iActivity = npc.LookupActivity("ACT_FT2_WALK");
		if(iActivity > 0) npc.StartActivity(iActivity);
		
		SDKHook(npc.index, SDKHook_Think, RaidbossNemesis_ClotThink);
		SDKHook(npc.index, SDKHook_OnTakeDamage, RaidbossNemesis_ClotDamaged);
		RaidBossActive = EntIndexToEntRef(npc.index);
		RaidModeTime = GetGameTime(npc.index) + 200.0;

		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_GIANT;	
		npc.m_iNpcStepVariation = STEPSOUND_NORMAL;
		npc.m_bThisNpcIsABoss = true;
		npc.Anger = false;
		npc.m_flSpeed = 300.0;
		npc.m_iTarget = 0;
		npc.m_flGetClosestTargetTime = 0.0;
		npc.m_bDissapearOnDeath = true;
		Zero(f_NemesisEnemyHitCooldown);
		npc.m_flNextMeleeAttack = 0.0;
		npc.m_flAttackHappens = 0.0;
		i_GrabbedThis[npc.index] = -1;
		fl_RegainWalkAnim[npc.index] = 0.0;
		npc.m_flNextRangedAttack = GetGameTime(npc.index) + 15.0;

		npc.m_flNextRangedSpecialAttack = GetGameTime(npc.index) + GetRandomFloat(45.0, 60.0);
		npc.m_flNextRangedSpecialAttackHappens = 0.0;
		i_GunMode[npc.index] = 0;
		i_GunAmmo[npc.index] = 0;
		
		Citizen_MiniBossSpawn(npc.index);
		npc.StartPathing();
		return npc;
	}
}

public void RaidbossNemesis_ClotThink(int iNPC)
{
	RaidbossNemesis npc = view_as<RaidbossNemesis>(iNPC);
	
	float gameTime = GetGameTime(npc.index);
	
	if(RaidModeTime < GetGameTime())
	{
		int entity = CreateEntityByName("game_round_win"); //You loose.
		DispatchKeyValue(entity, "force_map_reset", "1");
		SetEntProp(entity, Prop_Data, "m_iTeamNum", TFTeam_Blue);
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "RoundWin");
		Music_RoundEnd(entity);
		RaidBossActive = INVALID_ENT_REFERENCE;
		SDKUnhook(npc.index, SDKHook_Think, RaidbossNemesis_ClotThink);
	}

	npc.Update();

	if(npc.m_blPlayHurtAnimation)
	{
		npc.AddGesture("ACT_MP_GESTURE_FLINCH_CHEST", false);
		npc.PlayHurtSound();
		npc.m_blPlayHurtAnimation = false;
	}
	if(npc.m_flDoingAnimation < gameTime && i_GunMode[npc.index] == 0)
	{
		Nemesis_TryDodgeAttack(npc.index);
	}

	if(fl_StopDodge[npc.index])
	{
		if(fl_StopDodge[npc.index] < GetGameTime(npc.index))
		{
			b_IgnoredByPlayerProjectiles[npc.index] = false;
			int iActivity = npc.LookupActivity("ACT_FT_RAISE");
			if(iActivity > 0) npc.StartActivity(iActivity);
			npc.m_iChanged_WalkCycle = 9;
			npc.m_bisWalking = false;
			npc.m_bAllowBackWalking = true;
			npc.m_flSpeed = 0.0;
			PF_StopPathing(npc.index);
			fl_StopDodge[npc.index] = 0.0;

			i_GunMode[npc.index] = 1;
			i_GunAmmo[npc.index] = 300;

			npc.m_iWearable1 = npc.EquipItem("weapon_bone", "models/weapons/c_models/c_minigun/c_minigun.mdl");
			SetVariantString("1.0");
			AcceptEntityInput(npc.m_iWearable1, "SetModelScale");
			f_NpcTurnPenalty[npc.index] = 1.0;
		}
	}

	if(i_GunAmmo[npc.index] < 0 && i_GunMode[npc.index] == 1)
	{
		if(npc.m_iChanged_WalkCycle != 11) 	
		{
			int iActivity = npc.LookupActivity("ACT_FT_LOWER");
			if(iActivity > 0) npc.StartActivity(iActivity);
			npc.m_iChanged_WalkCycle = 11;
			npc.m_bisWalking = false;
			npc.m_bAllowBackWalking = false;
			npc.m_flSpeed = 0.0;
			PF_StopPathing(npc.index);
			i_GunMode[npc.index] = 0;
			fl_RegainWalkAnim[npc.index] = gameTime + 1.5;
			npc.m_flDoingAnimation = gameTime + 1.55;
			f_NpcTurnPenalty[npc.index] = 1.0;
		}
	}

	if(fl_OverrideWalkDest[npc.index] > gameTime)
	{
		return;
	}

	if(npc.m_flGetClosestTargetTime < gameTime)
	{
		if(	i_GunMode[npc.index] != 0)
		{
			npc.m_iTarget = GetClosestTarget(npc.index,_,_,_,_,_,_,true);
			if(npc.m_iTarget == -1)
			{
				npc.m_iTarget = GetClosestTarget(npc.index);
			}
		}
		else
		{
			npc.m_iTarget = GetClosestTarget(npc.index);
		}
		npc.m_flGetClosestTargetTime = GetGameTime(npc.index) + 1.0;
	}
	if(fl_RegainWalkAnim[npc.index])
	{
		if(fl_RegainWalkAnim[npc.index] < gameTime)
		{
			switch(i_GunMode[npc.index])
			{
				case 0:
				{
					if(npc.m_iChanged_WalkCycle != 2) 	
					{
						if(IsValidEntity(npc.m_iWearable1))
						{
							RemoveEntity(npc.m_iWearable1);
						}
						int iActivity = npc.LookupActivity("ACT_FT2_WALK");
						if(iActivity > 0) npc.StartActivity(iActivity);
						npc.m_iChanged_WalkCycle = 2;
						npc.m_bisWalking = true;
						npc.m_flSpeed = 300.0;
						npc.StartPathing();
						f_NpcTurnPenalty[npc.index] = 1.0;
					}
				}
				case 1:
				{
					if(npc.m_iChanged_WalkCycle != 10) 	
					{
						int iActivity = npc.LookupActivity("ACT_FT_WALK");
						if(iActivity > 0) npc.StartActivity(iActivity);
						npc.m_iChanged_WalkCycle = 10;
						npc.m_bisWalking = true;
						npc.m_flSpeed = 50.0;
						npc.StartPathing();
						f_NpcTurnPenalty[npc.index] = 1.0;
					}					
				}
			}
			fl_RegainWalkAnim[npc.index] = 0.0;
		}
	}
	int client_victim = EntRefToEntIndex(i_GrabbedThis[npc.index]);
	if(IsValidEntity(client_victim))
	{
		if(npc.m_flNextRangedAttackHappening)
		{
			if(npc.m_flNextRangedAttackHappening < gameTime)
			{
				i_GrabbedThis[npc.index] = -1;
				AcceptEntityInput(client_victim, "ClearParent");
						
				float flPos[3]; // original
				float flAng[3]; // original
						
						
				npc.GetAttachment("RightHand", flPos, flAng);
				TeleportEntity(client_victim, flPos, NULL_VECTOR, {0.0,0.0,0.0});
						
				SDKCall_SetLocalOrigin(client_victim, flPos);
						
				if(client_victim <= MaxClients)
				{
					SetEntityMoveType(client_victim, MOVETYPE_WALK); //can move XD
							
					TF2_AddCondition(client_victim, TFCond_LostFooting, 1.0);
					TF2_AddCondition(client_victim, TFCond_AirCurrent, 1.0);
							
					if(dieingstate[client_victim] == 0)
					{
						SetEntityCollisionGroup(client_victim, 5);
						b_ThisEntityIgnored[client_victim] = false;
					}
					Custom_Knockback(npc.index, client_victim, 3000.0, true, true);
				}
				npc.m_flNextRangedAttackHappening = 0.0;	
				SDKHooks_TakeDamage(client_victim, npc.index, npc.index, 10000.0, DMG_CLUB, -1);
				i_TankAntiStuck[client_victim] = EntIndexToEntRef(npc.index);
				CreateTimer(0.1, CheckStuckNemesis, EntIndexToEntRef(client_victim), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	else
	{
		if(npc.m_flNextRangedAttackHappening)
		{
			if(npc.m_flNextRangedAttackHappening - 5.75 < gameTime)
			{
				if(npc.m_iChanged_WalkCycle != 6 && npc.m_iChanged_WalkCycle != 5 && npc.m_iChanged_WalkCycle != 7) 
				{
					npc.m_iChanged_WalkCycle = 6;
					npc.m_bisWalking = false;
					npc.m_flSpeed = 600.0;
					npc.StartPathing();
				}
				if(npc.flXenoInfectedSpecialHurtTime < gameTime && npc.m_flNextRangedAttackHappening - 1.5 > gameTime)
				{
					npc.flXenoInfectedSpecialHurtTime = gameTime + 0.4;
					npc.SetCycle(0.45);
				}
			}

			if(IsValidEnemy(npc.index, npc.m_iTarget))
			{
				float vecTarget[3]; vecTarget = WorldSpaceCenter(npc.m_iTarget);
				float flDistanceToTarget = GetVectorDistance(vecTarget, WorldSpaceCenter(npc.index), true);
				if(flDistanceToTarget < Pow(NORMAL_ENEMY_MELEE_RANGE_FLOAT * 1.25, 2.0))
				{
					int Enemy_I_See;
						
					Enemy_I_See = Can_I_See_Enemy(npc.index, npc.m_iTarget);

					//Target close enough to hit
					if(IsValidEntity(npc.m_iTarget) && IsValidEnemy(npc.index, Enemy_I_See))
					{
						int iActivity = npc.LookupActivity("ACT_FT2_GRABKILL");
						if(iActivity > 0) npc.StartActivity(iActivity);
						npc.m_iChanged_WalkCycle = 5;
						npc.m_bisWalking = false;
						npc.m_flSpeed = 0.0;
						PF_StopPathing(npc.index);
						npc.m_flDoingAnimation = gameTime + 5.0;
						npc.m_flNextRangedAttackHappening = gameTime + 3.1;
						fl_RegainWalkAnim[npc.index] = gameTime + 5.1;

						GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", f3_LastValidPosition[Enemy_I_See]);
						
						float flPos[3]; // original
						float flAng[3]; // original
					
						npc.GetAttachment("RightHand", flPos, flAng);
						
						TeleportEntity(Enemy_I_See, flPos, NULL_VECTOR, {0.0,0.0,0.0});
						
						SDKCall_SetLocalOrigin(Enemy_I_See, flPos);
						
						if(Enemy_I_See <= MaxClients)
						{
							SetEntityMoveType(Enemy_I_See, MOVETYPE_NONE); //Cant move XD
							SetEntityCollisionGroup(Enemy_I_See, 1);
							SetParent(npc.index, Enemy_I_See, "RightHand");
						}
						i_GrabbedThis[npc.index] = EntIndexToEntRef(Enemy_I_See);
						b_DoNotUnStuck[Enemy_I_See] = true;
						f_NpcTurnPenalty[npc.index] = 1.0;
					}
				}
			}
			if(npc.m_iChanged_WalkCycle != 5) 
			{
				if(npc.m_flNextRangedAttackHappening - 0.6 < gameTime)
				{
					if(npc.m_iChanged_WalkCycle != 7) 
					{
						npc.m_iChanged_WalkCycle = 7;
						npc.m_bisWalking = false;
						npc.m_flSpeed = 0.0;
						PF_StopPathing(npc.index);
					}
				}
				if(npc.m_flNextRangedAttackHappening < gameTime)
				{
					if(npc.m_iChanged_WalkCycle != 2) 	
					{
						int iActivity = npc.LookupActivity("ACT_FT2_WALK");
						if(iActivity > 0) npc.StartActivity(iActivity);
						npc.m_iChanged_WalkCycle = 2;
						npc.m_bisWalking = true;
						npc.m_flSpeed = 300.0;
						npc.StartPathing();
						f_NpcTurnPenalty[npc.index] = 1.0;
					}
					npc.m_flNextRangedAttackHappening = 0.0;			
				}	
			}
		}
	}

	if(npc.m_flAttackHappens)
	{
		if(f_NemesisHitBoxStart[npc.index] < gameTime && f_NemesisHitBoxEnd[npc.index] > gameTime)
		{
			Nemesis_AreaAttack(npc.index, 1500.0, {-40.0,-40.0,-40.0}, {40.0,40.0,40.0});
		}

		if(npc.m_flAttackHappens < gameTime)
		{
			if(npc.m_flDoingAnimation > gameTime)
			{
				if(IsValidEnemy(npc.index, npc.m_iTarget))
				{
					float vecTarget[3]; vecTarget = WorldSpaceCenter(npc.m_iTarget);
					float flDistanceToTarget = GetVectorDistance(vecTarget, WorldSpaceCenter(npc.index), true);
					if(flDistanceToTarget < Pow(NORMAL_ENEMY_MELEE_RANGE_FLOAT * 2.0, 2.0))
					{

						if(npc.m_iChanged_WalkCycle != 3) 
						{
							//the enemy is still close, do another attack.
							float flPos[3]; // original
							float flAng[3]; // original
							npc.GetAttachment("RightHand", flPos, flAng);
							if(IsValidEntity(npc.m_iWearable5))
								RemoveEntity(npc.m_iWearable5);
						
							npc.m_iWearable5 = ParticleEffectAt(flPos, "spell_fireball_small_blue", 1.25);
							TeleportEntity(npc.m_iWearable5, flPos, flAng, NULL_VECTOR);
							SetParent(npc.index, npc.m_iWearable5, "RightHand");
							npc.m_flAttackHappens = gameTime + 2.0;
							npc.m_flDoingAnimation = gameTime + 2.0;
							f_NemesisHitBoxStart[npc.index] = gameTime + 0.65;
							f_NemesisHitBoxEnd[npc.index] = gameTime + 1.25;
							int iActivity = npc.LookupActivity("ACT_FT2_ATTACK_2");
							if(iActivity > 0) npc.StartActivity(iActivity);
							npc.m_iChanged_WalkCycle = 3;
							npc.m_bisWalking = false;
							npc.m_flSpeed = 50.0;
							npc.StartPathing();
							f_NpcTurnPenalty[npc.index] = 0.25;
						}
						else
						{
							npc.m_flAttackHappens = 0.0;
						}
					}
				}
			}
			else
			{
				if(npc.m_iChanged_WalkCycle != 2) 	
				{
					int iActivity = npc.LookupActivity("ACT_FT2_WALK");
					if(iActivity > 0) npc.StartActivity(iActivity);
					npc.m_iChanged_WalkCycle = 2;
					npc.m_bisWalking = true;
					npc.m_flSpeed = 300.0;
					npc.StartPathing();
					f_NpcTurnPenalty[npc.index] = 1.0;
				}
				npc.m_flAttackHappens = 0.0;
			}
		}
	}
	if(IsValidEnemy(npc.index, npc.m_iTarget))
	{
		float vecTarget[3]; vecTarget = WorldSpaceCenter(npc.m_iTarget);
		float flDistanceToTarget = GetVectorDistance(vecTarget, WorldSpaceCenter(npc.index), true);
		//Predict their pos.
		if(fl_OverrideWalkDest[npc.index] < gameTime)
		{
			if(flDistanceToTarget < npc.GetLeadRadius()) 
			{
				float vPredictedPos[3]; vPredictedPos = PredictSubjectPosition(npc, npc.m_iTarget);
				PF_SetGoalVector(npc.index, vPredictedPos);
			} 
			else 
			{
				PF_SetGoalEntity(npc.index, npc.m_iTarget);
			}	
		}


		int ActionToTake = -1;

		if(npc.m_flDoingAnimation > GetGameTime(npc.index)) //I am doing an animation or doing something else, default to doing nothing!
		{
			ActionToTake = -1;
		}
		else if(i_GunMode[npc.index] == 0)
		{
			if(flDistanceToTarget < Pow(NORMAL_ENEMY_MELEE_RANGE_FLOAT * 1.50, 2.0) && npc.m_flNextMeleeAttack < GetGameTime(npc.index))
			{
				ActionToTake = 1;
			}
			else if(flDistanceToTarget > Pow(NORMAL_ENEMY_MELEE_RANGE_FLOAT * 1.50, 2.0) && npc.m_flNextRangedAttack < GetGameTime(npc.index))
			{
				ActionToTake = 2;
			}
		}
		else if(i_GunMode[npc.index] == 1)
		{
			if(npc.m_flJumpStartTime < GetGameTime(npc.index))
			{
				ActionToTake = 3;
			}			
		}

		/*
		TODO:
		If didnt attack for abit, sprints and grabs someone
		Can dodge projetiles and then equip rocket launcher to retaliate
		Same with minigun, its random what he chooses
		During any melee animation he does, he will ggain 50% ranged resistance
		Make him instantly crush any NPC enemy basically, mainly aoe attacks only
		all his attacks will be aoe and dodgeable easily

		Main threat is trying to do massive damage to him and taking him down before the timer runs out, being too greedy kill you, being too safe makes you lose with a timer.
		Most effective way is backstabbing during melee attacks.
		*/


		switch(ActionToTake)
		{
			case 1:
			{
				npc.m_flNextMeleeAttack = gameTime + 5.0;
				npc.m_flDoingAnimation = gameTime + 2.5;
				npc.m_flAttackHappens = gameTime + 1.25;
				float flPos[3]; // original
				float flAng[3]; // original
				npc.GetAttachment("RightHand", flPos, flAng);
				if(IsValidEntity(npc.m_iWearable5))
					RemoveEntity(npc.m_iWearable5);
		
				npc.m_iWearable5 = ParticleEffectAt(flPos, "spell_fireball_small_red", 1.0);
				TeleportEntity(npc.m_iWearable5, flPos, flAng, NULL_VECTOR);
				SetParent(npc.index, npc.m_iWearable5, "RightHand");
				f_NemesisHitBoxStart[npc.index] = gameTime + 0.45;
				f_NemesisHitBoxEnd[npc.index] = gameTime + 1.0;

				if(npc.m_iChanged_WalkCycle != 1) 
				{
					int iActivity = npc.LookupActivity("ACT_FT2_ATTACK_1");
					if(iActivity > 0) npc.StartActivity(iActivity);
					npc.m_iChanged_WalkCycle = 1;
					npc.m_bisWalking = false;
					npc.m_flSpeed = 50.0;
					npc.StartPathing();
					f_NpcTurnPenalty[npc.index] = 0.25;
				}
			}
			case 2:
			{
				npc.m_flNextRangedAttack = gameTime + 35.0;
				npc.m_flNextRangedAttackHappening = gameTime + 7.5;
				npc.flXenoInfectedSpecialHurtTime = gameTime + 1.25;
				npc.SetCycle(0.15);
				npc.m_flDoingAnimation = gameTime + 7.55;

				if(npc.m_iChanged_WalkCycle != 4) 
				{
					int iActivity = npc.LookupActivity("ACT_FT2_GRAB");
					if(iActivity > 0) npc.StartActivity(iActivity);
					npc.m_iChanged_WalkCycle = 4;
					npc.m_bisWalking = false;
					npc.m_flSpeed = 0.0;
					PF_StopPathing(npc.index);
					f_NpcTurnPenalty[npc.index] = 1.0;
				}
			}
			case 3:
			{
				npc.m_flJumpStartTime = gameTime + 0.1;
				npc.FaceTowards(vecTarget, 99999.9);

				float Vecpos[3];
				Vecpos = vecTarget;

				for(int Repeat; Repeat <= 2; Repeat++)
				{
					vecTarget = Vecpos;

					if(flDistanceToTarget < 1000000.0)	// 1000 HU
						vecTarget = PredictSubjectPositionForProjectiles(npc, npc.m_iTarget, 1300.0);

					vecTarget[0] += GetRandomFloat(-50.0,50.0);
					vecTarget[1] += GetRandomFloat(-50.0,50.0);
					vecTarget[2] += GetRandomFloat(-50.0,50.0);

					i_GunAmmo[npc.index] -= 1;
					
					npc.FireRocket(vecTarget, 75.0, 1300.0, "models/weapons/w_bullet.mdl", 2.0,_, 45.0);	
				}
			}
		}
	}
	else
	{
		npc.m_flGetClosestTargetTime = 0.0;
		npc.m_iTarget = GetClosestTarget(npc.index);
	}
}

	
public Action RaidbossNemesis_ClotDamaged(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	//Valid attackers only.
	if(attacker < 1)
		return Plugin_Continue;
		
	RaidbossNemesis npc = view_as<RaidbossNemesis>(victim);
	
	if (npc.m_flHeadshotCooldown < GetGameTime(npc.index))
	{
		npc.m_flHeadshotCooldown = GetGameTime(npc.index) + DEFAULT_HURTDELAY;
		npc.m_blPlayHurtAnimation = true;
	}

	return Plugin_Changed;
}

public void RaidbossNemesis_NPCDeath(int entity)
{
	RaidbossNemesis npc = view_as<RaidbossNemesis>(entity);
	if(!npc.m_bDissapearOnDeath)
	{
		npc.PlayDeathSound();
	}
	int client = EntRefToEntIndex(i_GrabbedThis[npc.index]);
	
	if(IsValidClient(client))
	{
		AcceptEntityInput(client, "ClearParent");
		
		SetEntityMoveType(client, MOVETYPE_WALK); //can move XD
		SetEntityCollisionGroup(client, 5);
		
		float pos[3];
		float Angles[3];
		GetEntPropVector(entity, Prop_Data, "m_angRotation", Angles);

		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(client, pos, Angles, NULL_VECTOR);
	}	
	
	i_GrabbedThis[npc.index] = -1;
	SDKUnhook(npc.index, SDKHook_Think, RaidbossNemesis_ClotThink);
	SDKUnhook(npc.index, SDKHook_OnTakeDamage, RaidbossNemesis_ClotDamaged);
	
	if(IsValidEntity(npc.m_iWearable1))
		RemoveEntity(npc.m_iWearable1);
	if(IsValidEntity(npc.m_iWearable2))
		RemoveEntity(npc.m_iWearable2);
	if(IsValidEntity(npc.m_iWearable3))
		RemoveEntity(npc.m_iWearable3);
	if(IsValidEntity(npc.m_iWearable4))
		RemoveEntity(npc.m_iWearable4);
	if(IsValidEntity(npc.m_iWearable5))
		RemoveEntity(npc.m_iWearable5);
	if(IsValidEntity(npc.m_iWearable6))
		RemoveEntity(npc.m_iWearable6);
	if(IsValidEntity(npc.m_iWearable7))
		RemoveEntity(npc.m_iWearable7);
		
//	AcceptEntityInput(npc.index, "KillHierarchy");
//	npc.Anger = false;
	Citizen_MiniBossDeath(entity);
}

void Nemesis_TryDodgeAttack(int entity)
{
	RaidbossNemesis npc = view_as<RaidbossNemesis>(entity);
	bool RocketInfrontOfMe = false;

	float flMyPos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", flMyPos);
	static float hullcheckmaxs_Player[3];
	static float hullcheckmins_Player[3];
	flMyPos[2] += 18.0; //Step height.
	
	float ang[3];
	GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
	
	ang[0] = 0.0; //I dont want him to go up or down with his prediction.
	float vecForward_2[3];
			
	GetAngleVectors(ang, vecForward_2, NULL_VECTOR, NULL_VECTOR);
					
	float vecSwingStart_2[3]; vecSwingStart_2 = flMyPos;
				
	float ExtraDistance = 250.0;
	float vecSwingEnd_2[3];
	vecSwingEnd_2[0] = vecSwingStart_2[0] + vecForward_2[0] * ExtraDistance;
	vecSwingEnd_2[1] = vecSwingStart_2[1] + vecForward_2[1] * ExtraDistance;
	vecSwingEnd_2[2] = vecSwingStart_2[2] + vecForward_2[2] * ExtraDistance;

	if(b_IsGiant[entity])
	{
		hullcheckmaxs_Player = view_as<float>( { 30.0, 30.0, 80.0 } );
		hullcheckmins_Player = view_as<float>( { -30.0, -30.0, 0.0 } );	
	}
	else
	{
		hullcheckmaxs_Player = view_as<float>( { 24.0, 24.0, 42.0 } );
		hullcheckmins_Player = view_as<float>( { -24.0, -24.0, 0.0 } );		
	}

	Handle hTrace = TR_TraceHullFilterEx(vecSwingEnd_2, flMyPos, hullcheckmins_Player, hullcheckmaxs_Player, MASK_PLAYERSOLID, TraceRayHitProjectilesOnly, entity);
	int ref = TR_GetEntityIndex(hTrace);
	if(IsValidEntity(ref))
	{
		ref = EntRefToEntIndex(ref);
		RocketInfrontOfMe = true;
	}
	delete hTrace;

	if(RocketInfrontOfMe)
	{
		if(fl_StopDodgeCD[npc.index] < GetGameTime(npc.index))
		{
			if(npc.m_iChanged_WalkCycle != 8) 
			{
				int DodgeLeft;
				b_IgnoredByPlayerProjectiles[npc.index] = true;

				DodgeLeft = GetRandomInt(0,1);
				float PosToDodgeTo[3];

				if(DodgeLeft == 0)
				{
					int iActivity = npc.LookupActivity("ACT_DODGE_2");
					if(iActivity > 0) npc.StartActivity(iActivity);
					PosToDodgeTo = Nemesis_DodgeToDirection(npc, 200.0, -90.0);
				}
				else
				{
					int iActivity = npc.LookupActivity("ACT_DODGE_1");
					if(iActivity > 0) npc.StartActivity(iActivity);
					PosToDodgeTo = Nemesis_DodgeToDirection(npc, 200.0, 90.0);					
				}
				npc.m_iChanged_WalkCycle = 8;
				npc.m_bisWalking = false;
				npc.m_bAllowBackWalking = true;
				npc.m_flSpeed = 600.0;
				fl_OverrideWalkDest[npc.index] = GetGameTime(npc.index) + 1.5;
				if(IsValidEntity(npc.m_iTarget))
				{
					float vecTarget[3]; vecTarget = WorldSpaceCenter(ref);
					npc.FaceTowards(vecTarget);
				}
				PF_SetGoalVector(npc.index, PosToDodgeTo);
				npc.StartPathing();
				npc.m_flDoingAnimation = GetGameTime(npc.index) + 1.55;
				fl_StopDodge[npc.index] = GetGameTime(npc.index) + 0.5;
				fl_StopDodgeCD[npc.index] = GetGameTime(npc.index) + 50.0;
				fl_RegainWalkAnim[npc.index] = GetGameTime(npc.index) + 1.5;
				f_NpcTurnPenalty[npc.index] = 1.0;
			}
		}
	}
}

public bool TraceRayHitProjectilesOnly(int entity,int mask,any data)
{
	if(entity == 0)
	{
		return false;
	}
	if(b_Is_Player_Projectile[entity])
	{
		return true;
	}
	
	return false;
}


void Nemesis_AreaAttack(int entity, float damage, float m_vecMins_1[3], float m_vecMaxs_1[3])
{
	RaidbossNemesis npc = view_as<RaidbossNemesis>(entity);
	//focus a box around a certain part of the body, the arm for example.					
	float flPos[3]; // original
	float flAng[3]; // original
	npc.GetAttachment("RightHand", flPos, flAng);

	static float m_vecMaxs[3];
	static float m_vecMins[3];
	m_vecMaxs = m_vecMaxs_1;
	m_vecMins = m_vecMins_1;	

	for (int i = 1; i < MAXENTITIES; i++)
	{
		i_NemesisEntitiesHitAoeSwing[i] = -1;
	}
	Handle hTrace = TR_TraceHullFilterEx(flPos, flPos, m_vecMins, m_vecMaxs, MASK_SOLID, Nemeis_AoeAttack, entity);
	delete hTrace;

	for (int counter = 1; counter < MAXENTITIES; counter++)
	{
		if (i_NemesisEntitiesHitAoeSwing[counter] != -1)
		{
			if(IsValidEntity(i_NemesisEntitiesHitAoeSwing[counter]) && f_NemesisEnemyHitCooldown[i_NemesisEntitiesHitAoeSwing[counter]] < GetGameTime())
			{
				f_NemesisEnemyHitCooldown[i_NemesisEntitiesHitAoeSwing[counter]] = GetGameTime() + 0.15;
				SDKHooks_TakeDamage(i_NemesisEntitiesHitAoeSwing[counter], npc.index, npc.index, damage, DMG_CLUB, -1);
			}
		}
		else
		{
			break;
		}
	}
	for(int client; client <= MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			static float m_vecMaxs_2[3];
			static float m_vecMins_2[3];
			static float f_pos[3];
			m_vecMaxs_2 = m_vecMaxs_1;
			m_vecMins_2 = m_vecMins_1;	
			f_pos = flPos;
			TE_DrawBox(client, f_pos, m_vecMins_2, m_vecMaxs_2, 0.1, view_as<int>({255, 0, 0, 255}));
		}
	}
}

static bool Nemeis_AoeAttack(int entity, int contentsMask, int filterentity)
{
	if(IsValidEnemy(filterentity,entity, true, true))
	{
		for(int i=1; i < (MAXENTITIES); i++)
		{
			if(i_NemesisEntitiesHitAoeSwing[i] == -1)
			{
				i_NemesisEntitiesHitAoeSwing[i] = entity;
				break;
			}
		}
	}
	return false;
}

public Action CheckStuckNemesis(Handle timer, any entid)
{
	int client = EntRefToEntIndex(entid);
	if(IsValidEntity(client))
	{
		b_DoNotUnStuck[client] = false;
		float flMyPos[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", flMyPos);
		static float hullcheckmaxs_Player[3];
		static float hullcheckmins_Player[3];

		if(IsValidClient(client)) //Player size
		{
			hullcheckmaxs_Player = view_as<float>( { 24.0, 24.0, 82.0 } );
			hullcheckmins_Player = view_as<float>( { -24.0, -24.0, 0.0 } );		
		}
		
		if(IsSpaceOccupiedIgnorePlayers(flMyPos, hullcheckmins_Player, hullcheckmaxs_Player, client))
		{
			if(IsValidClient(client)) //Player Unstuck, but give them a penalty for doing this in the first place.
			{
				int damage = SDKCall_GetMaxHealth(client) / 8;
				SDKHooks_TakeDamage(client, 0, 0, float(damage), DMG_GENERIC, -1, NULL_VECTOR);
			}
			TeleportEntity(client, f3_LastValidPosition[client], NULL_VECTOR, { 0.0, 0.0, 0.0 });
		}
		else
		{
			int tank = EntRefToEntIndex(i_TankAntiStuck[client]);
			if(IsValidEntity(tank))
			{
				bool Hit_something = Can_I_See_Enemy_Only(tank, client);
				//Target close enough to hit
				if(!Hit_something)
				{	
					if(IsValidClient(client)) //Player Unstuck, but give them a penalty for doing this in the first place.
					{
						int damage = SDKCall_GetMaxHealth(client) / 8;
						SDKHooks_TakeDamage(client, 0, 0, float(damage), DMG_GENERIC, -1, NULL_VECTOR);
					}
					TeleportEntity(client, f3_LastValidPosition[client], NULL_VECTOR, { 0.0, 0.0, 0.0 });
				}
			}
			else
			{
				//Just teleport back, dont fucking risk it.
				TeleportEntity(client, f3_LastValidPosition[client], NULL_VECTOR, { 0.0, 0.0, 0.0 });
			}
		}
	}
	return Plugin_Handled;
}



stock float[] Nemesis_DodgeToDirection(CClotBody npc, float extra_backoff = 64.0, float Angle = -90.0)
{
	float botPos[3];
	botPos = WorldSpaceCenter(npc.index);
	
	// compute our desired destination
	float pathTarget[3];
	
		
	//https://forums.alliedmods.net/showthread.php?t=278691 im too stupid for vectors.
	float ang[3];
	GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
	
	ang[0] = 0.0; //I dont want him to go up or down with his prediction.
	ang[1] += Angle; //try to the left/right.
	float vecForward_2[3];
			
	GetAngleVectors(ang, vecForward_2, NULL_VECTOR, NULL_VECTOR);
					
	float vecSwingStart_2[3]; vecSwingStart_2 = botPos;
				
	float vecSwingEnd_2[3];
	vecSwingEnd_2[0] = vecSwingStart_2[0] + vecForward_2[0] * extra_backoff;
	vecSwingEnd_2[1] = vecSwingStart_2[1] + vecForward_2[1] * extra_backoff;
	vecSwingEnd_2[2] = vecSwingStart_2[2] + vecForward_2[2] * extra_backoff;
			
	Handle trace_2; 
			
	trace_2 = TR_TraceRayFilterEx(botPos, vecSwingEnd_2, MASK_SOLID, RayType_EndPoint, HitOnlyTargetOrWorld, 0); //If i hit a wall, i stop retreatring and accept death, for now!
	TR_GetEndPosition(pathTarget, trace_2);

	delete trace_2;

	Handle trace_3; //2nd one, make sure to actually hit the ground!
	
	trace_3 = TR_TraceRayFilterEx(pathTarget, {89.0, 1.0, 0.0}, MASK_SOLID, RayType_Infinite, HitOnlyTargetOrWorld, 0); //If i hit a wall, i stop retreatring and accept death, for now!
	
	TR_GetEndPosition(pathTarget, trace_3);
	
	delete trace_3;
	
	/*
	int g_iPathLaserModelIndex = PrecacheModel("materials/sprites/laserbeam.vmt");
	TE_SetupBeamPoints(botPos, pathTarget, g_iPathLaserModelIndex, g_iPathLaserModelIndex, 0, 30, 5.0, 1.0, 0.1, 5, 0.0, view_as<int>({255, 0, 255, 255}), 30);
	TE_SendToAll();
	*/
	
	pathTarget[2] += 20.0; //Clip them up, minimum crouch level preferred, or else the bots get really confused and sometimees go otther ways if the player goes up or down somewhere, very thin stairs break these bots.
	
	return pathTarget;
}