-- 本文件最初创作于2015年3月，2016年11月托管于github。
-- 初创时作者还不是专业码农，不懂版本控制，因此有一些注释掉的代码。
-- 由于历史原因，本文件的风格较混乱：空格与制表符混用，CRLF与LF混用。
-- 2018年4月起新增代码将统一使用空格与LF。
-- 以上注释写于2018-04-06。

module("extensions.fun", package.seeall)
extension = sgs.Package("fun")

jiangzhongzheng=sgs.General(extension, "jiangzhongzheng","god",4,true,true)
maorunzhi=sgs.General(extension, "maorunzhi","god",4,true,true)
sphuanggai=sgs.General(extension, "sphuanggai","wu",10)
shenhuatuo=sgs.General(extension, "shenhuatuo","god", 3, true, true)
spguojia=sgs.General(extension, "spguojia","god", 30, true, true)
spdongzhuo=sgs.General(extension, "spdongzhuo$","qun", 8)
anu=sgs.General(extension, "anu","shu", 3, false)




dawujia=sgs.CreateTriggerSkill{
	name="#dawujia",
	frequency=sgs.Skill_Compulsory,
	events={sgs.DamageInflicted},
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		if (damage.nature==sgs.DamageStruct_Fire or damage.nature==sgs.DamageStruct_Normal) then
			local log= sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg  = self:objectName()
			room:sendLog(log)
			room:broadcastSkillInvoke(self:objectName())
			return true
		end

		--以下为雷电伤害+1

		if damage.nature==sgs.DamageStruct_Thunder then
			local hurt=damage.damage
			damage.damage=hurt+1
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

qimen = sgs.CreateMaxCardsSkill{
	name = "#qimen", --必须
	extra_func = function(self, target) --必须
		if target:hasSkill("#qimen") then
			return 160
		else
			return 0
		end
	end
}

tiewan=sgs.CreateTriggerSkill{
	name="tiewan",
	frequency=sgs.Skill_Frequent,
	events={sgs.DrawNCards, sgs.EventPhaseStart, sgs.Damage},
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event == sgs.DrawNCards then
			if not room:askForSkillInvoke(player,self:objectName(),data) then return false end
			room:setPlayerFlag(player, "tiewan_used")
			local count=data:toInt()+6
			data:setValue(count)
		elseif event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Finish and player:hasFlag("tiewan_used") then
				room:askForDiscard (player, self:objectName(), 1,1, false, true)
			end
		elseif event == sgs.Damage then
			local damage=data:toDamage()
			alive=damage.to:isAlive()
			for i=1, damage.damage,1 do
				if alive then
					player:drawCards(1)
				end
				if player:isWounded() then
					local recover=sgs.RecoverStruct()
					recover.recover=1
					recover.who=player
					room:recover(player,recover)
				else
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp()+1))
				end
			end
		end
	end,
}

--[[
taoxian=sgs.CreateFilterSkill{
	name="taoxian",
	view_filter=function(self, to_select)
		local suit=to_select:getSuit()
		return suit==sgs.Card_Heart
	end,
	view_as=function(self,card)
		local id=card:getId()
		local suit=card:getSuit()
		local point=card:getNumber()
		local peach=sgs.Sanguosha:cloneCard("peach",suit,point)
		peach:setSkillName("taoxian")
		local vs_card=sgs.Sanguosha:getWrappedCard(id)
		vs_card:takeOver(peach)
		return vs_card
	end,
}

--]]

