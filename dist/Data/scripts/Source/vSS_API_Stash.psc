Scriptname vSS_API_Stash extends vSS_APIBase Hidden
{API for saving, loading, and managing Stashes.}
;
; === [ vSS_API_Stash.psc ] ===============================================---
; @class vSS_API_Stash
; API for saving and loading Stashs. A Stash is a container that will be shared
; between multiple savegames/sessions.
; ========================================================---
; FIXME: HEY I just had this really hoopy idea. Papyrus coerces Forms into Strings. This means I can check
; to see if an incoming string is actually a Form, and consolidate these split functions into one 
; without breaking compatibility. Maybe. Might not be worth the effort.

Import vSS_Registry
Import vSS_Session

Int Function GetStashFormMap() Global
{
/**
*  @brief 	Return the JFormMap for all Stashes, creating it if it does not exist.
*  @return	A jFormMap.
*/
}
	Int jStashFormMap = GetRegObj("StashFormMap")
	If jStashFormMap
		Return jStashFormMap
	EndIf
	jStashFormMap = JFormMap.Object()
	SetRegObj("StashFormMap",jStashFormMap)
	Int jStashUUIDS = JMap.Object()
	SetRegObj("Stashes",jStashUUIDS)

	Return jStashFormMap
EndFunction

String Function CreateStashData(ObjectReference akStashRef) Global
{
/**
*  @brief 	Initialize the data for a new Stash based on akStashRef.
*  @param 	akStashRef The ObjectReference to use for the new Stash.
*  @return	The UUID of the new Stash.
*/
}
	Int jStashJMap = JMap.object()
	String sUUID = SuperStash.UUID()
	JMap.SetStr(jStashJMap,"UUID",sUUID)
	JMap.SetForm(jStashJMap,"Form",akStashRef)
	JMap.SetInt(jStashJMap,"FormID",akStashRef.GetFormID())
	JMap.SetStr(jStashJMap,"FormIDString",SuperStash.GetFormIDString(akStashRef))
	JMap.SetStr(jStashJMap,"Source",SuperStash.GetSourceMod(akStashRef))
	
	;Create Registry entries
	SetRegObj("Stashes." + sUUID, jStashJMap)
	JFormMap.SetObj(GetStashFormMap(),akStashRef,jStashJMap)
	SaveReg()
	
	Return sUUID
EndFunction

Int Function GetStashJMap(String asUUID) Global
{
/**
*  @brief 	Get the JMap for the specified Stash. If it's not in the registry, load it from its JSON file.
*  @param 	asUUID The UUID of the Stash.
*  @return	The JMap object or 0 if not found.
*/
}
	Int jStashJMap = GetRegObj("Stashes." + asUUID)
	If JValue.isMap(jStashJMap)
		Return jStashJMap
	Else ;Attempt to load from JSON
		String sStashFileName  = GetStashFileNameString(asUUID)
		String sFilePath = SuperStash.userDirectory() + "Stashes\\" ;"; <-- fix for highlighting in SublimePapyrus
		sFilePath += sStashFileName + ".json"
		jStashJMap = JValue.ReadFromFile(sFilePath)
		If JValue.isMap(jStashJMap)
			If JMap.GetStr(jStashJMap,"UUID") == asUUID
				SetRegObj("Stashes." + asUUID,jStashJMap)
				Return jStashJMap
			Else ; UUID mismatch - probably should give the user the option to load anyway, but for now just fail
				DebugTraceAPIStash("ERROR: Stash in JSON (" + JMap.GetStr(jStashJMap,"UUID") + ") does not match registry entry (" + asUUID + ")!")
			EndIf
		EndIf
	EndIf
	Return 0
EndFunction

Int Function GetStashBackupJMap(String asUUID, Int aiBackupNum = 1) Global
{
/**
*  @brief 	Get the JMap for the specified revison of a Stash.
*  @param 	asUUID The UUID of the Stash.
*  @param 	aiBackupNum The revision number. Higher is older. Default max is 9.
*  @return	The JMap object or 0 if not found.
*/
}
	String sStashFileName  = GetStashFileNameString(asUUID)
	String sFilePath = SuperStash.userDirectory() + "Stashes\\" ;"; <-- fix for highlighting in SublimePapyrus
	sFilePath += sStashFileName + "." + aiBackupNum + ".json" 
	Int jStashJMap = JValue.ReadFromFile(sFilePath)
	If JValue.isMap(jStashJMap)
		Return jStashJMap
	EndIf
	Return 0
EndFunction

Int Function RevertToBackup(String asUUID, Int aiBackupNum = 1) Global
{
/**
*  @brief 	Revert the contents of the Stash to those in the specified revision.
*  @param 	asUUID The UUID of the Stash.
*  @param 	aiBackupNum The revision number. Higher is older. Default max is 9.
*  @return	0 if successful, -1 if the Stash is not found.
*
*  @warning This function will DELETE any items currently in the Stash Container.
*/
}
	Int jStashJMap = GetStashBackupJMap(asUUID,aiBackupNum)
	If !jStashJMap
		Return -1
	EndIf
	DebugTraceAPIStash("RevertToBackup/ + " + asUUID + ": Reverting to revision " + aiBackupNum + "!")
	JMap.SetInt(jStashJMap,"DataSerial",GetStashSessionInt(asUUID,"DataSerial") + 1)
	SetRegObj("Stashes." + asUUID,jStashJMap)
	ExportStash(asUUID)
	Utility.WaitMenuMode(0.1)
	ObjectReference kStashRef = GetStashRefForUUID(asUUID)
	DebugTraceAPIStash("RevertToBackup/ + " + asUUID + ": ObjectReference is " + kStashRef + "!")
	If kStashRef
		If kStashRef.Is3DLoaded()
			DebugTraceAPIStash("RevertToBackup/ + " + asUUID + ": ObjectReference is loaded, importing item right now!")
			Int iCount = ImportStashRefItems(kStashRef)
		EndIf
	EndIf

	Return 0
