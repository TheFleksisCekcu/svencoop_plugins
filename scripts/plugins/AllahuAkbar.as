// script is crashy, especialy when many players allahu at once -> server crash

#include "MapBlacklist"

array<string> g_Allahus;
array<string> g_AllahusActive;
CScheduledFunction@ g_pThinkFunc = null;
const string sound = 'twlz/allahusingle.ogg';
const int satchelcount = 8;

void PluginInit() {
  g_Module.ScriptInfo.SetAuthor("incognico");
  g_Module.ScriptInfo.SetContactInfo("https://discord.gg/qfZxWAd");

  g_Hooks.RegisterHook(Hooks::Weapon::WeaponTertiaryAttack, @WeaponTertiaryAttack);
}

void MapInit() {
  g_Game.PrecacheGeneric('sound/' + sound);
  g_SoundSystem.PrecacheSound(sound);

  g_Allahus.resize(0);
  g_AllahusActive.resize(0);
}

void Boom(CBasePlayer@ pPlayer) {
  if (pPlayer is null)
    return;

  const string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

  if (g_AllahusActive.find(steamId) >= 0) {
    return;
  }
  else {
    g_AllahusActive.insertLast(steamId);
  }

  if (g_SurvivalMode.IsActive() || MapBlacklisted()) {
    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Suicide bombing restricted on this map\n");
    RemoveWait(steamId);
    return;
  }

  if (!pPlayer.IsAlive()) {
    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Can not suicide bomb when dead\n");
    RemoveWait(steamId);
    return;
  }

  if (pPlayer.HasNamedPlayerItem("weapon_satchel") is null && pPlayer.HasNamedPlayerItem("weapon_tripmine") is null && pPlayer.HasNamedPlayerItem("weapon_handgrenade") is null) {
    RemoveWait(steamId);
    return;
  }

  if (g_Engine.mapname != 'stadium4') {
    if (g_Allahus.find(steamId) < 0) {
      g_Allahus.insertLast(steamId);
    }
    else {
      g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Max. once per map\n");
      RemoveWait(steamId);
      return;
    }
  }

  if (Math.RandomLong(1,3) > 1) {
    if (pPlayer !is null && pPlayer.IsAlive())
      pPlayer.TakeDamage(g_EntityFuncs.Instance(0).pev, g_EntityFuncs.Instance(0).pev, Math.RandomFloat(14.88f,99.0f), DMG_BLAST);

    RemoveWait(steamId);
    return;
  }

  g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[TAKE COVER INFIDELS!] " + pPlayer.pev.netname + " is suicide bombing!\n");

  array<CBaseEntity@> pSatchels(satchelcount);

  for (int i = 0; i < satchelcount; ++i) {
    @pSatchels[i] = g_EntityFuncs.Create("monster_satchel", pPlayer.pev.origin + Vector(Math.RandomLong(-90, 90), Math.RandomLong(-90, 90), 0 ), Vector(-90, 0, 0), false, pPlayer.edict());
    g_Scheduler.SetTimeout("SatchelCharge", 2.0f, EHandle(pSatchels[i]));
  }

  array<SOUND_CHANNEL> channels = {CHAN_STATIC, CHAN_STREAM, CHAN_BODY, CHAN_ITEM};

  for (uint i = 0; i < channels.length(); i++) {
    g_SoundSystem.PlaySound(pPlayer.edict(), channels[i], sound, 0.8f, 0.35f, 0, 100, 0, true, pPlayer.pev.origin);
  }

  CBaseEntity@ plrEnt = g_EntityFuncs.Instance(pPlayer.pev);

  g_Scheduler.SetTimeout("KillPlayer", 2.0f, EHandle(plrEnt));
  g_Scheduler.SetTimeout("TimeClusterBomb", 2.2f, EHandle(plrEnt));
  g_Scheduler.SetTimeout("RemoveWait", 5.0f, steamId);
}

void RemoveWait(const string steamId) {
  uint sIndex = g_AllahusActive.find(steamId);
  if (sIndex >= 0)
    g_AllahusActive.removeAt(sIndex);
}

void SatchelCharge(EHandle& in ent) {
  CBaseEntity@ pSatchel = null;

  if (!ent.IsValid())
    return;

  @pSatchel = ent.GetEntity();

  CBaseEntity@ pPlayer = g_EntityFuncs.Instance(pSatchel.pev.owner);

  for (int i = 0; i < satchelcount; ++i) {
    g_EntityFuncs.SpawnHeadGib(pSatchel.pev);
    g_EntityFuncs.SpawnRandomGibs(pSatchel.pev, 8, 1);
  }

  if (pSatchel !is null)
    pSatchel.Use(pPlayer, pPlayer, USE_ON, 0);
}

void TimeClusterBomb(EHandle& in plrEnt) {
  if (!plrEnt.IsValid())
    return;

  if (g_pThinkFunc !is null)
    g_Scheduler.RemoveTimer(g_pThinkFunc);

  @g_pThinkFunc = g_Scheduler.SetInterval("ClusterBomb", 0.1f, 15, plrEnt);
}

void ClusterBomb(EHandle& in plrEnt) {
  if (!plrEnt.IsValid())
    return;

  CBaseEntity@ pPlayer = plrEnt.GetEntity();

  g_EntityFuncs.CreateExplosion(pPlayer.pev.origin, Vector(-90, 0, 0), g_EntityFuncs.IndexEnt(0), Math.RandomLong(25, 125), true);
}

void KillPlayer(EHandle& in plrEnt) {
  if (!plrEnt.IsValid())
    return;

  CBaseEntity@ pPlayer = plrEnt.GetEntity();

  if (pPlayer !is null && pPlayer.IsAlive())
    pPlayer.TakeDamage(g_EntityFuncs.Instance(0).pev, g_EntityFuncs.Instance(0).pev, 9999.0f, DMG_BLAST);
}

HookReturnCode WeaponTertiaryAttack(CBasePlayer@ pPlayer, CBasePlayerWeapon@ wep) {
  if (wep is null)
    return HOOK_CONTINUE;

  if (wep.GetClassname() != "weapon_satchel") {
    return HOOK_CONTINUE;
  }
  else {
    Boom(pPlayer);
    return HOOK_HANDLED;
  }
}
