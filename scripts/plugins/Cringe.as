const array<string> g_ChangeEnts = { 'func_door', 'func_door_rotating', 'momentary_door', 'func_plat', 'func_platrot', 'func_rotating', 'func_train', 'func_pendulum', 'func_rot_button' };

void PluginInit() {
  g_Module.ScriptInfo.SetAuthor("incognico");
  g_Module.ScriptInfo.SetContactInfo("https://discord.gg/qfZxWAd");

  g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @PlayerKilled );
}

void MapStart() {
  CBaseEntity@ pEnt = null;

  for (uint i = 0; i < g_ChangeEnts.length(); ++i) {
    while( ( @pEnt = g_EntityFuncs.FindEntityByClassname( pEnt, g_ChangeEnts[i] ) ) !is null ) {
      g_EntityFuncs.DispatchKeyValue( pEnt.edict(), "dmg", 9999 );
    }
  }
}

HookReturnCode PlayerKilled(CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib) {
  if (pAttacker !is null && g_ChangeEnts.find(pAttacker.GetClassname()) >= 0)
     g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[Cringe] " + pPlayer.pev.netname + " was killed by a " + pAttacker.GetClassname() + ".\n");

  return HOOK_CONTINUE;
}