EndFunction

Int Function GetStashRefJMap(ObjectReference akStashRef) Global
{
/**
*  @brief 	Get the Stash JMap for the specified ObjectReference.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @return	The JMap object or 0 if not found.
*/
}
	Int jStashFormMap = GetStashFormMap()
	Int jStashJMap = JFormMap.GetObj(jStashFormMap,akStashRef)
	If JValue.isMap(jStashJMap)
		Return jStashJMap
	EndIf
	;jStashJMap wasn't valid, try searching the long way
	Int jStashList = GetRegObj("Stashes")
	String sKey = JMap.NextKey(jStashList)
	While sKey
		Int jStashValue = JMap.GetObj(jStashList,sKey)
		If JMap.GetForm(jStashValue,"Form") == akStashRef
			DebugTraceAPIStash("GetStashRefJMap: Warning! Stash data exists for " + akStashRef + " but is not indexed in StashFormMap! UUID: " + JMap.GetStr(jStashValue,"UUID"))
			Return jStashValue
		EndIf
		sKey = JMap.NextKey(jStashList,sKey)
	EndWhile
	Return 0
EndFunction

String Function GetUUIDForStashRef(ObjectReference akStashRef) Global
{
/**
*  @brief 	Get the Stash UUID of the specified ObjectReference.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @return	The Stash's UUID, or an empty string if none is found.
*/
}
	Return JMap.GetStr(GetStashRefJMap(akStashRef),"UUID")
EndFunction

ObjectReference Function GetStashRefForUUID(String asUUID) Global
{
/**
*  @brief 	Get the ObjectReferenc for the specified Stash.
*  @param 	asUUID The UUID of the Stash.
*  @return	The ObjectReference for the Stash if it exists, or None. *See note.*
*
*  @note	
*  ObjectReferences in unloaded Cells will also return None. There really isn't any way around this.
*/
}
	Return JMap.GetForm(GetStashJMap(asUUID),"Form") as ObjectReference
EndFunction

;@defgroup	SessionFunctions	Session-specific Functions

Int Function GetStashSessionFormMap() Global
{
/**
*  @brief 	Return the JFormMap for all Stashes in this Session, creating it if it does not exist.
*  @return	A jFormMap.
*  @ingroup	SessionFunctions
*/
}
	Int jStashFormMap = GetSessionObj("StashFormMap")
	If jStashFormMap
		Return jStashFormMap
	EndIf
	jStashFormMap = JFormMap.Object()
	SetSessionObj("StashFormMap",jStashFormMap)
	Return jStashFormMap
EndFunction

Int Function CreateStashSessionJMap(String asUUID = "") Global
{
/**
*  @brief 	Create the Session-specific data for a new Stash based on akStashRef.
*  @param 	asUUID The UUID to use for the new Stash, if one exists.
*  @return	The Session JMap for the new Stash.
*  @ingroup	SessionFunctions
*/
}
	Int jStashJMap = JMap.object()
	If !asUUID
		asUUID = SuperStash.UUID()
	Else
		DebugTraceAPIStash("CreateStashSessionJMap: Creating new Stash Session JMap based on existing UUID! UUID: " + asUUID,1)
	EndIf
	JMap.SetStr(jStashJMap,"UUID",asUUID)
	SetSessionObj("Stashes." + asUUID, jStashJMap)
	SaveSession()
	Return jStashJMap
EndFunction

Int Function GetStashSessionJMap(String asUUID, Bool abCreateIfMissing = False) Global
{
/**
*  @brief 	Return the Session-specific data for a Stash, optionally creating it if it is missing.
*  @param 	asUUID The UUID of the Stash.
*  @param 	abCreateIfMissing If set to True, create the Session-specific Stash data if it is missing. Default: False.
*  @return	The Session JMap for the Stash.
*  @ingroup	SessionFunctions
*/
}
	Int jStashJMap = GetSessionObj("Stashes." + asUUID)
	If JValue.isMap(jStashJMap)
		Return jStashJMap
	EndIf
	If abCreateIfMissing
		Return CreateStashSessionJMap(asUUID)
	EndIf
	Return 0
EndFunction

Int Function GetStashRefSessionJMap(ObjectReference akStashRef, Bool abCreateIfMissing = False) Global
{
/**
*  @brief 	Return the Session-specific data for a Stash using its ObjectReference, optionally creating it if it is missing.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @param 	abCreateIfMissing If set to True, create the Session-specific Stash data if it is missing. Default: False.
*  @return	The Session JMap for the Stash.
*  @ingroup	SessionFunctions
*/
}
	Int jStashFormMap = GetStashSessionFormMap()
	Int jStashJMap = JFormMap.GetObj(jStashFormMap,akStashRef)
	If JValue.isMap(jStashJMap)
		Return jStashJMap
	EndIf
	If abCreateIfMissing
		jStashJMap = CreateStashSessionJMap()
		JFormMap.SetObj(jStashFormMap,akStashRef,jStashJMap)
		SaveSession()
		Return jStashJMap
	EndIf
	Return 0
EndFunction

