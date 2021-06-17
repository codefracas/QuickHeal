local function writeLine(s,r,g,b)
   if DEFAULT_CHAT_FRAME then
       DEFAULT_CHAT_FRAME:AddMessage(s, r or 1, g or 1, b or 0.5)
   end
end

function QuickHeal_Priest_GetRatioHealthyExplanation()
    if QuickHealVariables.RatioHealthyPriest >= QuickHealVariables.RatioFull then
        return QUICKHEAL_SPELL_FLASH_HEAL .. " will always be used in combat, and "  .. QUICKHEAL_SPELL_LESSER_HEAL .. ", " .. QUICKHEAL_SPELL_HEAL .. " or " .. QUICKHEAL_SPELL_GREATER_HEAL .. " will be used when out of combat. ";
    else
        if QuickHealVariables.RatioHealthyPriest > 0 then
            return QUICKHEAL_SPELL_FLASH_HEAL .. " will be used in combat if the target has less than " .. QuickHealVariables.RatioHealthyPriest*100 .. "% life, and " .. QUICKHEAL_SPELL_LESSER_HEAL .. ", " .. QUICKHEAL_SPELL_HEAL .. " or " .. QUICKHEAL_SPELL_GREATER_HEAL .. " will be used otherwise. ";
        else
            return QUICKHEAL_SPELL_FLASH_HEAL .. " will never be used. " .. QUICKHEAL_SPELL_LESSER_HEAL .. ", " .. QUICKHEAL_SPELL_HEAL .. " or " .. QUICKHEAL_SPELL_GREATER_HEAL .. " will always be used in and out of combat. ";
        end
    end
end

