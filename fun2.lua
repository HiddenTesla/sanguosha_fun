module("extensions.fun2", package.seeall)
extension = sgs.Package("fun2")

guaitai=sgs.General(extension, "guaitai$","shu", 5, false,true)
BTliubei=sgs.General(extension, "BTliubei$","shu", 5, true)
BTsunquan=sgs.General(extension, "BTsunquan$","wu", 4, true)
lingxi=sgs.General(extension, "lingxi","wu", 3, false, true)

mashu2 = sgs.CreateDistanceSkill{
    name = "mashu2",
    correct_func = function(self, from, to)
        if from:hasSkill("mashu2") then
            return -6
        end
    end,
}

shihun = sgs.CreateTriggerSkill{
    name = "shihun", 
    frequency = sgs.Skill_Compulsory, 
    events = {sgs.EventPhaseStart, sgs.Damaged},
    on_trigger = function (self, event, player, data)
        if player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish or event==sgs.Damaged then
            local room = player:getRoom()
            local x=player:getLostHp()
            if x<1 then x=1 end
            x=1                    
            local targets = room:getAlivePlayers()
            local dest = room:askForPlayerChosen(player,targets,self:objectName())
            if not dest then return end
            local choices =  {"shihun_add+shihun_deduct"}
            local result = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
            if result=="shihun_deduct" then
                if dest:getMaxHp()>1 then
                    room:loseMaxHp(dest,x)
                else
                    local source=room:askForPlayerChosen(player,targets,"shihun_askForSource")
                    local theDamage=sgs.DamageStruct()
                    theDamage.damage=1
                    theDamage.from=source
                    theDamage.to=dest
                    room:damage(theDamage)                    
                end
            else    
                room:loseMaxHp(dest,-x)
            end                        
        end
    end,
}

wuni = sgs.CreateTargetModSkill{
    name = "wuni",
    pattern = "Slash",
    residue_func = function(self, player)
        if player:hasSkill(self:objectName()) then
            return 1000        
        end
    end,    
    distance_limit_func = function(self, from, card)
        if from:hasSkill(self:objectName()) and (card:isBlack()) then
            return 1000
        else
            return 0
        end
    end,    
    extra_target_func = function(self, from, card)
        if from:hasSkill(self:objectName()) and (card:isBlack()) then
            return 8
        else
            return 0
        end
    end
}
tonggui = sgs.CreateTriggerSkill{
    name = "tonggui" ,
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_NotFrequent, 
    on_trigger = function(self, event, player, data)
        local use = data:toCardUse()
        local room=player:getRoom()
        local source=use.from
        if use.card:isKindOf("Slash")  and use.to:contains(player) then
            if player:getHp()<=1 or source:getMaxHp()<=1 then return end
            if room:askForSkillInvoke(player,self:objectName(),data) then 
                room:loseHp(player,1)
                room:loseMaxHp(source,1)
            end
        
        end
        return false
    end
}

zuzhou = sgs.CreateTriggerSkill{
    name = "zuzhou", 
    frequency = sgs.Skill_NotFrequent, 
    events = {sgs.Death}, 
    
    on_trigger = function(self, event, player, data) 
        local room=player:getRoom()
        local source=room:findPlayerBySkillName(self:objectName())
        if not source then return end
        local victim = room:askForPlayerChosen(source,room:getOtherPlayers(source),self:objectName(),"",true,true)
        local one=sgs.QVariant()
        one:setValue(1)
        room:setPlayerProperty(victim,"maxhp",one)
    end, 
    
    can_trigger = function(self, target)
        return target
    end, 

}

xunjie = sgs.CreateTriggerSkill{
    name = "xunjie", 
    frequency = sgs.Skill_Compulsory, 
    events = {sgs.CardAsked}, 
    
    on_trigger = function(self, event, player, data) 
        local room=player:getRoom()

        local pattern=data:toString()
        if pattern=="jink" then
            room:loseHp(player,-1)
        end
    end,         
}

