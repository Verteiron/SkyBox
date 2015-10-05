Scriptname vSS_API_Stash extends vSS_APIBase Hidden
{Save and restore Stash data, including custom Stashs.}

; === [ vSS_API_Stash.psc ] ===============================================---
; API for saving and loading Stashs. A Stash is a container that will be shared
; between multiple savegames/sessions.
; ========================================================---

; FIXME: HEY I just had this really hoopy idea. Papyrus coerces Forms into Strings. This means I can check
; to see if an incoming string is actually a Form, and consolidate these split functions into one 
; without breaking compatibility. Maybe. Might not be worth the effort.

Import vSS_Registry
Import vSS_Session

;=== Stash data init Functions ===--

Int Function GetStashFormMap() Global
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
	Int jStashJMap = GetRegObj("Stashes." + asUUID)
	If JValue.isMap(jStashJMap)
		Return jStashJMap
	EndIf
	Return 0
EndFunction

Int Function GetStashBackupJMap(String asUUID, Int aiBackupNum = 1) Global
	String sStashFileName  = GetStashFileNameString(asUUID)
	String sFilePath = SuperStash.userDirectory() + "Stashes\\" ;"; <-- fix for highlighting in SublimePapyrus
	sFilePath += sStashFileName + "." + aiBackupNum + ".json" 
	Int jStashJMap = JValue.ReadFromFile(sFilePath)
	If JValue.isMap(jStashJMap)
		Return jStashJMap
	EndIf
	Return 0
EndFunction

Int Function GetStashRefJMap(ObjectReference akStashRef) Global
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
	Return JMap.GetStr(GetStashRefJMap(akStashRef),"UUID")
EndFunction

ObjectReference Function GetStashRefForUUID(String asUUID) Global
	Return JMap.GetForm(GetStashJMap(asUUID),"Form") as ObjectReference
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

Int Function CreateStashSessionJMap(String asUUID = "") Global
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

;=== Generic Get/Set by UUID Functions ===--

Int Function GetStashSessionInt(String asUUID, String asKey) Global
	asKey = MakePath(asKey)
	Int jStashJMap = GetStashSessionJMap(asUUID)
	If jStashJMap
		Return JValue.solveInt(jStashJMap,asKey)
	EndIf
	Return 0
EndFunction

Function SetStashSessionInt(String asUUID, String asKey, Int aiValue) Global
	asKey = MakePath(asKey)
	JValue.solveIntSetter(GetStashSessionJMap(asUUID,True),asKey,aiValue,True)
	SaveSession()
EndFunction

Int Function GetStashInt(String asUUID, String asKey) Global
	asKey = MakePath(asKey)
	Int jStashJMap = GetStashJMap(asUUID)
	If jStashJMap
		Return JValue.solveInt(jStashJMap,asKey)
	EndIf
	Return 0
EndFunction

Function SetStashInt(String asUUID, String asKey, Int aiValue) Global
	asKey = MakePath(asKey)
	JValue.solveIntSetter(GetStashJMap(asUUID),asKey,aiValue,True)
	SaveReg()
EndFunction

Float Function GetStashFlt(String asUUID, String asKey) Global
	asKey = MakePath(asKey)
	Int jStashJMap = GetStashJMap(asUUID)
	If jStashJMap
		Return JValue.solveFlt(jStashJMap,asKey)
	EndIf
	Return 0
EndFunction

Function SetStashFlt(String asUUID, String asKey, Float afValue) Global
	asKey = MakePath(asKey)
	JValue.solveFltSetter(GetStashJMap(asUUID),asKey,afValue,True)
	SaveReg()
EndFunction

String Function GetStashStr(String asUUID, String asKey) Global
	asKey = MakePath(asKey)
	Int jStashJMap = GetStashJMap(asUUID)
	If jStashJMap
		Return JValue.solveStr(jStashJMap,asKey)
	EndIf
	Return ""
EndFunction

Function SetStashStr(String asUUID, String asKey, String asValue) Global
	asKey = MakePath(asKey)
	JValue.solveStrSetter(GetStashJMap(asUUID),asKey,asValue,True)
	SaveReg()
EndFunction