;@defgroup	StashBasicFunctions	Stash Basic Functions
;@{

Int Function GetStashSessionInt(String asUUID, String asKey) Global
{
/**
*  @brief 	Return an Int from the Session-specific data for a Stash.
*  @param 	asUUID The UUID of the Stash.
*  @param 	asKey The JContainers key to lookup.
*  @return	The requested Int.
*/
}
	asKey = MakePath(asKey)
	Int jStashJMap = GetStashSessionJMap(asUUID)
	If jStashJMap
		Return JValue.solveInt(jStashJMap,asKey)
	EndIf
	Return 0
EndFunction

Function SetStashSessionInt(String asUUID, String asKey, Int aiValue) Global
{
/**
*  @brief 	Set an Int in the Session-specific data for a Stash.
*  @param 	asUUID The UUID of the Stash.
*  @param 	asKey The JContainers key to set.
*  @param 	aiValue The new value.
*/
}
	asKey = MakePath(asKey)
	JValue.solveIntSetter(GetStashSessionJMap(asUUID,True),asKey,aiValue,True)
	SaveSession()
EndFunction

Int Function GetStashInt(String asUUID, String asKey) Global
{
/**
*  @brief 	Return an Int from the data for a Stash.
*  @param 	asUUID The UUID of the Stash.
*  @param 	asKey The JContainers key to lookup.
*  @return	The requested Int.
*/
}
	asKey = MakePath(asKey)
	Int jStashJMap = GetStashJMap(asUUID)
	If jStashJMap
		Return JValue.solveInt(jStashJMap,asKey)
	EndIf
	Return 0
EndFunction

Function SetStashInt(String asUUID, String asKey, Int aiValue) Global
{
/**
*  @brief 	Set an Int in the data for a Stash.
*  @param 	asUUID The UUID of the Stash.
*  @param 	asKey The JContainers key to set.
*  @param 	aiValue The new value.
*/
}
	asKey = MakePath(asKey)
	JValue.solveIntSetter(GetStashJMap(asUUID),asKey,aiValue,True)
	SaveReg()
EndFunction

Float Function GetStashFlt(String asUUID, String asKey) Global
{
/**
*  @brief 	Return a Float from the data for a Stash.
*  @param 	asUUID The UUID of the Stash.
*  @param 	asKey The JContainers key to lookup.
*  @return	The requested Float.
*/
}
	asKey = MakePath(asKey)
	Int jStashJMap = GetStashJMap(asUUID)
	If jStashJMap
		Return JValue.solveFlt(jStashJMap,asKey)
	EndIf
	Return 0
EndFunction

Function SetStashFlt(String asUUID, String asKey, Float afValue) Global
{
/**
*  @brief 	Set an Float in the data for a Stash.
*  @param 	asUUID The UUID of the Stash.
*  @param 	asKey The JContainers key to set.
*  @param 	afValue The new value.
*/
}
	asKey = MakePath(asKey)
	JValue.solveFltSetter(GetStashJMap(asUUID),asKey,afValue,True)
	SaveReg()
EndFunction

String Function GetStashStr(String asUUID, String asKey) Global
{
/**
*  @brief 	Return a String from the data for a Stash.
*  @param 	asUUID The UUID of the Stash.
*  @param 	asKey The JContainers key to lookup.
*  @return	The requested String.
*/
}
	asKey = MakePath(asKey)
	Int jStashJMap = GetStashJMap(asUUID)
	If jStashJMap
		Return JValue.solveStr(jStashJMap,asKey)
	EndIf
	Return ""
EndFunction

Function SetStashStr(String asUUID, String asKey, String asValue) Global
{
/**
*  @brief 	Set a String in the data for a Stash.
*  @param 	asUUID The UUID of the Stash.
*  @param 	asKey The JContainers key to set.
*  @param 	asValue The new value.
*/
}
	asKey = MakePath(asKey)
	JValue.solveStrSetter(GetStashJMap(asUUID),asKey,asValue,True)
	SaveReg()
EndFunction

Form Function GetStashForm(String asUUID, String asKey) Global
{
/**
*  @brief 	Return a Form from the data for a Stash.
*  @param 	asUUID The UUID of the Stash.
*  @param 	asKey The JContainers key to lookup.
*  @return	The requested Form.
*/
}
	asKey = MakePath(asKey)
	Int jStashJMap = GetStashJMap(asUUID)
	If jStashJMap
		Return JValue.solveForm(jStashJMap,asKey)
	EndIf
	Return None
EndFunction

Function SetStashForm(String asUUID, String asKey, Form akValue) Global
{
/**
*  @brief 	Set a Form in the data for a Stash.
*  @param 	asUUID The UUID of the Stash.
*  @param 	asKey The JContainers key to set.
*  @param 	akValue The new value.
*/
}
	asKey = MakePath(asKey)
	JValue.solveFormSetter(GetStashJMap(asUUID),asKey,akValue,True)
	SaveReg()
EndFunction

Int Function GetStashObj(String asUUID, String asKey) Global
{
/**
*  @brief 	Return a JObject from the data for a Stash.
*  @param 	asUUID The UUID of the Stash.
*  @param 	asKey The JContainers key to lookup.
*  @return	The requested JObject.
*/
}
	asKey = MakePath(asKey)
	Int jStashJMap = GetStashJMap(asUUID)
	If jStashJMap
		Return JValue.solveObj(jStashJMap,asKey)
	EndIf
	Return 0
EndFunction

Function SetStashObj(String asUUID, String asKey, Int ajValue) Global
{
/**
*  @brief 	Set a JContainers JObject in the data for a Stash.
*  @param 	asUUID The UUID of the Stash.
*  @param 	asKey The JContainers key to set.
*  @param 	ajValue The new value.
*/
}
	asKey = MakePath(asKey)
	JValue.solveObjSetter(GetStashJMap(asUUID),asKey,ajValue,True)
	SaveReg()
EndFunction

; @addtogroup ByObjectReference
; @{

Int Function GetStashRefSessionInt(ObjectReference akStashRef, String asKey) Global
{
/**
*  @brief 	Return an Int from the Session-specific data for a Stash.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @param 	asKey The JContainers key to lookup.
*  @return	The requested Int.
*/
}
	Return GetStashSessionInt(GetUUIDForStashRef(akStashRef), asKey)
EndFunction

Function SetStashRefSessionInt(ObjectReference akStashRef, String asKey, Int aiValue) Global
{
/**
*  @brief 	Set an Int in the Session-specific data for a Stash.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @param 	asKey The JContainers key to set.
*  @param 	aiValue The new value.
*/
}
	SetStashSessionInt(GetUUIDForStashRef(akStashRef), asKey, aiValue)
EndFunction

Int Function GetStashRefInt(ObjectReference akStashRef, String asKey) Global
{
/**
*  @brief 	Return an Int from the data for a Stash.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @param 	asKey The JContainers key to lookup.
*  @return	The requested Int.
*/
}
	Return GetStashInt(GetUUIDForStashRef(akStashRef), asKey)
EndFunction

Function SetStashRefInt(ObjectReference akStashRef, String asKey, Int aiValue) Global
{
/**
*  @brief 	Set an Int in the data for a Stash.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @param 	asKey The JContainers key to set.
*  @param 	aiValue The new value.
*/
}
	SetStashInt(GetUUIDForStashRef(akStashRef), asKey, aiValue)
EndFunction

Float Function GetStashRefFlt(ObjectReference akStashRef, String asKey) Global
{
/**
*  @brief 	Return a Float from the data for a Stash.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @param 	asKey The JContainers key to lookup.
*  @return	The requested Float.
*/
}
	Return GetStashFlt(GetUUIDForStashRef(akStashRef), asKey)
EndFunction

Function SetStashRefFlt(ObjectReference akStashRef, String asKey, Float afValue) Global
{
/**
*  @brief 	Set a Float in the data for a Stash.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @param 	asKey The JContainers key to set.
*  @param 	afValue The new value.
*/
}
	SetStashFlt(GetUUIDForStashRef(akStashRef), asKey, afValue)
EndFunction

String Function GetStashRefStr(ObjectReference akStashRef, String asKey) Global
{
/**
*  @brief 	Return a String from the data for a Stash.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @param 	asKey The JContainers key to lookup.
*  @return	The requested String.
*/
}
	Return GetStashStr(GetUUIDForStashRef(akStashRef), asKey)
EndFunction

Function SetStashRefStr(ObjectReference akStashRef, String asKey, String asValue) Global
{
/**
*  @brief 	Set a String in the data for a Stash.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @param 	asKey The JContainers key to set.
*  @param 	asValue The new value.
*/
}
	SetStashStr(GetUUIDForStashRef(akStashRef), asKey, asValue)
EndFunction

Form Function GetStashRefForm(ObjectReference akStashRef, String asKey) Global
{
/**
*  @brief 	Return a Form from the data for a Stash.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @param 	asKey The JContainers key to lookup.
*  @return	The requested Form.
*/
}
	Return GetStashForm(GetUUIDForStashRef(akStashRef), asKey)
EndFunction

Function SetStashRefForm(ObjectReference akStashRef, String asKey, Form akValue) Global
{
/**
*  @brief 	Set a Form in the data for a Stash.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @param 	asKey The JContainers key to set.
*  @param 	akValue The new value.
*/
}
	SetStashForm(GetUUIDForStashRef(akStashRef), asKey, akValue)
EndFunction

Int Function GetStashRefObj(ObjectReference akStashRef, String asKey) Global
{
/**
*  @brief 	Return a JObject from the data for a Stash.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @param 	asKey The JContainers key to lookup.
*  @return	The requested JObject.
*/
}
	Return GetStashObj(GetUUIDForStashRef(akStashRef), asKey)
EndFunction

Function SetStashRefObj(ObjectReference akStashRef, String asKey, Int ajValue) Global
{
/**
*  @brief 	Set a JContainers JObject in the data for a Stash.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @param 	asKey The JContainers key to set.
*  @param 	ajValue The new value.
*/
}
	SetStashObj(GetUUIDForStashRef(akStashRef), asKey, ajValue)
EndFunction

;@}
;@}