xinchun = sgs.CreateTriggerSkill{
    name = "xinchun", --必须 
    frequency = sgs.Skill_Compulsory, 
    events = {sgs.Dying}, 
    on_trigger = function(self, event, player, data) --必须
        local room=player:getRoom()
        local dying = data:toDying()
        local dyer = dying.who
        local triggerred
        local r1=player:getRole()
        local r2=dyer:getRole()
        local count = room:alivePlayerCount()
        triggerred = (r1==r2) or (r1=="lord" and r2=="loyalist") or (r2=="lord" and r1=="loyalist") or (r1=="renegade" and r2=="lord" and count>=3)
                
        if triggerred then
            local theRecover=sgs.RecoverStruct()
            theRecover.recover=1-dyer:getHp()        
            room:broadcastSkillInvoke(self:objectName())
            room:recover(dyer,theRecover)
        end
    end, 
     
}

dianshen = sgs.CreateFilterSkill{
    name = "dianshen",
    view_filter = function(self, to_select)
        local room = sgs.Sanguosha:currentRoom()
        local place = room:getCardPlace(to_select:getEffectiveId())
        return place == sgs.Player_PlaceHand
                
    end,
    
    view_as = function(self, card)
        local id = card:getId()
        local suit = card:getSuit()
        local point = card:getNumber()
        local chain = sgs.Sanguosha:cloneCard("lightning", suit, point)
        chain:setSkillName(self:objectName())
        local vs_card = sgs.Sanguosha:getWrappedCard(id)
        vs_card:takeOver(chain)
        return vs_card
    end,
}

heixin = sgs.CreateTriggerSkill{
    name = "heixin",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.SlashEffected},
    on_trigger = function(self, event, player, data)
        local effect = data:toSlashEffect()
        -- if effect.slash:getSuit() ~= sgs.Card_Spade or effect.slash:getNumber()%3~=0 then        
        if effect.slash:isRed() or effect.slash:getNumber()%3~=0 then        
            player:getRoom():notifySkillInvoked(player, self:objectName())
            return true
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil and target:isAlive() and target:hasSkill(self:objectName()) --and (target:getArmor() == nil)
    end
}

chaoyuanCard = sgs.CreateSkillCard{
    name = "chaoyuanCard", 
    target_fixed = false, 
    will_throw = true, 
    filter = function(self, targets, to_select) 
        if #targets>=4 then return false end
        if not to_select:isWounded() then return false end --只能对已受伤的角色使用
        -- local count = self:subcardsLength()
        -- if count<=1 then return false
        -- elseif count==2 then return #targets<=1 
        -- else return count>=#targets+1 end
        return #targets<4
    end,
    feasible = function(self, targets)
        local count = self:subcardsLength()
        if #targets==0 then return false
        elseif #targets==1 then return count==2 --如果只选一名角色，需2张牌
        else return #targets==count --如果选择X名角色(X>=2)，需X张牌
        end
    end,
    on_effect = function(self, effect)
        local room=effect.from:getRoom()
        local theRecover=sgs.RecoverStruct()
        theRecover.recover=1
        theRecover.who=effect.from
        room:recover(effect.to, theRecover)
        --room:recover(effect.from, theRecover)
    end,    
}

chaoyuan = sgs.CreateViewAsSkill{
    name = "chaoyuan", --必须
    n = 4, --必须
    view_filter = function(self, selected, to_select)
        if to_select:isEquipped() then return false end
        if #selected==0 then return true
        elseif #selected==1 then return to_select:isRed()~=selected[1]:isRed()
        elseif #selected==2 then return to_select:getSuit()~=selected[1]:getSuit() and to_select:getSuit()~=selected[2]:getSuit() 
        elseif #selected==3 then return to_select:getSuit()~=selected[1]:getSuit() and to_select:getSuit()~=selected[2]:getSuit() and to_select:getSuit()~=selected[3]:getSuit() 
        end
    end,     
    view_as = function(self, cards) --必须
        local card = chaoyuanCard:clone()
        for _, c in ipairs(cards) do
               card:addSubcard(c)
        end
           return card
    end, 
    enabled_at_play = function(self, player)
        return not player:hasUsed ("#chaoyuanCard")
    end,     
}

