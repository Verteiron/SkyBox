Scriptname vSS_MetaQuestScript extends vSS_BaseQuest
{Do initialization and track variables for scripts.}

;=== Imports ===--

Import Utility
Import Game
Import vSS_Registry

;=== Properties ===--

Actor Property PlayerRef Auto

Bool Property Ready = False Auto

Float Property ModVersion Auto Hidden
Int Property ModVersionInt Auto Hidden

Int Property ModVersionMajor Auto Hidden
Int Property ModVersionMinor Auto Hidden
Int Property ModVersionPatch Auto Hidden

String Property ModName = "SuperStash" Auto Hidden

Message Property vSS_ModLoadedMSG Auto
Message Property vSS_ModUpdatedMSG Auto
Message Property vSS_ModShutdownMSG Auto

;=== Script properties ===--
vSS_StashManager Property StashManager Auto

;=== Config variables ===--

GlobalVariable Property vSS_CFG_Changed Auto
GlobalVariable Property vSS_CFG_Shutdown Auto
GlobalVariable Property vSS_WaitForMQ Auto

;=== Variables ===--

Float _CurrentVersion
Int _iCurrentVersion
String _sCurrentVersion

Bool _ShowedSKSEWarning = False
Bool _ShowedJContainersWarning = False
Bool _Running
Bool _bVersionSystemUpdated = False

Int _iUpkeepsExpected
Int _iUpkeepsCompleted

;=== Events ===--

Event OnInit()
	DebugTrace("Metaquest event: OnInit - IsRunning: " + IsRunning() + " ModVersion: " + ModVersion + " ModVersionMajor: " + ModVersionMajor)
	If IsRunning() && ModVersion == 0 && !ModVersionMajor
		DoUpkeep(True)
	EndIf
EndEvent

Event OnReset()
	;DebugTrace("Metaquest event: OnReset")
EndEvent

Event OnUpdate()

EndEvent

Event OnGameReload()
	DebugTrace("Metaquest event: OnGameReload")
	;If vSS_CFG_Shutdown.GetValue() != 0
		DoUpkeep(False)
	;EndIf
EndEvent

Event OnUpkeepState(string eventName, string strArg, float numArg, Form sender)
	If eventName == "vSS_UpkeepBegin"
		_iUpkeepsExpected += 1
	ElseIf eventName == "vSS_UpkeepEnd"
		_iUpkeepsCompleted += 1
		DebugTrace("Metaquest Upkeep finished for " + sender + ". (" + _iUpkeepsCompleted + "/" + _iUpkeepsExpected + ")")
	EndIf
EndEvent

Event OnShutdown(string eventName, string strArg, float numArg, Form sender)
	DebugTrace("OnShutdown!")
	Wait(0.1)
	DoShutdown()
EndEvent

;=== Functions ===--

Function DoUpkeep(Bool DelayedStart = True)
	DebugTrace("Metaquest event: DoUpkeep(" + DelayedStart + ")")
	;FIXME: CHANGE THIS WHEN UPDATING!
	ModVersionMajor = 0
	ModVersionMinor = 1
	ModVersionPatch = 0
	If !CheckDependencies()
		AbortStartup()
		Return
	EndIf
	_iCurrentVersion = GetVersionInt(ModVersionMajor,ModVersionMinor,ModVersionPatch)
	_sCurrentVersion = GetVersionString(_iCurrentVersion)
	String sModVersion = GetVersionString(ModVersion as Int)
	RegisterForModEvent("vSS_InitBegin","OnInitState")
	RegisterForModEvent("vSS_InitEnd","OnInitState")
	RegisterForModEvent("vSS_UpkeepBegin","OnUpkeepState")
	RegisterForModEvent("vSS_UpkeepEnd","OnUpkeepState")
	RegisterForModEvent("vSS_Shutdown","OnShutdown")
	Ready = False
	If DelayedStart
		Wait(RandomFloat(3,5))
	EndIf
	
	String sErrorMessage
	SendModEvent("vSS_UpkeepBegin")
	DebugTrace("" + ModName)
	DebugTrace("Performing upkeep...")
	DebugTrace("Loaded version is " + sModVersion + ", Current version is " + _sCurrentVersion)
	If ModVersion == 0
		DebugTrace("Newly installed, doing initialization...")
		DoInit()
		If ModVersion == _iCurrentVersion
			DebugTrace("Initialization succeeded.")
		Else
			DebugTrace("WARNING! Initialization had a problem!")
		EndIf
	ElseIf ModVersion < _iCurrentVersion
		DebugTrace("Installed version is older. Starting the upgrade...")
		DoUpgrade() ; this should also fire DoUpkeep
		If ModVersion != _iCurrentVersion
			DebugTrace("WARNING! Upgrade failed!")
			Debug.MessageBox("WARNING! " + ModName + " upgrade failed for some reason. You should report this to the mod author.")
		EndIf
		DebugTrace("Upgraded to " + GetVersionString(_iCurrentVersion))
		vSS_ModUpdatedMSG.Show(ModVersionMajor,ModVersionMinor,ModVersionPatch)
	Else
		;FIXME: Do init stuff in other quests
		DebugTrace("Loaded, no updates.")
	EndIf
	CheckForExtras()
	UpdateConfig()
	DebugTrace("Upkeep complete!")
	Ready = True
	SendModEvent("vSS_UpkeepEnd")

