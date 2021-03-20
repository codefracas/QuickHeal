
# QuickHeal v1.16

QuickHeal for Turtle WoW

QuickHeal gives healers fast access to all of their direct healing spells for healing party/raid members and themselves. It lets you heal the people who need it, without having to target them manually, or even having to deselect the enemy you're fighting. It gives maximum mana efficiency, and will automatically use a lower rank of healing if the target doesn't need your biggest heal, or if your mana is running low. This also works when not in a party or a raid, and this will save you mana and precious time by automatically selecting the healing spell that does the necessary healing. There are several different key bindings for narrowing the group of people that will be considered for healing.

I'm not the author of this revised version.  I modified Sulpitz's version to include an interface that allows the user to define a tank group independently of oRA.  This version also works with the 1.12.1 client.

I shamelessly plagiarized the most recent version of QuickHeal with integration for HealComm from
https://github.com/Sulpitz/QuickHeal

..who previously got it from
https://wow.curseforge.com/projects/project-2800

**Integration of HealComm**

QuickHeal uses the incoming heal information broadcasted by HealComm (Luna unit Frames), through the addonchannel to reduce overhealing and making this addon used by multiple raidmembers more effective.

## Installation
- Download QuickHeal from this repository into your Interface folder and remove the "-main" in the folder name
- Download HealComm or Luna unit Frames: https://github.com/Aviana/LunaUnitFrames
- Download Bonusscanner (Makes QhickHeal and HealComm (Luna unit Frames) more accurate by taking gear and +Heal into account: http://www.vanilla-addons.com/dls/bonusscanner/

## Usage

**Help**
`/qh help` displays help inside the console

**Configuration**
`/qh cfg` invokes the configuration interface

**Heal**
To invoke quickheal, make a macro with the `/qh` slash command syntax or set Key Bindings:

![Imgur](https://i.imgur.com/iznZGhP.png)

**Downrank**
To conserve mana and heal more effitiently you can limit the max rank that QuickHeal will use. It is done by moving the slider. on the Downrank Window. 

`/qh dr` to open the Downrank Window:

![Imgur](https://i.imgur.com/ncZ7PJ8.png)

**Healing in Non-Partition Mode**
There are 3 modes for healing in non-partition mode.  Non-partition mode means invoking QuickHeal to consider the entire raid rather than focusing on subgroups.

**Low HPS**
`/qh hm 1`
Priest: Will only cast Greater Heal, Heal and Lesser Heal.
Paladin: Will only use Flash of Light

**Moderate HPS**
`/qh hm 2`
Priest: Will only cast Flash Heal
Paladin: Will only cast Holy Light

**High HPS**
`/qh hm 3`
Will cast the heal with the highest Healing Per Second.
Priest: Will cast Prayer of Healing if possible

**Healing in Partition Mode: HPS Toggle**
Partition mode means invoking QuickHeal to consider predefined subgroups within the raid (e.g. mt, nonmt, subgroup).  There are two modes for healing in partition mode: Low HPS (Normal) & High HPS (FlashHeal).

`/qh toggle`
Toggles between mana efficient heals and max HPS heals.  
This corresponds to the **Toggle Heathy Threshold 0/100** keybind.  When invoked, it will echo 
`QuickHeal Mode: Normal` and `QuickHeal Mode: FlashHeal` 
in the console to display its current state.

`/qh mt`
Only considers targets that are in the tank group, which is defined by populating the MT Target Filter:

![Imgur](https://i.imgur.com/AvVqwVz.png)
![Imgur](https://i.imgur.com/BVmvcHD.png?1)

`+` adds current target into the list.  `C` clears the list.

** Additional Functions (priest class only at this time) **

/script SmartRenew();
  ..applies max rank renew to any player w/o renew AND < 100% health

/script SmartRenewThrottle();
  ..applies downranked renew to any player w/o renew AND < 100% health
  
/script SmartRenewFirehose();
  ..applies max rank renew to any player w/o renew

## ChangeLog:
**1.14.5**<Br>
Disabled vestigial config UI tab 'Target Filtering'
Fixed lua error messages that were being generated from bad OnEnter syntax in QuickHeal.xml:1620:FilterRaidGroup1-8
Revised readme.md
<hr>
