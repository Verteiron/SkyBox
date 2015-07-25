Scriptname vSS_StashManager extends vSS_ManagerBase
{Save and restore character and other data using the registry.}

; === [ vSS_StashManager.psc ] ============================================---
; Main interface for managing character-related data. 
; Handles:
;  Loading/saving character data
;  Scanning of Player for various data
;  Game session identification and matching
;  Equipment serialization
;  Population of certain lists, like AVNames
; ========================================================---

;=== Imports ===--

Import Utility
Import Game
Import vSS_Registry
Import vSS_Session

;=== Constants ===--

String				Property META			= ".Info"				Auto Hidden

Int 				Property VOICETYPE_NOFILTER  	= 0				AutoReadOnly Hidden
Int 				Property VOICETYPE_FOLLOWER  	= 1				AutoReadOnly Hidden
Int 				Property VOICETYPE_SPOUSE 		= 2				AutoReadOnly Hidden
Int 				Property VOICETYPE_ADOPT 		= 4				AutoReadOnly Hidden
Int 				Property VOICETYPE_GENDER		= 8 			AutoReadOnly Hidden

;=== Properties ===--

String 				Property SessionID 								Hidden
{Return SessionID for this game session.}
	String Function Get()
		Return GetSessionStr("SessionID")
	EndFunction
EndProperty


Bool 				Property NeedRefresh 	= False 				Auto Hidden
Bool 				Property NeedReset 		= False 				Auto Hidden
Bool				Property NeedUpkeep		= False					Auto Hidden

Bool 				Property IsBusy 		= False 				Auto Hidden

Int 				Property SerializationVersion = 5 				Auto Hidden

Actor 				Property PlayerRef 								Auto
{The Player, duh.}

Perk 				Property vSS_StashCheckPerk 					Auto

ObjectReference 	Property ContainerTarget 						Auto
ObjectReference 	Property ContainerTemp	 						Auto
ObjectReference 	Property MoveTarget		 						Auto

vSS_WeaponScanner[]	Property WeaponScanners							Auto

EffectShader   		Property ContainerFXShader 						Auto

;=== Variables ===--

Int		_iThreadCount	= 0

Int		_jAVNames		= 0

;=== Events ===--

Event OnInit()
	If IsRunning() && !IsBusy
		IsBusy = True

		DoUpkeep(False)
		RegisterForSingleUpdate(1.0)
	EndIf
EndEvent

Event OnUpdate()
	If NeedUpkeep
		DoUpkeep(False)
	EndIf
	SendModEvent("vSS_StashManagerReady")
	RegisterForSingleUpdate(5.0)
EndEvent

;=== Functions - Startup ===--

Function DoUpkeep(Bool bInBackground = True)
{Run whenever the player loads up the Game.}
	If bInBackground
		NeedUpkeep = True
		RegisterForSingleUpdate(0.25)
		Return
	EndIf
	NeedUpkeep = False
	GotoState("Busy")
	IsBusy = True
	DebugTrace("Starting upkeep...")
	SendModEvent("vSS_UpkeepBegin")
	InitReg()
	If !GetConfigBool("DefaultsSet")
		SetConfigDefaults()
	EndIf

	If !GetSessionInt("SessionFingerPrint")
		Int iSessionFingerprint = Game.QueryStat("Animals Killed") + Game.QueryStat("Gold Found") + Game.QueryStat("Ingredients Harvested") + Game.QueryStat("Diseases Contracted")
		SetSessionInt("SessionFingerPrint",iSessionFingerprint)
		SetSessionFlt("SessionStartTime",GetRealHoursPassed())
	EndIf

	String sMatchedSID = MatchSession()
	If sMatchedSID
		SetSessionID(sMatchedSID)
	Else
		String sCharacterName = PlayerREF.GetActorBase().GetName()
		String sSessionID = GetSessionStr("SessionID")
		SetRegFlt("Sessions." + sCharacterName + "." + sSessionID + ".SessionStartTime",GetSessionFlt("SessionStartTime"))
		SetRegInt("Sessions." + sCharacterName + "." + sSessionID + ".SessionFingerPrint",GetSessionInt("SessionFingerPrint"))
	EndIf

	If !PlayerREF.HasPerk(vSS_StashCheckPerk)
		DebugTrace("Adding vSS_StashCheckPerk to Player!")
		PlayerREF.AddPerk(vSS_StashCheckPerk)
	EndIf

	;UpgradeRegistryData()
	;=== Don't register this until after we've init'd everything else
	RegisterForModEvent("vSS_BackgroundFunction","OnBackgroundFunction")
	;RegisterForModEvent("vSS_LoadSerializedEquipmentReq","OnLoadSerializedEquipmentReq")

	IsBusy = False
	GotoState("")
	DebugTrace("Finished upkeep!")
	SendModEvent("vSS_UpkeepEnd")
