Scriptname vSS_MCMConfigQuestScript extends vSS_MCMPanelNav
{MCM config script for SkyBox.}

; === [ vSS_MCMConfigQuestScript.psc ] ===================================---
; MCM config script. 
; ========================================================---

; === Imports ===--

Import vSS_Registry
Import vSS_Session

; === Constants ===--

; === Enums ===--

String[] TEXT_GLOBALS_DELETE_BACKUPS
String[] TEXT_GLOBALS_USE_FXSHADER

; === Properties ===--

vSS_MetaQuestScript 	Property MetaQuest 						Auto
vSS_StashManager 		Property StashManager 					Auto

String 					Property CurrentStashName 				Auto Hidden
String 					Property CurrentStashUUID 				Auto Hidden

; === Variables ===--

String[] 	_sStashNames

Int[] 		_iHistoryOptions

; === Events/Functions ===--

Int Function GetVersion()
    return 1
EndFunction

Event OnVersionUpdate(int a_version)
	If CurrentVersion < 1
		OnConfigInit()
		DebugTrace("Updating script to version 1...")
	EndIf
EndEvent

Event OnConfigInit()
	ModName = "$SkyBox"
	Pages = New String[2]
	Pages[0] = "$Manage Stashes"
	Pages[1] = "$Global Options"
	; Pages[7] = "$Debugging"

	CreatePanel("PANEL_STASH_PICKER","$Stash Picker")
	CreatePanel("PANEL_STASH_OPTIONS","$Stash Options","PANEL_STASH_PICKER")
	CreatePanel("PANEL_STASH_INFO","$Stash Info","PANEL_STASH_PICKER")
	CreatePanel("PANEL_STASH_HISTORY","$Stash History","PANEL_STASH_PICKER")
EndEvent

Event OnConfigOpen()
	DoInit()
EndEvent

Event OnPageReset(string a_page)
	
	; === Handle Logo ===--
	If (a_page == "")
        LoadCustomContent("vSS_logo.dds")
        Return
    Else
        UnloadCustomContent()
    EndIf

	; === Handle other pages ===--
	If a_page == Pages[0]
		SetTitleText(Pages[0])
		If !TopPanel()
			PushPanel("PANEL_STASH_PICKER")
			PushPanel("PANEL_STASH_HISTORY")
		EndIf
		DisplayPanels()
	ElseIf a_page == Pages[1]
		SetCursorFillMode(TOP_TO_BOTTOM)
		AddHeaderOption("$Visuals")
		AddTextOptionST("OPTION_TEXT_GLOBALS_USE_FXSHADER","$Show visuals",TEXT_GLOBALS_USE_FXSHADER[GetRegInt("Config.UseFXShader")])
		AddEmptyOption()
		AddHeaderOption("$UI options")
		AddTextOptionST("OPTION_TEXT_GLOBALS_DELETE_BACKUPS","$Delete backups when removing stash",TEXT_GLOBALS_DELETE_BACKUPS[GetRegInt("Config.DeleteBackups")])

	ElseIf a_page == Pages[7]
		; AddTextOptionST("OPTION_TEXT_PLAYER_SAVE", "Save player", "right now!")
	Else

	EndIf
EndEvent

; === Panel display functions ===--

State PANEL_STASH_PICKER

	Event OnPanelAdd(Int aiLeftRight)
		SetCursorFillMode(TOP_TO_BOTTOM)
		
		SetCursorPosition(aiLeftRight)
		If !CurrentStashUUID
			AddMenuOptionST("OPTION_MENU_STASH_PICKER","$Select a stash from the list",CurrentStashName)
		Else
			AddMenuOptionST("OPTION_MENU_STASH_PICKER","",CurrentStashName)
		EndIf

		If !CurrentStashUUID
			DebugTrace("No Stash selected!")
			Return
		EndIf

		SetTitleText("$Stash Properties")

		AddHeaderOption(CurrentStashName)

		Int jStashData = GetRegObj("Stashes." + CurrentStashUUID)

		ObjectReference kStashRef = JMap.GetForm(jStashData,"Form") as ObjectReference
		Int iEntryCount = JArray.Count(JMap.GetObj(jStashData,"containerEntries")) + JArray.Count(JMap.GetObj(jStashData,"entryDataList"))

		SetCursorPosition(aiLeftRight + 4)
		AddInputOptionST("OPTION_INPUT_STASH_NAME","$Stash name",JMap.GetStr(jStashData,"StashName"))
		AddTextOption("$Parent Cell",JMap.GetStr(jStashData,"CellName"))
		AddTextOption("$Form ID",JMap.GetStr(jStashData,"FormIDString") + " (" + JMap.GetStr(jStashData,"Source") + ")")

		String sStatus = "$Not loaded"
		If kStashRef
			sStatus = "$Loaded"
		EndIf

		AddTextOption("$Status",sStatus)
		AddTextOption("$Item entries",iEntryCount)
		AddTextOption("$Last accessed by", JMap.GetStr(jStashData,"LastCharacterName"))
		;AddPanelLinkOption("PANEL_STASH_HISTORY","$History")
		AddEmptyOption()
		AddTextOptionST("OPTION_TEXT_DESTROY_STASH","$Destroy this stash", "")
	EndEvent
