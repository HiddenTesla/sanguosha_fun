-- Project:     Qsanguosha::patch::wizard
-- File:        wizard.lua
-- Author:      Erwin <chen90071@163.com>

-- Background:  Some guys designed some interesting generals (in natural language), 
             -- making of former Chinese president, elder.
             -- I think this is doable in Qsanguosha and not hard,
             -- so I implemented these file (not all ready yet)
             -- Due to the sucky censorship, names of the generals are changed to
             -- ancient celebrities

-- Instructions:
            -- In Qsanguosha directory, find the subdirectory "extensions".
            -- Create it if it does not exist.
            -- Put this file under the "extensions" directory.
            -- Please do not modify name of this file.

-- Finding bugs, feel free to tell me

module("extensions.wizard", package.seeall)
extension = sgs.Package("wizard")

-- printf("Coding without vim is painful\n");

--sgs.General(扩展包,姓名,所属势力,体力上限,性别,是否隐藏,是否完全隐藏)

anlushan = sgs.General(extension, "anlushan","wu", 4, true)
mayun = sgs.General(extension, "mayun","wu", 4, true)
jianbi = sgs.General(extension, "jianbi","wu", 3, true)

wizard_qinding = sgs.CreateTriggerSkill{
    name = "wizard_qinding",
    events = {sgs.Damaged, sgs.HpLost},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local turnOver = false
        
        if event == sgs.HpLost then
            turnOver = true        
        -- below judge seems unnecassary, but good for extensibility
        -- if this skill has more triggering events
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            local card = damage.card
            if card:isKindOf("Slash") 
                and not card:isRed() and not card:isBlack() then
                turnOver = true
            end
        end
    
        if turnOver and not player:faceUp() then
            player:turnOver()
        end
        return
    end
}

wizard_lianren = sgs.CreateTriggerSkill{
    name = "wizard_lianren",
    events = {sgs.EventPhaseStart, sgs.PreCardUsed},
    frequency = sgs.Skill_NotFrequent, -- Should this be Skill_Frequent? No reason not to use skill
    on_trigger = function(self, event, player, data)
    --若你于出牌阶段使用了至少一张红色牌，回合结束开始时，你可以进行一个额外的回合。
    -- Divide into two parts:
    -- When in player phase, use any red card will give you a flag.
    -- When in finish phase, check if you have that flag.
    -- If so, you will be prompted whether to get an extra turn.
        if event == sgs.EventPhaseStart then
            local room = player:getRoom()
            
            local phase = player:getPhase()
            if phase == sgs.Player_Finish and player:hasFlag("wizard_useRedCard") then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    --XXX: Must clear the flags, otherwise it will accumulate
                    player:setFlags("-wizard_useRedCard")
                    player:gainAnExtraTurn()
                end
            end
        elseif event == sgs.PreCardUsed then
            local card = data:toCardUse().card
            if card:isRed() then
                player:setFlags("wizard_useRedCard")
            end
        end

    end
}

wizard_guisuo = sgs.CreateMaxCardsSkill
{
    name = "wizard_guisuo",
    extra_func = function(self, target)
        if target:hasSkill(self:objectName()) then
            return 160
        end
    end
}

wizard_taowang = sgs.CreateTriggerSkill {
    name = "wizard_taowang",
    events = {sgs.TargetConfirmed, sgs.PreHpRecover},
    frequency = sgs.Skill_Compulsory, 
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.from:hasSkill(self:objectName()) and 
                    (use.card:isKindOf("Peach") or use.card:isKindOf("GodSalvation")) then
                
                room:setCardFlag(use.card, "wizard_taowang")
            end
        
        elseif event == sgs.PreHpRecover then           
            local rec = data:toRecover()
            if rec.card and rec.card:hasFlag("wizard_taowang") then
                rec.recover = rec.recover + 1
                data:setValue(rec)
            end
        end
        
    end,
    
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}

