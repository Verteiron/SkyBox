Scriptname vSS_API_Item extends vSS_APIBase Hidden
{Save and restore item data, including custom items.}

; === [ vSS_API_Item.psc ] ===============================================---
; API for saving and loading customized items. 
; 
; This will serialize and write to the Registry Weapons, Armor, and Potions
; with all customizations included. Once serialized, the item is represented 
; by a UUID. 
; 
; This ID can then be used to recreate the item in any gaming session, with 
; all customizations intact.
; ========================================================---

Import vSS_Registry
Import vSS_Session

;=== Generic Functions ===--

String Function GetItemName(String asItemID) Global
	DebugTraceAPIItem("Looking up item name for " + asItemID + " ...")
	String sRet = ""
	Int jItemInfo = GetItemJMap(asItemID)
	If jItemInfo
		sRet = JValue.SolveStr(jItemInfo,".DisplayName")
		If !sRet
			Form kItem = JValue.SolveForm(jItemInfo,".Form")
			If kItem
				sRet = kItem.GetName()
				If !sRet
					sRet = GetFormIDString(kItem)
				EndIf
			EndIf
		EndIf
	EndIf
	Return sRet
EndFunction

Int Function GetItemJMap(String asItemID) Global
	Int iRet = -2 ; ItemID not present
	String sRegKey = "Items." + asItemID
	Int jItemData = GetRegObj(sRegKey)
	If jItemData
		Return jItemData
	EndIf
	Return iRet
EndFunction

Int Function GetItemInfosForForm(Form akForm) Global
;Return a JMap of JItemInfos already saved for akForm
	Int jItemFMap = GetRegObj("ItemMap")
	If !JValue.IsFormMap(jItemFMap)
		SetRegObj("ItemMap",JFormMap.Object())
		jItemFMap = GetRegObj("ItemMap")
	EndIf
	Int jItemInfoMap = JFormMap.GetObj(jItemFMap,akForm)
	If !jItemInfoMap
		JFormMap.SetObj(jItemFMap,akForm,JMap.Object())
		jItemInfoMap = JFormMap.GetObj(jItemFMap,akForm)
	EndIf
	Return jItemInfoMap
EndFunction

Function SetItemInfosForForm(Form akForm, Int jItemInfoMap) Global
;Return a JMap of JItemInfos already saved for akForm
	Int jItemFMap = GetRegObj("ItemMap")
	If !JValue.IsFormMap(jItemFMap)
		SetRegObj("ItemMap",JFormMap.Object())
		jItemFMap = GetRegObj("ItemMap")
	EndIf
	JFormMap.SetObj(jItemFMap,akForm,jItemInfoMap)
	SetRegObj("ItemMap",jItemFMap)
EndFunction

