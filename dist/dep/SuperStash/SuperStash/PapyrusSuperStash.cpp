
#include "common/IPrefix.h"
#include "common/IFileStream.h"

#include "json/json.h"

#include "skse/GameData.h"
#include "skse/GameRTTI.h"
#include "skse/GameExtraData.h"
//#include "skse/GameStreams.h"

//#include "skse/PapyrusObjectReference.h"
#include "skse/PapyrusWornObject.h"
#include "skse/PapyrusSKSE.h"
#include "skse/PapyrusSpell.h"

#include "skse/HashUtil.h"

#include <shlobj.h>
#include <functional>
#include <random>
#include <algorithm>
//#include <iostream>
//#include <sstream>

#include "PapyrusSuperStash.h"

//#include "skse/skse_version.h"
//#include "skse/PluginManager.h"

//#include "skse/PluginAPI.h"

//#include "nioverride/ItemDataInterface.h"

typedef std::vector<TESForm*> FormVec;

//Temporary fix until this is implented in SKSE officially.
class SoulGemEntryData : public InventoryEntryData
{
public:
	//MEMBER_FN_PREFIX(InventoryEntryData);
	DEFINE_MEMBER_FN(GetSoulLevel, UInt32, 0x004756F0);
};

bool IsPlayerPotion(TESForm* potion)
{
	return (bool)(potion->formID >> 24 == 0xff && (potion->formType == AlchemyItem::kTypeID));
}

void VisitFormList(BGSListForm * formList, std::function<void(TESForm*)> functor)
{
	for (int i = 0; i < formList->forms.count; i++)
	{
		TESForm* childForm = NULL;
		if (formList->forms.GetNthItem(i, childForm))
			functor(childForm);
	}

	// Script Added Forms
	if (formList->addedForms) {
		for (int i = 0; i < formList->addedForms->count; i++) {
			UInt32 formid = 0;
			formList->addedForms->GetNthItem(i, formid);
			TESForm* childForm = LookupFormByID(formid);
			if (childForm)
				functor(childForm);
		}
	}
}

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

AlchemyItem* _CreateCustomPotionFromVector(std::vector<EffectSetting*> effects, std::vector<float> magnitudes, std::vector<UInt32> areas, std::vector<UInt32> durations, SInt32 forceType = 0)
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

AlchemyItem* _CreateCustomPotion(VMArray<EffectSetting*> effects, VMArray<float> magnitudes, VMArray<UInt32> areas, VMArray<UInt32> durations, SInt32 forceType = 0)
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


bool isReadable(const std::string& name) {
	FILE *file;
	
	if (fopen_s(&file, name.c_str(), "r") == 0) {
		fclose(file);
		return true;
	}
	else {
		return false;
	}
}

std::string GetSSDirectory()
{
	char path[MAX_PATH];
	if (!SUCCEEDED(SHGetFolderPath(NULL, CSIDL_MYDOCUMENTS | CSIDL_FLAG_CREATE, NULL, SHGFP_TYPE_CURRENT, path)))
	{
		return std::string();
	}
	strcat_s(path, sizeof(path), "\\My Games\\Skyrim\\SuperStash\\");
	return path;
}

UInt32 SSCopyFile(LPCSTR lpExistingFileName, LPCSTR lpNewFileName)
{
	UInt32 ret = 0;
	if (!isReadable(lpExistingFileName))
	{
		return ERROR_FILE_NOT_FOUND;
	}
	IFileStream::MakeAllDirs(lpNewFileName);
	if (!CopyFile(lpExistingFileName, lpNewFileName, false)) {
		UInt32 lastError = GetLastError();
		ret = lastError;
		switch (lastError) {
		case ERROR_FILE_NOT_FOUND: // We don't need to display a message for this
			break;
		default:
			_ERROR("%s - error copying file %s (Error %d)", __FUNCTION__, lpExistingFileName, lastError);
			break;
		}
	}
	return ret;
}

UInt32 SSMoveFile(LPCSTR lpExistingFileName, LPCSTR lpNewFileName)
{
	UInt32 ret = 0;
	if (!isReadable(lpExistingFileName))
	{
		return ERROR_FILE_NOT_FOUND;
	}
	IFileStream::MakeAllDirs(lpNewFileName);
	if (!MoveFile(lpExistingFileName, lpNewFileName)) {
		UInt32 lastError = GetLastError();
		ret = lastError;
		switch (lastError) {
		case ERROR_FILE_NOT_FOUND: // We don't need to display a message for this
			break;
		default:
			_ERROR("%s - error moving file %s (Error %d)", __FUNCTION__, lpExistingFileName, lastError);
			break;
		}
	}
	return ret;
}

