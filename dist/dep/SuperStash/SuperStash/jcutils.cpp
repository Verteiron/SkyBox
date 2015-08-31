#include <sstream>
#include "skse/GameData.h"

#include "jcutils.h"

const jc::reflection_interface * g_jContainersRootInterface = NULL;

TESForm* (*JArray_getForm)(void*, SInt32 obj, SInt32 idx, TESForm* def) = nullptr;
SInt32(*JValue_objectFromPrototype)(void*, const char *prototype) = nullptr;
SInt32(*JValue_release)(void*, SInt32 obj) = nullptr;

template<class T>
void obtain_func(const jc::reflection_interface *refl, const char *funcName, const char *className, T& func) {
	assert(refl);
	func = (T)refl->tes_function_of_class(funcName, className);
	assert(func);
}

void OnJCAPIAvailable(const jc::root_interface * root) {
	g_jContainersRootInterface = root->query_interface<jc::reflection_interface>();
	
	if (!JValue_release)
		obtain_func(g_jContainersRootInterface, "release", "JValue", JValue_release);
	if (!JValue_objectFromPrototype)
		obtain_func(g_jContainersRootInterface, "objectFromPrototype", "JValue", JValue_objectFromPrototype);
	if (!JArray_getForm)
		obtain_func(g_jContainersRootInterface, "getForm", "JArray", JArray_getForm);
}

void JCMessageHandler(SKSEMessagingInterface::Message * message)
{
	//_MESSAGE("Got message from %s of type %d", std::string(message->sender).c_str(), message->type);
	if (message && message->type == jc::message_root_interface) {
		OnJCAPIAvailable(jc::root_interface::from_void(message->data));
		if (g_jContainersRootInterface)
			_MESSAGE("Obtained JContainers interface! :D");
	}
}

bool JCAvailable() {
	if (g_jContainersRootInterface)
		return true;
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

	// If JContainers is around, use it to get the form. Otherwise use our own method.
	if (JCAvailable()) {
		//Turn the string into a single-item JSON array, then get JContainers to retrieve the form.
		std::string formArrayString("[ \"" + formString + "\" ]");
		SInt32 tempJArray = JValue_objectFromPrototype(nullptr, formArrayString.c_str());
		result = JArray_getForm(nullptr, tempJArray, 0, nullptr);
		JValue_release(nullptr, tempJArray);

		return result;
	}
	// The following works without JContainers, but is nasty and may break in future versions

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