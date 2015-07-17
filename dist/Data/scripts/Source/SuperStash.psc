Scriptname SuperStash Hidden
{Series of utility functions provided by SuperStash.dll.}

; === [ SuperStash.psc ] =====================================================---
; Thanks to expired for starting this plugin for me. It has since been 
; added to considerably. These are mostly bulk functions that are much
; faster to do on the c++ side than on the Papyrus side.
; ========================================================---

Function TraceConsole(String asTrace) native global
{Print a string to the console.}

String Function userDirectory() native global
{Returns "%UserProfile%/My Documents/My Games/Skyrim/Familiar Faces".}

String Function UUID() native global
{Returns a random UUID.}

Int Function FilterFormlist(FormList sourceList, Formlist filteredList, Int aiType) native global
{Populates filteredList with all forms in sourceList that are aiType. Returns number of matching forms.}

Form[] Function GetFilteredList(FormList sourceList, Int aiType) native global
{Returns an array (may be >128) of all forms in sourceList that are aiType.}

Form[] Function FilterFormArray(Form[] sourceArray, Form[] opArray, Bool abWhitelist = True) native global
{Return an array (may be >128) of Forms.
 If Whitelist is true, return Forms present in both arrays. 
 If Whitelist is false, return Forms found in sourceArray but not opArray.}

Int[] Function GetItemCounts(Form[] sourceArray, ObjectReference akObject) native global
{Returns an array (may be >128) of the counts for all form in sourceArray in akObject's inventory.}

Int[] Function GetItemTypes(Form[] sourceArray) native global
{Returns an array (may be >128) of the numeric ItemTypes for all forms in sourceArray.}

Int[] Function GetItemFavorited(Form[] sourceArray) native global
{Returns an array (may be >128) of Bool as Int indicating whether the item is favorited.}

Int[] Function GetItemHasExtraData(Form[] sourceArray) native global
{Returns an array (may be >128) of Bool as Int indicating whether the item has ExtraData (is customized or enchanted).}

String[] Function GetItemNames(Form[] sourceArray) native global
{Returns an array (may be >128) of String containing the names of all forms in sourceArray.}

String Function GetSourceMod(Form akForm) native global
{Returns the name of the mod that provides akForm.}
