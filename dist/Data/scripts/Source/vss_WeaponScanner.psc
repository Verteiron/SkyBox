Scriptname vSS_WeaponScanner extends ObjectReference
{Automatically serialize any items added to it.}

;=== Imports ===--

Import Utility
Import Game
Import vSS_Registry
Import vSS_Session

;=== Properties ===--

ObjectReference Property TargetContainer 	Auto

Bool 			Property Busy 				Auto Hidden
Int  			Property jContainerState 	Auto Hidden

Int 			Property Index 				Auto Hidden

;=== Variables ===--

ObjectReference _SourceContainer

;=== Events ===--

Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	Busy = True
	DebugTrace("OnItemAdded(" + akBaseItem + "," + aiItemCount + "," + akItemReference + "," + akSourceContainer + ")")
	_SourceContainer = akSourceContainer
	GotoState("Scanning")

EndEvent

Event OnUpdate()
	If GetNumItems()
		GotoState("Scanning")
	Else
		Busy = False
	EndIf
EndEvent

State Scanning

	Event OnBeginState()
		Busy = True
		DebugTrace("Starting item scan loop...")
		If !jContainerState 
			jContainerState = JArray.Object()
			JValue.Retain(jContainerState)
		EndIf
		RegisterForSingleUpdate(0.1)

	EndEvent

	Event OnUpdate()
		Int jItemMap = 0
		Int iNumItems = GetNumItems()
		While iNumItems
			DebugTrace("Found " + iNumItems + " items to scan!")
			Form kItem = GetNthForm(0)
			Int iCount = 0
			While GetItemCount(kItem)
				iCount += 1
				ObjectReference kObject = DropObject(kItem, 1)
				DebugTrace("Processing Object " + kObject + "...")
				String sItemID = vSS_API_Item.GetObjectID(kObject)
				If !sItemID
					sItemID = vSS_API_Item.SerializeObject(kObject)
				EndIf
				If sItemID
					jItemMap = vSS_API_Item.GetItemJMap(sItemID)
					If jItemMap
						JArray.AddObj(jContainerState,jItemMap)
					EndIf
				Else
					jItemMap = JMap.Object()
					JMap.SetForm(jItemMap,"Form",kItem)
					JMap.SetInt(jItemMap,"Count",iCount)
				EndIf
				TargetContainer.AddItem(kObject,1,True)
				DebugTrace("Added " + kObject + " to TargetContainer!")
			EndWhile
			If jItemMap
				JArray.AddObj(jContainerState,jItemMap)
			EndIf
			iNumItems = GetNumItems()
		EndWhile
		RemoveAllItems(TargetContainer)
		GoToState("")
		RegisterForSingleUpdate(0.1)
	EndEvent

	Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
		; Do nothing
	EndEvent

EndState

Function DebugTrace(String sDebugString, Int iSeverity = 0)
	Debug.Trace("vSS/WeaponScanner[" + Index + "]: " + sDebugString,iSeverity)
EndFunction
