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

Int Function GetStashSessionFormMap() Global
	Int jStashFormMap = GetSessionObj("StashFormMap")
	If jStashFormMap
		Return jStashFormMap
	EndIf
	jStashFormMap = JFormMap.Object()
	SetSessionObj("StashFormMap",jStashFormMap)
	Return jStashFormMap
EndFunction

Int Function GetStashSessionJMap(ObjectReference akStashRef, Bool abCreateIfMissing = False) Global
	Int jStashFormMap = GetStashSessionFormMap()
	Int jStashJMap = JFormMap.GetObj(jStashFormMap,akStashRef)
	If JValue.isMap(jStashJMap)
		Return jStashJMap
	EndIf
	If abCreateIfMissing
		jStashJMap = JMap.object()
		JFormMap.SetObj(jStashFormMap,akStashRef,jStashJMap)
		Return jStashJMap
	EndIf
	Return 0
EndFunction

;=== Generic Get/Set Functions ===--

Int Function GetStashSessionInt(ObjectReference akStashRef, String asKey) Global
	asKey = MakePath(asKey)
	Int jStashJMap = GetStashSessionJMap(akStashRef)
	If jStashJMap
		Return JValue.solveInt(jStashJMap,asKey)
	EndIf
	Return 0
EndFunction

Function SetStashSessionInt(ObjectReference akStashRef, String asKey, Int aiValue) Global
	asKey = MakePath(asKey)
	JValue.solveIntSetter(GetStashSessionJMap(akStashRef,True),asKey,aiValue,True)
	SaveReg()
EndFunction

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
			DebugTraceAPIStash("Found Stash " + kContainer + "!")
			
			Int iCount = ImportStashItems(kContainer)
			;String sFilePath = SuperStash.userDirectory() + "Stashes\\player.json"
			
			;Int iCount = SuperStash.FillContainerFromJSON(kContainer,sFilePath)
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

	vSS_StashManager StashManager 		= Quest.GetQuest("vSS_StashManagerQuest") as vSS_StashManager
	ObjectReference kContainerTemp 		= StashManager.ContainerTemp
	ObjectReference kMoveTarget 		= StashManager.MoveTarget
	ObjectReference kContainerTarget 	= StashManager.ContainerTarget

	String sStashID  = SuperStash.GetStashNameString(akStashRef)
	String sFilePath = SuperStash.userDirectory() + "Stashes\\" ;"; <-- fix for highlighting in SublimePapyrus
	sFilePath += sStashID + ".json" 

	;Create ExtraContainerChanges data for Container
	Form kGold = Game.GetFormFromFile(0xf,"Skyrim.esm")
	akStashRef.AddItem(kGold, 1, True)
	akStashRef.RemoveItem(kGold, 1, True)

	DebugTraceAPIStash("Filling " + akStashRef + " from " + sFilePath + "!")
	
	;This very quickly fills the container with all the base forms
	Return SuperStash.FillContainerFromJson(akStashRef,sFilePath)

EndFunction

Int Function _CreateItemMap(ObjectReference akStashRef, ObjectReference akMoveTarget, ObjectReference akContainerTarget, Form akItem, Int aiItemCount, Int aiItemType) Global
	Int jItemMap = 0
	String sItemID = ""
	If akItem as ObjectReference || aiItemType == 41 || aiItemType == 26 ; Weapon or Armor
		If akItem as ObjectReference
			DebugTraceAPIStash(akItem + " is an ObjectReference!")
			(akItem as ObjectReference).MoveTo(akMoveTarget)
			sItemID = vSS_API_Item.SerializeObject(akItem as ObjectReference)
			akStashRef.AddItem((akItem as ObjectReference),abSilent = True)
		ElseIf aiItemType == 41 || aiItemType == 26 ; Weapon or Armor
			DebugTraceAPIStash(akItem + " is a Weapon or Armor!")
			akStashRef.RemoveItem(akItem,1,True,akContainerTarget)
			ObjectReference kObject = akContainerTarget.DropObject(akItem, 1)
			sItemID = vSS_API_Item.GetObjectID(kObject)
			If !sItemID
				sItemID = vSS_API_Item.SerializeObject(kObject)
			EndIf
			akStashRef.AddItem(kObject,abSilent = True)
		EndIf
	EndIf
	If sItemID
		jItemMap = vSS_API_Item.GetItemJMap(sItemID)
	Else
		jItemMap = JMap.Object()
		JMap.SetForm(jItemMap,"Form",akItem)
		JMap.SetInt(jItemMap,"Count",aiItemCount)
	EndIf
	
	Return jItemMap
EndFunction

;For anyone reading this, I had this whole scan working perfectly in pure Papyrus. It was beautiful.
;It used several containers working in parallel to sort and scan everything. For Papyrus, it was 
;blindingly fast. By any realistic standard, though, it was also mind-numbingly slow. Call it a 
;moral victory. At any rate, I gave up on doing it in pure Papyris and instead learned c++ well 
;enough to reimplement it in an SKSE plugin. Now it's nearly instantaneous. So it goes.
Int Function ScanContainer(ObjectReference akStashRef) Global
	DebugTraceAPIStash("=== Starting scan of " + akStashRef + " ===--")
	vSS_StashManager StashManager = Quest.GetQuest("vSS_StashManagerQuest") as vSS_StashManager

	Int jContainerState = JValue.objectFromPrototype(SuperStash.GetContainerJSON(akStashRef))
	JValue.WriteToFile(jContainerState,SuperStash.userDirectory() + "Stashes/quick.json")
	
	DebugTraceAPIStash("=== Finished scan of " + akStashRef + " ===--")
	Return jContainerState
