#include <functional>
#include <random>
#include <algorithm>

#include "skse/GameData.h"
#include "skse/GameRTTI.h"
#include "skse/GameExtraData.h"

#include "skse/PapyrusWornObject.h"
#include "skse/PapyrusSKSE.h"
#include "skse/PapyrusSpell.h"

#include "json/json.h"

#include "fileutils.h"
#include "itemutils.h"
#include "jcutils.h"
#include "PapyrusSuperStash.h"

typedef std::vector<TESForm*> FormVec;

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

void CreateEnchantmentFromJson(TESForm* form, BaseExtraList* bel, float maxCharge, Json::Value jEnchantment)
{
	if (!form || !bel || !maxCharge || jEnchantment.empty())
		return;

	std::vector<EffectSetting*> effects;
	std::vector<UInt32> durations;
	std::vector<float> magnitudes;
	std::vector<UInt32> areas;
	
	int effectNum = 0;
	for (auto & jMagicEffect : jEnchantment["magicEffects"]) {
		EffectSetting* effect = DYNAMIC_CAST(GetJCStringForm(jMagicEffect["form"].asString()), TESForm, EffectSetting);
		effects.push_back(effect);
		durations.push_back((UInt32)jMagicEffect["duration"].asInt());
		areas.push_back((UInt32)jMagicEffect["area"].asInt());
		magnitudes.push_back((float)jMagicEffect["magnitude"].asFloat());
		effectNum++;
	}
	CreateEnchantmentFromVectors(form, bel, maxCharge, effects, magnitudes, areas, durations);
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

bool IsWorthLoading(Json::Value jBaseExtraData)
{
	if (jBaseExtraData.empty())
		return false;

	return (jBaseExtraData["displayName"].isString()
		|| jBaseExtraData["enchantment"].isObject()
		|| jBaseExtraData["itemCharge"].isNumeric()
		|| jBaseExtraData["soulSize"].isNumeric());
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

//Removes (Fine), (Flawless), (Legendary) etc. Will also remove (foo).
std::string StripWeaponHealth(std::string displayName)
{
	//std::string displayName(jBaseExtraData["displayName"].asString());
	std::istringstream str(displayName);
	std::vector<std::string> stringData;
	std::string token;
	while (std::getline(str, token, '(')) {
		stringData.push_back(token);
	}
	return stringData[0].substr(0, stringData[0].length() - 1);
		
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
	const char * formName = NULL;
	TESFullName* pFullName = DYNAMIC_CAST(form, TESForm, TESFullName);
	if (pFullName)
		formName = pFullName->name.data;
	formData["name"] = formName ? formName : "";

	_DMESSAGE("Processing %s - %08x ==---", formName, form->formID);

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

BaseExtraList * CreateBaseExtraListFromJson(TESForm* thisForm, Json::Value jBaseExtraData)
{
	if (!thisForm || jBaseExtraData.empty())
		return nullptr;

	//The following seems to successfully create a new, working BEL without crashing anything.
	//Not 100% sure about the initialization, but so far it doesn't seem to crash...
	
	BaseExtraList * newBEL = (BaseExtraList *)FormHeap_Allocate(sizeof(BaseExtraList));
	ASSERT(newBEL);
	newBEL->m_data = nullptr;
	//Is this right? Seems to work as is...
	newBEL->m_presence = (BaseExtraList::PresenceBitfield*)FormHeap_Allocate(sizeof(BaseExtraList::PresenceBitfield));
	ASSERT(newBEL->m_presence);
	//Fill m_presence with 0s, otherwise the bad flags cause Skyrim to crash.
	std::fill(newBEL->m_presence->bits, newBEL->m_presence->bits + 0x18, 0);
	
	if (jBaseExtraData["displayName"].isString()) {
		std::string displayName(jBaseExtraData["displayName"].asString());
		displayName = StripWeaponHealth(displayName);
		if (displayName.length())
			referenceUtils::SetDisplayName(newBEL, displayName.c_str(), false);
	}

	if (jBaseExtraData["enchantment"].isObject()) {
		//Armors don't have maxcharge, so provide a default.
		float itemMaxCharge = 0xffff;
		if (jBaseExtraData["itemMaxCharge"].isNumeric())
			itemMaxCharge = jBaseExtraData["itemMaxCharge"].asFloat();
		CreateEnchantmentFromJson(thisForm, newBEL, itemMaxCharge, jBaseExtraData["enchantment"]);
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

	return newBEL;
}

//This should only be called on empty containers, at least for now.
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
		if (thisForm && (thisForm->formID >> 24 == 0xff)) {
			//This is a temporary form and should be sanity-checked, since these are not synced between saves.
			TESFullName* pFullName = DYNAMIC_CAST(thisForm, TESForm, TESFullName);
			if (!pFullName) {
				thisForm = nullptr;
			}
			else {
				if (jEntryData["name"].isString()) {
					if (pFullName->name.data != jEntryData["name"].asString().c_str())
						thisForm = nullptr;
				}
			}
		}
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
				//If anything in this plugin causes leaks or other Bad Things, it's probably this next bit.
				for (auto & jBaseExtraData : jExtendDataList) {
					if (IsWorthLoading(jBaseExtraData)) {
						BaseExtraList * newBEL = CreateBaseExtraListFromJson(thisForm, jBaseExtraData);
						if (newBEL->m_data)
							edl->Push(newBEL);
					}
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

		return ssRotateFile(filename.data, maxCount);
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
		new NativeFunction1<StaticFunctionTag, BSFixedString, TESForm*>("GetSourceMod", "SuperStash", papyrusSuperStash::GetSourceMod, registry));

	registry->RegisterFunction(
		new NativeFunction1<StaticFunctionTag, BSFixedString, TESObjectREFR*>("GetContainerJSON", "SuperStash", papyrusSuperStash::GetContainerJSON, registry));

	registry->RegisterFunction(
		new NativeFunction1<StaticFunctionTag, BSFixedString, TESObjectREFR*>("GetObjectJSON", "SuperStash", papyrusSuperStash::GetObjectJSON, registry));

	registry->RegisterFunction(
		new NativeFunction2<StaticFunctionTag, SInt32, TESObjectREFR*, BSFixedString>("FillContainerFromJSON", "SuperStash", papyrusSuperStash::FillContainerFromJSON, registry));
	
	registry->RegisterFunction(
		new NativeFunction5<StaticFunctionTag, AlchemyItem*, VMArray<EffectSetting*>, VMArray<float>, VMArray<UInt32>, VMArray<UInt32>, SInt32>("CreateCustomPotion", "SuperStash", papyrusSuperStash::CreateCustomPotion, registry));

}
