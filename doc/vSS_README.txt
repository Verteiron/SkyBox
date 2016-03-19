[h]SkyBox[/h]

Skyrim mod that allow items to be shared between different playthroughs. Any number of in-game chests can be turned into a [em]Stash[/em], which means its contents will be persistent no matter which character you are playing. This is still in development.

[b][u]How to use it[/u][/b]

After installing, you'll get a lesser power called [em]SkyBox: Create Stash[/em]. Aim yourself at a Container object (anything you can put stuff in that isn't another actor) and use the Power. The container is now a [em]Stash[/em], and will glow a bit. Anything you put in the Stash will be saved and made available to your other characters.

[b][u]What you can store and transfer[/u][/b]

If the game will let you put it in there, then the Stash should handle it properly. This includes tempered, enchanted, and custom-made Weapons and Armor, player-created Potions and Poisons, and Soulgems (captured souls should be preserved). Of course you can also store regular items like gold, Ammo, MiscItems, Ingredients, crafting materials, etc.

Be cautious when storing Quest-related items. If you store, say, Auriel's Bow, then load up another character that hasn't done Dawnguard yet and start using it, I can't vouch for the safety of the results. It will [em]probably[/em] be okay in this particular example, but it's still not a good idea. Use common sense. If you try to break the game, the game will probably break ;)

[b][u]Managing your Stashes[/u][/b]

Once a container has been turned into a Stash, it can be managed from the SkyBox MCM panel. From the MCM you can get info about all the Stashes you can created, as well as do things like roll them back to earlier "versions" of their contents. In the future you will be able to do cute tricks like link containers together within a single save, so you can, say, make all your player homes in all your saved games have a box with a single shared storage pool.

[b][u]Removing a Stash[/u][/b]

You can remove the Stash spell from a container using the MCM. This will make it behave like a standard container. Any items already in it will remain available in all games that have been saved since the Stash was created.

[b][u]How Stashes work (AKA how to avoid losing your items)[/u][/b]

Stashes save their contents any time you close their inventory screen. These saves are completely independent from your normal saved games, which can lead to unexpected behavior if you don't understand how it works.

This is the short version: [b]Stashes save and update in real time, not game time.[/b] Everything else follows from that, but sometimes the ramifications can be confusing.

For example, item duplication is trivial.

[b]How to use a Stash for item duplication[/b]

