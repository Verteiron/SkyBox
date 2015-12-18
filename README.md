Please note this has not yet reached 1.0, which means there are known (and probably unknown) bugs that may do bad things to your game. Unless you're willing to help me test it and work with me to resolve any issues you encounter, don't even think about installing it right now.

Download the current release here: https://github.com/Verteiron/SkyBox/releases
You can view the Stash API here: [Stash API documentation](http://verteiron.github.io/SkyBox/api/classv_s_s___a_p_i___stash.html)

#SkyBox
Skyrim mod that allow items to be shared between different playthroughs. Any number of in-game chests can be turned into a *Stash*, which means its contents will be persistent no matter which character you are playing. This is still in development.

##How to use it
After installing, you'll get a lesser power called *SkyBox: Create Stash*. Aim yourself at a Container object (anything you can put stuff in that isn't another actor) and use the Power. The container is now a *Stash*, and will glow a bit. Anything you put in the Stash will be saved and made available to your other characters. 

##What you can store and transfer
If the game will let you put it in there, then the Stash should handle it properly. This includes tempered, enchanted, and custom-made Weapons and Armor, player-created Potions and Poisons, and Soulgems (captured souls should be preserved). Of course you can also store regular items like gold, Ammo, MiscItems, Ingredients, crafting materials, etc. 

Be cautious when storing Quest-related items. If you store, say, Auriel's Bow, then load up another character that hasn't done Dawnguard yet and start using it, I can't vouch for the safety of the results. It will *probably* be okay in this particular example, but it's still not a good idea. Use common sense. If you try to break the game, the game will probably break ;)

##Managing your Stashes
Once a container has been turned into a Stash, it can be managed from the SkyBox MCM panel. From the MCM you can get info about all the Stashes you can created, as well as do things like roll them back to earlier "versions" of their contents. In the future you will be able to do cute tricks like link containers together within a single save, so you can, say, make all your player homes in all your saved games have a box with a single shared storage pool.

##Removing a Stash
You can remove the Stash spell from a container using the MCM. This will make it behave like a standard container. Any items already in it will remain available in all games that have been saved since the Stash was created. 

##How Stashes work (AKA how to avoid losing your items)
Stashes save their contents any time you close their inventory screen. These saves are completely independent from your normal saved games, which can lead to unexpected behavior if you don't understand how it works.

This is the short version: **Stashes save and update in real time, not game time.** Everything else follows from that, but sometimes the ramifications can be confusing.

For example, item duplication is trivial.

###How to use a Stash for item duplication

1. Create a Stash.
2. Place an item in it.
3. Load a game from before you put the item in the Stash.
4. Remove the item from the Stash. Now you have two.
5. Profit!

This works because the Stash is only tracking its own state. It doesn't care about game time, your inventory, or anything else. All it "knows" is that your character added an item, and later (in real time) removed the item again.

###How to use a Stash for MMORPG-style shared storage

Skyrim's not designed with this in mind. If you want to have MMORPG or Diablo-style "account" storage, where only one character can use a given item at a time, you need to make sure you save appropriately. 

To *transfer* an Ogre-Slaying Knife from **Alicekiin** to **Bobahkiin**
1. Create a Stash (with any character).
2. Load up Alicekiin and have her place the Ogre-Slaying Knife in the Stash.
3. Save Alicekiin's game.
4. Load up Bobahkiin.
5. Have him retrieve the Ogre-Slaying Knife.
6. Save Bobahkiin.

As long as you stick to the most recent saves, Bobahkiin now has Alicekiin's knife, and she can't get it back until he puts it back in the Stash. If you just want Bobahkiin to have a duplicate Ogre-Slaying Knife, then there's no need to save Alicekiin's game after putting the it in the Stash. Just put it in, load up Bobahkiin, and grab it. Then they'll both have one, because remember, the Stash doesn't know anything but its own contents.

###How to avoid losing your items
Because the Stash saves are independent of the regular savegames, it is possible to lose an item if you don't save after removing it from the Stash. For example, if you skipped step 6 in the previous section and Bobahkiin immediately jumped off a cliff without saving, the game would revert to a point *before* he removed the item from the Stash. The Stash doesn't know that, though, so the item would still be missing. Thanks to frequent auto-saves, this scenario is unlikely to occur, but it is *possible*, which is why I went to considerable effort to allow for...