;@defgroup	StashDataFunctions	Stash Data Functions
;			Functions for manipulating or testing Stash data.
;@{

Bool Function IsStash(String asUUID) Global
{
/**
*  @brief 	Check if the specified UUID is a valid Stash.
*  @param 	asUUID The UUID of the Stash.
*  @return 	True if UUID is a valud Stash, otherwise False.
*/
}
	Return JValue.IsMap(GetStashJMap(asUUID))
EndFunction

Bool Function CreateStashRef(ObjectReference akStashRef, Int aiStashGroup = 0) Global
{
/**
*  @brief 	Turn the ObjectReference specified by akStashRef into a new Stash.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @param 	aiStashGroup The group ID of the Stash.
*  @return 	True for success, otherwise False.
*
*  @note	aiStashGroup does nothing right now.
*/
}
	If IsStashRef(akStashRef)
		DebugTraceAPIStash("Error! " + akStashRef + " is already a Stash!")
		Return False
	EndIf
	If akStashRef.GetType() == 28 || akStashRef.GetBaseObject().GetType() == 28 ;kContainer
		;JFormMap.SetObj(GetStashFormMap(),akStashRef,CreateStashJMap())
		String sStashID = CreateStashData(akStashRef)
		Int jStashMap = GetStashJMap(sStashID)
		If jStashMap
			;Calling SetStashRef* creates the JMap entry automatically
			SetStashRefInt(akStashRef,"DataSerial",0)
			SetStashRefSessionInt(akStashRef,"DataSerial",0)
			SetStashRefGroup(akStashRef,aiStashGroup)
			SaveReg()
			Return True
		EndIf
		DebugTraceAPIStash("Error! Tried and failed to create record for " + akStashRef + "!")
		Return False
	Else
		DebugTraceAPIStash("Error! " + akStashRef + " is not a Container!")
		Return False
	EndIf
	Return False
EndFunction

Bool Function RemoveStash(String asUUID, Form akStashRef = None, Bool abDeleteBackups = False) Global
{
/**
*  @brief 	Remove the Stash data for the specified Stash.
*  @param 	asUUID The UUID of the Stash.
*  @param 	akStashRef (Optional) The ObjectReference of the Stash.
*  @return 	True for success, otherwise False.
*  @note	This removes the Stash data from the persistent registry, 
*			but does not touch the items in the Stash's Container.
*/
}
	If !IsStash(asUUID)
		DebugTraceAPIStash("Error! " + asUUID + " is not a Stash!")
		Return False
	EndIf
	ObjectReference kStashRef = akStashRef as ObjectReference
	If !kStashRef 
		kStashRef = GetStashRefForUUID(asUUID)
	EndIf
	DebugTraceAPIStash("Removing Stash " + kStashRef + " (" + asUUID + ")!")
	SuperStash.DeleteStashFile(GetStashFileNameString(asUUID),abDeleteBackups)
	JMap.RemoveKey(GetRegObj("Stashes"),asUUID)
	JFormMap.RemoveKey(GetRegObj("StashFormMap"),kStashRef)
	JMap.RemoveKey(GetSessionObj("Stashes"),asUUID)
	SaveReg()


	;Now remove the shader effects from the ref if it's loaded
	If kStashRef
		vSS_StashManager StashManager = Quest.GetQuest("vSS_StashManagerQuest") as vSS_StashManager
		EffectShader kContainerShader = StashManager.ContainerFXShader
		kContainerShader.Stop(kStashRef)
	EndIf

	Return True
EndFunction

Bool Function RemoveStashRef(ObjectReference akStashRef) Global
{
/**
*  @brief 	Remove the Stash data for the specified Stash by its ObjectReference.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @return 	True for success, otherwise False.
*  @note	This removes the Stash data from the persistent registry, 
*			but does not touch the items in the Stash's Container.
*/
}
	If !IsStashRef(akStashRef)
		DebugTraceAPIStash("Error! " + akStashRef + " is not a Stash!")
		Return False
	EndIf
	String sStashID = GetUUIDForStashRef(akStashRef)
	Bool bResult = RemoveStash(sStashID,akStashRef)
	SaveReg()

	Return bResult
EndFunction

Bool Function IsStashRef(ObjectReference akStashRef) Global
{
/**
*  @brief 	Check if the specified ObjectReference is a valid Stash.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @return 	True if UUID is a valud Stash, otherwise False.
*  @see 	IsStash()
*/
}
	If akStashRef 
		String sStashID = GetUUIDForStashRef(akStashRef)
		If sStashID
			If JValue.IsMap(GetStashJMap(sStashID))
				Return True
			EndIf
		EndIf
	EndIf
	Return False
EndFunction

Function SetStashGroup(String asUUID, Int aiStashGroup = 0) Global
{
/**
*  @brief 	Set the Group ID for the specified Stash.
*  @param 	asUUID The UUID of the Stash.
*  @param 	aiStashGroup The new Group ID.
*  @note 	Stash Groups aren't implemented, so this does nothing right now.
*/
}
	If IsStash(asUUID)
		SetStashInt(asUUID,"Group",aiStashGroup)
	Else
		DebugTraceAPIStash("SetStashGroup: Error! " + asUUID + " is not a valid Stash!")
	EndIf
EndFunction

Int Function GetStashGroup(String asUUID) Global
{
/**
*  @brief 	Get the Group ID for the specified Stash.
*  @param 	asUUID The UUID of the Stash.
*  @return	The Group ID.
*  @note 	Stash Groups aren't implemented, so this does nothing right now.
*/
}
	Return GetStashInt(asUUID,"Group")
EndFunction

Function SetStashRefGroup(ObjectReference akStashRef, Int aiStashGroup = 0) Global
{
/**
*  @brief 	Set the Group ID for the specified Stash by ObjectReference.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @param 	aiStashGroup The new Group ID.
*  @note 	Stash Groups aren't implemented, so this does nothing right now.
*  @see 	SetStashGroup()
*/
}
	SetStashRefInt(akStashRef,"Group",aiStashGroup)
EndFunction

Int Function GetStashRefGroup(ObjectReference akStashRef) Global
{
/**
*  @brief 	Get the Group ID for the specified Stash by ObjectReference.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @return	The Group ID.
*  @note 	Stash Groups aren't implemented, so this does nothing right now.
*  @see 	GetStashGroup()
*/
}
	Return GetStashRefInt(akStashRef,"Group")
EndFunction

Int Function GetStashEntryCount(String asUUID) Global
{
/**
*  @brief 	Get the number of item entries for the specified Stash.
*  @param 	asUUID The UUID of the Stash.
*  @return	The number of item entries in the Stash, or 0 if not found.
*  @note 	Item entries are not the same as items, objects, or anything else.
*			They consist of a Form (used as the index) and various attached info. 
* 			The ItemEntry count is equal to the number of *Forms*, not the number of *items* in the Stash.
*/
}
	Int jStashData = GetStashJMap(asUUID)
	Return JArray.Count(JMap.GetObj(jStashData,"containerEntries")) + JArray.Count(JMap.GetObj(jStashData,"entryDataList"))
EndFunction

String[] Function GetStashItems(String asUUID) Global
{
/**
*	@deprecated	This does nothing now and will be removed shortly.
*/
}
	;FIXME
	; String[] sRet = New String[1]

	; Int jItemArray = GetStashObj(akStashRef,"Items")
	; If jItemArray 
	; 	Return SuperStash.JObjToArrayStr(jItemArray)
	; EndIf

	; Return sRet
EndFunction

Form[] Function GetAllStashObjects() Global
{
/**
*  @brief 	Get an array of ObjectReferences that are set as Stashes.
*  @return	An array of ObjectReferences currently set a Stashes.
*  @bug 	ObjectReferences in unloaded Cells will not be on the list. This is a Skyrim bug
* 			and not one that I can fix.
*/
}
	Int jStashFormMap = GetStashFormMap()
	Int iCount = JFormMap.Count(jStashFormMap)
	Form[] kResult = Utility.CreateFormArray(iCount)
	
	Int i = 0
	Form kKey = JFormMap.NextKey(jStashFormMap)
	While kKey
		kResult[i] = kKey
		kKey = JFormMap.NextKey(jStashFormMap,kKey)
		i += 1
	EndWhile

	Return kResult
EndFunction

Form[] Function GetStashObjectsInCell() Global
{
/**
*  @brief 	Get an array of ObjectReferences that are set as Stashes in a Cell.
*  @return	An array of ObjectReferences currently set a Stashes in a Cell.
*  @bug 	This identical to GetAllStashObjects(), must not have ever needed to use it.
*/
}
	Int jStashFormMap = GetStashFormMap()
	Int iCount = JFormMap.Count(jStashFormMap)
	Form[] kResult = Utility.CreateFormArray(iCount)
	
	Int i = 0
	Form kKey = JFormMap.NextKey(jStashFormMap)
	While kKey
		kResult[i] = kKey
		kKey = JFormMap.NextKey(jStashFormMap,kKey)
		i += 1
	EndWhile

	Return kResult
EndFunction

;@}