;Retrieve or create an ItemID for ajObjectInfo. If it has been serialized before, it will return its current itemID.
String Function AssignItemID(Int ajObjectInfo) Global
	Form kForm = JValue.SolveForm(ajObjectInfo,".Form")
	;Debug.Trace("vSS/API/Item/AssignItemID: Attempting to match item with form " + kForm + "...")
	Int jItemInfoMap = GetItemInfosForForm(kForm)
	Int jItemIDs = JMap.AllKeys(jItemInfoMap)
	Int jItemInfos = JMap.AllValues(jItemInfoMap)
	Int i = JArray.Count(jItemIDs)
	While i > 0
		i -= 1
		Int jItemInfo = JArray.GetObj(jItemInfos,i)
		If kForm as Weapon || kForm as Armor
			;FIXME: Are these the best comparisons? What would work better?
			;Debug.Trace("vSS/API/Item/AssignItemID: " + kForm + " is a weapon or armor!")
			;Debug.Trace("vSS/API/Item/AssignItemID: " + kForm + " .Enchantment.Effects[0].MagicEffect is " + JValue.SolveForm(ajObjectInfo,".Enchantment.Effects[0].MagicEffect"))
			;Debug.Trace("vSS/API/Item/AssignItemID: Saved form's .Enchantment.Effects[0].MagicEffect is " + JValue.SolveForm(jItemInfo,".Enchantment.Effects[0].MagicEffect"))
			If 	(JValue.HasPath(ajObjectInfo,".Enchantment.Effects[0].MagicEffect") && (JValue.SolveForm(jItemInfo,".Enchantment.Effects[0].MagicEffect") == JValue.SolveForm(ajObjectInfo,".Enchantment.Effects[0].MagicEffect"))) || \
				(JValue.HasPath(ajObjectInfo,".ItemHealthPercent") && (JValue.SolveFlt(jItemInfo,".ItemHealthPercent") == JValue.SolveFlt(ajObjectInfo,".ItemHealthPercent"))) && \
				(JValue.HasPath(ajObjectInfo,".ItemMaxCharge") && (JValue.SolveFlt(jItemInfo,".ItemMaxCharge") == JValue.SolveFlt(ajObjectInfo,".ItemMaxCharge")))
				Debug.Trace("vSS/API/Item/AssignItemID: " + kForm + " has a matching ItemID!")
				Return JArray.GetStr(JItemIDs,i)
			EndIf
		ElseIf kForm as Potion
			Debug.Trace("vSS/API/Item/AssignItemID: " + kForm + " is a potion!")
			If 	(JValue.HasPath(ajObjectInfo,".Effects[0].Magnitude") && (JValue.SolveFlt(jItemInfo,".Effects[0].Magnitude") == JValue.SolveFlt(ajObjectInfo,".Effects[0].Magnitude"))) && \
				(JValue.HasPath(ajObjectInfo,".Effects[0].Duration") && (JValue.SolveFlt(jItemInfo,".Effects[0].Duration") == JValue.SolveFlt(ajObjectInfo,".Effects[0].Duration"))) && \
				(JValue.HasPath(ajObjectInfo,".Effects[0].MagicEffect") && (JValue.SolveForm(jItemInfo,".Effects[0].MagicEffect") == JValue.SolveForm(ajObjectInfo,".Effects[0].MagicEffect")))
				Debug.Trace("vSS/API/Item/AssignItemID: " + kForm + " has a matching ItemID!")
				Return JArray.GetStr(JItemIDs,i)
			EndIf
		Else
			Debug.Trace("vSS/API/Item/AssignItemID: " + kForm + " is something I don't know how to check!")
		EndIf
	EndWhile
	Debug.Trace("vSS/API/Item/AssignItemID: " + kForm + " has no match, creating a new ItemID!")
	Return SuperStash.UUID()
EndFunction

String Function SaveItem(Int ajObjectInfo, String asItemId = "") Global
	If !JValue.IsMap(ajObjectInfo)
		Return ""
	EndIf

	String sItemID = asItemId
	If !sItemID
		;Attempt to use item's existing UUID if it has one
		sItemID = JValue.SolveStr(ajObjectInfo,".UUID")
	EndIf

	If !sItemID || GetItemJMap(sItemID) <= 0
	; ItemID not passed, or is already in use
		sItemID = AssignItemID(ajObjectInfo)
	EndIf

	String sRegKey = "Items." + sItemID

	If !JValue.HasPath(ajObjectInfo,".SID")
		JValue.SolveStrSetter(ajObjectInfo,".SID",GetSessionStr("SessionID"),True)
	EndIf
	
	If JValue.SolveStr(ajObjectInfo,".UUID") != sItemID
		JValue.SolveStrSetter(ajObjectInfo,".UUID",sItemID,True)
	EndIf

	;FIXME: Ugleh, UGLEH!
	Int jItemInfoMap = GetItemInfosForForm(JMap.GetForm(ajObjectInfo,"Form"))
	JMap.SetObj(jItemInfoMap,sItemID,ajObjectInfo)
	;SetItemInfosForForm(JMap.GetForm(ajObjectInfo,"Form"),jItemInfoMap)
	SetRegObj(sRegKey,ajObjectInfo)

	Return sItemID
EndFunction

