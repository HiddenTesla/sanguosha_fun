module("extensions.fun4", package.seeall)
extension = sgs.Package("fun4")
spmenghuo=sgs.General(extension, "spmenghuo","shu", 3, true, true)
sphuaxiong=sgs.General(extension, "sphuaxiong","qun", 80, true, true)
haha=sgs.General(extension, "haha","shu", 7, true, true)
feizei=sgs.General(extension, "feizei","wu", 3, true, true)
jianggan=sgs.General(extension, "jianggan","wei", 4, true)

zaiqiBT = sgs.CreateTriggerSkill{
	name = "zaiqiBT",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Draw then
			if player:isWounded() then
				local room = player:getRoom()
				if room:askForSkillInvoke(player, self:objectName()) then
					local luckySuit=room:askForSuit(player, self:objectName())
					local x = player:getLostHp()
					local has_heart = false
					local ids = room:getNCards(x, false)
					local move = sgs.CardsMoveStruct()
					move.card_ids = ids
					move.to = player
					move.to_place = sgs.Player_PlaceTable
					move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
					room:moveCardsAtomic(move, true)
					local card_to_throw = {}
					local card_to_gotback = {}
					for i=0, x-1, 1 do
						local id = ids:at(i)
						local card = sgs.Sanguosha:getCard(id)
						local suit = card:getSuit()
						if suit == luckySuit then
							table.insert(card_to_throw, id)
						else
							table.insert(card_to_gotback, id)
						end
					end
					if #card_to_throw > 0 then
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, id in ipairs(card_to_throw) do
							dummy:addSubcard(id)
						end
						local recover = sgs.RecoverStruct()
						recover.card = nil
						recover.who = player
						recover.recover = #card_to_throw
						room:recover(player, recover)
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
						room:throwCard(dummy, reason, nil)
						has_heart = true
					end
					if #card_to_gotback > 0 then
						local dummy2 = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, id in ipairs(card_to_gotback) do
							dummy2:addSubcard(id)
						end
						room:obtainCard(player, dummy2)
					end
					return true
				end
			end
		end
		return false
	end
}

shibeiT = sgs.CreateTriggerSkill{
	name = "shibeiT",
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room=player:getRoom()
		if player:hasFlag("shibei_damaged") then
			room:loseHp(player)
		else
			local recover=sgs.RecoverStruct()
			recover.recover=1
			room:recover(player, recover)
			room:setPlayerFlag(player, "shibei_damaged")
		end
	end, 
}

xianhaiCard = sgs.CreateSkillCard{
	name = "xianhaiCard", 
	target_fixed = true,
	will_throw = false,
	on_effect = function(self, effect)
		local source=effect.from
		local room=source:getRoom()
		for _,c in ipairs(self:getSubcards()) do
			-- room:moveCardTo (c, source, sgs.Player_DrawPile, true)
			room:throwCard(c,source)
			room:loseHp(source)
			room:drawCards(source,2)
		end
	end,
}	

xianhai = sgs.CreateViewAsSkill{
	name = "xianhai", 
	n = 127, 
	view_filter = function(self, selected, to_select)
		return to_select:isBlack()
	end, 
	view_as = function(self, cards)
		local card = xianhaiCard:clone()
		for _, c in ipairs(cards) do
	   		card:addSubcard(c)
		end
	   	return card
	end, 
}

wb = sgs.CreateTriggerSkill{
	name = "wb",
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data) 
		local room=player:getRoom()
		local phase=player:getPhase()
		if phase ~= sgs.Player_Finish then return end
		if not room:askForSkillInvoke(player, self:objectName()) then return end
		player:drawCards(2)
		local card = room:askForCard(player, ".|black|.", self:objectName())
		if card then
			room:moveCardTo (card, player, sgs.Player_DrawPile, true) 
		else
			room:loseHp(player)
		end
	end, 
}