BTqianxun = sgs.CreateProhibitSkill{
	name = "#BTqianxun", --必须
	is_prohibited = function(self, from, to, card) --必须
		return to:hasSkill(self:objectName()) and (card:isKindOf("Snatch") or card:isKindOf("Indulgence"))
		--return to:hasSkill(self:objectName()) and (card:isKindOf("Snatch") or card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage"))
	end
}

function isFriend(p1, p2)
    return getHouse(p1) == getHouse(p2)
end

function getHouse(player)
    local role = player:getRole()
    if role == "lord" or role == "loyalist" then
        return "lord"
    elseif role == "renegade" then
        return "renegade"
    else
        return "rebel"
    end
end

changsheng=sgs.CreateTriggerSkill{
	name = "changsheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.TurnStart, sgs.CardEffected, sgs.Damaged},
	on_trigger = function (self, event, player, data)
		local room = player:getRoom()
        
        if event == sgs.GameStart then               
            for _, current in sgs.qlist(room:getOtherPlayers(player)) do
                local skillName = self:objectName()
                if isFriend(current, player) then
                    if not current:hasSkill(skillName) then
                        room:attachSkillToPlayer(current, skillName)
                    end
                else
                    local key = current:objectName() .. "_changsheng"
                    local currentTag = room:getTag(key)
                    if currentTag == nil or currentTag:toInt() <= 0 then
                        room:setTag(key, sgs.QVariant(1))
                        local friends = 1
                        for _, ppp in sgs.qlist(room:getOtherPlayers(current)) do
                            if isFriend(ppp, current) then
                                friends = friends + 1
                            end
                        end
                        room:setPlayerProperty(current, "maxhp", sgs.QVariant(current:getMaxHp() + 2 * friends))
                        room:setPlayerProperty(current, "hp", sgs.QVariant(current:getMaxHp()))
                    else
                       local value = currentTag:toInt()
                       room:setTag(key, sgs.QVariant(value + 1))
                    end
                end
            end
        elseif event == sgs.TurnStart then
            local mhp = sgs.QVariant()
            local count = player:getMaxHp()
            local hp = player:getHp()

            player:drawCards(1)
            if (hp == count) then
                mhp:setValue(count + 1)
                room:setPlayerProperty(player, "maxhp", mhp)
            else
                local theRecover = sgs.RecoverStruct()
                theRecover.recover = 1
                theRecover.who = player
                room:recover(player, theRecover)
            end
        elseif event == sgs.CardEffected then
            local effect = data:toCardEffect()
            local card = effect.card
            if card:isKindOf("SavageAssault") or card:isKindOf("ArcheryAttack") then
                return true
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            local from = damage.from
            if not isFriend(from, player) then
                room:loseMaxHp(from, 1)
            end
		end
	end,
}

xiusheng=sgs.CreateTriggerSkill{
	name = "#xiusheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.EventPhaseStart},
	on_trigger = function (self, event, player, data)
		if event == sgs.GameStart then
			local chp=sgs.QVariant()
			local room=player:getRoom()
			local hp=player:getHp()
			local toLose=hp-2
			room:loseHp(player,toLose)
			room:sendLog()
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish then
				local room = player:getRoom()
				local theRecover=sgs.RecoverStruct()
				hp=player:getHp()
				if (hp<=3) then
					theRecover.recover=2
				else
					theRecover.recover=1
				end
				theRecover.who=player
				room:recover(player,theRecover)
			end
		end
	end,
}

xiusheng_initial = sgs.CreateTriggerSkill{
	name = "#xiusheng_initial", --必须
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart}, --必须
	on_trigger = function(self, event, player, data) --必须
		local chp=sgs.QVariant()
		local room=player:getRoom()
		local hp=player:getHp()
		--local maxHp=player:getMaxHp()
		local toLose=hp-2

			room:loseHp(player,toLose)
			room:sendLog()

	end,
}

xunjie = sgs.CreateDistanceSkill{
	name = "#xunjie", --必须
	correct_func = function(self, from, to) --必须
		if (from:hasSkill("#xunjie")) then
			return -6
		end
	end
}

lanman=sgs.CreateTriggerSkill{
	name="lanman",
	frequency=sgs.Skill_Compulsory,
	events={sgs.DamageInflicted},
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		if damage.nature==sgs.DamageStruct_Fire then
			local log= sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg  = self:objectName()

			room:drawCards(player,damage.damage,self:objectName())

			local theRecover=sgs.RecoverStruct()
			theRecover.recover=damage.damage
			room:recover(player,theRecover)

			room:sendLog(log)
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
	end,
}

taoxian = sgs.CreateViewAsSkill{
--创建技能，技能种类为ViewAsSkill。这里的技能是“你可以将任意一张牌当作桃使用。”
	name = "taoxian",
	n = 1,
	view_filter = function(self, selected, to_select)
		--return to_select:getSuit() == sgs.Card_Club and not to_select:isEquipped()
		return true
	end,

	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local new_card =sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
			new_card:addSubcard(card:getId())
			new_card:setSkillName(self:objectName())
			return new_card
		end
	end,

	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "peach")
	end
	}