wizard_taobian = sgs.CreateTriggerSkill {
    name = "wizard_taobian",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent, 
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        
        -- XXX: Misbehaves if multiple players has this skill
        -- Probably because room:findPlayerBySkillName() does not return a single player object
        if use.card:isKindOf("Peach") then
            -- This seems unnecessary as 'jianbi' is always 'player'
            jianbi = room:findPlayerBySkillName(self:objectName())
            
            if not room:askForSkillInvoke(jianbi, self:objectName()) then
                return false
            end
            
            local nullified_list = use.nullified_list
            for _, p in sgs.qlist(use.to) do
                table.insert(nullified_list, p:objectName())
            end
            use.nullified_list = nullified_list
            data:setValue(use)
                
            local judge = sgs.JudgeStruct()
            judge.who = jianbi
            judge.pattern = "."
            judge.good = true
            judge.reason = self:objectName()
            room:judge(judge)
            local from = use.from
            local suit = judge.card:getSuit()
            if suit == sgs.Card_Spade then
                room:loseHp(from, 1)
            elseif suit == sgs.Card_Heart then
                jianbi:obtainCard(use.card)
            elseif suit == sgs.Card_Club then
                room:askForDiscard(from, self:objectName(), 2, 2, false, true)
            elseif suit == sgs.Card_Diamond then
                local beneficiary = room:askForPlayerChosen(jianbi, room:getAlivePlayers(), self:objectName(), "wizard_taobian_draw", true, true)
                if beneficiary then
                    beneficiary:drawCards(2)
                end
            end
        end

    end,
    --[[
    can_trigger = function(self, target)
        return target:isAlive()
    end,
    ]]--
}

wizard_houzhou = sgs.CreateTriggerSkill {
    name = "wizard_houzhou",
    events = {sgs.Death},
    frequency = sgs.Skill_Compulsory, 
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()        
        local death = data:toDeath()
        if death.who:objectName() ~= player:objectName() then
            return false
        end
        
        if not (death.damage and death.damage.from) then
            return false
        end
        
        local murderer = death.damage.from
        room:setPlayerCardLimitation(murderer, "use", "Peach", false)
    end,
    
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}


anlushan:addSkill(wizard_qinding)
anlushan:addSkill(wizard_lianren)

mayun:addSkill(wizard_guisuo)

jianbi:addSkill(wizard_taowang)
jianbi:addSkill(wizard_taobian)
jianbi:addSkill(wizard_houzhou)

sgs.LoadTranslationTable{

    ["wizard"] = "真正的粉丝",

    ["anlushan"] = "安禄山",
    ["#anlushan"] = "连任狂膜",
    ["designer:anlushan"] = "低调哥",
    
    ["wizard_qinding"] = "钦定",
    [":wizard_qinding"] = "<b>锁定技，</b>当你受到无色【杀】的伤害或流失体力后，你将武将牌翻至正面朝上。",
    
    ["wizard_lianren"] = "连任",
    [":wizard_lianren"] = "若你于出牌阶段使用了至少一张红色牌，回合结束开始时，你可以进行一个额外的回合。",
    
    ["mayun"] = "马云",
    ["wizard_guisuo"] = "龟缩",
    [":wizard_guisuo"] = "<b>锁定技，</b>你的手牌无上限",
    
    ["jianbi"] = "坚逼",
    ["#jianbi"] = "见风是雨",
    ["designer:jianbi"] = "果先生",
    ["illustrator:jianbi"] = "低调哥",
    
    ["wizard_taowang"] = "桃王",
    [":wizard_taowang"] = "<b>锁定技，</b>你所使用的【桃】或【桃园结义】回复的体力+1。",
    
    ["wizard_taobian"] = "桃变",
    [":wizard_taobian"] = "每当场上的角色使用【桃】时，你可以令其不能回复一点体力并进行一次判定：\n黑桃：该角色失去1点体力；\n红桃：你获得这张【桃】；\n梅花：该角色须弃置两张牌；\n方块：你可以令一名角色摸两张牌。",    
    ["wizard_taobian_draw"] = "选择一名角色令其摸两张牌",
    
    ["wizard_houzhou"] = "猴咒",
    [":wizard_houzhou"] = "<b>锁定技，</b>杀死你的角色不可使用【桃】。",
}