EndState

State PANEL_STASH_OPTIONS

	Event OnPanelAdd(Int aiLeftRight)

	EndEvent

EndState

State PANEL_STASH_INFO

	Event OnPanelAdd(Int aiLeftRight)
	EndEvent

EndState

State PANEL_STASH_HISTORY

	Event OnPanelAdd(Int aiLeftRight)
		SetCursorFillMode(TOP_TO_BOTTOM)
		
		SetCursorPosition(aiLeftRight)

		AddHeaderOption("$Backup history")
	
		If !CurrentStashUUID
			DebugTrace("No Stash selected!")
			Return
		EndIf

		SetCursorPosition(aiLeftRight + 4)

		_iHistoryOptions = New Int[10]

		Int i = 1
		While i < 10
			Int jStashData = vSS_API_Stash.GetStashBackupJMap(CurrentStashUUID,i)
			If jStashData
				If i > 1
					;AddEmptyOption()
				EndIf
				_iHistoryOptions[i] = AddTextOption("Ver: " + JMap.GetInt(jStashData,"DataSerial") + ", {$Entries}: " + JMap.GetInt(jStashData,"ItemEntryCount") + ", saved by " + JMap.GetStr(jStashData,"LastCharacterName"),"")
			EndIf
			i += 1
		EndWhile
	EndEvent

EndState

State OPTION_MENU_STASH_PICKER

	Event OnMenuOpenST()
		SetMenuDialogOptions(_sStashNames)
		Int iStashNameIdx = _sStashNames.Find(CurrentStashName)
		If iStashNameIdx < 0
			iStashNameIdx = 0
		EndIf
		SetMenuDialogStartIndex(iStashNameIdx)
		SetMenuDialogDefaultIndex(iStashNameIdx)
	EndEvent

	Event OnMenuAcceptST(Int aiIndex)
		String sStashName = _sStashNames[aiIndex]
		If sStashName
			CurrentStashName = sStashName
			CurrentStashUUID = GetSessionStr("MCMMap.NameMap." + sStashName)
		Else
			DebugTrace("OPTION_MENU_STASH_PICKER: No stash name found for index " + aiIndex + "!")
		EndIf
		ForcePageReset()
	EndEvent

EndState

State OPTION_INPUT_STASH_NAME

	Event OnInputOpenST()
		SetInputDialogStartText(GetRegStr("Stashes." + CurrentStashUUID + ".StashName"))
	EndEvent

	Event OnInputAcceptST(string a_input)
		If a_input != GetRegStr("Stashes." + CurrentStashUUID + ".StashName")
			CurrentStashName = a_input
			SetRegStr("Stashes." + CurrentStashUUID + ".StashName",a_input)
			;SetTitleText("{$Properties for} " + CurrentStashName)
			UpdateMCMNames()
			vSS_API_Stash.ExportStash(CurrentStashUUID,abSkipBackup = True)
			ForcePageReset()
		EndIf
	EndEvent

EndState