[list=1][*]Create a Stash.[/*]
[*]Place an item in it.[/*]
[*]Load a game from before you put the item in the Stash.[/*]
[*]Remove the item from the Stash. Now you have two.[/*]
[*]Profit![/*]
[/list]

This works because the Stash is only tracking its own state. It doesn't care about game time, your inventory, or anything else. All it "knows" is that your character added an item, and later (in real time) removed the item again.

[b]How to use a Stash for MMORPG-style shared storage[/b]

Skyrim's not designed with this in mind. If you want to have MMORPG or Diablo-style "account" storage, where only one character can use a given item at a time, you need to make sure you save appropriately.

To [em]transfer[/em] an Ogre-Slaying Knife from [b]Alicekiin[/b] to [b]Bobahkiin[/b] 1. Create a Stash (with any character). 2. Load up Alicekiin and have her place the Ogre-Slaying Knife in the Stash. 3. Save Alicekiin's game. 4. Load up Bobahkiin. 5. Have him retrieve the Ogre-Slaying Knife. 6. Save Bobahkiin.

As long as you stick to the most recent saves, Bobahkiin now has Alicekiin's knife, and she can't get it back until he puts it back in the Stash. If you just want Bobahkiin to have a duplicate Ogre-Slaying Knife, then there's no need to save Alicekiin's game after putting the it in the Stash. Just put it in, load up Bobahkiin, and grab it. Then they'll both have one, because remember, the Stash doesn't know anything but its own contents.

[b]How to avoid losing your items[/b]

Because the Stash saves are independent of the regular savegames, it is possible to lose an item if you don't save after removing it from the Stash. For example, if you skipped step 6 in the previous section and Bobahkiin immediately jumped off a cliff without saving, the game would revert to a point [em]before[/em] he removed the item from the Stash. The Stash doesn't know that, though, so the item would still be missing. Thanks to frequent auto-saves, this scenario is unlikely to occur, but it is [em]possible[/em], which is why I went to considerable effort to allow for...

[b]Reverting a Stash[/b]

From the MCM, you can revert a Stash to a previous state. Just pick the Stash you want to revert, hit "History" and pick the version of the Stash you want to revert to. The change happens instantly if the Stash is currently loaded (i.e. you are standing next to it), otherwise it happens the next time its parent cell is loaded.

[b]Reverting a Stash will replace all the items in it with the items in the target revision.[/b] Generally speaking you should only use the revert function to recover a lost item that you don't have in another save.

[b]A note about custom items[/b]

Customized items are created when the Stash is first loaded, and are recreated when the Stash state is updated by another session. This means the FormID of an object may change after being transferred between characters. In other words, if you put your favorite custom sword in the Stash, another character retrieves it, plays with it, puts it back, and the original character then retrieves it, they will be getting an exact duplicate of the original item, not the original itself. This generally shouldn't be a problem, but it's something to be aware of.

[b][u]Modder resources and API[/u][/b]

There is an API for dealing with Stashes. Like so much else in this mod, it's practice for the new Familiar Faces, but I know it works because it's what my own scripts use, too. If you're interested, the [url=http://verteiron.github.io/SuperStash/api/classv_s_s___a_p_i___stash.html]Stash API documentation is available.[/url] It reads like C++ docs (Doxygen is a C++ documentation generator) but it's all Papyrus code.

[b][u]FAQ[/u][/b]

[b]Q.[/b] Can I "hide" items in dungeon chests for my other characters to find?
[b]A.[/b] Yes! Any items you put in a dungeon chest will be added to its default items when your other characters enters the cell it's in. So if Alicekiin puts 20 gold and an ogre-slaying knife in a dungeon chest that normally has 5 gold and a random fruit in it, Bobahkiin will find the chest contains 25 gold, a random fruit, and an ogre-slaying knife. 

[b]Q.[/b] What happens if my other characters are already using the Stash container I just created?
[b]A.[/b] The items will be merged with existing ones. Note that if you repeatedly load a game that merges items, you will start accumulating duplicates. For safety it's best if you pick containers that are empty.

[b]Q.[/b] What if the Stash's container isn't available in one of my saves?
[b]A.[/b] It won't cause any problems, but you won't be able to access it with that character until it [em]is[/em] available.

[b]Q.[/b] Can I make Stashes out of containers from other mods?
[b]A.[/b] Yes, but don't forget and uninstall the mod while the Stash is active, as you'll probably lose any items you have in it.

[b]Q.[/b] Is Skybox compatible with mods that link multiple containers together?
[b]A.[/b] Almost certainly not. If you want to try it, be my guest, but I don't think it will end well. Most of these types of mods work by using a hidden container in some other location. If you made [em]that[/em] container a Stash, it might sort-of work, but I haven't tried this and you probably shouldn't, either. I do plan to add same-game Stash synchronization (aka Stash Groups) as a feature at some point.

[b]Q.[/b] I LOST AN ITEM! WHAT DO I DO?
[b]A.[/b] First, calm down. If you still have a savegame with the item, you're fine, just load it up and put the item back in the Stash without saving. If you don't (how did that even happen?), go to the MCM, find the Stash you were using, and revert it to a version that you know still has the missing item. If none of the revisions have it, then... you may be out of luck. The item itself should be stored as a json file, but you'll have to re-add it to the Stash file by hand, as there's no in-game method to do this yet.

[b]Q.[/b] When do Stashes get saved?
[b]A.[/b] Any time the container's inventory menu is closed. In other words, if you open a Stash, look at it, and close it again, it will save a new revision even if you didn't add or remove anything. This may change in a future version, but I'm avoiding a script threading bug that can occur when a lot of items are added or removed at once.

[b]Q.[/b] When do Stash contents get loaded?
[b]A.[/b] Whenever the Cell containing the Stash is loaded. This means that Stash items will not disappear due to cell resets, so it's safe to use them even in dungeons, bandit camps, forts, etc.

[b]Q.[/b] Where are the Stash states stored?
[b]A.[/b] They are JSON files in "My Games/Skyrim/SuperStash" under "Stashes". The files are named "<Sourcefile>_<FormID>.json" (for example, the Breezehome bedroom chest is "Skyrim.esm_000F3922.json". The backups are numbered 1-9. Don't mess with the Config folder; if you screw that up you may lose all your Stash data.

[b]Q.[/b] How many revisions are there?
[b]A.[/b] 10. That's a more or less arbitrary number and there's no reason there can't be more if people want them.

[b]Q.[/b] What's with the Items folder?
[b]A.[/b] That's a feature from Familiar Faces that I wound up using here too. It stores custom items in a human-readable format, which may be used in future versions of either SkyBox or FF.

[b]Q.[/b] Why is the Stash system so weird? Why doesn't it track my saves better or prevent duplication?
[b]A.[/b] Frankly it's a miracle that this works at all, particularly as fast as it is. I looked into some basic duplication prevention that worked by identifying the current session and marking the item's source, comparing the two, etc etc but it was complicated, wasn't 100% accurate and was still pretty easy to defeat. Keeping the Stashes dumb makes everything simpler.

[b]Q.[/b] Why is this not Familiar Faces?
[b]A.[/b] Because I burned out on FF a while back and needed to do something different for a while. In the process I wanted to completely redo the way FF handles saving and loading data, and SuperStash/SkyBox became my learning project for implementing that. Many features developed for SkyBox have already been backported to FF, and believe me, that's a good thing.

[b][u]Disclaimer[/u][/b]

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.