zaihei = sgs.CreateTriggerSkill{
	name = "zaihei", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_Start then return end
		-- player:drawCards(2)
		local room=player:getRoom()
		local source=room:findPlayerBySkillName(self:objectName())
		-- source:drawCards(2)
		local diff = player:getHp()-source:getHp()
		if diff<=0 then return end
		if not room:askForSkillInvoke(source, self:objectName()) then return end
		source:drawCards(diff)
		local card = room:askForCard(source, ".|black|.", self:objectName())
		if card then
			room:moveCardTo (card, source, sgs.Player_DrawPile, true)
		else
			room:loseHp(source)
		end
	end, 
	can_trigger = function(self, target)
		return target and target:isAlive()
	end, 
}
mensheng = sgs.CreateTriggerSkill{
	name = "mensheng", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted, sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data)
		if event == sgs.DamageInflicted then
			local room = player:getRoom()
			local damage = data:toDamage()
			local source = damage.from
			if source and source:isAlive() and source:objectName()~=player:objectName() then
				local newDamage = damage
				newDamage.to = source
				newDamage.from = player
				room:damage(newDamage)
				return true
			else
				return true
			end
		elseif event == sgs.EventPhaseStart then
			local room=player:getRoom()
			-- if player:getPhase() == sgs.Player_Finish and player:getHp() > 1 then
			if player:getPhase() == sgs.Player_Finish then
				room:loseHp(player, 1)
			end
		end
	end,	 
}

xunjie = sgs.CreateTriggerSkill{
	name = "xunjie",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardAsked},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local pattern = data:toStringList()[1]
		if pattern ~= "jink" then return false end
		local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
		jink:setSkillName(self:objectName())
		room:provide(jink)
	end,
}

qingzhuang = sgs.CreateTriggerSkill{
	name = "qingzhuang" ,
	events = {sgs.EventPhaseChanging, sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Judge and not player:isSkipped(sgs.Player_Judge) and not player:isSkipped(sgs.Player_Draw) then
				player:skip(sgs.Player_Judge)
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			local myHandcardNum = player:getHandcardNum()
			local isFewest = true
			local others = room:getOtherPlayers(player)
			for _,p in sgs.qlist(others) do
				if p:getHandcardNum() < myHandcardNum then
					isFewest = false
					break
				end --if
			end --for
			if isFewest then
				player:drawCards(1)
			end --if
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Draw then
			player:drawCards(2)
			return true
		end
	end,
}

touxiCard = sgs.CreateSkillCard{
	name = "touxiCard" ,
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select)
		return true
	end ,
	on_use = function(self, room, source, targets)
		local targets_list = sgs.SPlayerList()
		for _, target in ipairs(targets) do
			if source:canSlash(target, nil, false) then
				targets_list:append(target)
			end
		end
		if targets_list:length() > 0 then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("touxi")
			room:useCard(sgs.CardUseStruct(slash, source, targets_list))
		end
	end
}

touxi = sgs.CreateViewAsSkill{
	name = "touxi" ,
	n = 2 ,
	view_filter = function(self, selected, to_select)
		return #selected == 0
	end ,
	view_as = function(self, cards)
		if #cards < 1 then return nil end
		local card = touxiCard:clone()
		card:addSubcard(cards[1])
		return card
	end ,
	enabled_at_play = function(self, player)
		return not player:isNude()
	end,
}

xianjiCard = sgs.CreateSkillCard{
	name = "xianjiCard", 
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return true
	end,
	on_effect = function(self, effect) --几乎必须
		local room = effect.to:getRoom()
		room:killPlayer (effect.from)
		room:killPlayer (effect.to)
	end
}

xianji = sgs.CreateViewAsSkill{
	name = "xianji", 
	n = 0, 
	view_as = function(self, cards) --必须
		local vs_card = xianjiCard:clone()
		return vs_card
	end, 
}