Function CreateMCMLists() Global
{
/**
*  @brief 	This creates the data structures used by the MCM for quickly sorting through Stashes.
*  @note 	This should only be called by the MCM script under most circumstances.
*  @see 	vSS_MCMConfigQuestScript
*/
}
	DebugTraceAPIStash("Creating MCM lists...")
	Int jMCM = JMap.Object()
	Int jMCMNames = JArray.Object()


	Int jStashList = GetRegObj("Stashes")
	String sUUID = JMap.NextKey(jStashList)
	While sUUID
		Int jStashData = JMap.GetObj(jStashList,sUUID)
		Form kStashRef = JMap.GetForm(jStashData,"Form")
		String sCellName = JMap.GetStr(jStashData,"CellName") 
		String sStashName = JMap.GetStr(jStashData,"StashName")
		String sStashID = JMap.GetStr(jStashData,"FormIDString")
		
		JValue.SolveStrSetter(jMCM,".CellMap." + sCellName + "." + sStashName + "." + sStashID,sUUID,True)
		String sStashMCMName = sCellName + "/" + sStashName
		
		Int i = 2
		While JArray.FindStr(jMCMNames,sStashMCMName) != -1
			sStashMCMName = sCellName + "/" + sStashName + "(" + i + ")"
			i += 1
		EndWhile
		JArray.AddStr(jMCMNames,sStashMCMName)
		JValue.SolveStrSetter(jMCM,".NameMap." + sStashMCMName,sUUID,True)

		sUUID = JMap.NextKey(jStashList,sUUID)
	EndWhile

	SetSessionObj("MCMMap",jMCM)
	SaveSession()
	JValue.Release(jMCMNames)
	DebugTraceAPIStash("Created MCM lists!")
