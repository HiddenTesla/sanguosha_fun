module("extensions.wumao", package.seeall)
extension = sgs.Package("wumao")

fiftycents1=sgs.General(extension, "fiftycents1","shu",9, true, true)
fiftycents2=sgs.General(extension, "fiftycents2$","shu",6, true, true)

function penaltyNullification (player)
	local room=player:getRoom()
	local count=player:getMark("@baqiNegative")/3
	if count<1 then count=1 end
	local lost = count * count * 16
	for _, c in sgs.qlist(player:getHandcards()) do --每张无懈可击都会让你失去n点体力上限
		if c:isKindOf ("Nullification") then
			room:throwCard(c, player, player)
			room:loseMaxHp(player, lost)
			-- room:loseHp(player, count)
		end
	end
end

jiangfei = sgs.CreateTriggerSkill{
	name = "jiangfei", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted, sgs.EventPhaseStart, sgs.TargetConfirmed, sgs.Dying},
	on_trigger = function(self, event, player, data)
		local room=player:getRoom()
		if event == sgs.DamageInflicted then
			local damage=data:toDamage()
			penaltyNullification (player)
			local count=player:getMark("@baqiNegative")/4
			if count<1 then count=1 end
			count=count*count
			if player:getMaxHp()<=1 then
				room:killPlayer(player,damage)
			else
				local maxHp=player:getMaxHp()
				if maxHp>count then
					room:loseMaxHp(player, count)
				else
					room:loseMaxHp(player, maxHp-1)
					return true
				end
			end
			local source = damage.from
			local currentCount = player:getMark("@baqiNegative")
			player:gainMark("@baqiNegative", 3 + currentCount * 0.02)

			if damage.card:isKindOf ("Lightning") then
				local n=player:getMark("@baqiNegative")
				room:loseMaxHp (player, n*(n-1)*(n-2)/6)
				damage.damage=damage.damage+15
				data:setValue(damage)
			end
			if damage.nature == sgs.DamageStruct_Thunder then				
				damage.damage=damage.damage*1.5
				data:setValue(damage)
			end		
			return false
		elseif event == sgs.EventPhaseStart then
			local UPBOUND = room:alivePlayerCount()*1.5
			if UPBOUND > player:getHp() then UPBOUND=player:getHp() end
			if UPBOUND < 3 then UPBOUND=3 end
			if player:getPhase() == sgs.Player_Play  or player:getPhase() == sgs.Player_Start then
				local nc=player:getHandcardNum()
				if nc > UPBOUND then
					room:askForDiscard(player,  self:objectName(),  nc-UPBOUND,  nc-UPBOUND, false, false, "")
				end
			end
			if player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish then				
				penaltyNullification (player)			
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if (use.card:isKindOf("Slash") or use.card:isKindOf ("TrickCard")) and use.to:contains(player) then
				penaltyNullification (player)				
			end
			if (use.from:objectName() == player:objectName() )and 
				  ( use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard") or use.card:isKindOf("EquipCard") )  then
				-- math.randomseed(os.time())
				-- local x = math.random(1,10)	
				local increment = player:getMark("@baqiNegative") * 256
				if (player:getRole() == "lord") then 
					increment = increment * 8
				end
				player:gainMark("@baqiNegative", 2)
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + increment ))
				room:setPlayerProperty(player, "hp", sgs.QVariant(player:getHp() + increment ))

			end
		-- elseif event == sgs.Dying then
			-- local dying = data:toDying()
			-- local dyer = dying.who
			-- if dyer:objectName() == player:objectName() then
				-- local gap=1-player:getHp()
				-- local theRecover=sgs.RecoverStruct()
				-- theRecover.recover=gap		
				-- room:broadcastSkillInvoke(self:objectName())
				-- room:recover(player, theRecover)
				-- if player:getMaxHp()>gap then
					-- room:loseMaxHp(player, gap)
				-- else
					-- room:loseMaxHp(player, player:getMaxHp()-1)
				-- end
			-- end
		end		
	end, 
	priority = -12
}

ruozhi = sgs.CreateFilterSkill{
	name = "ruozhi",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return place == sgs.Player_PlaceHand and (to_select:isRed() or to_select:getSuit()==sgs.Card_Spade)
	end, 
	view_as = function(self, card)
		local id = card:getId()
		-- local suit = card:getSuit()
		local suit = sgs.Card_Spade
		local point = 3
		local chain
		if card:getSuit()==sgs.Card_Spade then
			chain = sgs.Sanguosha:cloneCard("peach", suit, point)
		elseif card:isRed() then
			chain = sgs.Sanguosha:cloneCard("thunder_slash", suit, point)
		end
		chain:setSkillName(self:objectName())
		local vs_card = sgs.Sanguosha:getWrappedCard(id)
		vs_card:takeOver(chain)
		return vs_card
	end
}