;Serialize an objectReference if it is customized
String Function SerializeObject(ObjectReference akObject) Global
	
	Form kItem = akObject.GetBaseObject()
	If kItem as Weapon || kItem as Armor
		Return SerializeEquipment(akObject)
	ElseIf kItem as Potion
		Return SerializePotion(akObject)
	Else
		DebugTraceAPIItem("Item is not equipment or potion!")
	EndIf
	Return ""
EndFunction

String Function SerializeEquipment(ObjectReference akObject) Global
	Form kItem = akObject.GetBaseObject()
	
	ObjectReference kBaseObject = akObject.PlaceAtMe(kItem,abInitiallyDisabled = True)
	If !akObject.GetEnchantment() && \
		akObject.GetItemHealthPercent() == kBaseObject.GetItemHealthPercent() && \
		akObject.GetItemMaxCharge() == kBaseObject.GetItemMaxCharge() && \
		akObject.GetDisplayName() == kBaseObject.GetDisplayName()
		;Object is identical to its base, don't bother serializing it 
		kBaseObject.Delete()
		Return ""
	EndIf
	kBaseObject.Delete()

	Int jItemInfo = JMap.Object()

	JMap.SetForm(jItemInfo,"Form",kItem)
	JMap.SetStr(jItemInfo,"RefCount",akObject.GetNumReferenceAliases())
	Bool isWeapon = False
	Bool isEnchantable = False
	Bool isTwoHanded = False
	Enchantment kItemEnchantment
	If kItem
		JMap.SetStr(jItemInfo,"Source",SuperStash.GetSourceMod(kItem))
	EndIf
	If (kItem as Weapon)
		isWeapon = True
		isEnchantable = True
		Int iWeaponType = (kItem as Weapon).GetWeaponType()
		If iWeaponType > 4 && iWeaponType != 8
			IsTwoHanded = True
		EndIf
		kItemEnchantment = (kItem as Weapon).GetEnchantment()
	ElseIf (kItem as Armor)
		isEnchantable = True
		kItemEnchantment = (kItem as Armor).GetEnchantment()
	EndIf

	Int jItemEnchantmentInfo = JMap.Object()
	If isEnchantable ; don't create enchantment block unless object can be enchanted
		JMap.SetObj(jItemInfo,"Enchantment",jItemEnchantmentInfo)
	EndIf

	If kItemEnchantment
		;PlayerEnchantments[newindex] = kItemEnchantment
		;Debug.Trace("vSS/CM: " + kItem.GetName() + " has enchantment " + kItemEnchantment.GetFormID() + ", " + kItemEnchantment.GetName())
		JMap.SetForm(jItemEnchantmentInfo,"Form",kItemEnchantment)
;		AddToReqList(kItemEnchantment,"Enchantment")
		JMap.SetStr(jItemEnchantmentInfo,"Source",SuperStash.GetSourceMod(kItemEnchantment))
		JMap.SetInt(jItemEnchantmentInfo,"IsCustom",0)
	EndIf
	String sItemDisplayName = akObject.GetDisplayName()
	sItemDisplayName = StringUtil.SubString(sItemDisplayName,0,StringUtil.Find(sItemDisplayName,"(") - 1) ; Strip " (Legendary)"
	kItemEnchantment = akObject.GetEnchantment()
	If sItemDisplayName || kItemEnchantment
		;Debug.Trace("vSS/CM: " + kItem + " is enchanted/forged item " + sItemDisplayName)
		JMap.SetInt(jItemInfo,"IsCustom",1)
		JMap.SetFlt(jItemInfo,"ItemHealthPercent",akObject.GetItemHealthPercent())
		JMap.SetFlt(jItemInfo,"ItemCharge",akObject.GetItemCharge())
		JMap.SetFlt(jItemInfo,"ItemMaxCharge",akObject.GetItemMaxCharge())
		JMap.SetStr(jItemInfo,"DisplayName",sItemDisplayName)
		kItemEnchantment = akObject.GetEnchantment()
		If kItemEnchantment
			JMap.SetForm(jItemEnchantmentInfo,"Form",kItemEnchantment)
			JMap.SetStr(jItemEnchantmentInfo,"Source",SuperStash.GetSourceMod(kItemEnchantment))