shenyou=sgs.CreateTriggerSkill{
    name="shenyou",
    frequency=sgs.Skill_Compulsory,
    events={sgs.DamageInflicted},
    on_trigger=function(self,event,player,data)
        local room=player:getRoom()
        local damage=data:toDamage()
        if damage.damage>1 then
            damage.damage=1
            data:setValue(damage)
            local log= sgs.LogMessage()
            log.type = "#TriggerSkill"
            log.from = player
            log.arg  = self:objectName()
            room:sendLog(log)
            room:broadcastSkillInvoke(self:objectName())
        end
    end,
}
function getCardList(intlist)
    local ids = sgs.CardList()
    for _, id in sgs.qlist(intlist) do
        ids:append(sgs.Sanguosha:getCard(id))
    end
    return ids
end
wuqi = sgs.CreateTriggerSkill{
    name = "wuqi",
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, shenlvmeng, data)
        if shenlvmeng:getPhase() ~= sgs.Player_Draw then
            return false
        end
        local room = shenlvmeng:getRoom()
        if not shenlvmeng:askForSkillInvoke(self:objectName()) then
            return false
        end
        local card_ids = room:getNCards(5)
        room:fillAG(card_ids)
        local to_get = sgs.IntList()
        local to_throw = sgs.IntList()
        while not card_ids:isEmpty() do
            local card_id = room:askForAG(shenlvmeng, card_ids, false, "shelie")
            card_ids:removeOne(card_id)
            to_get:append(card_id)--弃置剩余所有符合花色的牌(原文：throw the rest cards that matches the same suit)
            local card = sgs.Sanguosha:getCard(card_id)
            local suit = card:getSuit()
            room:takeAG(shenlvmeng, card_id, false)
            local _card_ids = card_ids
            for _,id in sgs.qlist(_card_ids) do
                local c = sgs.Sanguosha:getCard(id)
                if c:getSuit() == suit then
                    card_ids:removeOne(id)
                    room:takeAG(nil, id, false)
                    to_throw:append(id)
                end
            end
        end
        local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        if not to_get:isEmpty() then
            dummy:addSubcards(getCardList(to_get))
            shenlvmeng:obtainCard(dummy)
        end
        dummy:clearSubcards()
        if not to_throw:isEmpty() then
            dummy:addSubcards(getCardList(to_throw))
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, shenlvmeng:objectName(), self:objectName(),"")
            room:throwCard(dummy, reason, nil)
        end
        dummy:deleteLater()
        room:clearAG()
        return true
    end
}

langfeiCard = sgs.CreateSkillCard{
    name = "langfeiCard", --必须
    target_fixed = false,
    filter = function(self, targets, to_select) 
        return #targets==0 and to_select:objectName()~=sgs.Self:objectName()
    end,
    will_throw = true, 
    on_use = function(self, room, source, targets) --几乎必须
        --room:loseHp(source)
        local victim=targets[1]
        local judge = sgs.JudgeStruct()
        judge.pattern = ".|spade,heart|."
        judge.good = true
        judge.reason = self:objectName()
        judge.who = victim
        room:judge(judge)
        if judge:isGood() then
            local theDamage=sgs.DamageStruct()
            theDamage.damage=3
            if judge.card:getSuit()==sgs.Card_Spade then theDamage.nature=sgs.DamageStruct_Thunder
            else theDamage.nature=sgs.DamageStruct_Fire end
            theDamage.from=source
            theDamage.to=victim
            theDamage.card=nil
            room:damage(theDamage)
        else
            local theRecover=sgs.RecoverStruct()
            theRecover.recover=1
            theRecover.who=source
            room:recover(source,theRecover)
            room:drawCards(source,3)
        end
        
    end,
}

langfei = sgs.CreateViewAsSkill{
    name = "lengfei", --必须
    n = 0, --必须
    view_as = function(self, cards) --必须
        local card=langfeiCard:clone()
        return card
    end, 
    enabled_at_play = function(self, player)
        return not player:hasUsed("#langfeiCard")
    end, 
    
}

