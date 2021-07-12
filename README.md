
# QuickHeal v1.17.0

QuickHeal for Turtle WoW

QuickHeal gives healers fast access to all of their direct healing spells for healing party/raid members and themselves. It lets you heal the people who need it, without having to target them manually, or even having to deselect the enemy you're fighting. It gives maximum mana efficiency, and will automatically use a lower rank of healing if the target doesn't need your biggest heal, or if your mana is running low. This also works when not in a party or a raid, and this will save you mana and precious time by automatically selecting the healing spell. There are several different key bindings for constraining the scope of players that will be considered for heals.

I'm not the author of this revised version.  I modified Sulpitz's version to include an interface that allows the user to define a tank group independently of oRA.  This version works with the 1.12.1 client.

I shamelessly plagiarized the most recent version of QuickHeal with integration for HealComm from
https://github.com/Sulpitz/QuickHeal

..who previously got it from
https://wow.curseforge.com/projects/project-2800

**Integration of HealComm**

QuickHeal uses the incoming heal information broadcast by HealComm (Luna unit Frames), through the addonchannel to reduce overhealing and making this addon used by multiple raidmembers more effective.

## Installation
- Download QuickHeal from this repository into your Interface folder and remove the "-main" in the folder name
- Download HealComm or Luna unit Frames: https://github.com/Aviana/LunaUnitFrames
- Download Bonusscanner (Makes QuickHeal and HealComm (Luna unit Frames) more accurate by taking gear and +Heal into account: http://www.vanilla-addons.com/dls/bonusscanner/

## Usage

**Help**
`/qh help` displays help inside the console

**Configuration**
`/qh cfg` invokes the configuration interface

**Heal**
To invoke quickheal, make a macro with the `/qh` slash command syntax or set Key Bindings:

![Imgur](https://i.imgur.com/iznZGhP.png)

**Downrank**
To conserve mana and heal more efficiently you can limit the maximum rank that QuickHeal will use. It is done by moving the slider. on the Downrank Window.

`/qh dr` to open the Downrank Window:

![Imgur](https://i.imgur.com/ncZ7PJ8.png)

**Healing in Partition Mode: HPS Toggle**
Partition mode means invoking QuickHeal to consider predefined subgroups within the raid (e.g. mt, nonmt, subgroup).  There are two modes for healing in partition mode: Normal HPS & High HPS.

**High HPS** is restricted to fast-casting heal spells.
    High healing throughput but low mana efficiency. e.g. Flash Heal

**Normal HPS** encomapsses ALL healing spells regardless of relative cast time.
    Normal healing throughput with higher mana efficiency.

`/qh toggle`
Toggles between Normal HPS and High HPS.
This corresponds to the **Toggle Heathy Threshold 0/100** keybind.  When invoked, it will echo `QuickHeal mode: Normal HPS` and `QuickHeal mode: High HPS` in the console to display its current state.

`/qh mt`
Only considers targets that are in the tank group, which is defined by populating the MT Target Filter:

![Imgur](https://i.imgur.com/AvVqwVz.png)<Br>
![Imgur](https://i.imgur.com/BVmvcHD.png)<Br>

`+` adds current target into the list.  `C` clears the list.

** Additional Functionality (priest and druid classes only) **

`/qh hot`<Br>
  ..applies throttled HoT to any player w/o your class HoT AND < lowest % health in raid/party

`/qh hot max`<Br>
  ..applies maximum rank HoT to any player w/o your class HoT AND < lowest % health in raid/party

`/qh mt hot fh`<Br>
  ..applies maximum rank HoT to any player defined in the Main Tank group w/o your class HoT regardless of their health

## ChangeLog:
**1.14.5**<Br>
Disabled vestigial config UI tab 'Target Filtering'
Fixed lua error messages that were being generated from bad OnEnter syntax in QuickHeal.xml:1620:FilterRaidGroup1-8
Revised readme.md
<hr>
  
**1.16**<Br>
Added functions `SmartRenew()`, `SmartRenewFirehose()` and `SmartRenewThrottle()`.
Revised readme.md
<hr>
  
**1.16.1**<Br>
Removed functions `SmartRenew()`, `SmartRenewFirehose()` and `SmartRenewThrottle()`.  These were causing target focus problems.<Br>
Implemented `/qh hot` to replace SmartRenewThrottle().<Br>
Regular SmartRenew & SmartRenewFirehose comin' soon-ish like.
<hr>

**1.17.0**<Br>
Modified the verbiage for `/qh toggle` to `QuickHeal mode: Normal HPS` and `QuickHeal mode: High HPS`.<Br>
The main tanks list is now saved to disk and will persist across sessions.</Br>
Removed non-partition mode (`hm`) commands.<Br>
Druids can now cast HoTs while moving.<Br>
Big overhaul on usage syntax, e.g.: `/qh [mask] [hot] [mod]` OR `/quickheal [mask] [hot] [mod]`:<Br>

`[mask]`: constrains healing pool to:<Br>
`player` = yourself<Br>
`target` = your target<Br>
`taregettarget` = your target's target<Br>
`party` = your party<Br>
`mt` = main tanks (defined in the configuration panel)<Br>
`nonmt` = everyone but the main tanks<Br>
`subgroup` = raid subgroups (defined in the configuration panel)<Br>

`[hot]`: Optional argument.  Forces the use of a HoT spell over a channeled spell.  Only works for Priests & Druids.<Br>

`[mod]`: optional argument.  Modifies the application of HoTs:<Br>
`[max]`= will apply a HoT to the next target that is not @100% hp and that does not currently have a HoT applied.<Br>
`[fh]` = firehose mode.  Will apply maximum rank HoT on the next target that does not have a HoT applied.<Br>
<hr>