// config:
// files must exist before loading this script !!!
const string g_FromSven = "scripts/plugins/store/_fromsven.txt";
const string g_ToSven   = "scripts/plugins/store/_tosven.txt";
const float delay       = 1.75f; // flush this often (sec.), don't set too low
//////////

File@ f_FromSven;
File@ f_ToSven;
CScheduledFunction@ sf_LinkChat = null;
bool lock = true;
int oldCount = 0;
dictionary ips;

void PluginInit() {
  g_Module.ScriptInfo.SetAuthor("incognico");
  g_Module.ScriptInfo.SetContactInfo("https://discord.gg/qfZxWAd");

  g_Hooks.RegisterHook(Hooks::Game::MapChange, @MapChange);
  g_Hooks.RegisterHook(Hooks::Player::ClientSay, @ClientSay);
  g_Hooks.RegisterHook(Hooks::Player::ClientConnected, @ClientConnected);
  g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @ClientPutInServer);
  g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @ClientDisconnect);

  MapStart();
}

void PluginExit() {
  if ( f_FromSven !is null && f_FromSven.IsOpen() )
    f_FromSven.Close();

  if ( f_ToSven !is null && f_ToSven.IsOpen() )
    f_ToSven.Close();
}

void MapStart() {
  TruncateFromSven();

  if ( sf_LinkChat is null )
    @sf_LinkChat = g_Scheduler.SetInterval( "ChatLink", delay );

  g_Scheduler.SetTimeout( "ServerStatus", delay * 3 );
  g_Scheduler.SetTimeout( "Unlock", 5.0f );
}

void Unlock() {
  lock = false;
  g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "[Info] In-game chat is now linked to Discord.\n" );
}

void ServerStatus() {
  string count = g_PlayerFuncs.GetNumPlayers() > oldCount ? g_PlayerFuncs.GetNumPlayers() : oldCount;
  string append = "status " + g_Engine.mapname + " " + count + "\n";
  AppendFromSven( append );
  oldCount = 0;
}

void ChatLink() {
  FlushFromSven();

  if ( !lock )
    FlushToSven();
}

void FlushFromSven() {
  if ( f_FromSven !is null && f_FromSven.IsOpen() )
    f_FromSven.Close();

  @f_FromSven = g_FileSystem.OpenFile( g_FromSven, OpenFile::APPEND );
}

void TruncateFromSven() {
  if ( f_FromSven !is null && f_FromSven.IsOpen() )
    f_FromSven.Close();

  @f_FromSven = g_FileSystem.OpenFile( g_FromSven, OpenFile::WRITE );
  f_FromSven.Write( null );
  f_FromSven.Close();
}

void FlushToSven() {
  if ( f_ToSven !is null && f_ToSven.IsOpen() )
    f_ToSven.Close();

  bool truncate = false;

  @f_ToSven = g_FileSystem.OpenFile( g_ToSven, OpenFile::READ );

  while ( !f_ToSven.EOFReached() ) {
    string sLine;
    f_ToSven.ReadLine( sLine );

    if ( sLine.IsEmpty() )
      continue;

    g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, sLine + "\n" );

    truncate = true;
  }

  f_ToSven.Close();

  if ( truncate )
    TruncateToSven();
}
  
void TruncateToSven() {
  @f_ToSven = g_FileSystem.OpenFile( g_ToSven, OpenFile::WRITE );
  f_ToSven.Write( null );
  f_ToSven.Close();
}

void AppendFromSven( string append ) {
  f_FromSven.Write( append );
}

HookReturnCode MapChange() {
  oldCount = g_PlayerFuncs.GetNumPlayers();
  lock = true;

  return HOOK_CONTINUE;
}

HookReturnCode ClientSay( SayParameters@ pParams ) {
  const CCommand@ pArgs = pParams.GetArguments();

  if ( pArgs.ArgC() < 1 )
    return HOOK_CONTINUE;

  CBasePlayer@ pPlayer = pParams.GetPlayer();
  const string steamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );

  if ( ips.exists( steamId ) )
    AppendFromSven( "<" + pPlayer.pev.netname + "><" + string(ips[steamId]) + "><" + steamId + "> " + pParams.GetCommand() + "\n" );

  return HOOK_CONTINUE;
}

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer ) {
  const string steamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );

  ips[steamId] = string( ips[pPlayer.pev.netname] );

  if ( ips.exists( pPlayer.pev.netname ) ) {
    ips.delete( pPlayer.pev.netname );
  }

  AppendFromSven( "+ <" + pPlayer.pev.netname + "><" + string(ips[steamId]) + "><" + steamId + "> has joined the game\n" );

  return HOOK_CONTINUE;
}

HookReturnCode ClientDisconnect( CBasePlayer@ pPlayer ) {
  const string steamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );

  if ( ips.exists( steamId ) ) {
    AppendFromSven( "- <" + pPlayer.pev.netname + "><" + string(ips[steamId]) + "><" + steamId + "> has left the game\n" );
    ips.delete( steamId );
  }

  return HOOK_CONTINUE;
}

HookReturnCode ClientConnected( edict_t@, const string& in szPlayerName, const string& in szIPAddress, bool& out, string& out ) {
  ips[szPlayerName] = szIPAddress;

  return HOOK_CONTINUE;
}