###Reverting a Stash
From the MCM, you can revert a Stash to a previous state. Just pick the Stash you want to revert, hit "History" and pick the version of the Stash you want to revert to. The change happens instantly if the Stash is currently loaded (i.e. you are standing next to it), otherwise it happens the next time its parent cell is loaded.

**Reverting a Stash will replace all the items in it with the items in the target revision.** Generally speaking you should only use the revert function to recover a lost item that you don't have in another save. 

###A note about custom items
Customized items are created when the Stash is first loaded, and are recreated when the Stash state is updated by another session. This means the FormID of an object may change after being transferred between characters. In other words, if you put your favorite custom sword in the Stash, another character retrieves it, plays with it, puts it back, and the original character then retrieves it, they will be getting an exact duplicate of the original item, not the original itself. This generally shouldn't be a problem, but it's something to be aware of.

##Modder resources and API
There is an API for dealing with Stashes. Like so much else in this mod, it's practice for the new Familiar Faces, but I know it works because it's what my own scripts use, too. If you're interested, the [Stash API documentation is available.](http://verteiron.github.io/SkyBox/api/classv_s_s___a_p_i___stash.html) It reads like C++ docs (Doxygen is a C++ documentation generator, I used regex trickery to get it to read Papyrus scripts) but it's all Papyrus code.

##FAQ

**Q.** What happens if my other characters are already using the Stash container I just created?  
**A.** The items will be merged with existing ones, but for safety it's best if you pick containers that are empty. 

**Q.** What if the Stash's container isn't available in one of my saves?   
**A.** It won't cause any problems, but you won't be able to access it with that character until it *is* available.  

**Q.** Can I make Stashes out of containers from other mods?  
**A.** Yes, but don't forget and uninstall the mod while the Stash is active, as you'll probably lose any items you have in it.  

**Q.** Is Skybox compatible with mods that link multiple containers together?  
**A.** Almost certainly not. If you want to try it, be my guest, but I don't think it will end well. Most of these types of mods work by using a hidden container in some other location. If you made *that* container a Stash, it might sort-of work, but I haven't tried this and you probably shouldn't, either.  

**Q.** I LOST AN ITEM! WHAT DO I DO?  
**A.** First, calm down. If you still have a savegame with the item, you're fine, just load it up and put the item back in the Stash without saving. If you don't (how did that even happen?), go to the MCM, find the Stash you were using, and revert it to a version that you know still has the missing item. If none of the revisions have it, then... you may be out of luck. The item itself should be stored as a json file, but you'll have to re-add it to the Stash file by hand, as there's no in-game method to do this yet.  

**Q.** When do Stashes get saved?  
**A.** Any time the container's inventory menu is closed. In other words, if you open a Stash, look at it, and close it again, it will save a new revision even if you didn't add or remove anything. This may change in a future version, but I'm avoiding a script threading bug that can occur when a lot of items are added or removed at once.  

**Q.** Where are the Stash states stored?  
**A.** In "My Games/Skyrim/SuperStash" (fixme: probably will be "My Games/Skyrim/SkyBox at release time") under "Stashes". Don't mess with the Config folder unless you know exactly what you're doing.  

**Q.** How many revisions are there?  
**A.** 10. That's a more or less arbitrary number and there's no reason there can't be more if people want them.  

**Q.** What's with the Items folder?  
**A.** That's a feature from Familiar Faces that I wound up using here too. It stores custom items in a human-readable format, which may be used in future versions of either SkyBox or FF.  

**Q.** Why is the Stash system so weird? Why doesn't it track my saves better or prevent duplication?  
**A.** Frankly it's a miracle that this works at all, particularly as fast as it is. I looked into some basic duplication prevention that worked by identifying the current session and marking the item's source, comparing the two, etc etc but it was complicated, wasn't 100% accurate and was still pretty easy to defeat. Keeping the Stashes dumb makes everything simpler.  

**Q.** Why is this not Familiar Faces?  
**A.** Because I burned out on FF a while back and needed to do something different for a while. In the process I wanted to completely redo the way FF handles saving and loading data, and SuperStash/SkyBox became my learning project for implementing that. Many features developed for SkyBox have already been backported to FF, and believe me, that's a good thing.   

Disclaimer
----------
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