;			AddToReqList(kItemEnchantment,"Enchantment")
			JMap.SetInt(jItemEnchantmentInfo,"IsCustom",1)
			Int iNumEffects = kItemEnchantment.GetNumEffects()
			JMap.SetInt(jItemEnchantmentInfo,"NumEffects",iNumEffects)
			Int jEffectsArray = JArray.Object()
			Int j = 0
			While j < iNumEffects
				Int jEffectsInfo = JMap.Object()
				JMap.SetFlt(jEffectsInfo, "Magnitude", kItemEnchantment.GetNthEffectMagnitude(j))
				JMap.SetFlt(jEffectsInfo, "Area", kItemEnchantment.GetNthEffectArea(j))
				JMap.SetFlt(jEffectsInfo, "Duration", kItemEnchantment.GetNthEffectDuration(j))
				JMap.SetForm(jEffectsInfo,"MagicEffect", kItemEnchantment.GetNthEffectMagicEffect(j))
				JMap.SetStr(jEffectsInfo,"Source",SuperStash.GetSourceMod(kItemEnchantment.GetNthEffectMagicEffect(j)))
;				AddToReqList(kItemEnchantment.GetNthEffectMagicEffect(j),"MagicEffect")
				JArray.AddObj(jEffectsArray,jEffectsInfo)
				j += 1
			EndWhile
			JMap.SetObj(jItemEnchantmentInfo,"Effects",jEffectsArray)
		EndIf
	Else
		JMap.SetInt(jItemInfo,"IsCustom",0)
	EndIf
	
	;Save dye color, if applicable
	;FIXME: Can dye color be saved when not equipped? There's no function for it...
	;If GetRegBool("Config.NIO.ArmorDye.Enabled") && kItem as Armor 
	;	Bool bHasDye = False
	;	Int iHandle = NiOverride.GetItemUniqueID(kWornObjectActor, 0, (kItem as Armor).GetSlotMask(), False)
	;	Int[] iNIODyeColors = New Int[15]
	;	Int iMaskIndex = 0
	;	While iMaskIndex < iNIODyeColors.Length
	;		Int iColor = NiOverride.GetItemDyeColor(iHandle, iMaskIndex)
	;		If Math.RightShift(iColor,24) > 0
	;			bHasDye = True
	;			iNIODyeColors[iMaskIndex] = iColor
	;		EndIf
	;		iMaskIndex += 1
	;	EndWhile
	;	If bHasDye
	;		JMap.SetObj(jItemInfo,"NIODyeColors",JArray.objectWithInts(iNIODyeColors))
	;	EndIf
	;EndIf

;	If !(iHand == 0 && IsTwoHanded) && kItem ; exclude left-hand iteration of two-handed weapons
;		If kWornObjectActor == PlayerREF
;			kItem.SendModEvent("vSS_EquipmentSaved","",iHand)
;		Else ;Was not saved from player, indicate this with iHand = -1
;			kItem.SendModEvent("vSS_EquipmentSaved","",-1)
;		EndIf
;	EndIf
	;Debug.Trace("vSS/CM: Finished serializing " + kItem.GetName() + ", JMap count is " + JMap.Count(jItemInfo))

	String sItemID = vSS_API_Item.SaveItem(jItemInfo)
	SetObjectID(akObject,sItemID)
	Return sItemID
EndFunction

ObjectReference Function CreateObject(String asItemID) Global
{Recreate an item from scratch using its ItemID.}
	Int jItem = GetItemJMap(asItemID)
	If jItem <= 0
		DebugTraceAPIItem("CreateObject: " + asItemID + " is not a valid ItemID!",1)
		Return None
	EndIf
	ObjectReference kObject = CreateObjectFromJObj(jItem)
	If kObject
		SetObjectID(kObject,asItemID)
	EndIf
	Return kObject
EndFunction

