Scriptname vSS_API_Stash extends vSS_APIBase Hidden
{Save and restore Stash data, including custom Stashs.}

; === [ vSS_API_Stash.psc ] ===============================================---
; API for saving and loading Stashs. A Stash is a container that will be shared
; between multiple savegames/sessions.
; 
; ========================================================---

Import vSS_Registry
Import vSS_Session

;=== Generic Functions ===--

Int Function GetStashFormMap() Global
	Int jStashFormMap = GetRegObj("StashFormMap")
	If jStashFormMap
		Return jStashFormMap
	EndIf
	jStashFormMap = JFormMap.Object()
	SetRegObj("StashFormMap",jStashFormMap)
	Return jStashFormMap
EndFunction

Int Function GetStashJMap(ObjectReference akStashRef, Bool abCreateIfMissing = False) Global
	Int iRet = -2 ; akStashRef is not a Stash
	Int jStashFormMap = GetStashFormMap()
	Int jStashJMap = JFormMap.GetObj(jStashFormMap,akStashRef)
	If JValue.isMap(jStashJMap)
		Return jStashJMap
	EndIf
	If abCreateIfMissing
		jStashJMap = JMap.object()
		JFormMap.SetObj(jStashFormMap,akStashRef,jStashJMap)
		SaveReg()
		Return jStashJMap
	EndIf
	Return iRet
EndFunction

;=== Generic Get/Set Functions ===--

Int Function GetStashInt(ObjectReference akStashRef, String asKey) Global
	asKey = MakePath(asKey)
	Int iRet = -2 ; akStashRef is not a Stash
	Int jStashJMap = GetStashJMap(akStashRef)
	If jStashJMap
		Return JValue.solveInt(jStashJMap,asKey)
	EndIf
	Return iRet
EndFunction

Function SetStashInt(ObjectReference akStashRef, String asKey, Int aiValue) Global
	asKey = MakePath(asKey)
	JValue.solveIntSetter(GetStashJMap(akStashRef,True),asKey,aiValue)
	SaveReg()
EndFunction

Float Function GetStashFlt(ObjectReference akStashRef, String asKey) Global
	asKey = MakePath(asKey)
	Float fRet = -2 ; akStashRef is not a Stash
	Int jStashJMap = GetStashJMap(akStashRef)
	If jStashJMap
		Return JValue.solveFlt(jStashJMap,asKey)
	EndIf
	Return fRet
EndFunction

Function SetStashFlt(ObjectReference akStashRef, String asKey, Float afValue) Global
	asKey = MakePath(asKey)
	JValue.solveFltSetter(GetStashJMap(akStashRef,True),asKey,afValue)
	SaveReg()
EndFunction

String Function GetStashStr(ObjectReference akStashRef, String asKey) Global
	asKey = MakePath(asKey)
	String sRet = ""
	Int jStashJMap = GetStashJMap(akStashRef)
	If jStashJMap
		Return JValue.solveStr(jStashJMap,asKey)
	EndIf
	Return sRet
EndFunction

Function SetStashStr(ObjectReference akStashRef, String asKey, String asValue) Global
	asKey = MakePath(asKey)
	JValue.solveStrSetter(GetStashJMap(akStashRef,True),asKey,asValue)
	SaveReg()
EndFunction

Form Function GetStashForm(ObjectReference akStashRef, String asKey) Global
	asKey = MakePath(asKey)
	Form kRet = None
	Int jStashJMap = GetStashJMap(akStashRef)
	If jStashJMap
		Return JValue.solveForm(jStashJMap,asKey)
	EndIf
	Return kRet
EndFunction

Function SetStashForm(ObjectReference akStashRef, String asKey, Form akValue) Global
	asKey = MakePath(asKey)
	JValue.solveFormSetter(GetStashJMap(akStashRef,True),asKey,akValue)
	SaveReg()
EndFunction

Int Function GetStashObj(ObjectReference akStashRef, String asKey) Global
	asKey = MakePath(asKey)
	Int iRet = -2 ; akStashRef is not a Stash
	Int jStashJMap = GetStashJMap(akStashRef)
	If jStashJMap
		Return JValue.solveObj(jStashJMap,asKey)
	EndIf
	Return iRet
EndFunction

Function SetStashObj(ObjectReference akStashRef, String asKey, Int ajValue) Global
	asKey = MakePath(asKey)
	JValue.solveObjSetter(GetStashJMap(akStashRef,True),asKey,ajValue)
	SaveReg()
EndFunction

;=== Data Functions ===--