EndFunction

String[] Function GetMCMNames() Global
{
/**
*  @brief 	Return an array of Strings containing the names of all available Stashes.
*  @note 	This should only be called by the MCM script under most circumstances.
* 			CreateMCMLists() must be called at least once before this will work.
*  @see 	vSS_MCMConfigQuestScript
*/
}
	Return SuperStash.JObjToArrayStr(JArray.Sort(JMap.AllKeys(GetSessionObj("MCMMap.NameMap"))))
EndFunction

;=== Stash object inventory Functions ===--

;@defgroup	StashInventoryFunctions	Stash Inventory Functions
;			These functions manipulate the contents of the Stash Containers in-game.
;@{

Int Function LoadStashesForCell(Cell akCell) Global
{
/**
*  @brief 	Find and populate all the Stash Containers for the specified Cell.
*  @param 	akCell The Cell to load the Stashes for. 
*  @return	The number Stashes loaded for the Cell.
*
*  @warning Do not attempt to use this for a Cell that is not currently loaded!	
*			ObjectReferences for unloaded Cells return None, so they will NOT get
* 			populated properly!
*
*  @note 	Depending on the number of Stashes and how many items are in them, this 
* 			may takes some time to return. Under normal circumstances it should still be
* 			less than a second, though.
*			
*			Also cleans up any StashRefs which no longer have valid Stash entries, and 
*			will strip the Stash effect from non-Stash containers.
*/
}
	vSS_StashManager StashManager = Quest.GetQuest("vSS_StashManagerQuest") as vSS_StashManager
	EffectShader kContainerShader = StashManager.ContainerFXShader
	Int iContainerCount = akCell.GetNumRefs(formTypeFilter = 28) ;kContainer
	Int i = 0
	While i < iContainerCount
		ObjectReference kContainer = akCell.GetNthRef(i,28)
		If IsStashRef(kContainer)
			String sStashID = GetUUIDForStashRef(kContainer)
			DebugTraceAPIStash("Found Stash " + kContainer + "! UUID: " + sStashID)
			
			Int iCount = ImportStashRefItems(kContainer)
			;String sFilePath = SuperStash.userDirectory() + "Stashes\\player.json"
			
			;Int iCount = SuperStash.FillContainerFromJSON(kContainer,sFilePath)
			DebugTraceAPIStash("Imported " + iCount + " items for " + kContainer + ".")
		Else
			kContainerShader.Stop(kContainer)
		EndIf
		i += 1
	EndWhile
	Return i
EndFunction

Int Function ImportStashRefItems(ObjectReference akStashRef, Bool abForce = False) Global
{
/**
*  @brief 	Populate akStashRef with the Stash items.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @param 	abForce Populate the Container even if the script already thinks it's up to date. Default: False.
*  @return	The number of ItemEntries placed in the Container, or 0 for an invalid Stash.
*  @note 	If the Container already contains items, its inventory will be merged with the Stash contents.
*  			This new item list will NOT be saved until the Player opens the Container, though.
*/
}
	If !IsStashRef(akStashRef)
		DebugTraceAPIStash("ImportStashItems: Error! " + akStashRef + " is not a valid Stash!")
		Return 0
	EndIf

	Bool bIsEmpty = True

	Int iReturn = 0

	vSS_StashManager StashManager 		= Quest.GetQuest("vSS_StashManagerQuest") as vSS_StashManager

	ObjectReference kTempStash = StashManager.ContainerTemp

	String sStashID = GetUUIDForStashRef(akStashRef)
	String sStashFileName  = GetStashFileNameString(sStashID)
	String sFilePath = SuperStash.userDirectory() + "Stashes\\" ;"; <-- fix for highlighting in SublimePapyrus
	sFilePath += sStashFileName + ".json" 

	Int jStashData = JValue.readFromFile(sFilePath)
	Int iDataSerial = JValue.SolveInt(jStashData,".DataSerial")

	If GetStashSessionInt(sStashID,"DataSerial") == 0 && akStashRef.GetNthForm(0)
		Debug.Notification("SkyBox: Stash '" + GetStashStr(sStashID,"StashName") + "' was not empty, contents have been merged!")
		akStashRef.RemoveAllItems(kTempStash,True,True)
		bIsEmpty = False 
	EndIf

	EffectShader    kContainerShader 	= StashManager.ContainerFXShader
	kContainerShader.Stop(akStashRef)
	kContainerShader.Play(akStashRef)

	;akStashRef.RemoveAllItems()
	DebugTraceAPIStash("Saved DataSerial is " + iDataSerial + ", Session DataSerial is " + GetStashSessionInt(sStashID,"DataSerial"))
	If iDataSerial > GetStashSessionInt(sStashID,"DataSerial") || abForce
		;Create ExtraContainerChanges data for Container
		Form kGold = Game.GetFormFromFile(0xf,"Skyrim.esm")
		akStashRef.AddItem(kGold, 1, True)
		akStashRef.RemoveItem(kGold, 1, True)
		akStashRef.RemoveAllItems(None)
		DebugTraceAPIStash("Filling " + akStashRef + " from " + sFilePath + "!")
		SetStashSessionInt(sStashID,"DataSerial",iDataSerial)
		iReturn = SuperStash.FillContainerFromJson(akStashRef,sFilePath)
		If !bIsEmpty
			kTempStash.RemoveAllItems(akStashRef,True,True)
		EndIf
	EndIf

	Return iReturn
EndFunction

;For anyone reading this, I had this whole scan working perfectly in pure Papyrus. It was beautiful.
;It used several containers working in parallel to sort and scan everything. For Papyrus, it was 
;blindingly fast. By any realistic standard, though, it was also mind-numbingly slow. Call it a 
;moral victory. At any rate, I gave up on doing it in pure Papyrus and instead learned c++ well 
;enough to reimplement it in an SKSE plugin. Now it's nearly instantaneous. So it goes.
Int Function ScanContainer(ObjectReference akStashRef) Global
{
/**
*  @brief 	Creates a new JMap containing the ItemEntries for the specified Container.
*  @param 	akStashRef The ObjectReference of the Stash.
*  @return	The ID of a new JMap containing the Stash Container's contents.
*
*  @warning	The JMap is not set to be retained, so it will expire unless written to the JDB or 
*			otherwise marked for retention.
*  @note 	Although this was written to be used on a newly created Stash, it can be used on any 
*			Container to quickly get its contents.
*  			
*/
}
	DebugTraceAPIStash("=== Starting scan of " + akStashRef + " ===--")
	vSS_StashManager StashManager = Quest.GetQuest("vSS_StashManagerQuest") as vSS_StashManager

	Int jContainerState = JValue.objectFromPrototype(SuperStash.GetContainerJSON(akStashRef))
	; JValue.WriteToFile(jContainerState,SuperStash.userDirectory() + "Stashes/quick.json")
	
	DebugTraceAPIStash("=== Finished scan of " + akStashRef + " ===--")
	Return jContainerState
EndFunction

Int Function UpdateStashData(String asUUID) Global
{
/**
*  @brief 	Updates the stored data for the specified Stash based on its Container contents.
*  @param 	asUUID The UUID of the Stash.
*  @return	The ItemEntry count of the Stash, or 0 for a problem.
*  @note 	
*	This updates the stored data for a Stash, doing a full inventory scan and ticking the
* 	data version. It also updates the various metadata to reflect the currently loaded 
* 	character and Session. It does not write the Stash data to a file, only the persistent Registry.
*  @par
*	This is a resource-intensive function and should be used only when the contents of the Stash's 
*	Container have been changed.
*/
}
	If !IsStash(asUUID)
		DebugTraceAPIStash("UpdateStashData: Error! " + asUUID + " is not a valid Stash!",2)
		Return -1
	EndIf

	ObjectReference kStashRef = GetStashRefForUUID(asUUID)

	If !kStashRef
		DebugTraceAPIStash("UpdateStashData: Error! " + kStashRef + " is not a valid Stash ObjectReference!",2)
		Return -2
	EndIf

	kStashRef.BlockActivation(True)
	
	If GetStashInt(asUUID,"Busy")
		DebugTraceAPIStash("Error! " + asUUID + " is busy!")
		Return 0
	EndIf
	SetStashInt(asUUID,"Busy",1)
	Int iDataSerial = GetStashInt(asUUID,"DataSerial") + 1

	Actor PlayerREF = Game.GetPlayer()
	String sSessionID = GetSessionStr("SessionID")
	String sPlayerName = PlayerREF.GetActorBase().GetName()
	Float fSessionTime = Game.GetRealHoursPassed()

	vSS_StashManager StashManager = Quest.GetQuest("vSS_StashManagerQuest") as vSS_StashManager

	EffectShader    kContainerShader 	= StashManager.ContainerFXShader
	kContainerShader.Stop(kStashRef)
	kContainerShader.Play(kStashRef)

	Int jStashState = ScanContainer(kStashRef)

	SetStashInt(asUUID,"DataSerial",iDataSerial)
	SetStashSessionInt(asUUID,"DataSerial",iDataSerial)

	Int jKeyList = JMap.AllKeys(jStashState)
	Int i = JArray.Count(jKeyList)
	While i > 0
		i -= 1
		String sKey = JArray.GetStr(jKeyList,i)
		If sKey
			SetStashObj(asUUID,sKey,JMap.GetObj(jStashState,sKey))
		EndIf
	EndWhile

	;SetStashObj(asUUID,"ContainerState",jStashState)
	SetStashStr(asUUID,"LastSessionID",sSessionID)
	SetStashFlt(asUUID,"LastSessionTime",fSessionTime)
	SetStashStr(asUUID,"LastCharacterName",Game.GetPlayer().GetActorBase().GetName())

	Int iEntryCount = GetStashEntryCount(asUUID)
	SetStashInt(asUUID,"ItemEntryCount",iEntryCount)
	
	DebugTraceAPIStash("Scanned Stash " + kStashRef + ", found " + iEntryCount + " entries! UUID: " + asUUID)

	String sCellName = kStashRef.GetParentCell().GetName()
	If sCellName
		SetStashStr(asUUID,"CellName",sCellName)
	Else
		SetStashStr(asUUID,"CellName","Unnamed Cell")
	EndIf

	If !GetStashStr(asUUID,"StashName")
		String sStashName = kStashRef.GetName()
		If !sStashName
			sStashName = kStashRef.GetBaseObject().GetName()
		EndIf

		If sStashName
			SetStashStr(asUUID,"StashName",sStashName)
		Else 
			SetStashStr(asUUID,"StashName","Unnamed container")
		EndIf
	EndIf

	;kContainerShader.Stop(kStashRef)
	kStashRef.BlockActivation(False)
	SetStashInt(asUUID,"Busy",0)

	JValue.CleanPool("vSS_ScanState")
	Return iEntryCount
EndFunction

Function ExportStash(String asUUID, Bool abSkipBackup = False) Global
{
/**
*  @brief 	Exports the data for the specified Stash to a file.
*  @param 	asUUID 			The UUID of the Stash.
*  @param 	abSkipBackup 	If True, don't do the usual file rotation before writing. Default: False.
*  @note 	
*	This should usually be called right after UpdateStashData();
*/
}
	String sStashID = GetStashFileNameString(asUUID)
	If !abSkipBackup
		SuperStash.RotateFile(SuperStash.userDirectory() + "Stashes/" + sStashID + ".json")
	EndIf
	JValue.WriteToFile(GetStashJMap(asUUID),SuperStash.userDirectory() + "Stashes/" + sStashID + ".json")
EndFunction

;@}

Function DebugTraceAPIStash(String sDebugString, Int iSeverity = 0) Global
	Debug.Trace("vSS/API/Stash: " + sDebugString,iSeverity)
EndFunction

String Function GetStashFileNameString(String asUUID) Global
	If GetStashStr(asUUID,"Source")
		Return GetStashStr(asUUID,"Source") + "_" + GetStashStr(asUUID,"FormIDString") ;+ "_" + asUUID
	Else
		Return GetStashStr(asUUID,"FormIDString") ;+ "_" + asUUID
	EndIf
EndFunction

String Function GetFormIDString(Form kForm) Global
	String sResult
	sResult = kForm as String ; [FormName < (FF000000)>]
	sResult = StringUtil.SubString(sResult,StringUtil.Find(sResult,"(") + 1,8)
	Return sResult
EndFunction

Form Function GetFormFromString(String asString) Global
	Return Game.GetFormEx(("0x" + StringUtil.SubString(asString,StringUtil.Find(asString,"(") + 1,8)) as Int) as Form
EndFunction