qingdangCard = sgs.CreateSkillCard{
	name = "qingdangCard", --必须
	target_fixed = false, --必须
	will_throw = true, --必须
	filter = function(self, targets, to_select) --必须
		return #targets==0 and to_select:objectName() ~= sgs.Self:objectName()
	end,

	on_use = function(self, room, source, targets) --几乎必须
		local dest=targets[1]
		local lost=dest:getHp()
		if lost<=2 then lost=2 end
		--room:askForDiscard(source,"qingdang",1,1,false,true)
		local id=0
		local i=0
		for i=1,lost,1 do
			if not dest:isNude() then
				id=room:askForCardChosen(source,dest,"he",self:objectName())
				room:throwCard(id,dest,source)
			end
		end
		
		room:setPlayerFlag(source,"qingdang_used")
		room:setEmotion(dest, "bad")
	end,
}
qingdang = sgs.CreateViewAsSkill{
	name = "qingdang", 
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected==0
	end,

	view_as = function(self, cards) 	
		if #cards~=1 then return nil end
		local vs_card = qingdangCard:clone()
		vs_card:addSubcard(cards[1])
		return vs_card
	end,


	enabled_at_play = function(self, player)
		if (player:isAllNude()) then return false
		end
		if player:hasFlag("qingdang_used") then return false
		end
		return true
	end

}

bii=sgs.CreateTriggerSkill{
	name="bii",
	frequency=sgs.Skill_NotFrequent,
	events={sgs.Damaged},
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()

		local choices={"bii_good+bad"}
		local damage=data:toDamage()
		local from=damage.from
		local result = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))

		if result=="bii_good" and not from:hasSkill("wumou") then

			room:acquireSkill (from, "wumou")
		end
	end,
}

bucaiCard = sgs.CreateSkillCard{
	name = "bucaiCard", --必须
	target_fixed = false, --必须
	will_throw = true, --必须
	filter = function(self, targets, to_select) --必须
		return #targets==0 and to_select:objectName() ~= sgs.Self:objectName()
	end,

	on_use = function(self, room, source, targets) --几乎必须
		local numDrawCards = 4
		local choices = {"bucai_regenerateHp+bucai_drawCards"}
		local dest=targets[1]
		if dest:isWounded() then 
			local result = room:askForChoice(source, self:objectName(),table.concat(choices, "+"))
			if result=="bucai_regenerateHp" then
				local recover=sgs.RecoverStruct()
				recover.who=source
				recover.card=self
				recover.recover=2
				room:recover(dest,recover)
			else
				room:drawCards(dest,numDrawCards)
				room:drawCards(source,1)
			end
		else
			room:drawCards(dest,numDrawCards)
			room:drawCards(source,1)
		end
		room:setPlayerFlag(source, "bucai_used")
		end,
}

bucai = sgs.CreateViewAsSkill{
	name = "bucai", --必须
	n = 2, --必须
	view_filter = function(self, selected, to_select)
		return #selected<=2 and not to_select:isEquipped()
	end,
	view_as = function(self, cards) --必须
		if #cards~=2 then return nil end

		local vs_card = bucaiCard:clone()
		vs_card:addSubcard(cards[1])
		vs_card:addSubcard(cards[2])
		return vs_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("bucai_used")
	end,

}

--整风：你每受到伤害后，可以摸X张牌（X为你已损失的体力值）
zhengfeng1 = sgs.CreateTriggerSkill{
	name = "zhengfeng1", --必须 
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged}, --必须 
	
	on_trigger = function(self, event, player, data) --必须
		if not player:askForSkillInvoke(self:objectName()) then return end
		
		local x = player:getLostHp()
		local room=player:getRoom()
		
		local log= sgs.LogMessage()
		log.type = "#TriggerSkill"
		log.from = player
		log.arg  = self:objectName()
		room:sendLog(log)		
		
		room:broadcastSkillInvoke(self:objectName())
		room:drawCards(player,2*x)
	end, 
		
}

