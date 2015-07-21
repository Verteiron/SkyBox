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

Bool Function AddStashTransaction(ObjectReference akStashRef, Int ajItemMap) Global
	Int jStashTransactions = GetStashObj(akStashRef,"Transactions")
	If !jStashTransactions
		SetStashObj(akStashRef,"Transactions",JArray.Object())
		jStashTransactions = GetStashObj(akStashRef,"Transactions")
	EndIf
	Int jStashTransaction = JMap.Object()
	JMap.SetStr(jStashTransaction,"Form",JMap.GetStr(ajItemMap,"Form"))
	JMap.SetInt(jStashTransaction,"Count",JMap.GetInt(ajItemMap,"Count"))
	If JMap.GetStr(ajItemMap,"UUID")
		JMap.SetStr(jStashTransaction,"UUID",JMap.GetStr(ajItemMap,"UUID"))
	EndIf
	JArray.AddObj(jStashTransactions,jStashTransaction)
	SaveReg()
	Return True
EndFunction

Int Function GetContainerDiffs(ObjectReference akStashRef) Global
	If !IsStash(akStashRef)
		DebugTraceAPIStash("Error! " + akStashRef + " is not a valid Stash!")
		Return -1
	EndIf

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

	ObjectReference kMoveTarget 		= StashManager.MoveTarget
	ObjectReference kContainerTarget 	= StashManager.ContainerTarget
	EffectShader    kContainerShader 	= StashManager.ContainerFXShader

	kContainerShader.Play(akStashRef)

	String sStashID = GetFormIDString(akStashRef)

	Int jStashTransactions = GetStashObj(akStashRef,"Transactions")
	If !jStashTransactions
		SetStashObj(akStashRef,"Transactions",JArray.Object())
		jStashTransactions = GetStashObj(akStashRef,"Transactions")
	EndIf
	Int jTransItemEntries = JArray.Object()

	Int jStashPrevState = GetStashObj(akStashRef,"Items") 
	Int jStashState = JArray.Object()
	JValue.Retain(jStashState,"vSS_" + sStashID)
	JValue.Retain(jTransItemEntries,"vSS_" + sStashID)

	Form[] 		kStashItems 	= akStashRef.GetContainerForms()
	Int[] 		iItemCount 		= SuperStash.GetItemCounts(kStashItems,akStashRef)
	Int[] 		iItemTypes 		= SuperStash.GetItemTypes(kStashItems)
	String[] 	sItemNames 		= SuperStash.GetItemNames(kStashItems)

	;First scan for items that have been changed or removed
	Int i = JArray.Count(jStashPrevState)
	While i > 0
		i -= 1
		Int jItemMap = JArray.GetObj(jStashPrevState,i)
		If jItemMap
			Int jTransItemEntry = JMap.Object()
			Form kForm = JMap.GetForm(jItemMap,"Form")
			Int iPrevCount = JMap.GetInt(jItemMap,"Count")
			If kForm
				JMap.SetForm(jTransItemEntry,"Form",kForm)
				Int iItemIdx = kStashItems.Find(kForm)
				If iItemIdx >= 0
					DebugTraceAPIStash("Checking for changes to " + kForm + ", previous count was " + iPrevCount + ", current count is " + iItemCount[iItemIdx] + "!")
					If iItemCount[iItemIdx] != iPrevCount
						JMap.SetInt(jTransItemEntry,"Count",iItemCount[iItemIdx] - iPrevCount)
					EndIf
				Else
					JMap.SetInt(jTransItemEntry,"Count",-iPrevCount)
				EndIf
				If JMap.GetInt(jTransItemEntry,"Count") != 0
					DebugTraceAPIStash(kForm + " changed, adding transaction!")
					If JMap.HasKey(jItemMap,"UUID")
						JMap.SetStr(jTransItemEntry,"UUID",JMap.GetStr(jItemMap,"UUID"))
					EndIf
					JArray.AddObj(jTransItemEntries,jTransItemEntry)
				EndIf
			EndIf
		EndIf
	EndWhile


	i = kStashItems.Length
	While i > 0
		i -= 1
		Bool bItemInTrans = False
		Bool bItemUnchanged = False
		String sItemID = ""
		Form kItem = kStashItems[i]
		If kItem
			Int iTransIdx = JValue.evalLuaInt(jTransItemEntries, "return jc.find(jobject, function (x) return x.form == Form(" + kItem.GetFormID() + ") end)") - 1
			If iTransIdx >= 0
				DebugTraceAPIStash(kItem + " is already in transaction!")
				bItemInTrans = True
			EndIf

			Int iType = iItemTypes[i]
			Int iCount = iItemCount[i]
			; Int jTemp = Array.object()
			; JArray.addObj(jTemp,jStashState)
			; JArray.addForm(jTemp,kItem)
			Int jItemMap = 0
			Int iItemIdx = JValue.evalLuaInt(jStashPrevState, "return jc.find(jobject, function (x) return x.form == Form(" + kItem.GetFormID() + ") end)") - 1
			If iItemIdx >= 0
				jItemMap = JArray.GetObj(jStashPrevState,iItemIdx)
			EndIf
			;DebugTraceAPIStash("jItemMap is " + jItemMap)
			If jItemMap 
				;Item is already in the container
				Int iStashCount = JMap.GetInt(jItemMap,"Count")
				DebugTraceAPIStash("jItemMap for " + kItem.GetName() + " exists with form " + JMap.Getform(jItemMap,"Form") + " and count " + iStashCount + "!")
				If JMap.GetStr(jItemMap,"UUID")
					Form kObject = vSS_API_Item.GetExistingObject(JMap.GetStr(jItemMap,"UUID")) 
					If kObject
						If (kObject as ObjectReference).GetBaseObject() == kItem
							DebugTraceAPIStash("Custom weapon exists in this Session and is already in the Container!")
							bItemUnchanged = True
						Else
							DebugTraceAPIStash("Custom weapon exists in this Session but is NOT in the Container!")	
						EndIf
					Else
						DebugTraceAPIStash("Custom weapon does not yet exist in this Session!")	
					EndIf
				ElseIf JMap.GetInt(jItemMap,"Count") == iCount
					;Item is not a custom one, so if the form and count match we're good
					DebugTraceAPIStash("Item is not customized!!")
					bItemUnchanged = True
				EndIf
			EndIf
			If bItemUnchanged
				JArray.AddObj(jStashState,JValue.DeepCopy(jItemMap))
			ElseIf iCount > 0 
				If kItem as ObjectReference || kItem as Weapon || kItem as Armor
					If kItem as ObjectReference
						DebugTraceAPIStash(kItem + " is an ObjectReference!")
						(kItem as ObjectReference).MoveTo(kMoveTarget)
						sItemID = vSS_API_Item.SerializeObject(kItem as ObjectReference)
						akStashRef.AddItem((kItem as ObjectReference),abSilent = True)
					ElseIf kItem as Weapon || kItem as Armor
						DebugTraceAPIStash(kItem + " is a Weapon or Armor!")
						akStashRef.RemoveItem(kItem,1,True,kContainerTarget)
						ObjectReference kObject = kContainerTarget.DropObject(kItem, 1)
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
					JMap.SetForm(jItemMap,"Form",kItem)
					JMap.SetInt(jItemMap,"Count",iCount)
				EndIf
				JMap.SetStr(jItemMap,"SID",sSessionID)
				JMap.SetStr(jItemMap,"PlayerName",sPlayerName)
				JMap.SetFlt(jItemMap,"SessionTime",fSessionTime)
				JMap.SetInt(jItemMap,"DataSerial",iDataSerial)
				JArray.AddObj(jStashState,jItemMap)
				If !bItemInTrans
					DebugTraceAPIStash("Adding " + kItem + " to transactions!")
					Int jTransItemEntry = JMap.Object()
					JMap.SetForm(jTransItemEntry,"Form",JMap.GetForm(jItemMap,"Form"))
					JMap.SetInt(jTransItemEntry,"Count",iCount)
					If JMap.HasKey(jItemMap,"UUID")
						JMap.SetStr(jTransItemEntry,"UUID",JMap.GetStr(jItemMap,"UUID"))
					EndIf
					JArray.AddObj(jTransItemEntries,jTransItemEntry)
				EndIf
			EndIf
		EndIf
	EndWhile
	DebugTraceAPIStash("Updated Stash " + akStashRef + ", found " + kStashItems.Length + " items!")

	Int jStashTransaction = JMap.Object()
	JMap.SetStr(jStashTransaction,"SID",sSessionID)
	JMap.SetFlt(jStashTransaction,"SessionTime",fSessionTime)
	JMap.SetObj(jStashTransaction,"ItemEntries",jTransItemEntries)
	JArray.AddObj(jStashTransactions,jStashTransaction)

	SetStashInt(akStashRef,"DataSerial",iDataSerial)
	SetStashSessionInt(akStashRef,"DataSerial",iDataSerial)
	
	SetStashObj(akStashRef,"Items",jStashState)
	SetStashStr(akStashRef,"LastSessionID",sSessionID)
	SetStashFlt(akStashRef,"LastSessionTime",fSessionTime)

	kContainerShader.Stop(akStashRef)
	akStashRef.BlockActivation(False)
	SetStashInt(akStashRef,"Busy",0)

	JValue.releaseObjectsWithTag("vSS_" + sStashID)

	JValue.WriteToFile(GetStashJMap(akStashRef),SuperStash.userDirectory() + "Stashes/" + sStashID + ".json")
	Return kStashItems.Length
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