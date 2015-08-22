
#include "common/IPrefix.h"
#include "common/IFileStream.h"

#include "json/json.h"

#include "skse/PluginAPI.h"
#include "skse/skse_version.h"
#include "skse/GameData.h"
#include "skse/GameRTTI.h"
#include "skse/GameExtraData.h"

#include "skse/PapyrusObjectReference.h"
#include "skse/PapyrusWornObject.h"
#include "skse/PapyrusSpell.h"

#include "skse/HashUtil.h"

#include <shlobj.h>
#include <functional>
#include <random>
#include <algorithm>

#include "PapyrusSuperStash.h"

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
	strcat_s(path, sizeof(path), "/My Games/Skyrim/SuperStash/");
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

bool SaveFile(const char * filePath) 
{

	IFileStream		currentFile;
	IFileStream::MakeAllDirs(filePath);
	if (!currentFile.Create(filePath))
	{
		_ERROR("%s: couldn't create preset file (%s) Error (%d)", __FUNCTION__, filePath, GetLastError());
		return true;
	}
	


	//std::string data = writer.write(root);

	//currentFile.WriteBuf(data.c_str(), data.length());
	currentFile.Close();
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

//Copied from papyrusactor.cpp since it's not in the header file
SInt32 CalcItemId(TESForm * form, BaseExtraList * extraList)
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

Json::Value _GetExtraDataJSON(TESForm* form, BaseExtraList* bel)
{
	Json::Value jBaseExtraList;
	
	if (!form || !bel)
		return jBaseExtraList;

	TESFullName* pFullName = DYNAMIC_CAST(form, TESForm, TESFullName);
	const char * sDisplayName = bel->GetDisplayName(form);

	if (sDisplayName && (sDisplayName != pFullName->name.data)) {
		jBaseExtraList["displayName"] = sDisplayName;
		SInt32 itemID = CalcItemId(form, bel); //ItemID as used by WornObject and SkyUI, might be useful
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
			UInt16 soulCount = xSoul->count & 0xFF;
			if (soulCount)
				jBaseExtraList["soulSize"] = (Json::UInt)(xSoul->count & 0xFF);
		}
	}

	EnchantmentItem * enchantment = referenceUtils::GetEnchantment(bel);
	if (enchantment) {
		Json::Value	enchantmentData;
		enchantmentData["form"] = GetJCFormString(enchantment);
		//enchantmentData["formID"] = (Json::UInt)enchantment->formID;
		enchantmentData["name"] = enchantment->fullName.name.data;
		Json::Value magicEffects;
		for (int k = 0; k < enchantment->effectItemList.count; k++) {
			MagicItem::EffectItem * effectItem;
			enchantment->effectItemList.GetNthItem(k, effectItem);
			if (effectItem) {
				Json::Value effectItemData;
				effectItemData["form"] = GetJCFormString(effectItem->mgef);
				//effectItemData["formID"] = (Json::UInt)effectItem->mgef->formID;
				effectItemData["name"] = effectItem->mgef->fullName.name.data;
				effectItemData["area"] = (Json::UInt)effectItem->area;
				effectItemData["magnitude"] = effectItem->magnitude;
				effectItemData["duration"] = (Json::UInt)effectItem->duration;
				magicEffects.append(effectItemData);
			}
		}
		enchantmentData["magicEffects"] = magicEffects;
		jBaseExtraList["enchantment"] = enchantmentData;
	}

	if (!jBaseExtraList.empty()) { //We don't want Count to be the only item in ExtraData
		ExtraCount* xCount = static_cast<ExtraCount*>(bel->GetByType(kExtraData_Count));
		if (xCount)
			jBaseExtraList["count"] = (Json::UInt)(xCount->count & 0xFFFF); //count returns UInt32 but value is UInt16, so strip the garbage
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
			m_json.append(_GetExtraDataJSON(m_form, bel));
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
		Json::Value	potionData;
		AlchemyItem * pAlchemyItem = DYNAMIC_CAST(form, TESForm, AlchemyItem);
		Json::Value magicEffects;
		for (int i = 0; i < magicItemUtils::GetNumEffects(pAlchemyItem); i++) {
			MagicItem::EffectItem * effectItem;
			pAlchemyItem->effectItemList.GetNthItem(i, effectItem);
			if (effectItem) {
				Json::Value effectItemData;
				effectItemData["form"] = GetJCFormString(effectItem->mgef);
				//effectItemData["formID"] = (Json::UInt)effectItem->mgef->formID;
				effectItemData["name"] = effectItem->mgef->fullName.name.data;
				effectItemData["area"] = (Json::UInt)effectItem->area;
				effectItemData["magnitude"] = effectItem->magnitude;
				effectItemData["duration"] = (Json::UInt)effectItem->duration;
				magicEffects.append(effectItemData);
			}
		}
		potionData["magicEffects"] = magicEffects;
		formData["potionData"] = potionData;
	}

	//If there is a BaseExtraList, get more info
	Json::Value formExtraData;
	if (bel)
		formExtraData = _GetExtraDataJSON(form, bel);

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

	BSFixedString GetJSONForObject(StaticFunctionTag*, TESObjectREFR* pObject)
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

	BSFixedString GetJSONForContainer(StaticFunctionTag*, TESObjectREFR* pContainerRef)
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
		new NativeFunction1<StaticFunctionTag, BSFixedString, TESObjectREFR*>("GetJSONForContainer", "SuperStash", papyrusSuperStash::GetJSONForContainer, registry));

	registry->RegisterFunction(
		new NativeFunction1<StaticFunctionTag, BSFixedString, TESObjectREFR*>("GetJSONForObject", "SuperStash", papyrusSuperStash::GetJSONForObject, registry));
}