dianhun = sgs.CreateOneCardViewAsSkill{
	name = "dianhun",
	filter_pattern = ".|.",
	response_or_use = true,
	view_as = function(self, card)
		local vs_card = sgs.Sanguosha:cloneCard("lightning",card:getSuit(),card:getNumber())
		vs_card:setSkillName(self:objectName())
		vs_card:addSubcard(card)
		return vs_card
	end
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

rexue = sgs.CreateFilterSkill{
	name = "#rexue",
	view_filter = function(self, to_select)
		return to_select:getSuit()~=sgs.Card_Heart
	end,
	view_as = function(self, card)
		local id = card:getEffectiveId()
		local new_card = sgs.Sanguosha:getWrappedCard(id)
		new_card:setSkillName(self:objectName())
		new_card:setSuit(sgs.Card_Heart)
		new_card:setModified(true)
		return new_card
	end
}

weishan=sgs.CreateTriggerSkill{
	name="#weishan",
	frequency=sgs.Skill_Compulsory,
	events={sgs.DamageInflicted},	
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		
		local newDamage=damage
		newDamage.to=damage.from
		
		if damage.from ~= player then room:damage(damage) end
		
		local log= sgs.LogMessage()
		log.type = "#TriggerSkill"
		log.from = player
		log.arg  = self:objectName()
		room:sendLog(log)
		room:broadcastSkillInvoke(self:objectName())		
		
		
		return true		
	end
	
}

changzhengCard = sgs.CreateSkillCard{
	name = "changzhengCard", --必须
	target_fixed = false, --必须
	will_throw = true, --必须
	filter = function(self, targets, to_select) --必须
		return #targets==0
	end,
	feasible = function(self, targets)
		return true
	end,
	on_use = function(self, room, source, targets) --几乎必须
		local dest=targets[1]
		local mhp=sgs.QVariant()
		mhp:setValue(dest:getMaxHp()+1)
		room:setPlayerProperty(dest,"maxhp",mhp)
	end,	
}

changzheng = sgs.CreateViewAsSkill{
	name = "changzheng", --必须
	n = 2, --必须
	view_filter = function(self, selected, to_select)
		return #selected<2 
		
	end, 
	
	view_as = function(self, cards) --必须
		if #cards~=2 then return nil end
		if cards[1]:isRed()==cards[2]:isRed() then return nil end

		local vs_card = changzhengCard:clone()
		vs_card:addSubcard(cards[1])
		vs_card:addSubcard(cards[2])
		return vs_card
	end, 
	
	enabled_at_play = function(self, player)
		return true
	end, 
	
}

xuming = sgs.CreateTriggerSkill{
	name = "xuming",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data) --必须
		local room=player:getRoom()
		if not room:askForSkillInvoke(player, self:objectName(), data) then return end
		local id = room:getNCards(data:toDamage().damage)
		player:addToPile ("stars",id)
		
	end
}

--当你成为【乐不思蜀】或【顺手牵羊】的目标后，你可以对使用者造成3点雷电伤害。
gangbi = sgs.CreateTriggerSkill{
	name = "gangbi" ,
	events = {sgs.TargetConfirmed},
	frequency = sgs.Skill_NotFrequent, 
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room=player:getRoom()
		local source=use.from
		if (use.card:isKindOf("Indulgence") or use.card:isKindOf("Snatch") or use.card:isKindOf("Slash") ) and use.to:contains(player) then
		--if use.to:contains(player) then
			
			if player:isAllNude() then return end
			if room:askForSkillInvoke(player,self:objectName(),data) then 
				--[[
				local theDamage=sgs.DamageStruct()
				local dest = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName() )
				theDamage.from=player
				theDamage.to=dest
				theDamage.damage=3
				theDamage.nature=sgs.DamageStruct_Thunder
				]]--
				
				room:askForDiscard(player,self:objectName(),1,1,false,true)
				room:loseMaxHp(source,1)
				--room:damage(theDamage)
				--room:killPlayer(source) 

			end
		
		end
		return false
	end
}


guiyiBlackCard = sgs.CreateSkillCard{
	name = "guiyiBlackCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
        return #targets == 0 and not to_select:hasFlag("guiyi_black")
	end,
	
	on_use = function(self, room, source, targets)
        local dest = targets[1]
        if dest:getMaxHp() <= 1 then
            return false
        end
        local drawCount = 1
        if not dest:isWounded() then
            drawCount = 2
        end
        room:loseMaxHp(dest, 1)
        room:drawCards(dest, drawCount)
        room:setPlayerFlag(dest, "guiyi_black")
	end
}

guiyiRedCard = sgs.CreateSkillCard{
	name = "guiyiRedCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
        return #targets == 0 and not to_select:hasFlag("guiyi_red")
	end,
	
    on_use = function(self, room, source, targets)
        local dest = targets[1]
        local mhp = sgs.QVariant()
        mhp:setValue(dest:getMaxHp() + 1)
        room:setPlayerProperty(dest, "maxhp", mhp)
        room:setPlayerFlag(dest, "guiyi_red")
    end
}

