#include <ShlObj.h>

#include "skse/PluginAPI.h"
#include "skse/skse_version.h"
#include "skse/SafeWrite.h"
#include "skse/GameAPI.h"

#include "jcutils.h"
#include "PapyrusSuperStash.h"

IDebugLog	gLog;

PluginHandle	g_pluginHandle = kPluginHandle_Invalid;

SKSEMessagingInterface *g_messaging = NULL;

SKSEPapyrusInterface              * g_papyrus = NULL;

ItemDataInterface       * g_itemDataInterface = NULL;

//const jc::reflection_interface * g_jContainersRootInterface = NULL;

extern "C"
{

#define MIN_PAP_VERSION 1

	void NIOMessageHandler(SKSEMessagingInterface::Message * message)
	{
		_MESSAGE("Got message from %s of type %d", std::string(message->sender).c_str(), message->type);
	}

	void SKSEMessageHandler(SKSEMessagingInterface::Message * message)
	{
		//_MESSAGE("Got message from %s of type %d", std::string(message->sender).c_str(), message->type);
		switch (message->type)
		{
		case SKSEMessagingInterface::kMessage_PostLoad:
		{
			g_messaging->RegisterListener(g_pluginHandle, "nioverride", NIOMessageHandler);
			g_messaging->RegisterListener(g_pluginHandle, "JContainers", JCMessageHandler);

			//_MESSAGE("Got kMessage_PostLoad message from SKSE!");
			InterfaceExchangeMessage message;
			_MESSAGE("Dispatching InterfaceExchangeMessage from plugin %d (me) to nioverride", g_pluginHandle);
			if (!g_messaging->Dispatch(g_pluginHandle, InterfaceExchangeMessage::kMessage_ExchangeInterface, (void*)&message, sizeof(InterfaceExchangeMessage*), "nioverride")) {
				_MESSAGE("NIOverride not listening for us, so we'll pretend to be chargen.dll ...");
				int i = 1;
				while (!(message.interfaceMap) && (i < 20)) {
					if (g_messaging->Dispatch(i, InterfaceExchangeMessage::kMessage_ExchangeInterface, (void*)&message, sizeof(InterfaceExchangeMessage*), "nioverride")) {
						_MESSAGE("... Success!");
					}
					i++;
					if (i == g_pluginHandle)
						i++;
				}
			}
			if (message.interfaceMap) {
				g_itemDataInterface = static_cast<ItemDataInterface*>(message.interfaceMap->QueryInterface("ItemData"));
				if (g_itemDataInterface) {
					_MESSAGE("Got ItemDataInterface!");
				}
				else {
					_MESSAGE("Couldn't get ItemDataInterface!");
				}
			}
		}
		break;
		}
	}


bool SKSEPlugin_Query(const SKSEInterface * skse, PluginInfo * info)
{
	gLog.OpenRelative(CSIDL_MYDOCUMENTS, "\\My Games\\Skyrim\\SKSE\\skse_SuperStash.log");
	_DMESSAGE("skse_SuperStash");

	// populate info structure
	info->infoVersion =	PluginInfo::kInfoVersion;
	info->name =		"SuperStash";
	info->version =		1;

	// store plugin handle so we can identify ourselves later
	g_pluginHandle = skse->GetPluginHandle();

	if(skse->isEditor)
	{
		_FATALERROR("loaded in editor, marking as incompatible");
		return false;
	}
	else if(skse->runtimeVersion != RUNTIME_VERSION_1_9_32_0)
	{
		_FATALERROR("unsupported runtime version %08X", skse->runtimeVersion);
		return false;
	}

	// get the papyrus interface and query its version
	g_papyrus = (SKSEPapyrusInterface *)skse->QueryInterface(kInterface_Papyrus);
	if (!g_papyrus)
	{
		_FATALERROR("couldn't get papyrus interface");
		return false;
	}
	if (g_papyrus->interfaceVersion < MIN_PAP_VERSION)
	{
		_FATALERROR("papyrus interface too old (%d expected %d)", g_papyrus->interfaceVersion, MIN_PAP_VERSION);
		return false;
	}
	g_messaging = (SKSEMessagingInterface *)skse->QueryInterface(kInterface_Messaging);
	if (!g_messaging) {
		_ERROR("couldn't get messaging interface");
	}

	// supported runtime version
	return true;
}

bool RegisterFuncs(VMClassRegistry * registry)
{
	papyrusSuperStash::RegisterFuncs(registry);
	return true;
}

bool SKSEPlugin_Load(const SKSEInterface * skse)
{
	if (g_messaging)
		g_messaging->RegisterListener(g_pluginHandle, "SKSE", SKSEMessageHandler);

	if (g_papyrus)
		g_papyrus->Register(RegisterFuncs);

	return true;
}

};
