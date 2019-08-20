#include "HLSPClassicMode"

void PluginInit() {
  g_Module.ScriptInfo.SetAuthor("incognico");
  g_Module.ScriptInfo.SetContactInfo("irc://irc.rizon.net/#/dev/null");

  g_Hooks.RegisterHook(Hooks::Weapon::WeaponTertiaryAttack, @WeaponTertiaryAttack);
}

void MapInit() {
}

HookReturnCode WeaponTertiaryAttack(CBasePlayer@, CBasePlayerWeapon@ wep) {
  // meh g_ClassicMode is not there do it does not work
  if ( g_ClassicMode.IsStateDefined() && g_ClassicMode.IsEnabled() && wep.GetClassname() == "weapon_crowbar")
    return HOOK_HANDLED;

  return HOOK_CONTINUE;
}