daoshuCard = sgs.CreateSkillCard {
	name = "daoshuCard", 
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets > 0 then return false end
		return (not to_select:isKongcheng()) and (sgs.Self:objectName() ~= to_select:objectName())
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local me = effect.from
		local you = effect.to
        local judge = sgs.JudgeStruct()
        judge.who = me
        judge.good = true
        judge.reason = self:objectName()
        room:judge(judge)

        local judgeCard = judge.card

		local card_id = room:askForCardChosen(me, you, "h", self:objectName())
		local showCard = sgs.Sanguosha:getCard(card_id)
		room:showCard(you, card_id)

		local suit = showCard:getSuit()
        if suit == judgeCard:getSuit() then
			room:setPlayerFlag(me, "daoshuFlag")
            local toThrow = nil
            if not me:isKongcheng() then
                local suitString = nil;
                -- XXX: 是否有办法可以直接把Suit enum转换为string？
                if suit == sgs.Card_Spade then
                    suitString = "spade"
                elseif suit == sgs.Card_Heart then
                    suitString = "heart"
                elseif suit == sgs.Card_Club then
                    suitString = "club"
                elseif suit == sgs.Card_Diamond then
                    suitString = "diamond"
                else
                    suitString = "diamond"
                end
                local pattern = ".|" .. suitString .. "|.|hand"
                toThrow = room:askForCard(me, pattern, "@daoshu-throw")
            end
            if toThrow then
                room:throwCard(toThrow, me)
            else
                room:loseHp(me, 1)
            end
            room:throwCard(showCard, you)
        else
            me:obtainCard(showCard)
        end
	end
}

daoshu = sgs.CreateViewAsSkill{
	name = "daoshu", 
	n = 0, 
	view_as = function(self, cards)
		local vs_card = daoshuCard:clone()
		return vs_card
	end, 
	enabled_at_play = function(self, player)
		return not player:hasFlag("daoshuFlag")
	end,
}

spmenghuo:addSkill(zaihei)
spmenghuo:addSkill(xianji)
sphuaxiong:addSkill("benghuai")
sphuaxiong:addSkill("shiyong")
haha:addSkill(mensheng)
haha:addSkill("nosbuqu")
haha:addSkill("kuanggu")
feizei:addSkill(xunjie)
feizei:addSkill(qingzhuang)
feizei:addSkill(touxi)
jianggan:addSkill(daoshu)

sgs.LoadTranslationTable {
	["fun4"]="娱乐4",
	["spmenghuo"]="SP孟获",
	["sphuaxiong"]="SP华雄",
	["jianggan"] = "蒋干",
	["#jianggan"] = "自作聪明",
	["zaiqiBT"]="再起",
	[":zaiqiBT"]="摸牌阶段开始时，若你已受伤，你可以放弃摸牌，改为选择一种花色，然后从牌堆顶亮出X张牌（X为你已损失的体力值），你回复等同于其中该花色牌数量的体力，然后将这些牌置入弃牌堆，并获得其余的牌。",
	["shibeiT"]="矢北",
	["wb"]="墨守",
	[":wb"]="回合结束阶段，你可以摸两张牌。若如此做，你将一张黑色牌置于牌堆顶，否则失去1点体力。",
	["zaihei"]="栽赃",
	["haha"]="蛤蛤",
	["mensheng"]="闷声",
	[":mensheng"]="<b>锁定技，</b>每当你受到伤害时，该伤害无效。若此伤害有来源且不是你，则伤害来源承受此伤害。回合结束阶段开始时，若你的体力大于1，你失去1点体力。",
	["feizei"]="飞贼",
	["xunjie"]="迅捷",
	[":xunjie"]="<b>锁定技，</b>当你需要使用或打出【闪】时，视为你使用或打出了【闪】。",
	["qingzhuang"]="轻装",
	[":qingzhuang"]="<b>锁定技，</b>摸牌阶段，你摸一张牌。你跳过判定阶段。回合结束阶段开始时，若你的手牌数为全场最少，你摸一张牌。",
	["touxi"]="偷袭",
	[":touxi"]="出牌阶段，你可以弃一张牌，视为对任意一名角色使用了【杀】。",
	["daoshu"]="盗书",
	[":daoshu"]="出牌阶段，你可以进行一次判定然后展示一名其他角色的一张手牌。若此牌与判定牌花色相同，弃置此牌，此回合不能再使用该技能，然后你选择：弃一张与此牌花色相同的手牌，或失去1点体力；否则你获得此牌。",

    ["@daoshu-throw"] = "弃掉一张与判定牌花色相同的手牌，否则你失去1点体力",
}