State OPTION_TEXT_DESTROY_STASH

	Event OnSelectST()
		;Confirm this 
		If ShowMessage("$Destroy Stash", True)
			Bool bDeleteBackups
			Int iConfigDeleteBackups = GetRegInt("Config.DeleteBackups")
			If iConfigDeleteBackups == 1
				bDeleteBackups = True
			ElseIf iConfigDeleteBackups == 2
				bDeleteBackups = False
			Else 
				bDeleteBackups = ShowMessage("$Keep Backups", True, "$Yes", "$No")
			EndIf
			vSS_API_Stash.RemoveStash(CurrentStashUUID,None,bDeleteBackups)
			CurrentStashUUID = ""
			CurrentStashName = ""
			UpdateMCMNames()
			ForcePageReset()
		EndIf
	EndEvent

EndState

State OPTION_TEXT_GLOBALS_USE_FXSHADER
	Event OnSelectST()
		SetRegInt("Config.UseFXShader",IncStringArray(TEXT_GLOBALS_USE_FXSHADER,GetRegInt("Config.UseFXShader")))
		SetTextOptionValueST(TEXT_GLOBALS_USE_FXSHADER[GetRegInt("Config.UseFXShader")], false, "OPTION_TEXT_GLOBALS_USE_FXSHADER")
	EndEvent
EndState

State OPTION_TEXT_GLOBALS_DELETE_BACKUPS
	Event OnSelectST()
		SetRegInt("Config.DeleteBackups",IncStringArray(TEXT_GLOBALS_DELETE_BACKUPS,GetRegInt("Config.DeleteBackups")))
		SetTextOptionValueST(TEXT_GLOBALS_DELETE_BACKUPS[GetRegInt("Config.DeleteBackups")], false, "OPTION_TEXT_GLOBALS_DELETE_BACKUPS")
	EndEvent
EndState

Event OnOptionSelect(int a_option)
	;A few options really aren't suited for states, so handle them here
	If _iHistoryOptions.Find(a_option) > -1
		;History option was picked!
		Int iRevision = _iHistoryOptions.Find(a_option)
		If iRevision <= 0
			DebugTrace("Error: Invalid revision " + iRevision + "!",2)
			Return
		EndIF
		If ShowMessage("$Revert to this state? You may lose any items currently in this Stash!", True)
			vSS_API_Stash.RevertToBackup(CurrentStashUUID,iRevision)
			ForcePageReset()
		EndIf
	EndIf
EndEvent

Int Function IncStringArray(String[] asOptionArray, Int aiValue)
	aiValue += 1
	If aiValue >= asOptionArray.Length
		aiValue = 0
	EndIf
	Return aiValue
EndFunction

Function DoInit()
	FillEnums()
	UpdateMCMNames()

	_iHistoryOptions = New Int[10]
EndFunction

Function UpdateMCMNames()
	vSS_API_Stash.CreateMCMLists()
	_sStashNames = vSS_API_Stash.GetMCMNames()
EndFunction

Function FillEnums()
	TEXT_GLOBALS_DELETE_BACKUPS = New String[3]
	TEXT_GLOBALS_DELETE_BACKUPS[0] = "$Ask"
	TEXT_GLOBALS_DELETE_BACKUPS[1] = "$Always"
	TEXT_GLOBALS_DELETE_BACKUPS[2] = "$Never"

	TEXT_GLOBALS_USE_FXSHADER = New String[2]
	TEXT_GLOBALS_USE_FXSHADER[0] = "$Never"
	TEXT_GLOBALS_USE_FXSHADER[1] = "$Brief"
EndFunction

; === Utility functions ===--

Function DebugTrace(String sDebugString, Int iSeverity = 0)
	Debug.Trace("vSS/MCMPanel: " + sDebugString,iSeverity)
EndFunction

String Function GetFormIDString(Form kForm)
	String sResult
	sResult = kForm as String ; [FormName < (FF000000)>]
	sResult = StringUtil.SubString(sResult,StringUtil.Find(sResult,"(") + 1,8)
	Return sResult
EndFunction

String Function GetPrettyTime(String asTimeInMinutes)
	Float fTimeInMinutes = asTimeInMinutes as Float
	Int iMinutes = Math.Floor(fTimeInMinutes)
	Int iSeconds = Math.Floor((fTimeInMinutes - iMinutes) * 60)
	String sZero = ""
	If iSeconds < 10
		sZero = "0"
	EndIf
	String sPrettyTime = iMinutes + ":" + sZero + iSeconds
	Return sPrettyTime
EndFunction
