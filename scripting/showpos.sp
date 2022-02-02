#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <clientprefs>
#pragma newdecls required
#pragma semicolon 1

#define PREFIX " \x10SP \x01| "

Handle gH_ShowPosCookie;
Handle gH_OriginCookie;
Handle gH_AnglesCookie;
Handle gH_VelocityCookie;
Handle gH_StaminaCookie;
Handle gH_DuckStaminaCookie;

int gI_Enable[MAXPLAYERS + 1];
bool gB_Origin[MAXPLAYERS + 1];
int gI_Angles[MAXPLAYERS + 1];
int gI_Velocity[MAXPLAYERS + 1];
bool gB_Stamina[MAXPLAYERS + 1];
bool gB_DuckStamina[MAXPLAYERS + 1];
enum
{
	ShowPos_Disabled = 0,
	ShowPos_Simple,
	ShowPos_Detailed,
	SHOWPOS_COUNT
};
enum
{
	Angles_Disabled = 0,
	Angles_YawPitch,
	Angles_All,
	ANGLES_COUNT
};
enum
{
	Velocity_Disabled = 0,
	Velocity_Horizontal,
	Velocity_Absolute,
	Velocity_Vector,
	VELOCITY_COUNT
};

public Plugin myinfo =
{
	name = "ShowPos",
	author = "zer0.k",
	description = "Server-sided showpos using hint text",
	version = "0.0.2",
	url = "https://github.com/zer0k-z/showpos"
};


// ====================
// Plugin Events
// ====================

public void OnPluginStart()
{
	RegConsoleCmd("sm_showpos", CommandShowPos);
	RegisterCookies();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!AreClientCookiesCached(i))
		{
			continue;
		}
		OnClientCookiesCached(i);
	}
}

// ====================
// Menu
// ====================

public Action CommandShowPos(int client, int args)
{
	Menu_ShowPos(client);
	return Plugin_Handled;
}


void Menu_ShowPos(int client)
{
	Menu menu = new Menu(Menu_ShowPos_Handler);
	menu.SetTitle("ShowPos Menu");
	char buffer[32];

	switch (gI_Enable[client])
	{
		case ShowPos_Disabled:
		{
			FormatEx(buffer, sizeof(buffer), "ShowPos - Disabled");
		}
		case ShowPos_Simple:
		{
			FormatEx(buffer, sizeof(buffer), "ShowPos - Simple");
		}
		case ShowPos_Detailed:
		{
			FormatEx(buffer, sizeof(buffer), "ShowPos - Detailed");
		}
	}
	menu.AddItem("ShowPos", buffer);

	if (gI_Enable[client] != 0)
	{
		FormatEx(buffer, sizeof(buffer), "Origin - %s", gB_Origin[client] ? "Enabled" : "Disabled");
		menu.AddItem("Origin", buffer);
		switch (gI_Angles[client])
		{
			case Angles_Disabled:
			{
				FormatEx(buffer, sizeof(buffer), "Angles - Disabled");
			}
			case Angles_YawPitch:
			{
				FormatEx(buffer, sizeof(buffer), "Angles - Yaw & Pitch");
			}
			case Angles_All:
			{
				FormatEx(buffer, sizeof(buffer), "Angles - Yaw & Pitch & Roll");
			}
		}
		menu.AddItem("Angles", buffer);
		switch (gI_Velocity[client])
		{
			case Velocity_Disabled:
			{
				FormatEx(buffer, sizeof(buffer), "Velocity - Disabled");
			}
			case Velocity_Horizontal:
			{
				FormatEx(buffer, sizeof(buffer), "Velocity - Horizontal");
			}
			case Velocity_Absolute:
			{
				FormatEx(buffer, sizeof(buffer), "Velocity - Absolute");
			}
			case Velocity_Vector:
			{
				FormatEx(buffer, sizeof(buffer), "Velocity - Vector");
			}
		}
		menu.AddItem("Velocity", buffer);
		FormatEx(buffer, sizeof(buffer), "Stamina - %s", gB_Stamina[client] ? "Enabled" : "Disabled");
		menu.AddItem("Stamina", buffer);
		FormatEx(buffer, sizeof(buffer), "Duck Stamina - %s", gB_DuckStamina[client] ? "Enabled" : "Disabled");
		menu.AddItem("Duck Stamina", buffer);
	}
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Menu_ShowPos_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, "ShowPos"))
		{
			ToggleShowPos(param1);
		}
		else if (StrEqual(info, "Origin"))
		{
			ToggleOrigin(param1);
		}
		else if (StrEqual(info, "Angles"))
		{
			ToggleAngles(param1);
		}
		else if (StrEqual(info, "Velocity"))
		{
			ToggleVelocity(param1);
		}
		else if (StrEqual(info, "Stamina"))
		{
			ToggleStamina(param1);
		}
		else if (StrEqual(info, "Duck Stamina"))
		{
			ToggleDuckStamina(param1);
		}
		Menu_ShowPos(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}