function QuickHeal_Priest_FindHealSpellToUse(Target, healType, multiplier)
    local SpellID = nil;
    local HealSize = 0;
    local Overheal = false;

    -- Return immediately if no player needs healing
    if not Target then
        return SpellID,HealSize;
    end

    if multiplier == nil then
        jgpprint(">>> multiplier is NIL <<<")
        --if multiplier > 1.0 then
        --    Overheal = true;
        --end
    elseif multiplier == 1.0 then
        jgpprint(">>> multiplier is " .. multiplier .. " <<<")
    elseif multiplier > 1.0 then
        jgpprint(">>> multiplier is " .. multiplier .. " <<<")
        Overheal = true;
    end

    -- +Healing-PenaltyFactor = (1-((20-LevelLearnt)*0.0375)) for all spells learnt before level 20
    local PF1 = 0.2875;
    local PF4 = 0.4;
    local PF10 = 0.625;
    local PF18 = 0.925;

    -- Determine health and healneed of target
    local healneed;
    local Health;

    if QuickHeal_UnitHasHealthInfo(Target) then
    -- Full info available
        healneed = UnitHealthMax(Target) - UnitHealth(Target) - HealComm:getHeal(UnitName(Target)); -- Implementatin for HealComm
        if Overheal then
            healneed = healneed * multiplier;
        else
            --
        end
        Health = UnitHealth(Target) / UnitHealthMax(Target);
    else
        -- Estimate target health
        healneed = QuickHeal_EstimateUnitHealNeed(Target,true); -- needs HealComm implementation maybe
        if Overheal then
            healneed = healneed * multiplier;
        else
            --
        end
        Health = UnitHealth(Target)/100;
    end

    jgpprint(">>> healneed is " .. healneed .. " <<<")

    -- if BonusScanner is running, get +Healing bonus
    local Bonus = 0;
    if (BonusScanner) then
    Bonus = tonumber(BonusScanner:GetBonus("HEAL"));
    QuickHeal_debug(string.format("Equipment Healing Bonus: %d", Bonus));
    end

    -- Spiritual Guidance - Increases spell damage and healing by up to 5% (per rank) of your total Spirit.
    local _,_,_,_,talentRank,_ = GetTalentInfo(2,14);
    local _,Spirit,_,_ = UnitStat('player',5);
    local sgMod = Spirit * 5*talentRank/100;
    QuickHeal_debug(string.format("Spiritual Guidance Bonus: %f", sgMod));

    -- Calculate healing bonus
    local healMod15 = (1.5/3.5) * (sgMod + Bonus);
    local healMod20 = (2.0/3.5) * (sgMod + Bonus);
    local healMod25 = (2.5/3.5) * (sgMod + Bonus);
    local healMod30 = (3.0/3.5) * (sgMod + Bonus);
    QuickHeal_debug("Final Healing Bonus (1.5,2.0,2.5,3.0)", healMod15,healMod20,healMod25,healMod30);

    local InCombat = UnitAffectingCombat('player') or UnitAffectingCombat(Target);

    -- Spiritual Healing - Increases healing by 2% per rank on all spells
    local _,_,_,_,talentRank,_ = GetTalentInfo(2,15);
    local shMod = 2*talentRank/100 + 1;
    QuickHeal_debug(string.format("Spiritual Healing modifier: %f", shMod));

    -- Improved Healing - Decreases mana usage by 5% per rank on LH,H and GH
    local _,_,_,_,talentRank,_ = GetTalentInfo(2,10);
    local ihMod = 1 - 5*talentRank/100;
    QuickHeal_debug(string.format("Improved Healing modifier: %f", ihMod));

    local TargetIsHealthy = Health >= QuickHealVariables.RatioHealthyPriest;
    local ManaLeft = UnitMana('player');

    if TargetIsHealthy then
    QuickHeal_debug("Target is healthy",Health);
    end

    -- Detect proc of 'Hand of Edward the Odd' mace (next spell is instant cast)
    if QuickHeal_DetectBuff('player',"Spell_Holy_SearingLight") then
    QuickHeal_debug("BUFF: Hand of Edward the Odd (out of combat healing forced)");
    InCombat = false;
    end

    -- Detect Inner Focus or Spirit of Redemption (hack ManaLeft and healneed)
    if QuickHeal_DetectBuff('player',"Spell_Frost_WindWalkOn",1) or QuickHeal_DetectBuff('player',"Spell_Holy_GreaterHeal") then
    QuickHeal_debug("Inner Focus or Spirit of Redemption active");
    ManaLeft = UnitManaMax('player'); -- Infinite mana
    healneed = 10^6; -- Deliberate overheal (mana is free)
    end

    if Overheal then
        QuickHeal_debug("MOOOOOOOOOOOOOOOOOOOOOOOOLTIPLIER");
    else

    end


    -- Get total healing modifier (factor) caused by healing target debuffs
    local HDB = QuickHeal_GetHealModifier(Target);
    QuickHeal_debug("Target debuff healing modifier",HDB);
    healneed = healneed/HDB;

    -- Get a list of ranks available for all spells
    local SpellIDsLH = QuickHeal_GetSpellIDs(QUICKHEAL_SPELL_LESSER_HEAL);
    local SpellIDsH  = QuickHeal_GetSpellIDs(QUICKHEAL_SPELL_HEAL);
    local SpellIDsGH = QuickHeal_GetSpellIDs(QUICKHEAL_SPELL_GREATER_HEAL);
    local SpellIDsFH = QuickHeal_GetSpellIDs(QUICKHEAL_SPELL_FLASH_HEAL);
    local SpellIDsR = QuickHeal_GetSpellIDs(QUICKHEAL_SPELL_RENEW);

    local maxRankLH = table.getn(SpellIDsLH);
    local maxRankH  = table.getn(SpellIDsH);
    local maxRankGH = table.getn(SpellIDsGH);
    local maxRankFH = table.getn(SpellIDsFH);
    local maxRankR = table.getn(SpellIDsR);

    QuickHeal_debug(string.format("Found LH up to rank %d, H up top rank %d, GH up to rank %d, FH up to rank %d, and R up to max rank %d", maxRankLH, maxRankH, maxRankGH, maxRankFH, maxRankR));

    --Get max HealRanks that are allowed to be used
    local downRankFH = QuickHealVariables.DownrankValueFH  -- rank for 1.5 sec heals
    local downRankNH = QuickHealVariables.DownrankValueNH -- rank for < 1.5 sec heals

    -- Compensation for health lost during combat
    local k=1.0;
    local K=1.0;
    if InCombat then
    k=0.9;
    K=0.8;
    end

    -- if healType = channel
    --jgpprint(healType)

    --if healType == "channel" and Overheal and healneed == 0 then
    --    SpellID = SpellIDsGH[5]; HealSize = 2080*shMod+healMod30;
    --end

    if healType == "channel" then
        jgpprint("CHANNEL HEAL: " .. healType)
        -- Find suitable SpellID based on the defined criteria
        if not InCombat or TargetIsHealthy or maxRankFH<1 then
            -- Not in combat or target is healthy so use the closest available mana efficient healing
            QuickHeal_debug(string.format("Not in combat or target healthy or no flash heal available, will use closest available LH, H or GH (not FH)"))
            if Health < QuickHealVariables.RatioFull then
            SpellID = SpellIDsLH[1]; HealSize = 53*shMod+healMod15*PF1; -- Default to LH
            if healneed > (  84*shMod+healMod20*PF4) *k and ManaLeft >=  45*ihMod and maxRankLH >=2 and downRankNH >= 2  then SpellID = SpellIDsLH[2]; HealSize =   84*shMod+healMod20*PF4  end
            if healneed > ( 154*shMod+healMod25*PF10)*K and ManaLeft >=  75*ihMod and maxRankLH >=3 and downRankNH >= 3  then SpellID = SpellIDsLH[3]; HealSize =  154*shMod+healMod25*PF10 end
            if healneed > ( 318*shMod+healMod30*PF18)*K and ManaLeft >= 155*ihMod and maxRankH  >=1 and downRankNH >= 4  then SpellID = SpellIDsH[1] ; HealSize =  318*shMod+healMod30*PF18 end
            if healneed > ( 460*shMod+healMod30)*K      and ManaLeft >= 205*ihMod and maxRankH  >=2 and downRankNH >= 5  then SpellID = SpellIDsH[2] ; HealSize =  460*shMod+healMod30      end
            if healneed > ( 604*shMod+healMod30)*K      and ManaLeft >= 255*ihMod and maxRankH  >=3 and downRankNH >= 6  then SpellID = SpellIDsH[3] ; HealSize =  604*shMod+healMod30      end
            if healneed > ( 758*shMod+healMod30)*K      and ManaLeft >= 305*ihMod and maxRankH  >=4 and downRankNH >= 7  then SpellID = SpellIDsH[4] ; HealSize =  758*shMod+healMod30      end
            if healneed > ( 956*shMod+healMod30)*K      and ManaLeft >= 370*ihMod and maxRankGH >=1 and downRankNH >= 8  then SpellID = SpellIDsGH[1]; HealSize =  956*shMod+healMod30      end
            if healneed > (1219*shMod+healMod30)*K      and ManaLeft >= 455*ihMod and maxRankGH >=2 and downRankNH >= 9  then SpellID = SpellIDsGH[2]; HealSize = 1219*shMod+healMod30      end
            if healneed > (1523*shMod+healMod30)*K      and ManaLeft >= 545*ihMod and maxRankGH >=3 and downRankNH >= 10 then SpellID = SpellIDsGH[3]; HealSize = 1523*shMod+healMod30      end
            if healneed > (1902*shMod+healMod30)*K      and ManaLeft >= 655*ihMod and maxRankGH >=4 and downRankNH >= 11 then SpellID = SpellIDsGH[4]; HealSize = 1902*shMod+healMod30      end
            if healneed > (2080*shMod+healMod30)*K      and ManaLeft >= 710*ihMod and maxRankGH >=5 and downRankNH >= 12 then SpellID = SpellIDsGH[5]; HealSize = 2080*shMod+healMod30      end
            end
        else
            -- In combat and target is unhealthy and player has flash heal
            QuickHeal_debug(string.format("In combat and target unhealthy and player has flash heal, will only use FH"));
            if Health < QuickHealVariables.RatioFull then
            SpellID = SpellIDsFH[1]; HealSize = 215*shMod+healMod15; -- Default to FH
            if healneed > (286*shMod+healMod15)*k and ManaLeft >= 155 and maxRankFH >=2 and downRankFH >= 2 then SpellID = SpellIDsFH[2]; HealSize = 286*shMod+healMod15 end
            if healneed > (360*shMod+healMod15)*k and ManaLeft >= 185 and maxRankFH >=3 and downRankFH >= 3 then SpellID = SpellIDsFH[3]; HealSize = 360*shMod+healMod15 end
            if healneed > (439*shMod+healMod15)*k and ManaLeft >= 215 and maxRankFH >=4 and downRankFH >= 4 then SpellID = SpellIDsFH[4]; HealSize = 439*shMod+healMod15 end
            if healneed > (567*shMod+healMod15)*k and ManaLeft >= 265 and maxRankFH >=5 and downRankFH >= 5 then SpellID = SpellIDsFH[5]; HealSize = 567*shMod+healMod15 end
            if healneed > (704*shMod+healMod15)*k and ManaLeft >= 315 and maxRankFH >=6 and downRankFH >= 6 then SpellID = SpellIDsFH[6]; HealSize = 704*shMod+healMod15 end
            if healneed > (885*shMod+healMod15)*k and ManaLeft >= 380 and maxRankFH >=7 and downRankFH >= 7 then SpellID = SpellIDsFH[7]; HealSize = 885*shMod+healMod15 end
            end
        end
    end

    if healType == "hot" then
        QuickHeal_debug(string.format("Spiritual Healing modifier: %f", shMod));
        --SpellID = SpellIDsR[1]; HealSize = 215*shMod+healMod15; -- Default to Renew

        --if Health < QuickHealVariables.RatioFull then
        --if Health > QuickHealVariables.RatioHealthyPriest then
        if not forceMaxHoTRank then
            SpellID = SpellIDsR[1]; HealSize = 45*shMod+healMod15; -- Default to Renew(Rank 1)
            if healneed > (100*shMod+healMod15)*k and ManaLeft >= 155 and maxRankR >=2 then SpellID = SpellIDsR[2]; HealSize = 100*shMod+healMod15 end
            if healneed > (175*shMod+healMod15)*k and ManaLeft >= 185 and maxRankR >=3 then SpellID = SpellIDsR[3]; HealSize = 175*shMod+healMod15 end
            if healneed > (245*shMod+healMod15)*k and ManaLeft >= 215 and maxRankR >=4 then SpellID = SpellIDsR[4]; HealSize = 245*shMod+healMod15 end
            if healneed > (315*shMod+healMod15)*k and ManaLeft >= 265 and maxRankR >=5 then SpellID = SpellIDsR[5]; HealSize = 315*shMod+healMod15 end
            if healneed > (400*shMod+healMod15)*k and ManaLeft >= 315 and maxRankR >=6 then SpellID = SpellIDsR[6]; HealSize = 400*shMod+healMod15 end
            if healneed > (510*shMod+healMod15)*k and ManaLeft >= 380 and maxRankR >=7 then SpellID = SpellIDsR[7]; HealSize = 510*shMod+healMod15 end
            if healneed > (650*shMod+healMod15)*k and ManaLeft >= 455 and maxRankR >=8 then SpellID = SpellIDsR[8]; HealSize = 650*shMod+healMod15 end
            if healneed > (810*shMod+healMod15)*k and ManaLeft >= 545 and maxRankR >=9 then SpellID = SpellIDsR[9]; HealSize = 810*shMod+healMod15 end
            if healneed > (970*shMod+healMod15)*k and ManaLeft >= 655 and maxRankR >=10 then SpellID = SpellIDsR[10]; HealSize = 970*shMod+healMod15 end
        else
            SpellID = SpellIDsR[10]; HealSize = 970*shMod+healMod15
            if maxRankR >=2 then SpellID = SpellIDsR[2]; HealSize = 100*shMod+healMod15 end
            if maxRankR >=3 then SpellID = SpellIDsR[3]; HealSize = 175*shMod+healMod15 end
            if maxRankR >=4 then SpellID = SpellIDsR[4]; HealSize = 245*shMod+healMod15 end
            if maxRankR >=5 then SpellID = SpellIDsR[5]; HealSize = 315*shMod+healMod15 end
            if maxRankR >=6 then SpellID = SpellIDsR[6]; HealSize = 400*shMod+healMod15 end
            if maxRankR >=7 then SpellID = SpellIDsR[7]; HealSize = 510*shMod+healMod15 end
            if maxRankR >=8 then SpellID = SpellIDsR[8]; HealSize = 650*shMod+healMod15 end
            if maxRankR >=9 then SpellID = SpellIDsR[9]; HealSize = 810*shMod+healMod15 end
            if maxRankR >=10 then SpellID = SpellIDsR[10]; HealSize = 970*shMod+healMod15 end
        end
    end


    return SpellID,HealSize*HDB;