Form Function GetStashForm(String asUUID, String asKey) Global
	asKey = MakePath(asKey)
	Int jStashJMap = GetStashJMap(asUUID)
	If jStashJMap
		Return JValue.solveForm(jStashJMap,asKey)
	EndIf
	Return None
EndFunction

Function SetStashForm(String asUUID, String asKey, Form akValue) Global
	asKey = MakePath(asKey)
	JValue.solveFormSetter(GetStashJMap(asUUID),asKey,akValue,True)
	SaveReg()
EndFunction

Int Function GetStashObj(String asUUID, String asKey) Global
	asKey = MakePath(asKey)
	Int jStashJMap = GetStashJMap(asUUID)
	If jStashJMap
		Return JValue.solveObj(jStashJMap,asKey)
	EndIf
	Return 0
EndFunction

Function SetStashObj(String asUUID, String asKey, Int ajValue) Global
	asKey = MakePath(asKey)
	JValue.solveObjSetter(GetStashJMap(asUUID),asKey,ajValue,True)
	SaveReg()
EndFunction

;=== Generic Get/Set by ObjectReference Functions ===--
;  These are mostly wrappers for the previous section. It is useful to refer to 
;  the Stash by its ObjectReference rather than by its UUID sometimes.

Int Function GetStashRefSessionInt(ObjectReference akStashRef, String asKey) Global
	Return GetStashSessionInt(GetUUIDForStashRef(akStashRef), asKey)
EndFunction

Function SetStashRefSessionInt(ObjectReference akStashRef, String asKey, Int aiValue) Global
	SetStashSessionInt(GetUUIDForStashRef(akStashRef), asKey, aiValue)
EndFunction

Int Function GetStashRefInt(ObjectReference akStashRef, String asKey) Global
	Return GetStashInt(GetUUIDForStashRef(akStashRef), asKey)
EndFunction

Function SetStashRefInt(ObjectReference akStashRef, String asKey, Int aiValue) Global
	SetStashInt(GetUUIDForStashRef(akStashRef), asKey, aiValue)
EndFunction

Float Function GetStashRefFlt(ObjectReference akStashRef, String asKey) Global
	Return GetStashFlt(GetUUIDForStashRef(akStashRef), asKey)
EndFunction

Function SetStashRefFlt(ObjectReference akStashRef, String asKey, Float afValue) Global
	SetStashFlt(GetUUIDForStashRef(akStashRef), asKey, afValue)
EndFunction

String Function GetStashRefStr(ObjectReference akStashRef, String asKey) Global
	Return GetStashStr(GetUUIDForStashRef(akStashRef), asKey)
EndFunction

Function SetStashRefStr(ObjectReference akStashRef, String asKey, String asValue) Global
	SetStashStr(GetUUIDForStashRef(akStashRef), asKey, asValue)
EndFunction

Form Function GetStashRefForm(ObjectReference akStashRef, String asKey) Global
	Return GetStashForm(GetUUIDForStashRef(akStashRef), asKey)
EndFunction

Function SetStashRefForm(ObjectReference akStashRef, String asKey, Form akValue) Global
	SetStashForm(GetUUIDForStashRef(akStashRef), asKey, akValue)
EndFunction

Int Function GetStashRefObj(ObjectReference akStashRef, String asKey) Global
	Return GetStashObj(GetUUIDForStashRef(akStashRef), asKey)
EndFunction

Function SetStashRefObj(ObjectReference akStashRef, String asKey, Int ajValue) Global
	SetStashObj(GetUUIDForStashRef(akStashRef), asKey, ajValue)
EndFunction

;=== Data Functions ===--

Bool Function IsStash(String asUUID) Global
	Return JValue.IsMap(GetStashJMap(asUUID))
EndFunction

Bool Function CreateStashRef(ObjectReference akStashRef, Int aiStashGroup = 0) Global
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

Bool Function DeleteStashRef(ObjectReference akStashRef) Global
	Return JFormMap.RemoveKey(GetStashFormMap(),akStashRef)
EndFunction

Bool Function IsStashRef(ObjectReference akStashRef) Global
	If akStashRef && GetStashRefJMap(akStashRef)
		Return True
	EndIf
	Return False
EndFunction