guiyi = sgs.CreateViewAsSkill{
	name = "guiyi", --必须
	n = 1, --必须
	view_filter = function(self, selected, to_select)
		return #selected==0 --and to_select:getSuit()==sgs.Card_Heart
	end, 
	view_as = function(self, cards) --必须
		if #cards~=1 then return nil end
		local card=cards[1]
		if card:isBlack() then
			local vs_card=guiyiBlackCard:clone()
			vs_card:addSubcard(cards[1])
			return vs_card
		else
			local vs_card=guiyiRedCard:clone()
			vs_card:addSubcard(cards[1])
			return vs_card
		end
	end, 
	enabled_at_play = function(self, player)
		return true
	end, 

}

kirin_dis_mod = sgs.CreateTargetModSkill {
    name = "#kirin_dis_mod",
    frequency = sgs.Skill_Compulsory,
    pattern = "Slash",
    residue_func = function(self, player)
        return 0
    end,

    distance_limit_func = function(self, player)
        if player:hasSkill(self:objectName()) then
            return 1000
        end
	end,

}

kirin = sgs.CreateTriggerSkill {
    name = "kirin",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data)
        local damage = data:toDamage()
        local card = damage.card
        local isSlash = (card and card:isKindOf("Slash") and (not damage.chain) and (not damage.transer))
        if not isSlash then return false end
        local room = player:getRoom()
        local to = damage.to
        if not to:hasEquip() then return false end
        if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
        local id = room:askForCardChosen(player, to, "e", self:objectName())
        room:throwCard(id, to, player)
    end
}


--触摸：阶段技，阶段技，选择两名体力值不相等的角色，你弃X张牌（X为体力值之差），另该两名角色交换体力值，然后原先体力较多的角色摸2X张牌。
hunchuCard= sgs.CreateSkillCard{
	name = "hunchuCard",
	filter = function(self, targets, to_select)
		if #targets>=2 then return false end
		if #targets==0 then return true
		else
			local diff = math.abs(to_select:getHp() - targets[1]:getHp())
			return diff > 0 and diff == self:subcardsLength()
		end
	end,
	feasible = function(self, targets)
		return #targets==2
	end,
	on_use = function(self, room, source, targets)
		local victim
		local beneficiary		
		if targets[1]:getHp() < targets[2]:getHp() then --血较少的为受益者
			beneficiary=targets[1]
			victim=targets[2]
		else
			beneficiary=targets[2]
			victim=targets[1]
		end			
		local hpG = victim:getHp()
		local hpL = beneficiary:getHp()
		local diff = hpG-hpL	
		room:setPlayerProperty (victim, "hp", sgs.QVariant(hpL))
		room:setPlayerProperty (beneficiary, "hp", sgs.QVariant(math.min(hpG, beneficiary:getMaxHp())))
		local balance=3
		room:drawCards(victim, balance*diff)
	end
}
hunchu = sgs.CreateViewAsSkill{
	name = "hunchu",
	n = 511 ,
	view_filter = function(self, selected, to_select)
		return 1
	end ,
	view_as = function(self, cards)
		local card = hunchuCard:clone()
		for _, c in ipairs(cards) do
	   		card:addSubcard(c)
		end
	   	return card
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#hunchuCard")
	end
}




jiangzhongzheng:addSkill (dawujia)
jiangzhongzheng:addSkill (qimen)
jiangzhongzheng:addSkill (tiewan)
jiangzhongzheng:addSkill (xunjie)
jiangzhongzheng:addSkill(BTqianxun)
jiangzhongzheng:addSkill(qingdang)
--jiangzhongzheng:addSkill("guicai")
--jiangzhongzheng:addSkill(rexue)

sphuanggai:addSkill ("kurou")
sphuanggai:addSkill ("kuanggu")

shenhuatuo:addSkill (changsheng) --当前文件里有的技能名不要带引号！
shenhuatuo:addSkill ("yingzi")
shenhuatuo:addSkill (guiyi)
shenhuatuo:addSkill(kirin)

spguojia:addSkill ("tiandu")
spguojia:addSkill ("nosyiji")
spguojia:addSkill("nosqianxun")
spguojia:addSkill (xiusheng)
spguojia:addSkill(xunjie)

