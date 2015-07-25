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
	
	Int iDataSerial = GetStashInt(akStashRef,"DataSerial")
	Int iStashSerial = GetStashSessionInt(akStashRef,"DataSerial")

	If iDataSerial == iStashSerial
		DebugTraceAPIStash(akStashRef + " is already up to date!")
		Return 0
	EndIf

	SetStashInt(akStashRef,"Busy",1)

	vSS_StashManager StashManager = Quest.GetQuest("vSS_StashManagerQuest") as vSS_StashManager

	String sSessionID = GetSessionStr("SessionID")
	Float fSessionTime = Game.GetRealHoursPassed()

	ObjectReference kMoveTarget 		= StashManager.MoveTarget
	ObjectReference kContainerTarget 	= StashManager.ContainerTarget

	EffectShader    kContainerShader 	= StashManager.ContainerFXShader

	Int iOriginalItemCount = akStashRef.GetContainerForms().Length

	Int jItemList = GetStashObj(akStashRef,"Items")
	If !jItemList
		DebugTraceAPIStash("Error! " + akStashRef + " is missing its ItemList!")
		SetStashInt(akStashRef,"Busy",0)
		Return 0
	EndIf

	akStashRef.BlockActivation(True)
	kContainerShader.Play(akStashRef)

	Int i = JArray.Count(jItemList)
	While i > 0
		i -= 1
		Int jItemMap = JArray.GetObj(jItemList,i)
		String sItemID = JMap.GetStr(jItemMap,"UUID")
		Int iItemSerial = JMap.GetInt(jItemMap,"DataSerial")
		If sSessionID == JMap.GetStr(jItemMap,"SessionID") && fSessionTime <= JMap.GetFlt(jItemMap,"SessionTime")
			DebugTraceAPIStash("Error! " + akStashRef + " - Item's session/timestamp indicates same-session duplication could occur! Item: " + JMap.GetStr(jItemMap,"DisplayName") + " (" + sItemID + ")!")
		EndIf
		If sItemID 
			;Check if this item has already been created in this Session
			ObjectReference kObject = vSS_API_Item.GetExistingObject(sItemID) as ObjectReference
			If kObject
				DebugTraceAPIStash(JMap.GetStr(jItemMap,"DisplayName") + " (" + sItemID + ") has already been created in this Session!")
				If akStashRef.GetItemCount(kObject)
					akStashRef.RemoveItem(kObject,1,True,kContainerTarget)
					DebugTraceAPIStash("... and it's already in this Stash object!")
				EndIf
			Else ;Item has not been created in this Session
				kObject = vSS_API_Item.CreateObject(sItemID)
				If kObject
					kContainerTarget.AddItem(kObject, 1, True)
				Else
					DebugTraceAPIStash("Error! " + akStashRef + " could not recreate item " + JMap.GetStr(jItemMap,"DisplayName") + " (" + sItemID + ")!")
				EndIf
			EndIf
		Else
			Form kItem = JMap.GetForm(jItemMap,"Form")
			If kItem 
				kContainerTarget.AddItem(kItem, JMap.GetInt(jItemMap,"Count"), abSilent = True)
				; Int iLocalItemCount = akStashRef.GetItemCount(kItem)
				; Int iSavedItemCount = JMap.GetInt(jItemMap,"Count")
				; If iLocalItemCount > iSavedItemCount
				; 	akStashRef.RemoveItem(kItem, iLocalItemCount - iSavedItemCount, abSilent = True)
				; ElseIf iLocalItemCount < iSavedItemCount
				; 	kContainerTarget.AddItem(kItem, iSavedItemCount - iLocalItemCount, abSilent = True)
				; EndIf
			Else
				DebugTraceAPIStash("Error! " + akStashRef + " could not load a form!")
			EndIf
		EndIf
	EndWhile

	akStashRef.RemoveAllItems()
	kContainerTarget.RemoveAllItems(akStashRef)

	SetStashSessionInt(akStashRef,"DataSerial",iDataSerial)
	SetStashInt(akStashRef,"Busy",0)
	
	;If iOriginalItemCount > 0 ;&& iOriginalItemCount != akStashRef.GetContainerForms().Length
		;ExportStashItems(akStashRef)
	;EndIf

	kContainerShader.Stop(akStashRef)
	akStashRef.BlockActivation(False)

	Return 0

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