EndFunction

Function SetConfigDefaults(Bool abForce = False)
	If !GetRegBool("Config.DefaultsSet") || abForce
		DebugTrace("Setting Config defaults!")
		SetConfigBool("Compat.Enabled",True,abMakeDefault = True)
		SetConfigBool("Warnings.Enabled",True,abMakeDefault = True)
		SetConfigBool("Debug.Perf.Threads.Limit",False,abMakeDefault = True)
		SetConfigInt("Debug.Perf.Threads.Max",4,abMakeDefault = True)
	EndIf
EndFunction

;=== Functions - List of Stashes ===--


;=== Functions - Requirement list ===--

String Function GetSourceMod(Form akForm)
	Return SuperStash.GetSourceMod(akForm)
EndFunction

Function AddToReqList(Form akForm, String asType, String sSID = "")
{Take the form and add its provider/source to the required mods list of the specified ajCharacterData.
If sSID is blank, then add to the current Session instead.}
	;Return
	
	If !sSID
		sSID = SessionID
	EndIf
	If !sSID || !akForm || !asType 
		Return
	EndIf

	Int jReqList 
	If sSID == SessionID 
		jReqList = GetSessionObj("Characters." + sSID + META + ".ReqList")		
	Else
		jReqList = GetRegObj("Characters." + sSID + META + ".ReqList")
	EndIf
	If !jReqList
		jReqList = JMap.Object()
	EndIf
	String sModName = SuperStash.GetSourceMod(akForm) ;GetSourceMod(akForm)
	If sModName
		If sModName == "Skyrim.esm" || sModName == "Update.esm"
			Return
		EndIf
		
		;sModName = StringReplace(sModName,".","_dot_") ; Strip . to avoid confusing JContainers
		sModName = StringUtil.Substring(sModName,0,StringUtil.Find(sModName,".")) ; Strip extension to avoid confusing JContainers
		String sFormName = akForm.GetName()
		If !sFormName
			sFormName = akForm as String
		EndIf
		If sSID == SessionID 
			SetSessionStr("Characters." + sSID + META + ".ReqList." + sModName + "." + asType + ".0x" + SuperStash.GetFormIDString(akForm),sFormName)
		Else
			SetRegStr("Characters." + sSID + META + ".ReqList." + sModName + "." + asType + ".0x" + SuperStash.GetFormIDString(akForm),sFormName)
		EndIf
	EndIf
EndFunction

String Function MatchSession(String sCharacterName = "", Float fPlayTime = 0.0)
{Return the UUID of a session that matches the passed name and playtime. Use the current player's data if none supplied.}
	If !sCharacterName 
		sCharacterName = PlayerREF.GetActorBase().GetName()
	EndIf
	If !fPlayTime
		fPlayTime = GetRealHoursPassed()
	EndIf
	Int jSIDList = JMap.AllKeys(GetRegObj("Sessions." + sCharacterName))
	DebugTrace("Looking for matching session in " + JArray.Count(jSIDList) + " saved sessions!")
	If jSIDList
		Int iSID = JArray.Count(jSIDList)
		While iSID > 0
			iSID -= 1
			String sSID = JArray.GetStr(jSIDList,iSID)
			DebugTrace("Checking current session against " + sSID + "...")
			If Math.ABS(GetRegFlt("Sessions." + sCharacterName + "." + sSID + ".SessionStartTime") - GetSessionFlt("SessionStartTime")) < 0.1
				If GetRegInt("Sessions." + sCharacterName + "." + sSID + ".SessionFingerPrint") >= GetSessionFlt("SessionFingerPrint")
					DebugTrace("Current session matches " + sSID + "!")
					Return sSID
				EndIf
			EndIf
		EndWhile
	EndIf

	Return ""
EndFunction

Function DebugTrace(String sDebugString, Int iSeverity = 0)
	Debug.Trace("vSS/StashManager: " + sDebugString,iSeverity)
EndFunction

;=== Functions - Busy state ===--

State Busy

	Function DoUpkeep(Bool bInBackground = True)
		DebugTrace("DoUpkeep called while busy!")
	EndFunction

EndState