// ShowPos //

void ToggleShowPos(int client)
{
	gI_Enable[client] = (gI_Enable[client] + 1) % SHOWPOS_COUNT;
	SetCookie(client, gH_ShowPosCookie, gI_Enable[client]);
	char buffer[64];
	switch (gI_Enable[client])
	{
		case ShowPos_Disabled:
		{
			FormatEx(buffer, sizeof(buffer), "ShowPos disabled.");
		}
		case ShowPos_Simple:
		{
			FormatEx(buffer, sizeof(buffer), "ShowPos now shows simplified values.");
		}
		case ShowPos_Detailed:
		{
			FormatEx(buffer, sizeof(buffer), "ShowPos now shows detailed values.");
		}
	}
	PrintToChat(client, "%s%s", PREFIX, buffer);
}

// Origin //

void ToggleOrigin(int client)
{
	gB_Origin[client] = !gB_Origin[client];
	SetCookie(client, gH_OriginCookie, gB_Origin[client]);
	PrintToChat(client, "%sOrigin display %s.", PREFIX, gB_Origin[client] ? "enabled" : "disabled");
}

// Angles //

void ToggleAngles(int client)
{
	gI_Angles[client] = (gI_Angles[client] + 1) % ANGLES_COUNT;
	SetCookie(client, gH_AnglesCookie, gI_Angles[client]);
	char buffer[64];
	switch (gI_Angles[client])
	{
		case Angles_Disabled:
		{
			FormatEx(buffer, sizeof(buffer), "Angles display disabled.");
		}
		case Velocity_Horizontal:
		{
			FormatEx(buffer, sizeof(buffer), "Angles now show pitch and yaw.");
		}
		case Velocity_Absolute:
		{
			FormatEx(buffer, sizeof(buffer), "Angles now show pitch, yaw and roll.");
		}
	}
	PrintToChat(client, "%s%s", PREFIX, buffer);
}

// Velocity //

void ToggleVelocity(int client)
{
	gI_Velocity[client] = (gI_Velocity[client] + 1) % VELOCITY_COUNT;
	SetCookie(client, gH_VelocityCookie, gI_Velocity[client]);
	char buffer[64];
	switch (gI_Velocity[client])
	{
		case Velocity_Disabled:
		{
			FormatEx(buffer, sizeof(buffer), "Velocity display disabled.");
		}
		case Velocity_Horizontal:
		{
			FormatEx(buffer, sizeof(buffer), "Velocity now shows horizontal speed.");
		}
		case Velocity_Absolute:
		{
			FormatEx(buffer, sizeof(buffer), "Velocity now shows absolute speed.");
		}
		case Velocity_Vector:
		{
			FormatEx(buffer, sizeof(buffer), "Velocity now shows as a vector.");
		}
	}
	PrintToChat(client, "%s%s", PREFIX, buffer);
}

// Stamina //

void ToggleStamina(int client)
{
	gB_Stamina[client] = !gB_Stamina[client];
	SetCookie(client, gH_StaminaCookie, gB_Stamina[client]);
	PrintToChat(client, "%sStamina display %s.", PREFIX, gB_Stamina[client] ? "enabled" : "disabled");
}

// DuckStamina //

void ToggleDuckStamina(int client)
{
	gB_DuckStamina[client] = !gB_DuckStamina[client];
	SetCookie(client, gH_DuckStaminaCookie, gB_DuckStamina[client]);
	PrintToChat(client, "%sDuck stamina display %s.", PREFIX, gB_DuckStamina[client] ? "enabled" : "disabled");
	if (gB_DuckStamina[client])
	{
		PrintToChat(client, "%sDuck stamina format: Dck | DuckAmount DuckSpeed", PREFIX);
	}
}

// ====================
// Hooks
// ====================

