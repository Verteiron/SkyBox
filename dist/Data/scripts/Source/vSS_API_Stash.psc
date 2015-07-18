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
	Return 0
EndFunction

;=== Generic Get/Set Functions ===--

Int Function GetStashInt(ObjectReference akStashRef, String asKey) Global
	asKey = MakePath(asKey)
	Int jStashJMap = GetStashJMap(akStashRef)
	If jStashJMap
		Return JValue.solveInt(jStashJMap,asKey)
	EndIf
	Return 0
EndFunction

Function SetStashInt(ObjectReference akStashRef, String asKey, Int aiValue) Global
	asKey = MakePath(asKey)
	JValue.solveIntSetter(GetStashJMap(akStashRef,True),asKey,aiValue,True)
	SaveReg()
EndFunction

Float Function GetStashFlt(ObjectReference akStashRef, String asKey) Global
	asKey = MakePath(asKey)
	Int jStashJMap = GetStashJMap(akStashRef)
	If jStashJMap
		Return JValue.solveFlt(jStashJMap,asKey)
	EndIf
	Return 0
EndFunction

Function SetStashFlt(ObjectReference akStashRef, String asKey, Float afValue) Global
	asKey = MakePath(asKey)
	JValue.solveFltSetter(GetStashJMap(akStashRef,True),asKey,afValue,True)
	SaveReg()
EndFunction

String Function GetStashStr(ObjectReference akStashRef, String asKey) Global
	asKey = MakePath(asKey)
	Int jStashJMap = GetStashJMap(akStashRef)
	If jStashJMap
		Return JValue.solveStr(jStashJMap,asKey)
	EndIf
	Return ""
EndFunction

Function SetStashStr(ObjectReference akStashRef, String asKey, String asValue) Global
	asKey = MakePath(asKey)
	JValue.solveStrSetter(GetStashJMap(akStashRef,True),asKey,asValue,True)
	SaveReg()
EndFunction

Form Function GetStashForm(ObjectReference akStashRef, String asKey) Global
	asKey = MakePath(asKey)
	Int jStashJMap = GetStashJMap(akStashRef)
	If jStashJMap
		Return JValue.solveForm(jStashJMap,asKey)
	EndIf
	Return None
EndFunction

Function SetStashForm(ObjectReference akStashRef, String asKey, Form akValue) Global
	asKey = MakePath(asKey)
	JValue.solveFormSetter(GetStashJMap(akStashRef,True),asKey,akValue,True)
	SaveReg()
EndFunction

Int Function GetStashObj(ObjectReference akStashRef, String asKey) Global
	asKey = MakePath(asKey)
	Int jStashJMap = GetStashJMap(akStashRef)
	If jStashJMap
		Return JValue.solveObj(jStashJMap,asKey)
	EndIf
	Return 0
EndFunction

Function SetStashObj(ObjectReference akStashRef, String asKey, Int ajValue) Global
	asKey = MakePath(asKey)
	JValue.solveObjSetter(GetStashJMap(akStashRef,True),asKey,ajValue,True)
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

Int Function LoadStashesForCell(Cell akCell) Global
	Int iContainerCount = akCell.GetNumRefs(formTypeFilter = 28) ;kContainer
	Int i = 0
	While i < iContainerCount
		ObjectReference kContainer = akCell.GetNthRef(i,28)
		If IsStash(kContainer)
			Int iCount = ImportStashItems(kContainer)
			DebugTraceAPIStash("Imported " + iCount + " items for " + kContainer + ".")
		EndIf
		i += 1
	EndWhile
	Return i
EndFunction

