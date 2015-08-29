#include "skse/GameData.h"
#include "skse/GameRTTI.h"
#include "skse/GameExtraData.h"

#include "skse/PapyrusWornObject.h"
#include "skse/PapyrusSKSE.h"
#include "skse/PapyrusSpell.h"

#include "skse/HashUtil.h"

#include "json/json.h"

#include "itemutils.h"

//Copied from referenceUtils::CreateEnchantment, modified to accept non-VM arrays
void CreateEnchantmentFromVectors(TESForm* baseForm, BaseExtraList * extraData, float maxCharge, std::vector<EffectSetting*> effects, std::vector<float> magnitudes, std::vector<UInt32> areas, std::vector<UInt32> durations)
{
	if (baseForm && (baseForm->formType == TESObjectWEAP::kTypeID || baseForm->formType == TESObjectARMO::kTypeID)) {
		EnchantmentItem * enchantment = NULL;
		if (effects.size() > 0 && magnitudes.size() == effects.size() && areas.size() == effects.size() && durations.size() == effects.size()) {
			tArray<MagicItem::EffectItem> effectItems;
			effectItems.Allocate(effects.size());

			UInt32 j = 0;
			for (UInt32 i = 0; i < effects.size(); i++) {
				EffectSetting * magicEffect = effects[i];
				if (magicEffect) { // Only add effects that actually exist
					effectItems[j].magnitude = magnitudes[i];
					effectItems[j].area = areas[i];
					effectItems[j].duration = durations[i];
					effectItems[j].mgef = magicEffect;
					j++;
				}
			}
			effectItems.count = j; // Set count to existing count

			if (baseForm->formType == TESObjectWEAP::kTypeID)
				enchantment = CALL_MEMBER_FN(PersistentFormManager::GetSingleton(), CreateOffensiveEnchantment)(&effectItems);
			else
				enchantment = CALL_MEMBER_FN(PersistentFormManager::GetSingleton(), CreateDefensiveEnchantment)(&effectItems);

			FormHeap_Free(effectItems.arr.entries);
		}

		if (enchantment) {
			if (maxCharge > 0xFFFF) // Charge exceeds uint16 clip it
				maxCharge = 0xFFFF;

			ExtraEnchantment* extraEnchant = static_cast<ExtraEnchantment*>(extraData->GetByType(kExtraData_Enchantment));
			if (extraEnchant) {
				PersistentFormManager::GetSingleton()->DecRefEnchantment(extraEnchant->enchant);
				extraEnchant->enchant = enchantment;
				PersistentFormManager::GetSingleton()->IncRefEnchantment(extraEnchant->enchant);

				extraEnchant->maxCharge = (UInt16)maxCharge;
			}
			else {
				ExtraEnchantment* extraEnchant = ExtraEnchantment::Create();
				extraEnchant->enchant = enchantment;
				extraEnchant->maxCharge = (UInt16)maxCharge;
				extraData->Add(kExtraData_Enchantment, extraEnchant);
			}
		}
	}
}

//Copied from papyrusactor.cpp since it's not in the header file
SInt32 ssCalcItemId(TESForm * form, BaseExtraList * extraList)
{
	if (!form || !extraList)
		return 0;

	const char * name = extraList->GetDisplayName(form);

	// No name in extra data? Use base form name
	if (!name)
	{
		TESFullName* pFullName = DYNAMIC_CAST(form, TESForm, TESFullName);
		if (pFullName)
			name = pFullName->name.data;
	}

	if (!name)
		return 0;

	return (SInt32)HashUtil::CRC32(name, form->formID & 0x00FFFFFF);
}