public Action OnPlayerRunCmd(int client)
{
	if (gI_Enable[client] == ShowPos_Disabled) return Plugin_Continue;
	bool detailed = (gI_Enable[client] == ShowPos_Detailed);
	char buffer[128];
	char display[768];

	if (gB_Origin[client])
	{
		float origin[3];
		GetClientAbsOrigin(client, origin);
		FormatEx(buffer, sizeof(buffer), "Pos | %s %s %s\n", FormatValue(origin[0],detailed), FormatValue(origin[1],detailed), FormatValue(origin[2],detailed));
		StrCat(display, sizeof(display), buffer);
	}

	if (gI_Angles[client] != Angles_Disabled)
	{
		float angles[3];
		GetClientEyeAngles(client, angles);
		FormatEx(buffer, sizeof(buffer), gI_Angles[client] == Angles_YawPitch ? "Ang | %s %s\n" : "Ang | %s %s %s \n", 
			FormatValue(angles[0],detailed), FormatValue(angles[1],detailed), FormatValue(angles[2],detailed));

		StrCat(display, sizeof(display), buffer);
	}

	if (gI_Velocity[client] != Velocity_Disabled)
	{
		float velocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
		switch (gI_Velocity[client])
		{
			case Velocity_Horizontal:
			{
				float speed = SquareRoot(velocity[0] * velocity[0] + velocity[1] * velocity[1]);
				
				FormatEx(buffer, sizeof(buffer), "Vel  | %s\n", FormatValue(speed, detailed));
			}
			case Velocity_Absolute:
			{
				float speed = SquareRoot(velocity[0] * velocity[0] + velocity[1] * velocity[1] + velocity[2] * velocity[2]);
				
				FormatEx(buffer, sizeof(buffer), "Vel  | %s\n", FormatValue(speed, detailed));
			}
			case Velocity_Vector:
			{
				FormatEx(buffer, sizeof(buffer), "Vel  | %s %s %s\n", FormatValue(velocity[0], detailed), FormatValue(velocity[1], detailed), FormatValue(velocity[2], detailed));
			}
		}
		StrCat(display, sizeof(display), buffer);
	}
	if (gB_Stamina[client])
	{
		float stamina = GetEntPropFloat(client, Prop_Send, "m_flStamina");
		FormatEx(buffer, sizeof(buffer), "Sta %c%c| %s\n", 8198, 8198, FormatValue(stamina, detailed));
		StrCat(display, sizeof(display), buffer);
	}
	if (gB_DuckStamina[client])
	{
		float amount = GetEntPropFloat(client, Prop_Send, "m_flDuckAmount");
		float speed = GetEntPropFloat(client, Prop_Send, "m_flDuckSpeed");
		FormatEx(buffer, sizeof(buffer), "Dck | %s %s\n", FormatValue(amount, detailed), FormatValue(speed, detailed));
		StrCat(display, sizeof(display), buffer);
	}
	PrintHintText(client, display);
	return Plugin_Continue;
}

// ====================
// Cookies
// ====================

void RegisterCookies()
{
	gH_ShowPosCookie = RegClientCookie("ShowPos-cookie", "Main cookie for ShowPos", CookieAccess_Private);
	gH_OriginCookie = RegClientCookie("ShowPosOrigin-cookie", "Origin cookie for ShowPos", CookieAccess_Private);
	gH_AnglesCookie = RegClientCookie("ShowPosAngles-cookie", "Angles cookie for ShowPos", CookieAccess_Private);
	gH_VelocityCookie = RegClientCookie("ShowPosVelocity-cookie", "Velocity cookie for ShowPos", CookieAccess_Private);
	gH_StaminaCookie = RegClientCookie("ShowPosStamina-cookie", "Stamina cookie for ShowPos", CookieAccess_Private);
	gH_DuckStaminaCookie = RegClientCookie("ShowPosDuckStamina-cookie", "Duck stamina cookie for ShowPos", CookieAccess_Private);
}

int LoadCookie(int client, Handle cookie)
{
	char buffer[2];
	GetClientCookie(client, cookie, buffer, sizeof(buffer));
	return StringToInt(buffer);
}

void SetCookie(int client, Handle cookie, int variable)
{
	if (!AreClientCookiesCached(client))
	{
		return;
	}

	char buffer[2];
	IntToString(variable, buffer, sizeof(buffer));
	SetClientCookie(client, cookie, buffer);
}

public void OnClientCookiesCached(int client)
{
	gI_Enable[client] = LoadCookie(client, gH_ShowPosCookie);
	gB_Origin[client] = !!LoadCookie(client, gH_OriginCookie);
	gI_Angles[client] = LoadCookie(client, gH_AnglesCookie);
	gI_Velocity[client] = LoadCookie(client, gH_VelocityCookie);
	gB_Stamina[client] = !!LoadCookie(client, gH_StaminaCookie);
	gB_DuckStamina[client] = !!LoadCookie(client, gH_DuckStaminaCookie);
}

// ====================
// Helpers
// ====================

static char[] FormatValue(float value, bool detailed)
{
	char str1[64];
	char str2[64];
	if (detailed)
	{
		Format(str1, 64, "%13.6f", value);
	}
	else
	{
		Format(str1, 64, "%9.2f", value);
	}
	for (int i = 0; i < 64; i++)
	{
		if (str1[i] == 32) // "space"
		{
			StrCat(str2, 64, " ");
		}
		else if (str1[i] == 45) // -
		{
			char space[2];
			space[0] = 8198; //Six-Per-Em Space
			space[1] = 8198;
			StrCat(str2, 64, space);
		}
	}
	StrCat(str2, 64, str1);
	return str2;
}