ObjectReference Function CreateObjectFromJObj(Int ajObjectInfo) Global
{Recreate an item from scratch using an appropriate JContainers object.}
	Int jItem = ajObjectInfo
	
	Form kItem = JMap.getForm(jItem,"Form")
	String sItemID = JMap.getStr(jItem,"UUID")
	If !kItem
		DebugTraceAPIItem("CreateObjectFromJObj: " + sItemID + " could not find base Form!",1)
		Return None
	EndIf

	vSS_StashManager StashManager = Quest.GetQuest("vSS_StashManagerQuest") as vSS_StashManager

	ObjectReference kMoveTarget = StashManager.MoveTarget

	ObjectReference kObject = kMoveTarget.PlaceAtMe(kItem)
	If !kObject
		DebugTraceAPIItem("CreateObjectFromJObj: " + sItemID + " could not use base Form " + kItem + " to create an ObjectReference!",1)
		Return None
	EndIf

	If !sItemID || GetItemJMap(sItemID) <= 0
		sItemID = SaveItem(ajObjectInfo,sItemID)
	EndIf

	If (kItem as Weapon) || (kItem as Armor)
		Return CustomizeEquipment(sItemID,kObject)
	ElseIf (kItem as Potion)
		Return CreatePotion(sItemID)
	EndIf
	Return kObject
EndFunction

ObjectReference Function CustomizeEquipment(String asItemID, ObjectReference akObject) Global
{Apply the customization information from the JObject referenced by asItemID to akObject.}
	Int jItem = GetItemJMap(asItemID)
	If jItem <= 0
		DebugTraceAPIItem("CustomizeEquipment: " + asItemID + " does not refer to a valid saved object!",1)
		Return kObject
	EndIf
	;DebugTraceAPIItem("CustomizeEquipment: Will apply attributes from " + JValue.SolveStr(jItem,".DisplayName") + " to " + akObject.GetBaseObject().GetName() + " " + akObject + "!")
	ObjectReference kObject = CustomizeEquipmentFromJObj(jItem,akObject)
	Return kObject
EndFunction

ObjectReference Function CustomizeObjectFromJObj(Int ajItemInfo, ObjectReference akObject) Global
{Apply the customization information from ajItemInfo to akObject.}
	ObjectReference kObject = akObject
	Int jItem = ajItemInfo

	Form kBaseObject = kObject.GetBaseObject()
	If (kBaseObject as Weapon) || (kBaseObject as Armor)
		Return CustomizeEquipmentFromJObj(jItem,kObject)
	
	; Soulgem stuff no worky.
	; ElseIf (kBaseObject as SoulGem)
	; 	Int iSoulLevel = JMap.getInt(jItem,"soulSize")
	; 	If iSoulLevel
	; 		DebugTraceAPIItem("Filling soulgem " + kObject + " with level " + iSoulLevel + " soul...")
	; 		Return SuperStash.FillSoulgem(kObject,iSoulLevel)
	; 		;Return kObject
	; 	EndIf
	EndIf

	Return kObject

EndFunction

ObjectReference Function CustomizeEquipmentFromJObj(Int ajItemInfo, ObjectReference akObject) Global
{Apply the customization information from ajItemInfo to weapon or armor akObject.}
	ObjectReference kObject = akObject
	Int jItem = ajItemInfo
	; Form kItem = JMap.getForm(jItem,"Form")
	; If !(kItem as Weapon) && !(kItem as Armor)
	; 	DebugTraceAPIItem("CustomizeEquipment: Item is not Weapon or Armor!",1)
	; 	Return kObject
	; EndIf
	String sDisplayName = JMap.getStr(jItem,"displayName")
	sDisplayName = StringUtil.SubString(sDisplayName,0,StringUtil.Find(sDisplayName,"(") - 1) ; Strip " (Legendary)"
	Float fHealth = JMap.getFlt(jItem,"health")
	Float fItemCharge = JMap.getFlt(jItem,"itemCharge")
	Float fItemMaxCharge = JMap.getFlt(jItem,"itemMaxCharge")

	If fHealth && fHealth > 1.0
		kObject.SetItemHealthPercent(fHealth)
	EndIf
	If fItemMaxCharge
		kObject.SetItemMaxCharge(fItemMaxCharge)
	EndIf
	If sDisplayName
		kObject.SetDisplayName(sDisplayName)
	EndIf

	Float[] fMagnitudes = New Float[4]
	Int[] iDurations = New Int[4]
	Int[] iAreas = New Int[4]
	MagicEffect[] kMagicEffects = New MagicEffect[4]

	If JValue.HasPath(jItem,".enchantment")
		Int jMagicEffects = JValue.SolveObj(jItem,".enchantment.magicEffects")
		Int iNumEffects = JArray.Count(jMagicEffects)
		Int j = 0
		While j < iNumEffects
			Int jMagicEffect = JArray.getObj(jMagicEffects,j)
			fMagnitudes[j] = JMap.GetFlt(jMagicEffect,"magnitude")
			iDurations[j] = JMap.GetInt(jMagicEffect,"duration")
			iAreas[j] = JMap.GetFlt(jMagicEffect,"area") as Int
			kMagicEffects[j] = JMap.GetForm(jMagicEffect,"form") as MagicEffect
			j += 1
		EndWhile
		kObject.CreateEnchantment(fItemMaxCharge, kMagicEffects, fMagnitudes, iAreas, iDurations)
		kObject.SetItemCharge(fItemCharge)
	ElseIf fItemCharge
		kObject.SetItemCharge(fItemCharge)
	EndIf

	Return kObject