Int Function ScanContainer(ObjectReference akStashRef) Global

	vSS_StashManager StashManager = Quest.GetQuest("vSS_StashManagerQuest") as vSS_StashManager
	ObjectReference 	kMoveTarget 		= StashManager.MoveTarget
	ObjectReference 	kContainerTarget 	= StashManager.ContainerTarget
	ObjectReference 	kContainerTemp 		= StashManager.ContainerTemp
	vSS_WeaponScanner[] WeaponScanners		= StashManager.WeaponScanners

	Int 		jContainerState	= JArray.Object()
	JValue.AddToPool(jContainerState,"vSS_ScanState")

	Int i = WeaponScanners.Length
	While i > 0
		i -= 1
		WeaponScanners[i].Index = i
		WeaponScanners[i].jContainerState = jContainerState
	EndWhile

	Form[] 		kStashItems 	= akStashRef.GetContainerForms()
	Int[] 		iItemCount 		= SuperStash.GetItemCounts(kStashItems,akStashRef)
	Int[] 		iItemTypes 		= SuperStash.GetItemTypes(kStashItems)
	String[] 	sItemNames 		= SuperStash.GetItemNames(kStashItems)
	;Int[] 		iItemExtraData 	= SuperStash.GetItemHasExtraData(kStashItems)

	;Int i = kStashItems.Length
	i = akStashRef.GetNumItems()

	DebugTraceAPIStash("Scanning " + i + " forms in " + akStashRef + "...")
	While i > 0
		i -= 1
		Bool bItemInTrans = False
		Bool bItemUnchanged = False
		String sItemID = ""

		Form kItem = kStashItems[i]
		Int iType = iItemTypes[i]
		Int iCount = iItemCount[i]
		; Bool bExtraData = iItemExtraData[i] as Bool
		; Form kItem = akStashRef.GetNthForm(i)
		; Int iType = kItem.GetType()
		; Int iCount = akStashRef.GetItemCount(kItem)

		Int jItemMap = 0

		DebugTraceAPIStash("Scanning " + iCount + " of Form " + kItem + "...")

		If kItem
			If iCount > 0 
				If kItem as ObjectReference || iType == 41 || iType == 26 ; Weapon or Armor
					If kItem as ObjectReference
						DebugTraceAPIStash(kItem + " is an ObjectReference!")
						(kItem as ObjectReference).MoveTo(kMoveTarget)
						sItemID = vSS_API_Item.SerializeObject(kItem as ObjectReference)
						akStashRef.AddItem((kItem as ObjectReference),abSilent = True)
					ElseIf iType == 41 || iType == 26 ; Weapon or Armor
						DebugTraceAPIStash(kItem + " is a Weapon or Armor!")
						akStashRef.RemoveItem(kItem,iCount,True,WeaponScanners[i % 4])
						; ObjectReference kObject = kContainerTarget.DropObject(kItem, 1)
						; sItemID = vSS_API_Item.GetObjectID(kObject)
						; If !sItemID
						; 	sItemID = vSS_API_Item.SerializeObject(kObject)
						; EndIf
						; akStashRef.AddItem(kObject,abSilent = True)
					EndIf
				EndIf
				If sItemID
					jItemMap = vSS_API_Item.GetItemJMap(sItemID)
				Else
					jItemMap = JMap.Object()
					JMap.SetForm(jItemMap,"Form",kItem)
					JMap.SetInt(jItemMap,"Count",iCount)
				EndIf
				JArray.AddObj(jContainerState,jItemMap)
			EndIf
		EndIf
	EndWhile

	While WeaponScanners[0].Busy || WeaponScanners[1].Busy || WeaponScanners[2].Busy || WeaponScanners[3].Busy
		Utility.WaitMenuMode(0.5)
		DebugTraceAPIStash("Waiting for weaponscanners...")
	EndWhile
	kContainerTarget.RemoveAllItems(akStashRef)

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

	String sStashID = GetFormIDString(akStashRef)

	Int jStashState = ScanContainer(akStashRef)

	Int iEntryCount = JArray.Count(jStashState)
	
	DebugTraceAPIStash("Updated Stash " + akStashRef + ", found " + iEntryCount + " entries!")

	SetStashInt(akStashRef,"DataSerial",iDataSerial)
	SetStashSessionInt(akStashRef,"DataSerial",iDataSerial)
	
	SetStashObj(akStashRef,"Items",jStashState)
	SetStashStr(akStashRef,"LastSessionID",sSessionID)
	SetStashFlt(akStashRef,"LastSessionTime",fSessionTime)

	kContainerShader.Stop(akStashRef)
	akStashRef.BlockActivation(False)
	SetStashInt(akStashRef,"Busy",0)

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