UInt32 SSDeleteFile(LPCSTR lpExistingFileName)
{
	UInt32 ret = 0;
	if (!isReadable(lpExistingFileName))
	{
		return ERROR_FILE_NOT_FOUND;
	}
	if (!DeleteFile(lpExistingFileName)) {
		UInt32 lastError = GetLastError();
		ret = lastError;
		_ERROR("%s - error moving file %s (Error %d)", __FUNCTION__, lpExistingFileName, lastError);
	}
	return ret;
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

bool LoadJsonFromFile(const char * filePath, Json::Value &jsonData)
{
	IFileStream		currentFile;
	if (!currentFile.Open(filePath))
	{
		_ERROR("%s: couldn't open file (%s) Error (%d)", __FUNCTION__, filePath, GetLastError());
		return true;
	}

	char buf[512];

	std::string jsonString;
	while (!currentFile.HitEOF()){
		currentFile.ReadString(buf, sizeof(buf) / sizeof(buf[0]));
		jsonString.append(buf);
	}
	currentFile.Close();
	
	Json::Features features;
	features.all();

	Json::Reader reader(features);

	bool parseSuccess = reader.parse(jsonString, jsonData);
	if (!parseSuccess) {
		_ERROR("%s: Error occured parsing json for %s.", __FUNCTION__, filePath);
		return true;
	}
	return false;
}

std::string GetJCFormString(TESForm * form)
{
	/*	Return JContainer-style form serialization
		"__formData|Skyrim.esm|0x1396a"
		"__formData|Dragonborn.esm|0x24037"
		"__formData||0xff000960"					*/

	if (!form)
	{
		return NULL;
	}
	const char * modName = nullptr;

	UInt8 modIndex = form->formID >> 24;
	if (modIndex < 255)
	{
		DataHandler* pDataHandler = DataHandler::GetSingleton();
		ModInfo* modInfo = pDataHandler->modList.modInfoList.GetNthItem(modIndex);
		modName = (modInfo) ? modInfo->name : NULL;
	}

	UInt32 modFormID = (modName) ? (form->formID & 0xFFFFFF) : form->formID;
	
	char returnStr[MAX_PATH];
	sprintf_s(returnStr, "__formData|%s|0x%x", (modName) ? (modName) : "", modFormID);

	return returnStr;
}

TESForm* GetJCStringForm(std::string formString)
{
	TESForm * result = nullptr;

	std::vector<std::string> stringData;

	std::string formData("__formData");

	std::string testString("__formData||0xff001953");

	if (testString == formString)
		_DMESSAGE("Do something!");

	std::istringstream str(formString);
	
	std::string token;
	while (std::getline(str, token, '|')) {
		//std::cout << token << std::endl;
		stringData.push_back(token);
	}
	
	/*while (std::string::npos != pos || std::string::npos != lastPos)
	{
		std::string token = str.substr(lastPos, pos - lastPos); 
		stringData.push_back(BSFixedString(token.c_str()));
		lastPos = pos; //str.find_first_not_of(delimiters, pos);
		pos = str.find_first_of(delimiters, lastPos);
	}*/

	if (stringData[0] != formData)
		return result;

	if (!stringData[2].length())
		return result;

	UInt8 modIndex = 0xff;

	if (stringData[1].length()) {
		DataHandler* pDataHandler = DataHandler::GetSingleton();
		modIndex = pDataHandler->GetModIndex(stringData[1].c_str());
	}
	
	if (modIndex == 0xff)
		return result;

	std::string formIdString(stringData[2].c_str());

	UInt32 formId;

	try {
		formId = std::stoul(std::string(formIdString.begin(), formIdString.end()), nullptr, 0);
	}
	catch (const std::invalid_argument&) {
		return result;
	}
	catch (const std::out_of_range&) {
		return result;
	}

	formId |= modIndex << 24;
	result = LookupFormByID(formId);
	return result;
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

bool WriteItemData(TESForm* form, Json::Value jItemData)
{
	Json::StyledWriter writer;
	std::string jsonString = writer.write(jItemData);
	
	if (!jsonString.length()) {
		return true;
	}

	if (!jItemData["displayName"].isString()) {
		return true;
	}
	
	char filePath[MAX_PATH];
	sprintf_s(filePath, "%s/Items/%08x_%s.json", GetSSDirectory().c_str(), form->formID, jItemData["displayName"].asCString());
	

	IFileStream	currentFile;
	IFileStream::MakeAllDirs(filePath);
	if (!currentFile.Create(filePath))
	{
		_ERROR("%s: couldn't create preset file (%s) Error (%d)", __FUNCTION__, filePath, GetLastError());
		return true;
	}

	currentFile.WriteBuf(jsonString.c_str(), jsonString.length());
	currentFile.Close();

	return false;
}

Json::Value GetMagicItemJSON(MagicItem * pMagicItem)
{
	Json::Value jMagicItem;

	if (!pMagicItem)
		return jMagicItem;

	jMagicItem["form"] = GetJCFormString(pMagicItem);

	Json::Value jMagicEffects;

	for (int i = 0; i < magicItemUtils::GetNumEffects(pMagicItem); i++) {
		MagicItem::EffectItem * effectItem;
		pMagicItem->effectItemList.GetNthItem(i, effectItem);
		if (effectItem) {
			Json::Value effectItemData;
			effectItemData["form"] = GetJCFormString(effectItem->mgef);
			//effectItemData["formID"] = (Json::UInt)effectItem->mgef->formID;
			effectItemData["name"] = effectItem->mgef->fullName.name.data;
			if (effectItem->area)
				effectItemData["area"] = (Json::UInt)effectItem->area;
			if (effectItem->magnitude)
				effectItemData["magnitude"] = effectItem->magnitude;
			if (effectItem->duration)
				effectItemData["duration"] = (Json::UInt)effectItem->duration;
			jMagicEffects.append(effectItemData);
		}
	}
	if (!jMagicEffects.empty())
		jMagicItem["magicEffects"] = jMagicEffects;

	return jMagicItem;
}

Json::Value GetExtraDataJSON(TESForm* form, BaseExtraList* bel)
{
	Json::Value jBaseExtraList;
	
	if (!form || !bel)
		return jBaseExtraList;

	TESFullName* pFullName = DYNAMIC_CAST(form, TESForm, TESFullName);
	const char * sDisplayName = bel->GetDisplayName(form);

	if (sDisplayName && (sDisplayName != pFullName->name.data)) {
		jBaseExtraList["displayName"] = sDisplayName;
		UInt32 itemID = ssCalcItemId(form, bel); //ItemID as used by WornObject and SkyUI, might be useful
		if (itemID)
			jBaseExtraList["itemID"] = (Json::Int)itemID;
	}

	if (form->formType == TESObjectWEAP::kTypeID || form->formType == TESObjectARMO::kTypeID) {
		float itemHealth = referenceUtils::GetItemHealthPercent(form, bel);
		if (itemHealth > 1.0)
			jBaseExtraList["health"] = itemHealth;
		if (form->formType == TESObjectWEAP::kTypeID) {
			float itemMaxCharge = referenceUtils::GetItemMaxCharge(form, bel);
			if (itemMaxCharge) {
				jBaseExtraList["itemMaxCharge"] = itemMaxCharge;
				jBaseExtraList["itemCharge"] = referenceUtils::GetItemCharge(form, bel);
			}
		}
	}

	if (bel->HasType(kExtraData_Soul)) {
		ExtraSoul * xSoul = static_cast<ExtraSoul*>(bel->GetByType(kExtraData_Soul));
		if (xSoul) {
			//count returns UInt32 but value is UInt8, so strip the garbage
			UInt8 soulCount = xSoul->count & 0xFF;
			if (soulCount)
				jBaseExtraList["soulSize"] = (Json::UInt)(soulCount);
		}
	}

	EnchantmentItem * enchantment = referenceUtils::GetEnchantment(bel);
	if (enchantment) {
		Json::Value	enchantmentData;
		enchantmentData = GetMagicItemJSON(enchantment);
		if (!enchantmentData.empty())
			jBaseExtraList["enchantment"] = enchantmentData;
	}

	if (!jBaseExtraList.empty()) { //We don't want Count to be the only item in ExtraData
		ExtraCount* xCount = static_cast<ExtraCount*>(bel->GetByType(kExtraData_Count));
		if (xCount)
			jBaseExtraList["count"] = (Json::UInt)(xCount->count & 0xFFFF); //count returns UInt32 but value is UInt16, so strip the garbage
	}

	if (form->formType == TESObjectWEAP::kTypeID || form->formType == TESObjectARMO::kTypeID) {
		Json::Value fileData = jBaseExtraList;
		fileData["form"] = GetJCFormString(form);
		WriteItemData(form, fileData);
	}

	/*for (UInt32 i = 1; i < 0xB3; i++) {
	if (bel->HasType(i))
	_DMESSAGE("BaseExtraList has type: %0x", i);
	}*/

	return jBaseExtraList;
}

bool IsWorthSaving(BaseExtraList * bel) 
{
	if (!bel)
	{
		return false;
	}
	return (bel->HasType(kExtraData_Health)
		||  bel->HasType(kExtraData_Enchantment)
		||  bel->HasType(kExtraData_Charge)
		||  bel->HasType(kExtraData_Soul));
}

//Modified from PapyrusObjectReference.cpp!ExtraContainerFiller
class ExtraListJsonFiller
{
	TESForm * m_form;
	Json::Value m_json;
public:
	ExtraListJsonFiller(TESForm* form) : m_form(form), m_json() { }
	bool Accept(BaseExtraList* bel)
	{
		if (IsWorthSaving(bel)) {
			m_json.append(GetExtraDataJSON(m_form, bel));
		}
		return true;
	}

	Json::Value GetJSON() 
	{
		return m_json;
	}
};

Json::Value _GetItemJSON(TESForm * form, InventoryEntryData * entryData = NULL, BaseExtraList* bel = NULL)
{
	Json::Value formData;
	
	if (!form)
		return formData;

	//Leveled items completely screw things up
	if (DYNAMIC_CAST(form, TESForm, TESLevItem))
		return formData;
	
	formData["form"] = GetJCFormString(form);
	//formData["formID"] = (Json::UInt)form->formID;
	
	TESFullName* pFullName = DYNAMIC_CAST(form, TESForm, TESFullName);
	formData["name"] = pFullName->name.data;

	//_DMESSAGE("Processing %s - %08x ==---", pFullName->name.data, form->formID);

	//Get potion data for player-made potions
	if (form->formType == AlchemyItem::kTypeID && IsPlayerPotion(form)) {
		AlchemyItem * pAlchemyItem = DYNAMIC_CAST(form, TESForm, AlchemyItem);
		Json::Value	potionData = GetMagicItemJSON(pAlchemyItem);
		if (!potionData.empty()) {
			potionData["isPoison"] = pAlchemyItem->IsPoison();
			formData["potionData"] = potionData;
		}
	}

	//If there is a BaseExtraList, get more info
	Json::Value formExtraData;
	if (bel)
		formExtraData = GetExtraDataJSON(form, bel);

	if (!formExtraData.empty())
		formData["extraData"] = formExtraData;

	return formData;
}

Json::Value GetItemJSON(TESForm * form)
{
	return _GetItemJSON(form, NULL, NULL);
}
Json::Value GetItemJSON(TESForm * form, InventoryEntryData * entryData)
{
	return _GetItemJSON(form, entryData, NULL);
}
Json::Value GetItemJSON(TESForm * form, InventoryEntryData * entryData, BaseExtraList * bel)
{
	return _GetItemJSON(form, entryData, bel);
}
Json::Value GetItemJSON(TESForm * form, BaseExtraList * bel)
{
	return _GetItemJSON(form, NULL, bel);
}

//Modified from PapyrusObjectReference.cpp!ExtraContainerInfo
class ContainerJson 
{
	FormVec			m_vec;
	
	Json::Value		m_json;

	TESObjectREFR*	m_ref;
	TESContainer*	m_base;

public:
	ContainerJson(TESObjectREFR * pContainerRef) : m_vec(), m_ref(pContainerRef), m_base()
	{
		TESForm* pBaseForm = pContainerRef->baseForm;
		if (pBaseForm)
			m_base = DYNAMIC_CAST(pBaseForm, TESForm, TESContainer);

		ExtraContainerChanges* pXContainerChanges = static_cast<ExtraContainerChanges*>(pContainerRef->extraData.GetByType(kExtraData_ContainerChanges));
		if (!pXContainerChanges)
			return;
		EntryDataList * entryList = pXContainerChanges ? pXContainerChanges->data->objList : NULL;

		m_json.clear();

		Json::Value jContainerEntries;
		m_json["containerEntries"] = jContainerEntries;

		m_vec.reserve(128);
		if (entryList) {
			Json::Value jEntryDataList;
			m_json["entryDataList"] = jEntryDataList;
			entryList->Visit(*this);
		}
		std::sort(m_vec.begin(), m_vec.end());
	}

	bool Accept(InventoryEntryData* data)
	{
		if (data) {
			AppendJsonFromInventoryEntry(data);
		}
		return true;
	}

	void AppendJsonFromContainerEntry(TESContainer::Entry * pEntry)
	{
		Json::Value jContainerEntry;
		TESForm * thisForm = pEntry->form;
		if (thisForm) {
			jContainerEntry = GetItemJSON(thisForm);
			if (!jContainerEntry.empty()) {
				jContainerEntry["count"] = (Json::UInt)pEntry->count;
				jContainerEntry["writtenBy"] = "0";
				m_json["containerEntries"].append(jContainerEntry);
			}
		}
	}

	void AppendJsonFromInventoryEntry(InventoryEntryData * entryData)
	{
		TESForm * thisForm = entryData->type;
		if (!thisForm)
			return;

		m_vec.push_back(thisForm);
		Json::Value jInventoryEntryData;
		UInt32 countBase = m_base->CountItem(thisForm);
		UInt32 countChanges = entryData->countDelta;
		UInt32 countTotal = countBase + countChanges;

		if (countTotal > 0) {
			jInventoryEntryData = GetItemJSON(thisForm, entryData);
			jInventoryEntryData["count"] = (Json::UInt)(countTotal);
			jInventoryEntryData["writtenBy"] = "1";
		}

		ExtendDataList* edl = entryData->extendDataList;
		if (edl) { 
			Json::Value jExtendDataList;
			ExtraListJsonFiller extraJsonFiller(thisForm);
			edl->Visit(extraJsonFiller);
			jExtendDataList = extraJsonFiller.GetJSON();
			if (!jExtendDataList.empty()) {
				jInventoryEntryData["extendDataList"] = jExtendDataList;
			}
		}

		if (!jInventoryEntryData.empty())
			m_json["entryDataList"].append(jInventoryEntryData);
	}

	bool IsValidEntry(TESContainer::Entry* pEntry)
	{
		if (pEntry) {
			TESForm* pForm = pEntry->form;

			if (DYNAMIC_CAST(pForm, TESForm, TESLevItem))
				return false;
			
			if (!std::binary_search(m_vec.begin(), m_vec.end(), pForm)) {
				return true;
			}
		}
		return false;
	}

	std::string GetJsonString() {
		Json::StyledWriter writer;
		std::string jsonString = writer.write(m_json);

		return jsonString;
	}

	bool WriteTofile(std::string relativePath) {
		
		std::string jsonString = GetJsonString();

		if (!jsonString.length()) {
			return true;
		}

		char filePath[MAX_PATH];

		sprintf_s(filePath, "%s/%s", GetSSDirectory().c_str(), relativePath.c_str());

		IFileStream	currentFile;
		IFileStream::MakeAllDirs(filePath);
		if (!currentFile.Create(filePath))
		{
			_ERROR("%s: couldn't create preset file (%s) Error (%d)", __FUNCTION__, filePath, GetLastError());
			return true;
		}

		currentFile.WriteBuf(jsonString.c_str(), jsonString.length());
		currentFile.Close();

		return false;
	}

};

//Modified from PapyrusObjectReference.cpp!ExtraContainerFiller
class ContainerJsonFiller
{
	ContainerJson& m_containerjson;
public:
	// ContainerJson(TESObjectREFR * pContainerRef) : m_map(), m_vec(), m_ref(pContainerRef), m_base()
	ContainerJsonFiller(ContainerJson& c_containerjson) : m_containerjson(c_containerjson) { }

	bool Accept(TESContainer::Entry* pEntry)
	{
		SInt32 numItems = 0;
		if (m_containerjson.IsValidEntry(pEntry)) {
			m_containerjson.AppendJsonFromContainerEntry(pEntry);
		}
		return true;
	}
};

class EntryFormFinder
{
	TESForm* m_form;
public:
	EntryFormFinder(TESForm* a_form) : m_form(a_form) {}

	bool Accept(InventoryEntryData* pEntry)
	{
		if (pEntry->type == m_form) {
			return true;
		}
		return false;
	}
};

SInt32 FillContainerFromJson(TESObjectREFR* pContainerRef, Json::Value jContainerData)
{
	SInt32 result = 0;

	Json::Value jEntryDataList = jContainerData["entryDataList"];
	if (jEntryDataList.empty() || jEntryDataList.type() != Json::arrayValue)
		return result;

	TESContainer* pContainer = NULL;
	TESForm* pBaseForm = pContainerRef->baseForm;
	if (pBaseForm)
		pContainer = DYNAMIC_CAST(pBaseForm, TESForm, TESContainer);

	if (!pContainer)
		return result;
		
	ExtraContainerChanges* pXContainerChanges = static_cast<ExtraContainerChanges*>(pContainerRef->extraData.GetByType(kExtraData_ContainerChanges));
	if (!pXContainerChanges) {
		return result;
	}
	EntryDataList * entryList = pXContainerChanges ? pXContainerChanges->data->objList : NULL;

	for (auto & jEntryData : jEntryDataList) {
		TESForm * thisForm = GetJCStringForm(jEntryData["form"].asString());
		if (!thisForm) {
			Json::Value jPotionData = jEntryData["potionData"];
			if (!jPotionData.empty()) {
				std::vector<EffectSetting*> effects;
				std::vector<UInt32> durations;
				std::vector<float> magnitudes;
				std::vector<UInt32> areas;

				int effectNum = 0;
				for (auto & jMagicEffect : jPotionData["magicEffects"]) {
					EffectSetting* effect = DYNAMIC_CAST(GetJCStringForm(jMagicEffect["form"].asString()), TESForm, EffectSetting);
					effects.push_back(effect);
					durations.push_back((UInt32)jMagicEffect["duration"].asInt());
					areas.push_back((UInt32)jMagicEffect["area"].asInt());
					magnitudes.push_back((float)jMagicEffect["magnitude"].asFloat());
					effectNum++;
				}
				AlchemyItem* thisPotion = _CreateCustomPotionFromVector(effects, magnitudes, areas, durations);
				if (thisPotion)
					thisForm = thisPotion;
			}
		}
		UInt32 count = jEntryData["count"].asInt();
		if (thisForm && count) {
			InventoryEntryData * thisEntry = pXContainerChanges->data->FindItemEntry(thisForm);
			if (thisEntry) {
				thisEntry->countDelta = count - pContainer->CountItem(thisForm);
			}
			else {
				thisEntry = InventoryEntryData::Create(thisForm, count);
				entryList->Push(thisEntry);
			}

			Json::Value jExtendDataList = jEntryData["extendDataList"];
			if (!jExtendDataList.empty() && jExtendDataList.type() == Json::arrayValue) {
				ExtendDataList * edl = thisEntry->extendDataList;
				if (!edl) {
					edl = ExtendDataList::Create();
					thisEntry->extendDataList = edl;
				}
				//** Can't repopulate BELs until we figure out a way to create them from scratch
				//newEntry->extendDataList->Dump();
				int i = 0;
				for (auto & jBaseExtraData : jExtendDataList) {
					BaseExtraList * newBEL = thisEntry->extendDataList->GetNthItem(i);
					if (!newBEL) {
						newBEL = (BaseExtraList *)FormHeap_Allocate(sizeof(BaseExtraList));
						ASSERT(newBEL);
						newBEL->m_data = NULL;
						newBEL->m_presence = (BaseExtraList::PresenceBitfield*)FormHeap_Allocate(sizeof(BaseExtraList::PresenceBitfield));
						ASSERT(newBEL->m_presence);
						std::fill(newBEL->m_presence->bits, newBEL->m_presence->bits + 0x18, 0);
					}
					if (jBaseExtraData["displayName"].isString()) {
						std::string displayName(jBaseExtraData["displayName"].asString());
						std::istringstream str(displayName);
						std::vector<std::string> stringData;
						std::string token;
						while (std::getline(str, token, '(')) {
							stringData.push_back(token);
						}
						referenceUtils::SetDisplayName(newBEL, stringData[0].substr(0, stringData[0].length() - 1).c_str(), false);
					}
					if (jBaseExtraData["enchantment"].isObject()) {
						float maxCharge = jBaseExtraData["itemMaxCharge"].asFloat();
						
						std::vector<EffectSetting*> effects;
						std::vector<UInt32> durations;
						std::vector<float> magnitudes;
						std::vector<UInt32> areas;
						
						int effectNum = 0;
						for (auto & jMagicEffect : jBaseExtraData["enchantment"]["magicEffects"]) {
							EffectSetting* effect = DYNAMIC_CAST(GetJCStringForm(jMagicEffect["form"].asString()), TESForm, EffectSetting);
							effects.push_back(effect);
							durations.push_back((UInt32)jMagicEffect["duration"].asInt());
							areas.push_back((UInt32)jMagicEffect["area"].asInt());
							magnitudes.push_back((float)jMagicEffect["magnitude"].asFloat());
							effectNum++;
						}
						CreateEnchantmentFromVectors(thisForm, newBEL, maxCharge, effects, magnitudes, areas, durations);
					}
					if (jBaseExtraData["itemCharge"].isNumeric())
						referenceUtils::SetItemCharge(thisForm, newBEL, jBaseExtraData["itemCharge"].asFloat());
					
					if (jBaseExtraData["health"].isNumeric())
						referenceUtils::SetItemHealthPercent(thisForm, newBEL, jBaseExtraData["health"].asFloat());
											
					if (jBaseExtraData["soulSize"].isInt()) {
						UInt8 soulLevel = jBaseExtraData["soulSize"].asInt();
						ExtraSoul * extraSoul = static_cast<ExtraSoul*>(newBEL->GetByType(kExtraData_Soul));
						if (extraSoul) {
							extraSoul->count = soulLevel;
						}
						else {
							extraSoul = ExtraSoul::Create();
							extraSoul->count = (UInt8)soulLevel;
							newBEL->Add(kExtraData_Soul, extraSoul);
						}
					}

					if (jBaseExtraData["count"].isInt()) {
						UInt32 thisCount = jBaseExtraData["count"].asInt();
						ExtraCount * extraCount = static_cast<ExtraCount*>(newBEL->GetByType(kExtraData_Count));
						if (extraCount) {
							extraCount->count = thisCount;
						}
						else {
							extraCount = ExtraCount::Create();
							extraCount->count = (UInt8)thisCount;
							newBEL->Add(kExtraData_Count, extraCount);
						}
					}
					
					if (newBEL->m_data) {
						edl->Push(newBEL);
					}
					else {
						//FormHeap_Free(newBEL->m_data);
						FormHeap_Free(newBEL->m_presence);
						FormHeap_Free(newBEL);
					}
					i++;
				}
			}
		}
		//entryList->Dump();
	}

	return entryList->Count();
}

namespace papyrusSuperStash
{
	void TraceConsole(StaticFunctionTag*, BSFixedString theString)
	{
		Console_Print(theString.data);
	}
	
	BSFixedString userDirectory(StaticFunctionTag*) {
		return GetSSDirectory().c_str();
	}

	SInt32 RotateFile(StaticFunctionTag*, BSFixedString filename, SInt32 maxCount)
	{
		SInt32 ret = 0;

		if (maxCount < 1)
			return ret;

		char sourcePath[MAX_PATH];
		sprintf_s(sourcePath, "%s", filename);

		char drive[_MAX_DRIVE];
		char dir[_MAX_DIR];
		char fname[_MAX_FNAME];
		char ext[_MAX_EXT];
		errno_t err;

		err = _splitpath_s(sourcePath, drive, _MAX_DRIVE, dir, _MAX_DIR, fname, _MAX_FNAME, ext, _MAX_EXT);
		if (err != 0)
		{
			_ERROR("%s - error splitting path %s (Error %d)", __FUNCTION__, sourcePath, err);
			return err;
		}

		char prevPath[MAX_PATH];
		char targetPath[MAX_PATH];
		char prevFilename[_MAX_FNAME];
		char targetFilename[_MAX_FNAME];

		//delete file.maxCount
		sprintf_s(targetFilename, "%s.%d", fname, maxCount);
		_makepath_s(targetPath, _MAX_PATH, drive, dir, targetFilename, ext);
		err = SSDeleteFile(targetPath);
		if (err != 0)
		{
			_ERROR("%s - error deleting file %s (Error %d)", __FUNCTION__, targetFilename, err);
			return err;
		}

		//do file rotation
		for (int i = maxCount - 1; i >= 0; i--) {
			sprintf_s(targetFilename, "%s.%d", fname, i + 1);
			sprintf_s(prevFilename, "%s.%d", fname, i);
			_makepath_s(targetPath, _MAX_PATH, drive, dir, targetFilename, ext);
			_makepath_s(prevPath, _MAX_PATH, drive, dir, prevFilename, ext);
			//_DMESSAGE("Moving %s to %s", prevPath, targetPath);
			SSMoveFile(prevPath, targetPath);
		}

		//move file.x to file.1.x
		sprintf_s(targetFilename, "%s.%d", fname, 1);
		_makepath_s(targetPath, _MAX_PATH, drive, dir, targetFilename, ext);
		SSMoveFile(sourcePath, targetPath);

		return ret;
	}

	BSFixedString UUID(StaticFunctionTag*)
	{
		int bytes[16];
		std::string s;
		std::random_device rd;
		std::mt19937 generator;
		std::uniform_int_distribution<int> distByte(0, 255);
		generator.seed(rd());
		for (int i = 0; i < 16; i++) {
			bytes[i] = distByte(generator);
		}
		bytes[6] &= 0x0f;
		bytes[6] |= 0x40;
		bytes[8] &= 0x3f;
		bytes[8] |= 0x80;
		char thisOctet[4];
		for (int i = 0; i < 16; i++) {
			sprintf_s(thisOctet, "%02x", bytes[i]);
			s += thisOctet;
		}
		s.insert(20, "-");
		s.insert(16, "-");
		s.insert(12, "-");
		s.insert(8, "-");
		return s.c_str();
	}

	SInt32 FilterFormlist(StaticFunctionTag*, BGSListForm* sourceList, BGSListForm* filteredList, UInt32 typeFilter)
	{
		SInt32 formCount = 0;
		if (sourceList && filteredList) {
			VisitFormList(sourceList, [&](TESForm * form){
				if (form->formType == typeFilter) {
					formCount++;
					CALL_MEMBER_FN(filteredList, AddFormToList)(form);
				}
			});
		}
		return formCount;
	}

	VMResultArray<TESForm*> GetFilteredList(StaticFunctionTag*, BGSListForm* sourceList, UInt32 typeFilter)
	{
		VMResultArray<TESForm*> result;
		if (sourceList) {
			VisitFormList(sourceList, [&](TESForm * form){
				if (form->formType == typeFilter) {
					result.push_back(form);
				}
			});
		}
		return result;
	}

	VMResultArray<SInt32> GetItemCounts(StaticFunctionTag*, VMArray<TESForm*> formArr, TESObjectREFR* object)
	{
		VMResultArray<SInt32> result;

		TESContainer* pContainer = NULL;
		TESForm* pBaseForm = object->baseForm;
		if (pBaseForm)
			pContainer = DYNAMIC_CAST(pBaseForm, TESForm, TESContainer);

		ExtraContainerChanges* containerChanges = static_cast<ExtraContainerChanges*>(object->extraData.GetByType(kExtraData_ContainerChanges));
		ExtraContainerChanges::Data* containerData = containerChanges ? containerChanges->data : NULL;
		if (!containerData)
			return result;

		TESForm *form = NULL;

		if (formArr.Length() && object) {
			for (int i = 0; i < formArr.Length(); i++) {
				formArr.Get(&form, i);
				if (form) {
					UInt32 countBase = pContainer->CountItem(form);
					
					UInt32 countChanges = 0;

					InventoryEntryData* entryData = containerData->FindItemEntry(form);
					
					InventoryEntryData::EquipData itemData;
					entryData->GetEquipItemData(itemData, 0, countBase);
					if (entryData) {
						countChanges = entryData->countDelta;
						result.push_back(countBase + countChanges);
					}
				}
			}
		}

		return result;
	}

	VMResultArray<SInt32> GetItemTypes(StaticFunctionTag*, VMArray<TESForm*> formArr)
	{
		VMResultArray<SInt32> result;

		TESForm *form = NULL;

		if (formArr.Length()) {
			for (int i = 0; i < formArr.Length(); i++) {
				formArr.Get(&form, i);
				if (form) {
					result.push_back(form->formType);
				}
			}
		}

		return result;
	}

	VMResultArray<BSFixedString> GetItemNames(StaticFunctionTag*, VMArray<TESForm*> formArr)
	{
		VMResultArray<BSFixedString> result;

		TESForm *form = NULL;

		if (formArr.Length()) {
			for (int i = 0; i < formArr.Length(); i++) {
				formArr.Get(&form, i);
				if (form) {
					TESFullName* pFullName = DYNAMIC_CAST(form, TESForm, TESFullName);
					result.push_back(pFullName->name.data);
				}
			}
		}

		return result;
	}

	VMResultArray<SInt32> GetItemFavorited(StaticFunctionTag* base, VMArray<TESForm*> formArr)
	{
		VMResultArray<SInt32> result;
		TESForm *form = NULL;

		if (formArr.Length()) {
			for (int i = 0; i < formArr.Length(); i++) {
				formArr.Get(&form, i);
				if (form) {
					result.push_back(IsObjectFavorited(form));
				}
			}
		}

		return result;
	}

	VMResultArray<SInt32> GetItemHasExtraData(StaticFunctionTag*, VMArray<TESForm*> formArr)
	{
		VMResultArray<SInt32> result;

		TESForm *form = NULL;

		PlayerCharacter* player = (*g_thePlayer);
		if (!player)
			return result;
		
		ExtraContainerChanges* containerChanges = static_cast<ExtraContainerChanges*>(player->extraData.GetByType(kExtraData_ContainerChanges));
		ExtraContainerChanges::Data* containerData = containerChanges ? containerChanges->data : NULL;
		if (!containerData)
			return result;

		if (formArr.Length()) {
			for (int i = 0; i < formArr.Length(); i++) {
				formArr.Get(&form, i);
				int thisResult = 0;
				if (form) {
					InventoryEntryData* formEntryData = containerData->FindItemEntry(form);
					//TESFullName* pFullName = DYNAMIC_CAST(form, TESForm, TESFullName);
					//_MESSAGE("Dumping extendDataList for form %08X (%s)-------", form->formID, (pFullName) ? pFullName->name.data : 0);
					if (formEntryData) {
						if (formEntryData->extendDataList->Count())
							thisResult = 1;
					}
					//_MESSAGE("------------------------------------------------", form->formID, (pFullName) ? pFullName->name.data : 0);
				}
				result.push_back(thisResult);
			}
		}

		return result;
	}

	BSFixedString GetSourceMod(StaticFunctionTag*, TESForm* form)
	{
		if (!form)
		{
			return NULL;
		}
		UInt8 modIndex = form->formID >> 24;
		if (modIndex > 255)
		{
			return NULL;
		}
		DataHandler* pDataHandler = DataHandler::GetSingleton();
		ModInfo* modInfo = pDataHandler->modList.modInfoList.GetNthItem(modIndex);
		return (modInfo) ? modInfo->name : NULL;
	}

	BSFixedString GetObjectJSON(StaticFunctionTag*, TESObjectREFR* pObject)
	{
		TESForm * form = pObject->baseForm;
		BaseExtraList * bel = &pObject->extraData;
	
		if (!(form && bel))
			return NULL;
		
		Json::StyledWriter writer;
		Json::Value formData = GetItemJSON(form, bel);

		std::string jsonData = writer.write(formData);
		return jsonData.c_str();
	}

	BSFixedString GetContainerJSON(StaticFunctionTag*, TESObjectREFR* pContainerRef)
	{
		const char * result = NULL;

		if (!pContainerRef) {
			return result;
		}

		TESContainer* pContainer = NULL;
		TESForm* pBaseForm = pContainerRef->baseForm;
		if (pBaseForm)
			pContainer = DYNAMIC_CAST(pBaseForm, TESForm, TESContainer);

		
		ContainerJson containerJsonData = ContainerJson(pContainerRef);

		//containerJsonData processes all the InventoryEntryData but still needs the ContainerEntries from the base object
		ContainerJsonFiller containerJsonFiller = ContainerJsonFiller(containerJsonData);
		pContainer->Visit(containerJsonFiller);

		containerJsonData.WriteTofile("/Stashes/superquick.json");

		return containerJsonData.GetJsonString().c_str();
	}

	SInt32 FillContainerFromJSON(StaticFunctionTag*, TESObjectREFR* pContainerRef, BSFixedString filePath)
	{
		Json::Value jsonData;
		LoadJsonFromFile(filePath.data, jsonData);
		if (jsonData.empty())
			return 0;
		return FillContainerFromJson(pContainerRef, jsonData);
	}

	AlchemyItem* CreateCustomPotion(StaticFunctionTag*, VMArray<EffectSetting*> effects, VMArray<float> magnitudes, VMArray<UInt32> areas, VMArray<UInt32> durations, SInt32 forcePotionType)
	{
		return _CreateCustomPotion(effects, magnitudes, areas, durations, forcePotionType);
	}

	/* This won't work. :( Soulgems do not retain their ExtraSoul data outside of containers, period.

	TESObjectREFR* FillSoulGem(StaticFunctionTag*, TESObjectREFR* object, SInt32 level)
	{
		TESSoulGem* soulgemBase = DYNAMIC_CAST(object->baseForm, TESForm, TESSoulGem);
		if (!soulgemBase)
			return object;

		BaseExtraList * bel = &object->extraData;

		for (int i = 0x01; i < 0xb3; i++) {
			if (bel->HasType(i))
				_DMESSAGE("Soulgem has BEL of type 0x%02x", i);
		}

		if (level && (level > 0 && level < 6)) {
			ExtraSoul * extraSoul = static_cast<ExtraSoul*>(bel->GetByType(kExtraData_Soul));
			if (extraSoul) {
				extraSoul->count = level;
			}
			else {
				extraSoul = ExtraSoul::Create();
				extraSoul->count = (UInt8)level;
				bel->Add(kExtraData_Soul, extraSoul);
			}
			_DMESSAGE("ExtraSoul->Count is now %d!", extraSoul->count);
		}
		return object;
	}

	*/
}

#include "skse/PapyrusVM.h"
#include "skse/PapyrusNativeFunctions.h"

void papyrusSuperStash::RegisterFuncs(VMClassRegistry* registry)
{
	registry->RegisterFunction(
		new NativeFunction1<StaticFunctionTag, void, BSFixedString>("TraceConsole", "SuperStash", papyrusSuperStash::TraceConsole, registry));

	registry->RegisterFunction(
		new NativeFunction0<StaticFunctionTag, BSFixedString>("userDirectory", "SuperStash", papyrusSuperStash::userDirectory, registry));

	registry->RegisterFunction(
		new NativeFunction2<StaticFunctionTag, SInt32, BSFixedString, SInt32>("RotateFile", "SuperStash", papyrusSuperStash::RotateFile, registry));

	registry->RegisterFunction(
		new NativeFunction0<StaticFunctionTag, BSFixedString>("UUID", "SuperStash", papyrusSuperStash::UUID, registry));

	registry->RegisterFunction(
		new NativeFunction3<StaticFunctionTag, SInt32, BGSListForm*, BGSListForm*, UInt32>("FilterFormlist", "SuperStash", papyrusSuperStash::FilterFormlist, registry));

	registry->RegisterFunction(
		new NativeFunction1<StaticFunctionTag, BSFixedString, TESForm*>("GetSourceMod", "SuperStash", papyrusSuperStash::GetSourceMod, registry));

	registry->RegisterFunction(
		new NativeFunction2<StaticFunctionTag, VMResultArray<TESForm*>, BGSListForm*, UInt32>("GetFilteredList", "SuperStash", papyrusSuperStash::GetFilteredList, registry));

	registry->RegisterFunction(
		new NativeFunction2<StaticFunctionTag, VMResultArray<SInt32>, VMArray<TESForm*>, TESObjectREFR*>("GetItemCounts", "SuperStash", papyrusSuperStash::GetItemCounts, registry));

	registry->RegisterFunction(
		new NativeFunction1<StaticFunctionTag, VMResultArray<SInt32>, VMArray<TESForm*>>("GetItemTypes", "SuperStash", papyrusSuperStash::GetItemTypes, registry));

	registry->RegisterFunction(
		new NativeFunction1<StaticFunctionTag, VMResultArray<SInt32>, VMArray<TESForm*>>("GetItemFavorited", "SuperStash", papyrusSuperStash::GetItemFavorited, registry));

	registry->RegisterFunction(
		new NativeFunction1<StaticFunctionTag, VMResultArray<SInt32>, VMArray<TESForm*>>("GetItemHasExtraData", "SuperStash", papyrusSuperStash::GetItemHasExtraData, registry));

	registry->RegisterFunction(
		new NativeFunction1<StaticFunctionTag, VMResultArray<BSFixedString>, VMArray<TESForm*>>("GetItemNames", "SuperStash", papyrusSuperStash::GetItemNames, registry));

	registry->RegisterFunction(
		new NativeFunction1<StaticFunctionTag, BSFixedString, TESObjectREFR*>("GetContainerJSON", "SuperStash", papyrusSuperStash::GetContainerJSON, registry));

	registry->RegisterFunction(
		new NativeFunction1<StaticFunctionTag, BSFixedString, TESObjectREFR*>("GetObjectJSON", "SuperStash", papyrusSuperStash::GetObjectJSON, registry));

	registry->RegisterFunction(
		new NativeFunction2<StaticFunctionTag, SInt32, TESObjectREFR*, BSFixedString>("FillContainerFromJSON", "SuperStash", papyrusSuperStash::FillContainerFromJSON, registry));
	
	registry->RegisterFunction(
		new NativeFunction5<StaticFunctionTag, AlchemyItem*, VMArray<EffectSetting*>, VMArray<float>, VMArray<UInt32>, VMArray<UInt32>, SInt32>("CreateCustomPotion", "SuperStash", papyrusSuperStash::CreateCustomPotion, registry));

	/*registry->RegisterFunction(
		new NativeFunction2<StaticFunctionTag, TESObjectREFR*, TESObjectREFR*, SInt32>("FillSoulGem", "SuperStash", papyrusSuperStash::FillSoulGem, registry));*/
		
}