EndFunction

Function DoInit()
	Debug.Notification("SuperStash will be ready in just a few seconds...")

	InitReg()

	DebugTrace("DoInit: Starting StashManager...")
	StashManager.Start()
	WaitMenuMode(1)
	While StashManager.IsBusy
		WaitMenuMode(0.5)
	EndWhile
	;JValue.WriteToFile(JValue.objectFromPrototype(SuperStash.GetContainerJSON(Game.GetPlayer())),SuperStash.userDirectory() + "Stashes/player.json")
	DebugTrace("DoInit: Starting Compatibility modules...")
	CheckCompatibilityModules()

	DebugTrace("DoInit: Starting PlayerTracker...")
	SendModEvent("vSS_PlayerTrackerStart")

	;StashManager.LoadTestCharacter()

	_Running = True
	ModVersion = _iCurrentVersion
	;vSS_FFLogoEffect.Play(PlayerREF)
	vSS_ModLoadedMSG.Show(ModVersionMajor,ModVersionMinor,ModVersionPatch)
EndFunction

Function DoUpgrade()
	_Running = False
	;version-specific upgrade code
	
	; If ModVersion < GetVersionInt(1,1,2)
	; 	Debug.Trace("vSS/Upgrade/1.1.2: Upgrading to 1.1.2...")
	; 	Debug.Trace("vSS/Upgrade/1.1.2: Upgrade to 1.1.2 complete!")
	; 	ModVersion = GetVersionInt(1,1,2)
	; EndIf
	
	;Generic upgrade code
	If ModVersion < _iCurrentVersion
		DebugTrace("Upgrading to " + GetVersionString(_iCurrentVersion) + "...")
		;FIXME: Do upgrade stuff!
		ModVersion = _iCurrentVersion
		DebugTrace("Upgrade to " + GetVersionString(_iCurrentVersion) + " complete!")
	EndIf
	_Running = True
	DebugTrace("Upgrade complete!")
EndFunction

Function CheckCompatibilityModules(Bool abReset = False)
	DebugTrace("Checking compatibility modules!")
	RegisterForModEvent("vSS_CompatReport","OnCompatReport")
	Int iHandle = ModEvent.Create("vSS_CompatCheck")
	If iHandle
		ModEvent.PushForm(iHandle,Self)
		ModEvent.Send(iHandle)
	Else
		DebugTrace("WARNING! Could not send vSS_CompatCheck event!",1)
	EndIf
EndFunction

Event OnCompatReport(String asName, Form akSender, Bool abRequired, Bool abEnabled)
	DebugTrace("Compat module " + asName + " report - Required: " + abRequired + ", Enabled: " + abEnabled)
EndEvent

Function AbortStartup(String asAbortReason = "None specified")
	DebugTrace("Aborting startup! Reason: " + asAbortReason,2)
	Ready = False

	_Running = False
	Ready = True
	Stop()
EndFunction

