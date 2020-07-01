const string g_SoundFile = "scripts/plugins/cfg/ChatSounds.txt";

const uint g_BaseDelay = 6666;
uint g_Delay = g_BaseDelay;

const string g_MalfunctionSound = 'parallax/message.wav';
const string g_SpriteName = 'sprites/flower.spr';
const string g_SpriteName2 = 'sprites/nyanpasu2.spr';

dictionary g_SoundList;
dictionary g_ChatTimes;
dictionary g_Pitch;

array<string> @g_SoundListKeys;

CClientCommand g_ListSounds("listsounds", "List all chat sounds", @listsounds);
CClientCommand g_CSPitch("cspitch", "Sets the pitch at which your ChatSounds play (25-255)", @cspitch);

void PluginInit() {
  g_Module.ScriptInfo.SetAuthor("incognico");
  g_Module.ScriptInfo.SetContactInfo("https://discord.gg/qfZxWAd");

  g_Hooks.RegisterHook(Hooks::Player::ClientSay, @ClientSay);
  g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @ClientDisconnect);
  g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @ClientPutInServer);

  ReadSounds();
}

void MapInit() {
  g_SoundList.deleteAll();
  g_ChatTimes.deleteAll();

  g_Delay = g_BaseDelay;

  ReadSounds();

  for (uint i = 0; i < g_SoundListKeys.length(); ++i) {
    g_Game.PrecacheGeneric("sound/" + string(g_SoundList[g_SoundListKeys[i]]));
    g_SoundSystem.PrecacheSound(string(g_SoundList[g_SoundListKeys[i]]));
  }

  g_Game.PrecacheGeneric('sound/' + g_MalfunctionSound);
  g_Game.PrecacheGeneric(g_SpriteName);
  g_Game.PrecacheGeneric(g_SpriteName2);
  g_SoundSystem.PrecacheSound(g_MalfunctionSound);
  g_Game.PrecacheModel(g_SpriteName);
  g_Game.PrecacheModel(g_SpriteName2);
}

void ReadSounds() {
  File@ file = g_FileSystem.OpenFile(g_SoundFile, OpenFile::READ);
  if (file !is null && file.IsOpen()) {
    while(!file.EOFReached()) {
      string sLine;
      file.ReadLine(sLine);
      if (sLine.SubString(0,1) == "#" || sLine.IsEmpty())
        continue;

      array<string> parsed = sLine.Split(" ");
      if (parsed.length() < 2)
        continue;

      g_SoundList[parsed[0]] = parsed[1];
    }
    file.Close();
    @g_SoundListKeys = g_SoundList.getKeys();
    g_SoundListKeys.sortAsc();
  }
}

void listsounds(const CCommand@ pArgs) {
  CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

  g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCONSOLE, "AVAILABLE SOUND TRIGGERS\n");
  g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCONSOLE, "------------------------\n");

  string sMessage = "";

  for (uint i = 1; i < g_SoundListKeys.length()+1; ++i) {
    sMessage += g_SoundListKeys[i-1] + " | ";

    if (i % 5 == 0) {
      sMessage.Resize(sMessage.Length() -2);
      g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCONSOLE, sMessage);
      g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCONSOLE, "\n");
      sMessage = "";
    }
  }
 
  if (sMessage.Length() > 2) {
    sMessage.Resize(sMessage.Length() -2);
    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCONSOLE, sMessage + "\n");
  }

  g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCONSOLE, "\n");
}

void cspitch(const CCommand@ pArgs) {
  CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
  const string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
 
  if (pArgs.ArgC() < 2)
    return;

  setpitch(steamId, pArgs[1]);
  g_PlayerFuncs.SayText(pPlayer, "[ChatSounds] Pitch set to: " + int(g_Pitch[steamId]) + ".\n");
}

