void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Nero" );
	g_Module.ScriptInfo.SetContactInfo( "Nero @ Svencoop forums" );

	@AmmoRegen::g_flRechargeRate = CCVar( "ar_rate", 15.0f, "Rate of regen-ticks. (default: 1.0)", ConCommandFlag::AdminOnly );
	@AmmoRegen::g_iRechargeAmount = CCVar( "ar_amount", 5, "Amount of ammo to give. (default: 5)", ConCommandFlag::AdminOnly );
}

void MapInit()
{
	if( AmmoRegen::g_pThinkFunc !is null )
		g_Scheduler.RemoveTimer( AmmoRegen::g_pThinkFunc );

	bool bDisabled = false;
	bool bWildcard = false;

	for( uint i = 0; i < AmmoRegen::g_DisabledMaps.length(); i++ )
	{
		string sBuffer = AmmoRegen::g_DisabledMaps[i];

		if( sBuffer.SubString(sBuffer.Length()-1, 1) == "*" )
		{
			bWildcard = true;
			sBuffer = sBuffer.SubString(0, sBuffer.Length()-1);
		}

		if( bWildcard )
		{
			string sMatch = g_Engine.mapname;
			if( sBuffer == sMatch.SubString(0, sBuffer.Length()) )
			{
				bDisabled = true;
				break;
			}
		}
		else if( g_Engine.mapname == AmmoRegen::g_DisabledMaps[i] )
		{
			bDisabled = true;
			break;
		}
	}

	if( !bDisabled )
		@AmmoRegen::g_pThinkFunc = g_Scheduler.SetInterval( "AmmoRegen", AmmoRegen::g_flRechargeRate.GetFloat() );
}

namespace AmmoRegen
{

CScheduledFunction@ g_pThinkFunc = null;
CCVar@ g_flRechargeRate, g_iRechargeAmount;

array<string> g_DisabledMaps =
{
	"crklf_*",
	"cracklife_*",
//	"th_*",
//	"hl_*",
//	"ba_*",
	"rust_*",
	"ops_*",
//	"of*"
};

const dictionary pAmmoValues =
{
	{ "buckshot", 2 },
	{ "health", 0 },
	{ "556", 0 },
	{ "m40a1", 0 },
	{ "argrenades", 0 },
	{ "357", 0 },
	{ "9mm", 9 },
	{ "sporeclip", 0 },
	{ "uranium", 0 },
	{ "rockets", 0 },
	{ "bolts", 0 },
	{ "trip mine", 0 },
	{ "satchel charge", 0 },
	{ "hand grenade", 0 },
	{ "snarks", 0 }
};

const array<string> pAmmoNames = pAmmoValues.getKeys();

void AmmoRegen()
{
	for( int i = 1; i <= g_Engine.maxClients; ++i )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);

		if( pPlayer is null )
			continue;

		for( uint j = 0; j < pAmmoNames.length() - 1; j++ )
		{
			if( pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex(pAmmoNames[j])) < 17 )
			{
				int give;
				pAmmoValues.get( pAmmoNames[j], give );
				pPlayer.GiveAmmo( give - pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex(pAmmoNames[j])), pAmmoNames[j], pPlayer.GetMaxAmmo(pAmmoNames[j])  );
			}
		}
	}
}

} //namespace AmmoRegen END
