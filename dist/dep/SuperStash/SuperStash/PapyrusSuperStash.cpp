
#include "common/IPrefix.h"
#include "common/IFileStream.h"

#include "skse/PluginAPI.h"
#include "skse/skse_version.h"
#include "skse/GameData.h"
#include "skse/GameRTTI.h"
#include "skse/GameExtraData.h"

#include "skse/PapyrusObjectReference.h"

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
					if (entryData) {
						countChanges = entryData->countDelta;
					}
					result.push_back(countBase + countChanges);
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

}