end

function QuickHeal_Priest_FindHoTSpellToUse(Target, healType, forceMaxRank)
    local SpellID = nil;
    local HealSize = 0;
    -- Return immediatly if no player needs healing
    if not Target then
        return SpellID,HealSize;
    end

    -- +Healing-PenaltyFactor = (1-((20-LevelLearnt)*0.0375)) for all spells learnt before level 20
    local PF1 = 0.2875;
    local PF4 = 0.4;
    local PF10 = 0.625;
    local PF18 = 0.925;

    -- Determine health and healneed of target
    local healneed;
    local Health;

    if QuickHeal_UnitHasHealthInfo(Target) then
        -- Full info available
        healneed = UnitHealthMax(Target) - UnitHealth(Target) - HealComm:getHeal(UnitName(Target)); -- Implementatin for HealComm
        Health = UnitHealth(Target) / UnitHealthMax(Target);
    else
        -- Estimate target health
        healneed = QuickHeal_EstimateUnitHealNeed(Target,true); -- needs HealComm implementation maybe
        Health = UnitHealth(Target)/100;
    end

    -- if BonusScanner is running, get +Healing bonus
    local Bonus = 0;
    if (BonusScanner) then
        Bonus = tonumber(BonusScanner:GetBonus("HEAL"));
        QuickHeal_debug(string.format("Equipment Healing Bonus: %d", Bonus));
    end

    -- Spiritual Guidance - Increases spell damage and healing by up to 5% (per rank) of your total Spirit.
    local _,_,_,_,talentRank,_ = GetTalentInfo(2,14);
    local _,Spirit,_,_ = UnitStat('player',5);
    local sgMod = Spirit * 5*talentRank/100;
    QuickHeal_debug(string.format("Spiritual Guidance Bonus: %f", sgMod));

    -- Calculate healing bonus
    local healMod15 = (1.5/3.5) * (sgMod + Bonus);
    local healMod20 = (2.0/3.5) * (sgMod + Bonus);
    local healMod25 = (2.5/3.5) * (sgMod + Bonus);
    local healMod30 = (3.0/3.5) * (sgMod + Bonus);
    QuickHeal_debug("Final Healing Bonus (1.5,2.0,2.5,3.0)", healMod15,healMod20,healMod25,healMod30);

    local InCombat = UnitAffectingCombat('player') or UnitAffectingCombat(Target);

    -- Spiritual Healing - Increases healing by 2% per rank on all spells
    local _,_,_,_,talentRank,_ = GetTalentInfo(2,15);
    local shMod = 2*talentRank/100 + 1;
    QuickHeal_debug(string.format("Spiritual Healing modifier: %f", shMod));

    -- Improved Healing - Decreases mana usage by 5% per rank on LH,H and GH
    local _,_,_,_,talentRank,_ = GetTalentInfo(2,10);
    local ihMod = 1 - 5*talentRank/100;
    QuickHeal_debug(string.format("Improved Healing modifier: %f", ihMod));

    local TargetIsHealthy = Health >= QuickHealVariables.RatioHealthyPriest;
    local ManaLeft = UnitMana('player');

    if TargetIsHealthy then
        QuickHeal_debug("Target is healthy",Health);
    end

    -- Detect proc of 'Hand of Edward the Odd' mace (next spell is instant cast)
    if QuickHeal_DetectBuff('player',"Spell_Holy_SearingLight") then
        QuickHeal_debug("BUFF: Hand of Edward the Odd (out of combat healing forced)");
        InCombat = false;
    end

    -- Detect Inner Focus or Spirit of Redemption (hack ManaLeft and healneed)
    if QuickHeal_DetectBuff('player',"Spell_Frost_WindWalkOn",1) or QuickHeal_DetectBuff('player',"Spell_Holy_GreaterHeal") then
        QuickHeal_debug("Inner Focus or Spirit of Redemption active");
        ManaLeft = UnitManaMax('player'); -- Infinite mana
        healneed = 10^6; -- Deliberate overheal (mana is free)
    end

    -- Get total healing modifier (factor) caused by healing target debuffs
    local HDB = QuickHeal_GetHealModifier(Target);
    QuickHeal_debug("Target debuff healing modifier",HDB);
    healneed = healneed/HDB;

    -- Get a list of ranks available for all spells
    local SpellIDsLH = QuickHeal_GetSpellIDs(QUICKHEAL_SPELL_LESSER_HEAL);
    local SpellIDsH  = QuickHeal_GetSpellIDs(QUICKHEAL_SPELL_HEAL);
    local SpellIDsGH = QuickHeal_GetSpellIDs(QUICKHEAL_SPELL_GREATER_HEAL);
    local SpellIDsFH = QuickHeal_GetSpellIDs(QUICKHEAL_SPELL_FLASH_HEAL);
    local SpellIDsR = QuickHeal_GetSpellIDs(QUICKHEAL_SPELL_RENEW);

    local maxRankLH = table.getn(SpellIDsLH);
    local maxRankH  = table.getn(SpellIDsH);
    local maxRankGH = table.getn(SpellIDsGH);
    local maxRankFH = table.getn(SpellIDsFH);
    local maxRankR = table.getn(SpellIDsR);

    QuickHeal_debug(string.format("Found LH up to rank %d, H up top rank %d, GH up to rank %d, FH up to rank %d, and R up to max rank %d", maxRankLH, maxRankH, maxRankGH, maxRankFH, maxRankR));

    --Get max HealRanks that are allowed to be used
    local downRankFH = QuickHealVariables.DownrankValueFH  -- rank for 1.5 sec heals
    local downRankNH = QuickHealVariables.DownrankValueNH -- rank for < 1.5 sec heals

    -- Compensation for health lost during combat
    local k=1.0;
    local K=1.0;
    if InCombat then
        k=0.9;
        K=0.8;
    end

    -- if healType = channel
    jgpprint(healType)

    if healType == "channel" then
        jgpprint("CHANNEL HEAL: " .. healType)
        -- Find suitable SpellID based on the defined criteria
        if not InCombat or TargetIsHealthy or maxRankFH<1 then
            -- Not in combat or target is healthy so use the closest available mana efficient healing
            QuickHeal_debug(string.format("Not in combat or target healthy or no flash heal available, will use closest available LH, H or GH (not FH)"))
            if Health < QuickHealVariables.RatioFull then
                SpellID = SpellIDsLH[1]; HealSize = 53*shMod+healMod15*PF1; -- Default to LH
                if healneed > (  84*shMod+healMod20*PF4) *k and ManaLeft >=  45*ihMod and maxRankLH >=2 and downRankNH >= 2  then SpellID = SpellIDsLH[2]; HealSize =   84*shMod+healMod20*PF4  end
                if healneed > ( 154*shMod+healMod25*PF10)*K and ManaLeft >=  75*ihMod and maxRankLH >=3 and downRankNH >= 3  then SpellID = SpellIDsLH[3]; HealSize =  154*shMod+healMod25*PF10 end
                if healneed > ( 318*shMod+healMod30*PF18)*K and ManaLeft >= 155*ihMod and maxRankH  >=1 and downRankNH >= 4  then SpellID = SpellIDsH[1] ; HealSize =  318*shMod+healMod30*PF18 end
                if healneed > ( 460*shMod+healMod30)*K      and ManaLeft >= 205*ihMod and maxRankH  >=2 and downRankNH >= 5  then SpellID = SpellIDsH[2] ; HealSize =  460*shMod+healMod30      end
                if healneed > ( 604*shMod+healMod30)*K      and ManaLeft >= 255*ihMod and maxRankH  >=3 and downRankNH >= 6  then SpellID = SpellIDsH[3] ; HealSize =  604*shMod+healMod30      end
                if healneed > ( 758*shMod+healMod30)*K      and ManaLeft >= 305*ihMod and maxRankH  >=4 and downRankNH >= 7  then SpellID = SpellIDsH[4] ; HealSize =  758*shMod+healMod30      end
                if healneed > ( 956*shMod+healMod30)*K      and ManaLeft >= 370*ihMod and maxRankGH >=1 and downRankNH >= 8  then SpellID = SpellIDsGH[1]; HealSize =  956*shMod+healMod30      end
                if healneed > (1219*shMod+healMod30)*K      and ManaLeft >= 455*ihMod and maxRankGH >=2 and downRankNH >= 9  then SpellID = SpellIDsGH[2]; HealSize = 1219*shMod+healMod30      end
                if healneed > (1523*shMod+healMod30)*K      and ManaLeft >= 545*ihMod and maxRankGH >=3 and downRankNH >= 10 then SpellID = SpellIDsGH[3]; HealSize = 1523*shMod+healMod30      end
                if healneed > (1902*shMod+healMod30)*K      and ManaLeft >= 655*ihMod and maxRankGH >=4 and downRankNH >= 11 then SpellID = SpellIDsGH[4]; HealSize = 1902*shMod+healMod30      end
                if healneed > (2080*shMod+healMod30)*K      and ManaLeft >= 710*ihMod and maxRankGH >=5 and downRankNH >= 12 then SpellID = SpellIDsGH[5]; HealSize = 2080*shMod+healMod30      end
            end
        else
            -- In combat and target is unhealthy and player has flash heal
            QuickHeal_debug(string.format("In combat and target unhealthy and player has flash heal, will only use FH"));
            if Health < QuickHealVariables.RatioFull then
                SpellID = SpellIDsFH[1]; HealSize = 215*shMod+healMod15; -- Default to FH
                if healneed > (286*shMod+healMod15)*k and ManaLeft >= 155 and maxRankFH >=2 and downRankFH >= 2 then SpellID = SpellIDsFH[2]; HealSize = 286*shMod+healMod15 end
                if healneed > (360*shMod+healMod15)*k and ManaLeft >= 185 and maxRankFH >=3 and downRankFH >= 3 then SpellID = SpellIDsFH[3]; HealSize = 360*shMod+healMod15 end
                if healneed > (439*shMod+healMod15)*k and ManaLeft >= 215 and maxRankFH >=4 and downRankFH >= 4 then SpellID = SpellIDsFH[4]; HealSize = 439*shMod+healMod15 end
                if healneed > (567*shMod+healMod15)*k and ManaLeft >= 265 and maxRankFH >=5 and downRankFH >= 5 then SpellID = SpellIDsFH[5]; HealSize = 567*shMod+healMod15 end
                if healneed > (704*shMod+healMod15)*k and ManaLeft >= 315 and maxRankFH >=6 and downRankFH >= 6 then SpellID = SpellIDsFH[6]; HealSize = 704*shMod+healMod15 end
                if healneed > (885*shMod+healMod15)*k and ManaLeft >= 380 and maxRankFH >=7 and downRankFH >= 7 then SpellID = SpellIDsFH[7]; HealSize = 885*shMod+healMod15 end
            end
        end
    end

    if healType == "hot" then
        QuickHeal_debug(string.format("Spiritual Healing modifier: %f", shMod));
        --SpellID = SpellIDsR[1]; HealSize = 215*shMod+healMod15; -- Default to Renew

        --if Health < QuickHealVariables.RatioFull then
        --if Health > QuickHealVariables.RatioHealthyPriest then
        if not forceMaxRank then
            SpellID = SpellIDsR[1]; HealSize = 45*shMod+healMod15; -- Default to Renew(Rank 1)
            if healneed > (100*shMod+healMod15)*k and ManaLeft >= 155 and maxRankR >=2 then SpellID = SpellIDsR[2]; HealSize = 100*shMod+healMod15 end
            if healneed > (175*shMod+healMod15)*k and ManaLeft >= 185 and maxRankR >=3 then SpellID = SpellIDsR[3]; HealSize = 175*shMod+healMod15 end
            if healneed > (245*shMod+healMod15)*k and ManaLeft >= 215 and maxRankR >=4 then SpellID = SpellIDsR[4]; HealSize = 245*shMod+healMod15 end
            if healneed > (315*shMod+healMod15)*k and ManaLeft >= 265 and maxRankR >=5 then SpellID = SpellIDsR[5]; HealSize = 315*shMod+healMod15 end
            if healneed > (400*shMod+healMod15)*k and ManaLeft >= 315 and maxRankR >=6 then SpellID = SpellIDsR[6]; HealSize = 400*shMod+healMod15 end
            if healneed > (510*shMod+healMod15)*k and ManaLeft >= 380 and maxRankR >=7 then SpellID = SpellIDsR[7]; HealSize = 510*shMod+healMod15 end
            if healneed > (650*shMod+healMod15)*k and ManaLeft >= 455 and maxRankR >=8 then SpellID = SpellIDsR[8]; HealSize = 650*shMod+healMod15 end
            if healneed > (810*shMod+healMod15)*k and ManaLeft >= 545 and maxRankR >=9 then SpellID = SpellIDsR[9]; HealSize = 810*shMod+healMod15 end
            if healneed > (970*shMod+healMod15)*k and ManaLeft >= 655 and maxRankR >=10 then SpellID = SpellIDsR[10]; HealSize = 970*shMod+healMod15 end
        else
            SpellID = SpellIDsR[10]; HealSize = 970*shMod+healMod15
            if maxRankR >=2 then SpellID = SpellIDsR[2]; HealSize = 100*shMod+healMod15 end
            if maxRankR >=3 then SpellID = SpellIDsR[3]; HealSize = 175*shMod+healMod15 end
            if maxRankR >=4 then SpellID = SpellIDsR[4]; HealSize = 245*shMod+healMod15 end
            if maxRankR >=5 then SpellID = SpellIDsR[5]; HealSize = 315*shMod+healMod15 end
            if maxRankR >=6 then SpellID = SpellIDsR[6]; HealSize = 400*shMod+healMod15 end
            if maxRankR >=7 then SpellID = SpellIDsR[7]; HealSize = 510*shMod+healMod15 end
            if maxRankR >=8 then SpellID = SpellIDsR[8]; HealSize = 650*shMod+healMod15 end
            if maxRankR >=9 then SpellID = SpellIDsR[9]; HealSize = 810*shMod+healMod15 end
            if maxRankR >=10 then SpellID = SpellIDsR[10]; HealSize = 970*shMod+healMod15 end
        end
        --end
    end


    return SpellID,HealSize*HDB;
end