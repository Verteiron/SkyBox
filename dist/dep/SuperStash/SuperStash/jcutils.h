#pragma once

#include "skse/GameData.h"
#include "skse/PluginManager.h"

#include "jContainers/jc_interface.h"

extern const jc::reflection_interface * g_jContainersRootInterface;

extern TESForm* (*JArray_getForm)(void*, SInt32 obj, SInt32 idx, TESForm* def);
extern SInt32(*JValue_objectFromPrototype)(void*, const char *prototype);
extern SInt32(*JValue_release)(void*, SInt32 obj);

template<class T>
void obtain_func(const jc::reflection_interface *refl, const char *funcName, const char *className, T& func);

void OnJCAPIAvailable(const jc::root_interface * root);

void JCMessageHandler(SKSEMessagingInterface::Message * message);

bool JCAvailable();

std::string GetJCFormString(TESForm * form);
TESForm* GetJCStringForm(std::string formString);