Int Function ImportStashItems(ObjectReference akStashRef) Global
	If !IsStash(akStashRef)
		DebugTraceAPIStash("Error! " + akStashRef + " is not a valid Stash!")
		Return 0
	EndIf

	If GetStashInt(akStashRef,"Busy")
		DebugTraceAPIStash("Error! " + akStashRef + " is busy!")
		Return 0
	EndIf
	SetStashInt(akStashRef,"Busy",1)

	vSS_StashManager StashManager = Quest.GetQuest("vSS_StashManagerQuest") as vSS_StashManager

	ObjectReference kMoveTarget 		= StashManager.MoveTarget
	ObjectReference kContainerTarget 	= StashManager.ContainerTarget

	EffectShader    kContainerShader 	= StashManager.ContainerFXShader

	Int iOriginalItemCount = akStashRef.GetContainerForms().Length

	Int jItemList = GetStashObj(akStashRef,"Items")
	If !jItemList
		DebugTraceAPIStash("Error! " + akStashRef + " is missing its ItemList!")
		Return 0
	EndIf

	akStashRef.BlockActivation(True)
	kContainerShader.Play(akStashRef)

	Int i = JArray.Count(jItemList)
	While i > 0
		i -= 1
		Int jItemMap = JArray.GetObj(jItemList,i)
		String sItemID = JMap.GetStr(jItemMap,"UUID")
		If sItemID
			ObjectReference kObject = vSS_API_Item.CreateObject(sItemID)
			If kObject
				akStashRef.AddItem(kObject, 1, True)
			Else
				DebugTraceAPIStash("Error! " + akStashRef + " could not recreate item " + JMap.GetStr(jItemMap,"DisplayName") + " (" + sItemID + ")!")
			EndIf
		Else
			Form kItem = JMap.GetForm(jItemMap,"Form")
			If kItem 
				akStashRef.AddItem(kItem, JMap.GetInt(jItemMap,"Count"), abSilent = True)
			Else
				DebugTraceAPIStash("Error! " + akStashRef + " could not load a form!")
			EndIf
		EndIf
	EndWhile
	If iOriginalItemCount > 0 ;&& iOriginalItemCount != akStashRef.GetContainerForms().Length
		ExportStashItems(akStashRef)
	EndIf
	kContainerShader.Stop(akStashRef)
	SetStashInt(akStashRef,"Busy",0)
	akStashRef.BlockActivation(False)

	Return 0

EndFunction

Int Function ExportStashItems(ObjectReference akStashRef) Global
	If !IsStash(akStashRef)
		DebugTraceAPIStash("Error! " + akStashRef + " is not a valid Stash!")
		Return -1
	EndIf

	akStashRef.BlockActivation(True)
	
	If GetStashInt(akStashRef,"Busy")
		DebugTraceAPIStash("Error! " + akStashRef + " is busy!")
		Return 0
	EndIf
	SetStashInt(akStashRef,"Busy",1)

	Actor PlayerREF = Game.GetPlayer()
	String sSessionID = GetSessionStr("SessionID")
	String sPlayerName = PlayerREF.GetActorBase().GetName()
	Float fSessionTime = Game.GetRealHoursPassed()

	vSS_StashManager StashManager = Quest.GetQuest("vSS_StashManagerQuest") as vSS_StashManager

	ObjectReference kMoveTarget 		= StashManager.MoveTarget
	ObjectReference kContainerTarget 	= StashManager.ContainerTarget
	EffectShader    kContainerShader 	= StashManager.ContainerFXShader

	kContainerShader.Play(akStashRef)

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
				If kItem as ObjectReference || kItem as Weapon || kItem as Armor
					If kItem as ObjectReference
						(kItem as ObjectReference).MoveTo(kMoveTarget)
						sItemID = vSS_API_Item.SerializeObject(kItem as ObjectReference)
						akStashRef.AddItem((kItem as ObjectReference),abSilent = True)
					ElseIf kItem as Weapon || kItem as Armor
						akStashRef.RemoveItem(kItem,1,True,kContainerTarget)
						ObjectReference kObject = kContainerTarget.DropObject(kItem, 1)
						sItemID = vSS_API_Item.SerializeObject(kObject)
						akStashRef.AddItem(kObject,abSilent = True)
					EndIf
				EndIf
				Int jItemMap
				If sItemID
					jItemMap = vSS_API_Item.GetItemJMap(sItemID)
				Else
					jItemMap = JMap.Object()
					JMap.SetForm(jItemMap,"Form",kItem)
					JMap.SetInt(jItemMap,"Count",iCount)
				EndIf
				JMap.SetStr(jItemMap,"SessionID",sSessionID)
				JMap.SetStr(jItemMap,"PlayerName",sPlayerName)
				JMap.SetFlt(jItemMap,"SessionTime",fSessionTime)
				JArray.AddObj(jItemList,jItemMap)
			EndIf
		EndIf
	EndWhile
	DebugTraceAPIStash("Updated Stash " + akStashRef + ", found " + (kStashItems.Length - 1) + " items!")
	SetStashObj(akStashRef,"Items",jItemList)
	SetStashStr(akStashRef,"LastSessionID",sSessionID)
	SetStashFlt(akStashRef,"LastSessionTime",fSessionTime)

	kContainerShader.Stop(akStashRef)
	akStashRef.BlockActivation(False)
	SetStashInt(akStashRef,"Busy",0)

	JValue.releaseObjectsWithTag("vSS_" + sStashID)

	Return (kStashItems.Length - 1)
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