quanxian = sgs.CreateTriggerSkill{
	name = "quanxian", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room=player:getRoom()
		local use=data:toCardUse()
		local card=use.card
		local lowerbound=2
		if use.to:contains(player) and card:isKindOf("TrickCard") then
			local newMaxHp=player:getMaxHp()+1
			room:setPlayerProperty (player, "maxhp", sgs.QVariant(newMaxHp))
			local recover=sgs.RecoverStruct()
			recover.recover=1
			recover.card=card
			room:recover(player,recover)
			if player:getMaxHp()>=31 then
				room:setPlayerProperty (player, "maxhp", sgs.QVariant(lowerbound))
			end			
		end
	end, 	
}

rigou = sgs.CreateTriggerSkill{
	name = "rigou$",
	frequency = sgs.Skill_Wake, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data) --必须
		if player:getPhase() ~= sgs.Player_Start or not player:hasSkill("quanxian") then return	end
		local trigger=true
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:getMaxHp() > p:getMaxHp() then
				trigger = false
				break
			end
		end
		if trigger then
			-- room:addPlayerMark(player, "rigou")
			if room:changeMaxHpForAwakenSkill(player, -1) then
				room:acquireSkill(player, "wushen")
				room:acquireSkill(player, "paoxiao")
				room:acquireSkill(player, "mashu")
				room:acquireSkill(player, "benghuai")
				room:acquireSkill(player, "shiyong")
				room:detachSkillFromPlayer(player, "quanxian")
			end
		end		
		
	end, 
}

gouri = sgs.CreateTriggerSkill{
	name = "gouri",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damaged},  
	on_trigger = function(self, event, player, data)
		if player:getHp()<=1 then return end
		local damage=data:toDamage()
		local room=player:getRoom()
		local nature=damage.nature
		local newDamage=sgs.DamageStruct()
		newDamage.from=nil
		newDamage.to=player
		newDamage.damage=1
		if nature == sgs.DamageStruct_Thunder then
			newDamage.nature=sgs.DamageStruct_Fire
			room:damage(newDamage)
		elseif nature == sgs.DamageStruct_Fire then
			newDamage.nature=sgs.DamageStruct_Thunder
			room:damage(newDamage)
		end
	end, 
}

zhanshen2 = sgs.CreateFilterSkill{
	name = "zhanshen2", 
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return (to_select:getSuit() == sgs.Card_Heart) and (to_select:isKindOf("BasicCard)"))
			and (place == sgs.Player_PlaceHand)
	end,
	view_as = function(self, originalCard)
		local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
		slash:setSkillName(self:objectName())
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(slash)
		return card
	end
}

fiftycents1:addSkill(jiangfei)
fiftycents1:addSkill("wumou")
fiftycents2:addSkill(ruozhi)
fiftycents2:addSkill(quanxian)
fiftycents2:addSkill(gouri)


sgs.LoadTranslationTable{
	["wumao"] = "五毛",
	["fiftycents1"] = "善良的ed汪",
	["#fiftycents1"] = "自干五",
	["designer:fiftycents1"] = "边锋员工陈诚",
	["cv:fiftycents1"] = "边锋员工杜鲁门",
	["illustrator:fiftycents1"] = "边锋员工蒋中正",
	["jiangfei"] = "蒋废",
	-- [":jiangfei"] = "<b>锁定技，</b>当你成为【杀】的目标并受到此【杀】的伤害时，若你没有手牌，此伤害+1。",
	[":jiangfei"] = "<b>锁定技，</b>当受到【杀】的伤害后，你减1点体力上限。",
	["fiftycents2"] = "孙坚需要主公技",
	["ruozhi"] = "弱智",
	[":ruozhi"] = "<b>锁定技，</b>你的所有锦囊牌均视为【闪电】。",
	["quanxian"] = "权限",
	[":quanxian"] = "<b>锁定技，</b>当你成为锦囊牌的目标时，你增加1点体力上限，然后回复1点体力。若此时你的体力上限不少于10，你将其重置为2，然后获得技能【崩坏】，【恃勇】。",
	["rigou"]= "哔狗",
	["gouri"]= "哔狗",
	["zhenshen2"]="战神",
}