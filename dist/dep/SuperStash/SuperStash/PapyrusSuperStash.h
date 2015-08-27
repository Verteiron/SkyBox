#pragma once

class VMClassRegistry;
struct StaticFunctionTag;

#include <string>
#include <stdint.h>

#include "skse/Utilities.h"
#include "skse/GameTypes.h"
#include "skse/GameAPI.h"

namespace papyrusSuperStash
{
	void RegisterFuncs(VMClassRegistry* registry);

	SInt32 FillContainerFromJSON(StaticFunctionTag*, TESObjectREFR* pContainerRef, BSFixedString filePath);
}