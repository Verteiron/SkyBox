#include "skse/GameData.h"

#include "jc_functions.h"

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

	//_MESSAGE("OnJCAPIAvailable");

	// Current API is not very usable - you'll have to obtain functions manually:

	g_jContainersRootInterface = root->query_interface<jc::reflection_interface>();
	if (!JArray_getForm)
		obtain_func(g_jContainersRootInterface, "getForm", "JArray", JArray_getForm);
	if (!JValue_objectFromPrototype)
		obtain_func(g_jContainersRootInterface, "objectFromPrototype", "JValue", JValue_objectFromPrototype);
	if (!JValue_release)
		obtain_func(g_jContainersRootInterface, "release", "JValue", JValue_release);
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