AlchemyItem* _CreateCustomPotionFromVector(std::vector<EffectSetting*> effects, std::vector<float> magnitudes, std::vector<UInt32> areas, std::vector<UInt32> durations, SInt32 forceType)
{
	AlchemyItem * potion = nullptr;

	bool isPoison = false;

	if (effects.size() > 0 && magnitudes.size() == effects.size() && areas.size() == effects.size() && durations.size() == effects.size()) {
		tArray<MagicItem::EffectItem> effectItems;
		effectItems.Allocate(effects.size());

		UInt32 j = 0;
		for (UInt32 i = 0; i < effects.size(); i++) {
			EffectSetting * magicEffect = effects[i];
			if (magicEffect) { // Only add effects that actually exist
				effectItems[j].magnitude = magnitudes[i];
				effectItems[j].area = areas[i];
				effectItems[j].duration = durations[i];
				effectItems[j].mgef = magicEffect;
				j++;
			}
		}
		effectItems.count = j; // Set count to existing count

		//Has user forced the poison setting?
		if (forceType == 1) {
			isPoison = false;
		}
		else if (forceType == 2) {
			isPoison = true;
		}
		else {
			//Auto-determine if it's poison
			UInt32 archetype = effectItems[0].mgef->properties.archetype;
			UInt32 isDetrimental = (effectItems[0].mgef->properties.flags & EffectSetting::Properties::kEffectType_Detrimental) != 0;

			switch (archetype)
			{
			case EffectSetting::Properties::kArchetype_ValueMod:
			case EffectSetting::Properties::kArchetype_DualValueMod:
			case EffectSetting::Properties::kArchetype_PeakValueMod:
			{
				isPoison = isDetrimental ? true : false;
				break;
			}
			case EffectSetting::Properties::kArchetype_Absorb:
			case EffectSetting::Properties::kArchetype_CureDisease:
			case EffectSetting::Properties::kArchetype_Invisibility:
			case EffectSetting::Properties::kArchetype_CureParalysis:
			case EffectSetting::Properties::kArchetype_CureAddiction:
			case EffectSetting::Properties::kArchetype_CurePoison:
			case EffectSetting::Properties::kArchetype_Dispel:
			{
				isPoison = false;
				break;
			}
			case EffectSetting::Properties::kArchetype_Frenzy:
			case EffectSetting::Properties::kArchetype_Calm:
			case EffectSetting::Properties::kArchetype_Demoralize:
			case EffectSetting::Properties::kArchetype_Paralysis:
			{
				isPoison = true;
				break;
			}
			}
		}
		if (isPoison) {
			CALL_MEMBER_FN(PersistentFormManager::GetSingleton(), CreatePoison)(&potion, &effectItems);
		}
		else {
			CALL_MEMBER_FN(PersistentFormManager::GetSingleton(), CreatePotion)(&potion, &effectItems);
		}

		FormHeap_Free(effectItems.arr.entries);
	}

	return (AlchemyItem*)potion;
}

AlchemyItem* _CreateCustomPotion(VMArray<EffectSetting*> effects, VMArray<float> magnitudes, VMArray<UInt32> areas, VMArray<UInt32> durations, SInt32 forceType)
{
	AlchemyItem * potion = nullptr;

	std::vector<EffectSetting*> effects_v;
	std::vector<float> magnitudes_v;
	std::vector<UInt32> areas_v;
	std::vector<UInt32> durations_v;

	for (UInt32 i = 0; i < effects.Length(); i++) {
		float magnitude = 0;
		UInt32 area = 0;
		UInt32 duration = 0;
		EffectSetting * magicEffect = NULL;
		effects.Get(&magicEffect, i);
		if (magicEffect) { // Only add effects that actually exist
			magnitudes.Get(&magnitude, i);
			areas.Get(&area, i);
			durations.Get(&duration, i);
			effects_v.push_back(magicEffect);
			magnitudes_v.push_back(magnitude);
			areas_v.push_back(area);
			durations_v.push_back(duration);
		}
	}

	return _CreateCustomPotionFromVector(effects_v, magnitudes_v, areas_v, durations_v, forceType);
}

bool IsPlayerPotion(TESForm* potion)
{
	return (bool)(potion->formID >> 24 == 0xff && (potion->formType == AlchemyItem::kTypeID));
}

bool IsObjectFavorited(TESForm * form)
{
	PlayerCharacter* player = (*g_thePlayer);
	if (!player || !form)
		return false;

	UInt8 formType = form->formType;

	// Spell or shout - check MagicFavorites
	if (formType == kFormType_Spell || formType == kFormType_Shout)
	{
		MagicFavorites * magicFavorites = MagicFavorites::GetSingleton();

		return magicFavorites && magicFavorites->IsFavorited(form);
	}
	// Other - check ExtraHotkey. Any hotkey data (including -1) means favorited
	else
	{
		bool result = false;

		ExtraContainerChanges* pContainerChanges = static_cast<ExtraContainerChanges*>(player->extraData.GetByType(kExtraData_ContainerChanges));
		if (pContainerChanges) {
			HotkeyData data = pContainerChanges->FindHotkey(form);
			if (data.pHotkey)
				result = true;
		}

		return result;
	}
}