Function SetStashGroup(String asUUID, Int aiStashGroup = 0) Global
	If IsStash(asUUID)
		SetStashInt(asUUID,"Group",aiStashGroup)
	Else
		DebugTraceAPIStash("SetStashGroup: Error! " + asUUID + " is not a valid Stash!")
	EndIf
EndFunction

Int Function GetStashGroup(String asUUID) Global
	Return GetStashInt(asUUID,"Group")
EndFunction

Function SetStashRefGroup(ObjectReference akStashRef, Int aiStashGroup = 0) Global
	SetStashRefInt(akStashRef,"Group",aiStashGroup)
EndFunction

Int Function GetStashRefGroup(ObjectReference akStashRef) Global
	Return GetStashRefInt(akStashRef,"Group")
EndFunction

Int Function GetStashEntryCount(String asUUID) Global
	Int jStashData = GetStashJMap(asUUID)
	Return JArray.Count(JMap.GetObj(jStashData,"containerEntries")) + JArray.Count(JMap.GetObj(jStashData,"entryDataList"))
EndFunction

String[] Function GetStashItems(String asUUID) Global
	;FIXME
	; String[] sRet = New String[1]

	; Int jItemArray = GetStashObj(akStashRef,"Items")
	; If jItemArray 
	; 	Return SuperStash.JObjToArrayStr(jItemArray)
	; EndIf

	; Return sRet
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
	Return SuperStash.JObjToArrayStr(JArray.Sort(JMap.AllKeys(GetSessionObj("MCMMap.NameMap"))))
EndFunction

;=== Stash object inventory Functions ===--

Int Function LoadStashesForCell(Cell akCell) Global
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
		EndIf
		i += 1
	EndWhile
	Return i
EndFunction

Int Function ImportStashRefItems(ObjectReference akStashRef) Global
	If !IsStashRef(akStashRef)
		DebugTraceAPIStash("ImportStashItems: Error! " + akStashRef + " is not a valid Stash!")
		Return 0
	EndIf

	String sStashID = GetUUIDForStashRef(akStashRef)

	vSS_StashManager StashManager 		= Quest.GetQuest("vSS_StashManagerQuest") as vSS_StashManager

	EffectShader    kContainerShader 	= StashManager.ContainerFXShader
	kContainerShader.Stop(akStashRef)
	kContainerShader.Play(akStashRef)

	String sStashFileName  = GetStashFileNameString(sStashID)
	String sFilePath = SuperStash.userDirectory() + "Stashes\\" ;"; <-- fix for highlighting in SublimePapyrus
	sFilePath += sStashFileName + ".json" 

	;Create ExtraContainerChanges data for Container
	Form kGold = Game.GetFormFromFile(0xf,"Skyrim.esm")
	akStashRef.AddItem(kGold, 1, True)
	akStashRef.RemoveItem(kGold, 1, True)

	DebugTraceAPIStash("Filling " + akStashRef + " from " + sFilePath + "!")
	
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

Int Function UpdateStashData(String asUUID) Global
	If !IsStash(asUUID)
		DebugTraceAPIStash("UpdateStashData: Error! " + asUUID + " is not a valid Stash!")
		Return -1
	EndIf

	ObjectReference kStashRef = GetStashRefForUUID(asUUID)

	If !kStashRef
		DebugTraceAPIStash("UpdateStashData: Error! " + kStashRef + " is not a valid Stash ObjectReference!")
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
	String sStashID = GetStashFileNameString(asUUID)
	If !abSkipBackup
		SuperStash.RotateFile(SuperStash.userDirectory() + "Stashes/" + sStashID + ".json")
	EndIf
	JValue.WriteToFile(GetStashJMap(asUUID),SuperStash.userDirectory() + "Stashes/" + sStashID + ".json")
EndFunction

Function DebugTraceAPIStash(String sDebugString, Int iSeverity = 0) Global
	Debug.Trace("vSS/API/Stash: " + sDebugString,iSeverity)
EndFunction

String Function GetStashFileNameString(String asUUID) Global
	If GetStashStr(asUUID,"Source")
		Return GetStashStr(asUUID,"Source") + "_" + GetStashStr(asUUID,"FormIDString") + "_" + asUUID
	Else
		Return GetStashStr(asUUID,"FormIDString") + "_" + asUUID
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