EndFunction

Function AddStashItem(ObjectReference akStashRef, Form akBaseItem, int aiItemCount, ObjectReference akItemReference = None) Global
	Int jStashMap = GetStashSessionJMap(akStashRef)
	Int jPending = JMap.GetObj(jStashMap,"Pending")
	If !jPending
		JMap.SetObj(jStashMap,"Pending",JFormMap.Object())
		jPending = JMap.GetObj(jStashMap,"Pending")
	EndIf
	Form kItem = akBaseItem
	If akItemReference
		kItem = akItemReference
	EndIf
	JFormMap.SetInt(jPending,kItem,JFormMap.GetInt(jPending,kItem) + aiItemCount)
	SaveSession()
EndFunction

Function RemoveStashItem(ObjectReference akStashRef, Form akBaseItem, int aiItemCount, ObjectReference akItemReference = None) Global
	Int jStashMap = GetStashSessionJMap(akStashRef)
	Int jPending = JMap.GetObj(jStashMap,"Pending")
	If !jPending
		JMap.SetObj(jStashMap,"Pending",JFormMap.Object())
		jPending = JMap.GetObj(jStashMap,"Pending")
	EndIf
	Form kItem = akBaseItem
	If akItemReference
		kItem = akItemReference
	EndIf
	JFormMap.SetInt(jPending,kItem,JFormMap.GetInt(jPending,kItem) - aiItemCount)
	SaveSession()
EndFunction

Int Function ProcessPending(ObjectReference akStashRef) Global
	Int jStashMap = GetStashSessionJMap(akStashRef)
	Int jPending = JMap.GetObj(jStashMap,"Pending")
	If !jPending
		Return 0
	EndIf

	Int iPendingCount = JFormMap.Count(jPending)

	vSS_StashManager StashManager 		= Quest.GetQuest("vSS_StashManagerQuest") as vSS_StashManager
	ObjectReference ContainerTemp 		= StashManager.ContainerTemp
	ObjectReference kMoveTarget 		= StashManager.MoveTarget
	ObjectReference kContainerTarget 	= StashManager.ContainerTarget

	Int jStashState = GetStashObj(akStashRef,"Items")

	Form kItem = JFormMap.nextKey(jPending)
	While kItem
		Int jItemMap = 0
		Int iCount = JFormMap.GetInt(jPending,kItem)
		Int iItemIdx = JValue.evalLuaInt(jStashState, "return jc.find(jobject, function (x) return x.form == Form(" + kItem.GetFormID() + ") end)") - 1
		If iItemIdx >= 0
			jItemMap = JArray.GetObj(jStashState,iItemIdx)
		EndIf
		If jItemMap
			Int iStateCount = JMap.GetInt(jItemMap,"Count")
			If iStateCount
				JMap.SetInt(jItemMap,"Count",iStateCount + iCount)
			EndIf
		Else
			Int iType = kItem.GetType()
			jItemMap = _CreateItemMap(akStashRef,kMoveTarget,kContainerTarget,kItem,iCount,iType)
			JArray.AddObj(jStashState,jItemMap)
		EndIf

		kItem = JFormMap.nextKey(jPending,kItem)
	EndWhile
	JMap.RemoveKey(jStashMap,"Pending")
	Return iPendingCount
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
	Int iDataSerial = GetStashInt(akStashRef,"DataSerial") + 1

	Actor PlayerREF = Game.GetPlayer()
	String sSessionID = GetSessionStr("SessionID")
	String sPlayerName = PlayerREF.GetActorBase().GetName()
	Float fSessionTime = Game.GetRealHoursPassed()

	vSS_StashManager StashManager = Quest.GetQuest("vSS_StashManagerQuest") as vSS_StashManager

	EffectShader    kContainerShader 	= StashManager.ContainerFXShader

	kContainerShader.Play(akStashRef)

	String sStashID = SuperStash.GetStashNameString(akStashRef)

	Int jStashState = ScanContainer(akStashRef)

	Int iEntryCount = JArray.Count(JMap.GetObj(jStashState,"containerEntries")) + JArray.Count(JMap.GetObj(jStashState,"entryDataList"))
	
	DebugTraceAPIStash("Updated Stash " + akStashRef + ", found " + iEntryCount + " entries!")

	SetStashInt(akStashRef,"DataSerial",iDataSerial)
	SetStashSessionInt(akStashRef,"DataSerial",iDataSerial)

	Int jKeyList = JMap.AllKeys(jStashState)
	Int i = JArray.Count(jKeyList)
	While i > 0
		i -= 1
		String sKey = JArray.GetStr(jKeyList,i)
		If sKey
			SetStashObj(akStashRef,sKey,JMap.GetObj(jStashState,sKey))
		EndIf
	EndWhile

	;SetStashObj(akStashRef,"ContainerState",jStashState)
	SetStashStr(akStashRef,"LastSessionID",sSessionID)
	SetStashFlt(akStashRef,"LastSessionTime",fSessionTime)

	kContainerShader.Stop(akStashRef)
	akStashRef.BlockActivation(False)
	SetStashInt(akStashRef,"Busy",0)

	SuperStash.RotateFile(SuperStash.userDirectory() + "Stashes/" + sStashID + ".json")
	JValue.WriteToFile(GetStashJMap(akStashRef),SuperStash.userDirectory() + "Stashes/" + sStashID + ".json")
	JValue.CleanPool("vSS_ScanState")
	Return iEntryCount
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