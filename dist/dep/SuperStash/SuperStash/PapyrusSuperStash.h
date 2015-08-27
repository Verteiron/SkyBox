#pragma once

class VMClassRegistry;
struct StaticFunctionTag;

#include <string>
#include <stdint.h>

#include "skse/Utilities.h"
#include "skse/PapyrusArgs.h"
#include "skse/GameTypes.h"
#include "skse/GameAPI.h"

#include "nioverride/ItemDataInterface.h"
#include "jContainers/jc_interface.h"

extern ItemDataInterface		* g_itemDataInterface;
extern const jc::reflection_interface * g_jContainersRootInterface;

namespace papyrusSuperStash
{
	void RegisterFuncs(VMClassRegistry* registry);

	BSFixedString GetObjectJSON(StaticFunctionTag*, TESObjectREFR* pObject);
	BSFixedString GetContainerJSON(StaticFunctionTag*, TESObjectREFR* pContainerRef);
	SInt32 FillContainerFromJSON(StaticFunctionTag*, TESObjectREFR* pContainerRef, BSFixedString filePath);
	AlchemyItem* CreateCustomPotion(StaticFunctionTag*, VMArray<EffectSetting*> effects, VMArray<float> magnitudes, VMArray<UInt32> areas, VMArray<UInt32> durations, SInt32 forcePotionType);
}