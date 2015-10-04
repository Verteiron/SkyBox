Scriptname SuperStash Hidden
{Series of utility functions provided by SuperStash.dll.}

Import vSS_Registry
Import vSS_Session

; === [ SuperStash.psc ] =====================================================---
; Thanks to expired for starting this plugin for me. It has since been 
; added to considerably. These are mostly bulk functions that are much
; faster to do on the c++ side than on the Papyrus side.
; ========================================================---

Function TraceConsole(String asTrace) native global
{Print a string to the console.}

String Function userDirectory() native global
{Returns "%UserProfile%/My Documents/My Games/Skyrim/SuperStash".}

Int Function RotateFile(String asFileName, Int aiMaxCount = 9) native global
{Does a UNIX-style file rotation on the file specified by asFileName. 
 Example.json -> Example.1.json -> Example.2.json -> ... Example.aiMaxCount.json}

String Function UUID() native global
{Returns a random UUID.}

Int[] Function GetItemFavorited(Form[] sourceArray) native global
{Returns an array (may be >128) of Bool as Int indicating whether the item is favorited.}

String Function GetSourceMod(Form akForm) native global
{Returns the name of the mod that provides akForm.}

String Function GetObjectJSON(ObjectReference akObjectRef) native global
{Return a JContainer-compatible JSON for an ObjectReference.}

String Function GetContainerJSON(ObjectReference akContainerRef) native global
{Return a JContainer-compatible JSON for all the forms in akContainerRef.}

Int Function FillContainerFromJSON(ObjectReference akContainerRef, String asJSON) native global
{Fill akContainerRef with all the form data in asJSON. Returns number of entries processed.}

Potion Function CreateCustomPotion(MagicEffect[] effects, float[] magnitudes, int[] areas, int[] durations, Int aiForcePotionType = 0) native global
{Create a new custom potion with the specified magic effects. 
 Set aiForcePotionType to 1 to force a Potion, 2 to force a Poison. 0 auto-detects.}

; Other useful functions

String Function GetFormIDString(Form akForm) Global
	String sResult
	sResult = akForm as String ; [FormName < (FF000000)>]
	sResult = StringUtil.SubString(sResult,StringUtil.Find(sResult,"(") + 1,8)
	Return sResult
EndFunction

Function StartTimer(String sTimerLabel) Global
	Float fTime = Utility.GetCurrentRealTime()
	;Debug.Trace("TimerStart(" + sTimerLabel + ") " + fTime)
	;DebugTrace("Timer: Starting for " + sTimerLabel)
	SetSessionFlt("Timers." + sTimerLabel,fTime)
EndFunction

Function StopTimer(String sTimerLabel) Global
	Float fTime = Utility.GetCurrentRealTime()
	;Debug.Trace("TimerStop (" + sTimerLabel + ") " + fTime)
	Debug.Trace("vSS/Timer: " + (fTime - GetSessionFlt("Timers." + sTimerLabel)) + " for " + sTimerLabel)
	ClearSessionKey("Timers." + sTimerLabel)
EndFunction

String Function StringReplace(String sString, String sToFind, String sReplacement) Global
	If sToFind == sReplacement 
		Return sString
	EndIf
	While StringUtil.Find(sString,sToFind) > -1
		sString = StringUtil.SubString(sString,0,StringUtil.Find(sString,sToFind)) + sReplacement + StringUtil.SubString(sString,StringUtil.Find(sString,sToFind) + 1)
	EndWhile
	Return sString
EndFunction

String[] Function JObjToArrayStr(Int ajObj) Global
	String[] sReturn
	Int jStrArray
	If JValue.IsMap(ajObj)
		jStrArray = JArray.Sort(JMap.AllKeys(ajObj))
	ElseIf jValue.IsArray(ajObj)
		jStrArray = ajObj
	EndIf
	If jStrArray
		Int i = JArray.Count(jStrArray)
		Debug.Trace("vSS/JObjToArrayStr: Converting " + i + " jValues to an array of strings...")
		sReturn = Utility.CreateStringArray(i, "")
		While i > 0
			i -= 1
			sReturn[i] = JArray.GetStr(jStrArray,i)
			Debug.Trace("vSS/JObjToArrayStr:  Added " + sReturn[i] + " at index " + i + "!")
		EndWhile
	EndIf
	Debug.Trace("vSS/JObjToArrayStr: Done!")
	Return sReturn
EndFunction

Form[] Function JObjToArrayForm(Int ajObj) Global
	Form[] kReturn
	Int jFormArray
	If JValue.IsMap(ajObj)
		jFormArray = JArray.Sort(JMap.AllKeys(ajObj))
	ElseIf jValue.IsArray(ajObj)
		jFormArray = ajObj
	EndIf
	If jFormArray
		Int i = JArray.Count(jFormArray)
		Debug.Trace("vSS/JObjToArrayForm: Converting " + i + " jValues to an array of forms...")
		kReturn = Utility.CreateFormArray(i, None)
		While i > 0
			i -= 1
			kReturn[i] = JArray.GetForm(jFormArray,i)
			Debug.Trace("vSS/JObjToArrayForm:  Added " + kReturn[i] + " at index " + i + "!")
		EndWhile
	EndIf
	Debug.Trace("vSS/JObjToArrayForm: Done!")
	Return kReturn
EndFunction