fanshi = sgs.CreateTriggerSkill{
    name = "fanshi",
    frequency = sgs.Skill_NotFrequent, 
    events = {sgs.Damaged}, 
    on_trigger = function(self, event, player, data) 
        local damage=data:toDamage()
        if damage.from:objectName() == player:objectName() then return end
        if player:askForSkillInvoke(self:objectName()) then
            local theDamage=sgs.DamageStruct()
            theDamage.damage=damage.damage*2
            theDamage.nature=damage.nature
            theDamage.from=player
            theDamage.to=damage.from
            local room=player:getRoom()
            room:damage(theDamage)
        end
    end, 
}

bengtuiMod = sgs.CreateMaxCardsSkill{
    name = "#bengtuiMod",
    extra_func = function(self, target) 
        return -target:getMark("@yeyan")
    end
}

bengtui = sgs.CreateTriggerSkill{
    name = "bengtui",
    frequency = sgs.Skill_Compulsory, 
    events = {sgs.DamageInflicted}, 
    on_trigger = function(self, event, player, data) 
        local damage=data:toDamage()
        local from=damage.from
        if from:objectName() == player:objectName() then return end
        --if player:askForSkillInvoke(self:objectName()) then
            local room=player:getRoom()
            if not from:hasSkill("#bengtuiMod") then room:acquireSkill(from, "#bengtuiMod") end
            
            local waste=from:getMark("@yeyan")+damage.damage*2-from:getMaxHp()
            if waste>0 then room:loseHp(from, waste)
            from:gainMark("@yeyan",damage.damage*2-waste)
            else from:gainMark("@yeyan",damage.damage*2) end
        --end
    end, 
}

chujian = sgs.CreateTriggerSkill{
    name = "chujian",
    frequency = sgs.Skill_Compulsory, 
    events = {sgs.DamageInflicted}, 
    on_trigger = function(self, event, player, data) 
        local damage=data:toDamage()
        local from=damage.from
        local room=player:getRoom()
        if from:getRole()=="renegade" and from:objectName() ~= player:objectName() then room:killPlayer(from) end        
    end, 
}

yongyi = sgs.CreateTriggerSkill{
    name = "yongyi", --必须 
    frequency = sgs.Skill_Limited, 
    events = {sgs.TurnStart}, 
    on_trigger = function(self, event, player, data) --必须
        local room=player:getRoom()
        if not player:isKongcheng() then 
            local card=room:askForCard(player, ".|black|2,3,4,5,6,7,8,9,10,J", "Please throw a black card", data)
            if card then
                room:throwCard(card,player)
                player:drawCards(card:getNumber())
            end
        end
    end, 
}


jile = sgs.CreateFilterSkill{
    name = "jile",
    view_filter = function(self, to_select)
        local room = sgs.Sanguosha:currentRoom()
        local place = room:getCardPlace(to_select:getEffectiveId())
        -- return place == sgs.Player_PlaceHand 
            -- and (to_select:isKindOf ("SupplyShortage") or to_select:isKindOf("Axe") or to_select:isKindOf("Nullification")) 
            return true
    end,    
    view_as = function(self, originalCard)
        local slash = sgs.Sanguosha:cloneCard("peach", originalCard:getSuit(), originalCard:getNumber())
        slash:setSkillName(self:objectName())
        local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
        card:takeOver(slash)
        return card
    end,
}