EndFunction


String Function SerializePotion(Form akItem) Global
{
	Serialize a custom potion and return its new ItemID.
}

	Potion kPotion = akItem as Potion
	JMap.SetForm(jPotionInfo,"Form",akItem)
	If !akItem as Potion
		Return ""
	EndIf

	Int jPotionInfo = JMap.Object()
	
	JMap.SetStr(jPotionInfo,"Name",kPotion.GetName())
	JMap.SetStr(jPotionInfo,"WorldModelPath",kPotion.GetWorldModelPath())
	JMap.SetStr(jPotionInfo,"Source",SuperStash.GetSourceMod(kPotion))
	
	JMap.SetInt(jPotionInfo,"IsHostile",kPotion.IsHostile() as Int)
	JMap.SetInt(jPotionInfo,"IsFood",kPotion.IsFood() as Int)
	JMap.SetInt(jPotionInfo,"IsPoison",kPotion.IsPoison() as Int)

	Int iNumEffects = kPotion.GetNumEffects()
	JMap.SetInt(jPotionInfo,"NumEffects",iNumEffects)
	Int jEffectsArray = JArray.Object()
	Int i = 0
	While i < iNumEffects
		Int jEffectsInfo = JMap.Object()
		JMap.SetFlt(jEffectsInfo, "Magnitude", kPotion.GetNthEffectMagnitude(i))
		JMap.SetFlt(jEffectsInfo, "Area", kPotion.GetNthEffectArea(i))
		JMap.SetFlt(jEffectsInfo, "Duration", kPotion.GetNthEffectDuration(i))
		JMap.SetForm(jEffectsInfo,"MagicEffect", kPotion.GetNthEffectMagicEffect(i))
		JMap.SetStr(jEffectsInfo,"Source",SuperStash.GetSourceMod(kPotion))
		;AddToReqList(kPotion.GetNthEffectMagicEffect(i),"MagicEffect")
		JArray.AddObj(jEffectsArray,jEffectsInfo)
		i += 1
	EndWhile
	JMap.SetObj(jPotionInfo,"Effects",jEffectsArray)
	;Debug.Trace("vSS/CM: Finished serializing " + akItem.GetName() + ", JMap count is " + JMap.Count(jPotionInfo))
	Return vSS_API_Item.SaveItem(jPotionInfo)
EndFunction