Function DoShutdown(Bool abClearData = False)
	Ready = False
	DebugTrace("Shutting down!")
	_iCurrentVersion = 0
	ModVersion = 0
	
	If StashManager.IsRunning()
		StashManager.Stop()
	EndIf

	If abClearData
		JDB.SolveObjSetter(".vSS",0)
		DebugTrace("Data cleared, ready for removal!")
		Debug.Notification("SuperStash\nData has been cleared. You should now save and exit, then uninstall the mod before re-launching the game.")
	EndIf
	vSS_ModShutdownMSG.Show()
	_Running = False
	Ready = True
EndFunction

Bool Function CheckDependencies()
	Float fSKSE = SKSE.GetVersion() + SKSE.GetVersionMinor() * 0.01 + SKSE.GetVersionBeta() * 0.0001
	DebugTrace("SKSE is version " + fSKSE)
	DebugTrace("JContainers is version " + SKSE.GetPluginVersion("Jcontainers") + ", API is " + JContainers.APIVersion())
	DebugTrace("SuperStash is version " + SKSE.GetPluginVersion("SuperStash"))
	DebugTrace("CharGen is version " + SKSE.GetPluginVersion("chargen"))
	DebugTrace("NIOverride is version " + SKSE.GetPluginVersion("nioverride"))
	;Debug.MessageBox("SKSE version is " + fSKSE)
	If fSKSE < 1.0702
		Debug.MessageBox("SuperStash\nThis mod requires SKSE 1.7.2 or higher, but it seems to be missing or out of date.\nThe mod will now shut down.")
		Return False
	Else
		;Proceed
	EndIf
	If JContainers.APIVersion() < 3
		Debug.MessageBox("SuperStash\nThis mod requires JContainers with API 3 (3.1.x), but it seems to be missing or out of date.\nThe mod will now shut down.")
		Return False
	Else
		;Proceed
	EndIf
	If SKSE.GetPluginVersion("chargen") < 4
		Debug.MessageBox("SuperStash\nThis mod requires RaceMenu 3.2.0 or higher, but it seems to be missing or out of date.\nThe mod will now shut down.")
		Return False
	Else
		;Proceed
	EndIf
	If SKSE.GetPluginVersion("nioverride") >= 3 && NIOverride.GetScriptVersion() > 1
		SetRegBool("Config.NIO.ArmorDye.Enabled",True)
	Else
		SetRegBool("Config.NIO.ArmorDye.Enabled",False)
	EndIf

	;In an upgrade from 1.x the *Manager objects might not be filled, so fill them.
	If !StashManager
		StashManager = Quest.GetQuest("vSS_StashManagerQuest") as vSS_StashManager
	EndIf

	;Removed write test in Skyrim folder, it was dumb anyway.

	Return True
EndFunction

Function UpdateConfig()
	DebugTrace("Updating configuration...")

	DebugTrace("Updated configuration values, some scripts may update in the background!")
EndFunction

Int Function GetVersionInt(Int iMajor, Int iMinor, Int iPatch)
	Return Math.LeftShift(iMajor,16) + Math.LeftShift(iMinor,8) + iPatch
EndFunction

String Function GetVersionString(Int iVersion)
	Int iMajor = Math.RightShift(iVersion,16)
	Int iMinor = Math.LogicalAnd(Math.RightShift(iVersion,8),0xff)
	Int iPatch = Math.LogicalAnd(iVersion,0xff)
	String sMajorZero
	String sMinorZero
	String sPatchZero
	If !iMajor
		sMajorZero = "0"
	EndIf
	If !iMinor
		sMinorZero = "0"
	EndIf
	;If !iPatch
		;sPatchZero = "0"
	;EndIf
	;DebugTrace("Got version " + iVersion + ", returning " + sMajorZero + iMajor + "." + sMinorZero + iMinor + "." + sPatchZero + iPatch)
	Return sMajorZero + iMajor + "." + sMinorZero + iMinor + "." + sPatchZero + iPatch
EndFunction

Function CheckForExtras()
	If GetModByName("Dawnguard.esm") != 255
		DebugTrace("Dawnguard is installed!")
	EndIf
	If GetModByName("Dragonborn.esm") != 255
		DebugTrace("Dragonborn is installed!")
	EndIf
EndFunction

Function DebugTrace(String sDebugString, Int iSeverity = 0)
	Debug.Trace("vSS/MetaQuest: " + sDebugString,iSeverity)
EndFunction
