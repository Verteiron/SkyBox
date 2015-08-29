#pragma once

#include "skse/GameData.h"
#include <vector>

//Copied from referenceUtils::CreateEnchantment, modified to accept non-VM arrays
void CreateEnchantmentFromVectors(TESForm* baseForm, BaseExtraList * extraData, float maxCharge, std::vector<EffectSetting*> effects, std::vector<float> magnitudes, std::vector<UInt32> areas, std::vector<UInt32> durations);

//Copied from papyrusactor.cpp since it's not in the header file
SInt32 ssCalcItemId(TESForm * form, BaseExtraList * extraList);

AlchemyItem* _CreateCustomPotionFromVector(std::vector<EffectSetting*> effects, std::vector<float> magnitudes, std::vector<UInt32> areas, std::vector<UInt32> durations, SInt32 forceType = 0);
AlchemyItem* _CreateCustomPotion(VMArray<EffectSetting*> effects, VMArray<float> magnitudes, VMArray<UInt32> areas, VMArray<UInt32> durations, SInt32 forceType = 0);
bool IsPlayerPotion(TESForm* potion);
bool IsObjectFavorited(TESForm * form);