Potion Function CreatePotionFromPotionData(Int jPotionData) Global
{Create a custom potion using jPotionData.}

	Float[] fMagnitudes = New Float[4]
	Int[] iDurations = New Int[4]
	Int[] iAreas = New Int[4]
	MagicEffect[] kMagicEffects = New MagicEffect[4]

	Int iForcePotionType = 0
	If JValue.HasPath(jPotionData,".isPoison")
		iForcePotionType = JValue.SolveInt(jPotionData,".isPoison")
	EndIf

	Int jMagicEffects = JValue.SolveObj(jPotionData,".magicEffects")
	Int iNumEffects = JArray.Count(jMagicEffects)
	Int i = 0
	While i < iNumEffects
		Int jMagicEffect = JArray.getObj(jMagicEffects,i)
		fMagnitudes[i] = JMap.GetFlt(jMagicEffect,"magnitude")
		iDurations[i] = JMap.GetInt(jMagicEffect,"duration")
		iAreas[i] = JMap.GetFlt(jMagicEffect,"area") as Int
		kMagicEffects[i] = JMap.GetForm(jMagicEffect,"form") as MagicEffect
		i += 1
	EndWhile
	Return SuperStash.CreateCustomPotion(kMagicEffects, fMagnitudes, iAreas, iDurations, iForcePotionType)
EndFunction

ObjectReference Function CreatePotion(String asItemID) Global
{Recreate a custom potion using jPotionInfo.}
;FIXME: This won't work because there is no SetNthMagicEffect!

	Int jPotionInfo = GetItemJMap(asItemID)
	Potion kDefaultPotion = Game.GetformFromFile(0x0005661f,"Skyrim.esm") as Potion
	Potion kDefaultPoison = Game.GetformFromFile(0x0005629e,"Skyrim.esm") as Potion
	
	vSS_StashManager StashManager = Quest.GetQuest("vSS_StashManagerQuest") as vSS_StashManager

	ObjectReference kMoveTarget = StashManager.MoveTarget

	Potion kPotion 
	If JMap.GetInt(jPotionInfo,"IsPoison")
		kPotion = kDefaultPoison
	Else
		kPotion = kDefaultPotion
	EndIf
	
	
	Int jEffectsArray = JMap.GetObj(jPotionInfo,"Effects")
	Int i = JArray.Count(jEffectsArray)
	While i > 0
		i -= 1
		Int jEffectsInfo = JArray.GetObj(jEffectsArray,i)
		;kPotion.SetNthEffectMagicEffect(i,JMap.GetForm(jEffectsInfo,"MagicEffect"))
		kPotion.SetNthEffectDuration(i,JMap.GetInt(jEffectsInfo,"Duration"))
		kPotion.SetNthEffectMagnitude(i,JMap.GetFlt(jEffectsInfo,"Magnitude"))
		kPotion.SetNthEffectArea(i,JMap.GetInt(jEffectsInfo,"Area"))
	EndWhile
	
	Return kMoveTarget.PlaceAtMe(kPotion,abForcePersist = True)
EndFunction

Form Function GetExistingObject(String asItemID) Global
	Int jItemIDMap 		= GetSessionObj("Items.IDMap")
	Return JMap.GetForm(jItemIDMap,asItemID)
EndFunction

String Function GetObjectID(ObjectReference akObject) Global
	Int jItemIDMap 		= GetSessionObj("Items.IDMap")
	Int jItemIDArray 	= JMap.AllKeys(jItemIDMap)
	Int jObjectArray 	= JMap.AllValues(jItemIDMap)
	Int iObjIndex = JArray.FindForm(jObjectArray,akObject)
	If iObjIndex >= 0
		Return JArray.GetStr(jItemIDArray,iObjIndex)
	EndIf
	Return ""
EndFunction

Function SetObjectID(ObjectReference akObject, String asItemID) Global
	Int jItemIDMap 		= GetSessionObj("Items.IDMap")
	If !JValue.IsMap(jItemIDMap)
		jItemIDMap = JMap.Object()
		SetSessionObj("Items.IDMap",jItemIDMap)
	EndIf
	JMap.SetForm(jItemIDMap,asItemID,akObject)
	SaveSession()
EndFunction

Function DebugTraceAPIItem(String sDebugString, Int iSeverity = 0) Global
	Debug.Trace("vSS/API/Item: " + sDebugString,iSeverity)
EndFunction

String Function GetFormIDString(Form kForm) Global
	String sResult
	sResult = kForm as String ; [FormName < (FF000000)>]
	sResult = StringUtil.SubString(sResult,StringUtil.Find(sResult,"(") + 1,8)
	Return sResult
EndFunction