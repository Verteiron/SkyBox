Scriptname vSS_API_Stash extends vSS_APIBase Hidden
{Save and restore Stash data, including custom Stashs.}

; === [ vSS_API_Stash.psc ] ===============================================---
; API for saving and loading Stashs. A Stash is a container that will be shared
; between multiple savegames/sessions.
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
		SetStashInt(akStashRef,"DataSerial",0)
		SetStashSessionInt(akStashRef,"DataSerial",0)
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

Form[] Function GetAllStashObjects() Global
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

Function CreateMCMLists() Global
	DebugTraceAPIStash("Creating MCM lists...")
	Int jMCM = JMap.Object()
	Int jStashFormMap = GetStashFormMap()

	Int jMCMNames = JArray.Object()
	Form kKey = JFormMap.NextKey(jStashFormMap)

	Int jStashList = JFormMap.AllValues(jStashFormMap)
	Int i = JArray.Count(jStashList)
	While i > 0
		i -= 1
		Int jStashData = JArray.GetObj(jStashList,i)
		kKey = JMap.GetForm(jStashData,"Form")
		DebugTraceAPIStash("Key is " + kKey + "!")
		String sCellName = JMap.GetStr(jStashData,"CellName") 
		String sStashName = JMap.GetStr(jStashData,"StashName")
		String sStashID = JMap.GetStr(jStashData,"FormIDString")
		
		JValue.SolveIntSetter(jMCM,".CellMap." + sCellName + "." + sStashName + "." + sStashID,JMap.GetInt(jStashData,"FormID"),True)

		;If kKey
			JArray.AddStr(jMCMNames,sCellName + "/" + sStashName)
		;EndIf

		;JValue.SolveFormSetter(jMCM,".CellMap." + sCellName + "." + sStashName + "." + sStashID,kKey,True)
	EndWhile
	jMCMNames = JArray.Sort(jMCMNames)
	JMap.SetObj(jMCM,"StringMap",jMCMNames)

	SetSessionObj("MCMMap",jMCM)
	SaveSession()
	DebugTraceAPIStash("Created MCM lists!")
EndFunction

String[] Function GetMCMNames() Global
	Return SuperStash.JObjToArrayStr(JArray.Sort(GetSessionObj("MCMMap.StringMap")))
EndFunction

;=== Stash object inventory Functions ===--

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

	EffectShader    kContainerShader 	= StashManager.ContainerFXShader
	kContainerShader.Stop(akStashRef)
	kContainerShader.Play(akStashRef)

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

;For anyone reading this, I had this whole scan working perfectly in pure Papyrus. It was beautiful.
;It used several containers working in parallel to sort and scan everything. For Papyrus, it was 
;blindingly fast. By any realistic standard, though, it was also mind-numbingly slow. Call it a 
;moral victory. At any rate, I gave up on doing it in pure Papyrus and instead learned c++ well 
;enough to reimplement it in an SKSE plugin. Now it's nearly instantaneous. So it goes.
Int Function ScanContainer(ObjectReference akStashRef) Global
	DebugTraceAPIStash("=== Starting scan of " + akStashRef + " ===--")
	vSS_StashManager StashManager = Quest.GetQuest("vSS_StashManagerQuest") as vSS_StashManager

	Int jContainerState = JValue.objectFromPrototype(SuperStash.GetContainerJSON(akStashRef))
	JValue.WriteToFile(jContainerState,SuperStash.userDirectory() + "Stashes/quick.json")
	
	DebugTraceAPIStash("=== Finished scan of " + akStashRef + " ===--")
	Return jContainerState
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
	kContainerShader.Stop(akStashRef)
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
	SetStashForm(akStashRef,"Form",akStashRef)
	SetStashInt(akStashRef,"FormID",akStashRef.GetFormID())
	SetStashStr(akStashRef,"FormIDString",GetFormIDString(akStashRef))
	SetStashStr(akStashRef,"Source",SuperStash.GetSourceMod(akStashRef))

	String sCellName = akStashRef.GetParentCell().GetName()
	If sCellName
		SetStashStr(akStashRef,"CellName",sCellName)
	Else
		SetStashStr(akStashRef,"CellName","Unnamed Cell")
	EndIf

	String sStashName = akStashRef.GetName()
	If !sStashName
		sStashName = akStashRef.GetBaseObject().GetName()
	EndIf

	If sStashName
		SetStashStr(akStashRef,"StashName",sStashName)
	Else 
		SetStashStr(akStashRef,"StashName","Unnamed container")
	EndIf

	;kContainerShader.Stop(akStashRef)
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