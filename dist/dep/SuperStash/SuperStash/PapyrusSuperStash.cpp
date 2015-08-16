
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

#include "PapyrusSuperStash.h"


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
	char static * modName = "";

	UInt8 modIndex = form->formID >> 24;
	if (modIndex <= 255)
	{
		DataHandler* pDataHandler = DataHandler::GetSingleton();
		ModInfo* modInfo = pDataHandler->modList.modInfoList.GetNthItem(modIndex);
		modName = (modInfo) ? modInfo->name : "";
	}
	

	UInt32 modFormID = (modName) ? (form->formID & 0xFFFFFF) : form->formID;
	
	char returnStr[MAX_PATH];
	sprintf_s(returnStr, "__formData|%s|0x%x", modName, modFormID);

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

Json::Value GetItemJSON(TESForm * form, BaseExtraList* bel)
{
	Json::Value formData;
	
	if (!form)
		return formData;

	formData["form"] = GetJCFormString(form);
	formData["formID"] = (Json::UInt)form->formID;
	
	TESFullName* pFullName = DYNAMIC_CAST(form, TESForm, TESFullName);
	formData["name"] = pFullName->name.data;

	Json::Value formExtraData;

	//Get potion data
	if (form->formType == AlchemyItem::kTypeID) {
		Json::Value	potionData;
		AlchemyItem * pAlchemyItem = DYNAMIC_CAST(form, TESForm, AlchemyItem);
		Json::Value magicEffects;
		for (int i = 0; i < magicItemUtils::GetNumEffects(pAlchemyItem); i++) {
			MagicItem::EffectItem * effectItem;
			pAlchemyItem->effectItemList.GetNthItem(i, effectItem);
			if (effectItem) {
				Json::Value effectItemData;
				effectItemData["form"] = GetJCFormString(effectItem->mgef);
				effectItemData["formID"] = (Json::UInt)effectItem->mgef->formID;
				effectItemData["name"] = effectItem->mgef->fullName.name.data;
				effectItemData["area"] = (Json::UInt)effectItem->area;
				effectItemData["magnitude"] = effectItem->magnitude;
				effectItemData["duration"] = (Json::UInt)effectItem->duration;
				magicEffects.append(effectItemData);
			}
		}
		potionData["magicEffects"] = magicEffects;
		formExtraData["potion"] = potionData;
	}

	//If there is a BaseExtraList, get more info
	if (bel) {
		const char * sDisplayName = bel->GetDisplayName(form);
		if (sDisplayName) {
			formExtraData["displayName"] = sDisplayName;
			SInt32 itemID = CalcItemId(form, bel); //ItemID as used by WornObject and SkyUI, might be useful
			if (itemID)
				formExtraData["itemID"] = (Json::Int)itemID;
		}

		if (form->formType == TESObjectWEAP::kTypeID || form->formType == TESObjectARMO::kTypeID) {
			float itemHealth = referenceUtils::GetItemHealthPercent(form, bel);
			if (itemHealth > 1.0)
				formExtraData["health"] = itemHealth;
			if (form->formType == TESObjectWEAP::kTypeID) {
				float itemMaxCharge = referenceUtils::GetItemMaxCharge(form, bel);
				if (itemMaxCharge) {
					formExtraData["itemMaxCharge"] = itemMaxCharge;
					formExtraData["itemCharge"] = referenceUtils::GetItemCharge(form, bel);
				}
				
			}
		}

		EnchantmentItem * enchantment = referenceUtils::GetEnchantment(bel);
		if (enchantment) {
			Json::Value	enchantmentData;
			enchantmentData["form"] = GetJCFormString(enchantment);
			enchantmentData["formID"] = (Json::UInt)enchantment->formID;
			enchantmentData["name"] = enchantment->fullName.name.data;
			Json::Value magicEffects;
			for (int k = 0; k < enchantment->effectItemList.count; k++) {
				MagicItem::EffectItem * effectItem;
				enchantment->effectItemList.GetNthItem(k, effectItem);
				if (effectItem) {
					Json::Value effectItemData;
					effectItemData["form"] = GetJCFormString(effectItem->mgef);
					effectItemData["formID"] = (Json::UInt)effectItem->mgef->formID;
					effectItemData["name"] = effectItem->mgef->fullName.name.data;
					effectItemData["area"] = (Json::UInt)effectItem->area;
					effectItemData["magnitude"] = effectItem->magnitude;
					effectItemData["duration"] = (Json::UInt)effectItem->duration;
					magicEffects.append(effectItemData);
				}
			}
			enchantmentData["magicEffects"] = magicEffects;
			formExtraData["enchantment"] = enchantmentData;
		}
	}

	if (!formExtraData.empty())
		formData["extraData"] = formExtraData;

	return formData;
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
			_DMESSAGE("Moving %s to %s", prevPath, targetPath);
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

		/*if (pContainer) {
			for (int i = 0; i < pContainer->numEntries; i++) {
				TESContainer::Entry* pEntry = pContainer->entries[i];
				pEntry->form
			}
		} */
		

		ExtraContainerChanges* pXContainerChanges = static_cast<ExtraContainerChanges*>(pContainerRef->extraData.GetByType(kExtraData_ContainerChanges));
		ExtraContainerChanges::Data* containerData = pXContainerChanges ? pXContainerChanges->data : NULL;
		if (!containerData)
			return result;

		TESForm *thisForm = NULL;

		Json::StyledWriter writer;
		Json::Value root;
		//All done except for container's base objects. 
		for (int i = 0; i < containerData->objList->Count(); i++) {
			InventoryEntryData * entryData = containerData->objList->GetNthItem(i);
			if (entryData) {
				thisForm = entryData->type;

				if (thisForm) {
					Json::Value formData;

					UInt32 countUnique = 0;
					UInt32 countBase = pContainer->CountItem(thisForm);
					UInt32 countChanges = entryData->countDelta;
					//TESObjectREFR* spawned = PlaceAtMe_Native(registry, this->stackId_, target, spawnForm, e.count, e.bForcePersist, e.bInitiallyDisabled);
					ExtendDataList* edl = entryData->extendDataList;
					formData = GetItemJSON(thisForm, NULL);
					if (edl) { //(thisForm->kTypeID == kFormType_Weapon || thisForm->kTypeID == kFormType_Armor) && 
						for (int j = 0; j < edl->Count(); j++) {
							BaseExtraList* bel = edl->GetNthItem(j);
							TESForm * entryForm = entryData->type;
							Json::Value customFormData = GetItemJSON(entryForm, bel);
							if (!customFormData["extraData"].empty()) {
								countUnique++;
								customFormData["count"] = 1;
								customFormData["writtenBy"] = "1";
								root.append(customFormData);
							}
							/*else {
								customFormData.removeMember("extraData"); //the test creates a null object in extraData, so remove it
								customFormData["count"] = (Json::UInt)(countBase + countChanges);
								customFormData["writtenBy"] = "2";
								root.append(customFormData);
							}*/
						}
					}
					//Add forms without EDLs to their own entry with their own count
					UInt32 countBaseForms = countBase + countChanges - countUnique;
					if (countBaseForms > 0) {
						formData["count"] = (Json::UInt)(countBase + countChanges - countUnique);
						formData["writtenBy"] = "3";
						//Strip extradata for persistent forms
						if (thisForm->formID >> 24 < 0xff)
							formData.removeMember("extraData");
						root.append(formData);
					}
				}
			}
		}

		std::string jsonData = writer.write(root);

		char filePath[MAX_PATH];

		sprintf_s(filePath, "%s/%s", GetSSDirectory().c_str(), "/Stashes/superquick.json");

		IFileStream		currentFile;
		IFileStream::MakeAllDirs(filePath);
		if (!currentFile.Create(filePath))
		{
			_ERROR("%s: couldn't create preset file (%s) Error (%d)", __FUNCTION__, filePath, GetLastError());
		}

		currentFile.WriteBuf(jsonData.c_str(), jsonData.length());
		currentFile.Close();

		return jsonData.c_str();
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