bayeBT = sgs.CreateTriggerSkill{
    name = "bayeBT",
    events = {sgs.TargetConfirmed, sgs.EventPhaseStart, sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory, 
    on_trigger = function(self, event, player, data)
        local room=player:getRoom()
        if event == sgs.TargetConfirmed then 
            local use = data:toCardUse()
            local source=use.from
            local skill1="wushen"
            local skill2="wumou"
            if (use.card:isKindOf("Indulgence") or use.card:isKindOf("Slash")) and use.to:contains(player) then
                if source:hasSkill ("benghuai") then                    
                    --source:throwAllHandCardsAndEquips()
                    -- if source:getHp()>1 then
                        -- room:loseHp(source,1)
                    -- end
                    room:setPlayerProperty(source,"maxhp", sgs.QVariant(1))
                elseif source:hasSkill ("wumou") then
                    room:acquireSkill (source, "benghuai")
                    room:setPlayerProperty (source, "maxhp", sgs.QVariant(source:getMaxHp()*2))
                    room:setPlayerProperty (source, "hp", sgs.QVariant(source:getMaxHp()))
                elseif source:hasSkill (skill1) then
                    room:acquireSkill(source,skill2)
                else
                    local skill_list = source:getVisibleSkillList()
                    for _,skill in sgs.qlist(skill_list) do
                        room:detachSkillFromPlayer(source, skill:objectName())
                    end
                    room:changeHero(source, "yujin", false,true,false,true)
                    room:setPlayerProperty (source, "maxhp", sgs.QVariant(source:getMaxHp()+2))                        
                    room:setPlayerProperty (source, "hp", sgs.QVariant(source:getMaxHp()-2))
                    room:acquireSkill(source,"wushen")
                    room:acquireSkill(source,"mashu")
                    room:acquireSkill(source,"kuanggu")
                    room:acquireSkill(source,self:objectName())
                end
            end
            if (player:objectName() == use.from:objectName() and use.card:isKindOf("Slash")) then
                for _, p in sgs.qlist(use.to) do
                    local armor=p:getArmor()
                    if armor then 
                        room:throwCard (armor, p)
                    end
                end
            end                
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                for _,c in sgs.qlist(player:getJudgingArea()) do
                    if c:isKindOf("Indulgence") then
                        room:obtainCard(player, c)
                    end
                end
            end
        elseif event == sgs.DamageInflicted then
            local damage=data:toDamage()
            local card=damage.card
            if card:isKindOf ("Lightning") then
                room:obtainCard (player, card)
                return true
            end                    
        end
    end
}

chengjieCard = sgs.CreateSkillCard{
    name = "chengjieCard",
    target_fixed = false, 
    will_throw = false, 
    filter = function(self, targets, to_select) 
        return to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect) 
        local room=effect.from:getRoom()
        room:obtainCard(effect.to, self, false)
        if effect.to:hasSkill ("juyi") or effect.to:hasSkill("zhenlie") then
            room:changeHero(effect.to, "sphuaxiong",true)
        end
        room:loseMaxHp(effect.from, 1+effect.from:getMaxHp()/67)
    end
}

chengjie = sgs.CreateViewAsSkill{
    name = "chengjie",
    n = 1, 
    view_filter = function(self, selected, to_select)
        if #selected>0 then return false end
        return to_select:isKindOf("Indulgence") or to_select:isKindOf("SupplyShortage") or to_select:isKindOf("Lightning")
    end, 
    view_as = function(self, cards)
        if #cards==0 then return nil end
        local card=chengjieCard:clone()
        card:addSubcard(cards[1])
        return card
    end, 
    enabled_at_play = function(self, player)
        return not player:hasUsed("#chengjieCard")
        -- return true
    end, 
}

dutao = sgs.CreateTriggerSkill {
    name = "dutao",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        local card = use.card

        if player:getRole() ~= "renegade" then
            return false
        end
        if not card:isKindOf("Peach") then
            return false
        end

        local isRebel = false
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getRole() == "rebel" and p:hasSkill(self:objectName()) then
                isRebel = true
            end
        end
        if not isRebel then 
            return false
        end
        
        for _, target in sgs.qlist(use.to) do
            room:loseMaxHp(target, 1)
        end
        room:killPlayer(player)
        
        return true        
    end,

    can_trigger = function(self, target)
        return target:isAlive()
    end
}

guzong_extra = sgs.CreateMaxCardsSkill {
    name = "#guzong_extra",
    extra_func = function(self, target)
        local extra = target:getMark("@guzong") / 3
        return math.floor(extra)
    end
}