spdongzhuo:addSkill ("jiuchi")
spdongzhuo:addSkill ("roulin")
spdongzhuo:addSkill ("baonue")

anu:addSkill(lanman)
anu:addSkill("bossmanjia")
anu:addSkill(hunchu)


maorunzhi:addSkill(bucai)
maorunzhi:addSkill(zhengfeng1)

sgs.LoadTranslationTable{
	["fun"] = "娱乐",

	["jiangzhongzheng"]="蒋中正",
	["#jiangzhongzheng"]="穿林北腿",

	["maorunzhi"]="毛润之",
	["#maorunzhi"]="混世魔王",

	["dawujia"]="大雾",
	[":dawujia"]="<b>锁定技，</b>防止你受到的非雷电伤害。",
	["qimen"]="奇门",
	[":qimen"]="<b>锁定技，</b>你的手牌数无上限。",
	["tiewan"]="铁腕",
	[":tiewan"]="摸牌阶段，你可以额外获得四张牌。",
	["BTqianxun"]="谦逊",
	[":BTqianxun"]="<b>锁定技，</b>你不能被选择为【顺手牵羊】与【乐不思蜀】的目标。",

	["sphuanggai"]="SP黄盖",

	["shenhuatuo"]="神华佗",
--	["taoxian"]="桃仙",
--	[":taoxian"]="<b>锁定技，</b>你的所有黑桃牌牌均视为桃",

	["changsheng"]="长生",
	[":changsheng"]="锁定技，回合开始阶段，若你体力值已满，则你增加1点体力上限，否则回复1点体力。与你同一阵营的角色也获得该技能。",

	["xiusheng"]="修生",
	[":xiusheng"]="锁定技，游戏开始时，你失去29点体力。回合开始阶段，若你的体力值不大于3点，你回复2点体力，否则回复1点体力。",

	["#xunjie"]="迅捷",

	--["fenghan"]="风寒",
	--[":fenghan"]="锁定技，游戏开始时，你失去10点体力。",

	["spguojia"]="SP郭嘉",

	["spdongzhuo"]="SP董卓",
	["anu"]="阿奴",

	["lanman"]="烂漫",
	[":lanman"]="锁定技，你每受到1点火焰伤害时，防止此伤害，然后若你体回复1点体力并摸一张牌。",
	["taoxian"] = "桃仙",
	[":taoxian"] = "你可以将你任意一张牌当桃使用。",
	["qingdang"]="清党",
	[":qingdang"]="出牌阶段，若你有牌，你可以选择一名其他角色，你和该角色各弃2张牌。每回合限用一次。",

	["bii"]="测试用技能",
	["bii_good"]="令伤害来源获得技能【无谋】",

	["bucai"]="不才",
	[":bucai"]="出牌阶段，你可以弃一张手牌，指定该角色回复2点体力或摸四张牌。",
	["bucaiCard"]="不才",
	["bucai_drawCards"]="目标角色摸四张牌，你摸一张牌",
	["bucai_regenerateHp"]="回复2点体力",
	--["bucai_cancel"]="取消",
	
	["dianshen"]="电神",
	[":dianshen"]="<b>锁定技，</b>你的所有手牌均视为【闪电】。",
	
	["#rexue"]="热血",
	
	["zhengfeng1"]="整风",
	[":zhengfeng1"]="你每受次到伤害后，可以摸2X张牌（X为你已损失的体力值）",

	["#weishan"]="伪善",
	
	["gangbi"]="刚愎",
	[":gangbi"]="当你成为【乐不思蜀】或【顺手牵羊】的目标后，你可以对使用者造成3点雷电伤害。",
	
	["guiyi"]="鬼医",
	[":guiyi"]="出牌阶段，你可以弃一黑色手张牌，令一名角色减1点体力上限（最多减至1点）并摸一张牌，或弃一张红色手张牌，令一名角色增加1点体力上限。每个出牌阶段中红黑对同一名角色各至多使用一次。",
	
	["hunchu"]="魂触",
	[":hunchu"]="阶段技，选择两名体力值不相等的角色，你弃X张牌（X为体力值之差），另该两名角色交换体力值，然后原先体力较多的角色摸2X张牌。",

    ["kirin"] = "麒麟",
    [":kirin"] = "当你使用【杀】对目标角色造成伤害时，你可以弃掉其一张装备区的牌。",
}