Bool Function CreateStash(ObjectReference akStashRef, Int aiStashGroup = 0) Global
	If IsStash(akStashRef)
		DebugTraceAPIStash("Error! " + akStashRef + " is already a Stash!")
		Return False
	EndIf
	If akStashRef.GetType() == 28 || akStashRef.GetBaseObject().GetType() == 28 ;kContainer
		SetStashObj(akStashRef,"Items",JArray.Object())
		SetStashGroup(akStashRef,aiStashGroup)
		Return True
	Else
		DebugTraceAPIStash("Error! " + akStashRef + " is not a Container!")
		Return False
	EndIf
	Return False
EndFunction

Bool Function DeleteStash(ObjectReference akStashRef) Global
	Return JFormMap.RemoveKey(GetStashFormMap(),akStashRef)
EndFunction

Bool Function IsStash(ObjectReference akStashRef) Global
	If GetStashJMap(akStashRef)
		Return True
	EndIf
	Return False
EndFunction

Function SetStashGroup(ObjectReference akStashRef, Int aiStashGroup = 0) Global
	If IsStash(akStashRef)
		SetStashInt(akStashRef,"Group",aiStashGroup)
	Else
		DebugTraceAPIStash("Error! " + akStashRef + " is not a valid Stash!")
	EndIf
EndFunction

Int Function GetStashGroup(ObjectReference akStashRef) Global
	Return GetStashInt(akStashRef,"Group")
EndFunction

String[] Function GetStashItems(ObjectReference akStashRef) Global
	String[] sRet = New String[1]

	Int jItemArray = GetStashObj(akStashRef,"Items")
	If jItemArray 
		Return SuperStash.JObjToArrayStr(jItemArray)
	EndIf

	Return sRet
EndFunction

Int Function UpdateStashItems(ObjectReference akStashRef) Global
	If !IsStash(akStashRef)
		DebugTraceAPIStash("Error! " + akStashRef + " is not a valid Stash!")
		Return -1
	EndIf

	akStashRef.BlockActivation(True)
	
	vSS_StashManager StashManager = Quest.GetQuest("vSS_StashManagerQuest") as vSS_StashManager

	ObjectReference kMoveTarget 		= StashManager.MoveTarget
	ObjectReference kContainerTarget 	= StashManager.ContainerTarget

	String sStashID = GetFormIDString(akStashRef)

	Int jItemList = JArray.Object()
	JValue.Retain(jItemList,"vSS_" + sStashID)

	Form[] 		kStashItems 	= akStashRef.GetContainerForms()
	Int[] 		iItemCount 		= SuperStash.GetItemCounts(kStashItems,akStashRef)
	Int[] 		iItemTypes 		= SuperStash.GetItemTypes(kStashItems)
	String[] 	sItemNames 		= SuperStash.GetItemNames(kStashItems)
	Int[] 		iItemHasExtra 	= SuperStash.GetItemHasExtraData(kStashItems)

	Int i = kStashItems.Length
	While i > 0
		i -= 1
		String sItemID = ""
		Form kItem = kStashItems[i]
		If kItem
			Int iType = iItemTypes[i]
			Int iCount = iItemCount[i]
			If iCount > 0 
				If kItem as ObjectReference
					(kItem as ObjectReference).MoveTo(kMoveTarget)
					sItemID = vSS_API_Item.SerializeObject(kItem as ObjectReference)
					akStashRef.AddItem((kItem as ObjectReference),abSilent = True)
				EndIf
				If sItemID
					JArray.AddObj(jItemList,vFF_API_Item.GetItemJMap(sItemID))
				Else
					Int jItemMap = JMap.Object()
					JMap.SetForm(jItemMap,"Form",kItem)
					JMap.SetInt(jItemMap,"Count",iCount)
					JArray.AddObj(jItemList,jItemMap)
				EndIf
			EndIf
		EndIf
	EndWhile
	DebugTraceAPIStash("Updated Stash " + akStashRef + ", found " + kStashItems.Length + " items!")
	
	akStashRef.BlockActivation(False)

	JValue.releaseObjectsWithTag("vSS_" + sStashID)


EndFunction

Function DebugTraceAPIStash(String sDebugString, Int iSeverity = 0) Global
	Debug.Trace("vSS/API/Stash: " + sDebugString,iSeverity)
EndFunction

String Function GetFormIDString(Form kForm) Global
	String sResult
	sResult = kForm as String ; [FormName < (FF000000)>]
	sResult = StringUtil.SubString(sResult,StringUtil.Find(sResult,"(") + 1,8)
	Return sResult
EndFunction