guzong_residue = sgs.CreateTargetModSkill {
    name = "#guzong_residue",
    frequency = sgs.Skill_NotFrequent,
    pattern = "Slash",
    residue_func = function(self, player)
        local extra = player:getMark("@guzong") / 3
        return math.floor(extra)
    end
}

guzong = sgs.CreateTriggerSkill {
    name = "guzong",
    events = {sgs.CardsMoveOneTime, sgs.DrawNCards},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            local discarded = move.card_ids:length()
            if player:getPhase() == sgs.Player_Discard and
                move.from and 
                move.from:objectName() == player:objectName() and 
                (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD)
            then
                player:gainMark("@guzong", discarded)
            end
        elseif event == sgs.DrawNCards then
            local extra = 1 + math.floor(player:getMark("@guzong") / 3)
            local count = data:toInt() + extra
            data:setValue(count)
        end
    end
}

luoxiu = sgs.CreatePhaseChangeSkill {
    name = "luoxiu",
    frequency = sgs.Skill_Compulsory,
    on_phasechange = function(self, player)
        local room = player:getRoom()
        local phase = player:getPhase()
        if phase == sgs.Player_Start then
            for _, jcard in sgs.qlist(player:getJudgingArea()) do
                room:obtainCard(player, jcard)
            end
        elseif phase == sgs.Player_Finish then
            player:drawCards(1)
        end
    end,

    can_trigger = function(self, target)
        return target and 
            target:isAlive() and 
            target:hasSkill(self:objectName()) and 
           (target:getPhase() == sgs.Player_Start or target:getPhase() == sgs.Player_Finish)
    end
}

heice = sgs.CreateViewAsSkill {
    name = "heice",
    n = 1,
    view_filter = function(self, selected, to_select)
        if #selected == 0 then
            return to_select:getSuit() == sgs.Card_Spade
        else
            return false
        end
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local cardA = cards[1]
            local suit = cardA:getSuit()
            local aa = sgs.Sanguosha:cloneCard("god_salvation", suit, 0);
            aa:addSubcard(cardA)
            aa:setSkillName(self:objectName())
            return aa
        end
    end
}

yongzhi = sgs.CreateTriggerSkill {
    name = "yongzhi",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.AskForPeaches, sgs.FinishJudge},

    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.AskForPeaches then
            local dying = data:toDying()
            local dyer = dying.who
            local role = dyer:getRole()
            if role ~= "lord" then
                return false
            end

            local aliveLoyal = false
            local playerList = room:getAlivePlayers()
            for _, p in sgs.qlist(playerList) do
                if p:getRole() == "loyalist"
                        and not p:hasSkill("guixin")
                        and not p:hasSkill("wuhun")
                then
                    aliveLoyal = true
                    break
                end
            end

            if not aliveLoyal then
                return false
            end

            local lord = dyer
            local maxHp = sgs.QVariant(lord:getMaxHp() + 1)
            room:setPlayerProperty(lord, "maxhp", maxHp)
            room:setPlayerProperty(lord, "hp", maxHp)
            return true
        elseif event == sgs.FinishJudge then
            local theJudge = data:toJudge()
            local badGuy = theJudge.who
            local role = badGuy:getRole()
            if role ~= "lord" and role ~= "loyalist" then
                return false
            end

            local judgeCard = theJudge.card
            local suit = judgeCard:getSuit()
            if suit == sgs.Card_Spade then
                local maxHp = sgs.QVariant(badGuy:getMaxHp() + 1)
                room:setPlayerProperty(badGuy, "maxhp", maxHp)
            elseif suit == sgs.Card_Heart then
                room:loseMaxHp(badGuy, 2)
            elseif suit == sgs.Card_Diamond then
                room:loseMaxHp(badGuy, 1)
            end
        end
    end,

    can_trigger = function(self, target)
        return true and target:isAlive()
    end,
}

guaitai:addSkill(heixin)
--guaitai:addSkill(yongyi)