HookReturnCode ClientSay(SayParameters@ pParams) {
  const CCommand@ pArguments = pParams.GetArguments();

  if (pArguments.ArgC() > 0) {
    const string soundArg = pArguments.Arg(0).ToLowercase();

    if (g_SoundList.exists(soundArg)) {
      CBasePlayer@ pPlayer = pParams.GetPlayer();
      const string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
 
      if (!g_ChatTimes.exists(steamId))
        g_ChatTimes[steamId] = 0;

      uint t = uint(g_EngineFuncs.Time()*1000);
      uint d = t - uint(g_ChatTimes[steamId]);

      if (d < g_Delay) {
        float w = float(g_Delay - d) / 1000.0f;
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Wait " + format_float(w) + " seconds\n");

        if ( pArguments.ArgC() == 1 )
          pParams.ShouldHide = true;

        return pArguments.ArgC() == 1 ? HOOK_HANDLED : HOOK_CONTINUE;
      }
      else {
        if (soundArg == 'medic' || soundArg == 'meedic') {
          pPlayer.ShowOverheadSprite('sprites/saveme.spr', 51.0f, 3.5f);
          g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_AUTO, string(g_SoundList[soundArg]), 1.0f, 0.2f, 0, Math.RandomLong(35, 220), 0, true, pPlayer.pev.origin);
        }
        else {
          pPlayer.ShowOverheadSprite(Math.RandomLong(0, 1) == 0 ? g_SpriteName : g_SpriteName2, 56.0f, 2.25f);

          if (pPlayer.IsAlive() && !g_SurvivalMode.IsActive() && Math.RandomLong(0, 42) == 0) {
            pPlayer.TakeDamage(g_EntityFuncs.Instance(0).pev, g_EntityFuncs.Instance(0).pev, 9999.9f, DMG_SHOCK);
            g_PlayerFuncs.SayText(pPlayer, "[ChatSounds] Error: System Malfunction.\n");
            g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_AUTO, g_MalfunctionSound, 1.0f, 0.75f, 0, 100, 0, true, pPlayer.pev.origin);
          }
          else {
            g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_AUTO, string(g_SoundList[soundArg]), 0.75f, 0.4f, 0, g_Pitch.exists(steamId) ? int(g_Pitch[steamId]) : 100, 0, true, pPlayer.pev.origin);
          }
        }
        g_ChatTimes[steamId] = t;

        if ( pArguments.ArgC() == 1 ) {
          return HOOK_HANDLED;
        }
        else {
          return HOOK_CONTINUE;
        }
      }
    }
    else if (pArguments.ArgC() > 1 && soundArg == '.cspitch') {
      CBasePlayer@ pPlayer = pParams.GetPlayer();
      const string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

      pParams.ShouldHide = true;

      setpitch(steamId, pArguments[1]);
      g_PlayerFuncs.SayText(pPlayer, "[ChatSounds] Pitch set to: " + int(g_Pitch[steamId]) + ".\n");

      return HOOK_HANDLED;
    }
  }
  return HOOK_CONTINUE;
}

HookReturnCode ClientPutInServer(CBasePlayer@ pPlayer) {
   g_Delay = g_Delay + 600;
   return HOOK_CONTINUE;
}

HookReturnCode ClientDisconnect(CBasePlayer@ pPlayer) {
   g_Delay = g_Delay - 600;
   return HOOK_CONTINUE;
}

void setpitch(string steamId, string val) {
  g_Pitch[steamId] = Math.clamp(25, 255, atoi(val));
}

string format_float(float f) {
   uint decimal = uint(((f - int(f)) * 10)) % 10;
   return "" + int(f) + "." + decimal;
}

// PlaySound(edict_t@ entity, SOUND_CHANNEL channel, const string& in sample,float volume, float attenuation, int flags = 0, int pitch = PITCH_NORM,int target_ent_unreliable = 0, bool setOrigin = false, const Vector& in vecOrigin = g_vecZero)
// CHAN_ITEM, CHAN_VOICE, CHAN_STATIC, CHAN_BODY, CHAN_STREAM, CHAN_WEAPON, CHAN_NETWORKVOICE_BASE, CHAN_AUTO
// ATTN_NONE > ATTN_NORM > ATTN_STATIC > ATTN_IDLE
