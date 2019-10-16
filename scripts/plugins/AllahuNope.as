const string sound = 'twlz/hq_hahahahaha.ogg';

void PluginInit() {
  g_Module.ScriptInfo.SetAuthor("incognico");
  g_Module.ScriptInfo.SetContactInfo("https://discord.gg/qfZxWAd");

  g_Hooks.RegisterHook(Hooks::Weapon::WeaponTertiaryAttack, @WeaponTertiaryAttack);
}

void MapInit() {
  g_Game.PrecacheGeneric('sound/' + sound);
  g_SoundSystem.PrecacheSound(sound);
}

HookReturnCode WeaponTertiaryAttack(CBasePlayer@ pPlayer, CBasePlayerWeapon@ wep) {
  if (wep.GetClassname() != "weapon_satchel") {
    return HOOK_CONTINUE;
  }
  else {
    if (pPlayer.IsAlive()) {
      pPlayer.TakeDamage(g_EntityFuncs.Instance(0).pev, g_EntityFuncs.Instance(0).pev, pPlayer.pev.health+1 , DMG_BLAST);
      g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "lmao nope :-D\n");
      g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_AUTO, sound, 0.75f, 0.4f, 0, 100, 0, true, pPlayer.pev.origin);
    }
  }

  return HOOK_HANDLED;
}