BTliubei:addSkill("nosrende")
BTliubei:addSkill("yingzi")
BTliubei:addSkill("jijiang")

BTsunquan:addSkill(guzong)
BTsunquan:addSkill(guzong_extra)
BTsunquan:addSkill(guzong_residue)
BTsunquan:addSkill(yongzhi)
BTsunquan:addSkill(luoxiu)
BTsunquan:addSkill("zhiheng")
BTsunquan:addSkill(heice)


lingxi:addSkill(chaoyuan)
lingxi:addSkill(shenyou)
lingxi:addSkill(wuqi)

sgs.LoadTranslationTable{
    ["fun2"]="娱乐2",
        
    ["guaitai"]="怪胎",
    ["designer:guaitai"]="寒星不察",
    ["shihun"]="噬魂",
    [":shihun"]="你受到伤害后或回合开始/结束阶段，你可以令一名角色增加或失去1点体力上限。",
    ["shihun_add"]="增加1点体力上限",
    ["shihun_deduct"]="失去1点体力上限",
    [":tonggui"]="当你成为【杀】的目标后，你可以失去1点体力，令使用者失去1点体力上限。",
    ["BTliubei"]="刘备",

    ["wuni"]="武逆",
    ["BTsunquan"]="会英姿的孙权",
    ["#BTsunquan"]="年轻的暴君",
    ["zuzhou"]="诅咒",
    ["heixin"]="黑心",
    [":heixin"]="<b>锁定技，</b>红色的以及点数不是3的倍数的【杀】对你无效。",    
    ["xinchun"]="信春",
    [":xinchun"]="<b>锁定技，</b>与你同一阵营的一名角色进入濒死状态时，该角色回复至1点体力。",
    ["baye"]="霸业",
    
    ["bengtui"]="崩退",
    [":bengtui"]="<b>锁定技，</b>你每受到其他角色的1点伤害时，令伤害源获得1个夜魇标记。每个夜魇标记令手牌上限-1。",
    
    ["lingxi"]="灵犀",
    ["#lingxi"]="惜相怜",
    ["chaoyuan"]="朝元",
    [":chaoyuan"]="出牌阶段限一次，你可以弃掉X张花色各不相同的手牌（至少两张且包含一红一黑），令至多X名角色与你各回复1点体力。",
    ["shenyou"]="神佑",
    [":shenyou"]="<b>锁定技，</b>你每次受到伤害时，最多承受1点伤害。",
    ["wuqi"]="五气",
    [":wuqi"]="摸牌阶段开始时，你可以放弃摸牌并亮出牌堆顶的五张牌。若如此做，你获得其中每种花色的牌各一张，然后将其余的牌置入弃牌堆。",
    ["chengjie"]="惩戒",
    [":chengjie"]="阶段技，你可以令任意数量的其他角o色变身为YJ华雄，然后你失去3点一半体力。",
    ["dutao"] = "毒桃",
    [":dutao"] = "<b>反贼技，锁定技，</b>每当内奸对一名角色使用【桃】时，该【桃】无效，该角色失去1点体力上限且该内奸立即死亡。",
    ["guzong"] = "故纵",    
    [":guzong"] = "<b>锁定技，</b>你于弃牌阶段每弃掉一张牌，你获得1个故纵标记。摸牌阶段，你额外摸X/3张牌，你的手牌上限+X/3。出牌阶段你可以额外使用X/3张【杀】（向下取整；X为故纵标记的数量）。",
    ["luoxiu"] = "罗修",
    [":luoxiu"] = "<b>锁定技，</b>准备阶段开始时，你获得判定区内所有牌。", 
    ["heice"] = "黑策",
    [":heice"] = "出牌阶段，你可以将任意一张黑桃牌当【桃园结义】使用。",

    ["yongzhi"] = "拥谪",
    [":yongzhi"] = "<b>锁定技，</b>当主公进入濒死状态时，若有忠臣存活，则主公增加1点体力上限并将体力值回复至体力上限。当主忠的红色判定牌生效后，将有好事发生。",
}
