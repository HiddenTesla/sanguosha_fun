--[[
	更新日志，自2015-12-22起：
	2015-12-22：将技能“霸业”从fun2转移至本文件，不完全。该技能未如预期，正在查找原因
	2015-12-25：将函数isFriend和healPlayer移至本文件，似乎正常了。继续观察中
	2016-05-02：第1次获得的技能改为武圣。不会获得技能再起
]]--

module("extensions.baye", package.seeall)
extension = sgs.Package("baye")

BTcaocao=sgs.General(extension, "BTcaocao$","wei", 3, true)


function isFriend (player1, player2) --判断两名玩家是否属于同一阵营
	local r1=player1:getRole()
	local r2=player2:getRole()
	if r1==r2 then return true end
	if r1=="lord" and r2=="loyalist" then return true end
	if r2=="lord" and r1=="loyalist" then return true end
	return false
end

function healPlayer (target, point)
	local room=target:getRoom()
	local recover=sgs.RecoverStruct()
	recover.recover=point
	recover.who=target
	room:recover(target, recover)
end

bayeDistance = sgs.CreateDistanceSkill{
	name = "#bayeDistance",
	correct_func = function(self, from, to) 
		if from:hasSkill("#bayeDistance") then
			return - (from:getMark("@baqi") + 1)
		end
	end
}

bayeQiangxiCard = sgs.CreateSkillCard{
	name = "bayeQiangxiCard", 

	filter = function(self, targets, to_select) 
		return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName() ) 
	end,

	on_use = function(self, room, source, targets)
	
		local power = source:getMark("@baqi")
		local victim = targets[1]
		local base = victim:getMark("@baqiNegative")
			
		local theDamage = sgs.DamageStruct()
		theDamage.from = source
		theDamage.to = victim
		theDamage.damage= 1

		room:damage(theDamage)
		
		if power < 1 then
			power = 1
		end
		if (base > 0 and power > 0) then
			room:loseMaxHp(victim, base^2 * power)
		end
		
		room:setPlayerFlag(source, "bayeQiangxi_used")
	end,
}

bayeQiangxi = sgs.CreateViewAsSkill{
	name = "bayeQiangxi", 
	n = 0,

	view_as = function(self, cards) 	

		local vs_card = bayeQiangxiCard:clone()
		return vs_card
	end,

	enabled_at_play = function(self, player)
		return not player:hasFlag("bayeQiangxi_used")
	end

}

function clearCertainSkills(player)
	local room = player:getRoom()
	local skill_list = player:getVisibleSkillList()
	for _,skill in sgs.qlist(skill_list) do
		local name = skill:objectName()
		if name == "yiji" or name == "nosyiji" or name == "fankui" or 
			name == "enyuan" or name == "ganglie" or name == "jieming"
			or name == "miji" or name == "zhenlie"
		then
			room:detachSkillFromPlayer(player, name)
			room:setPlayerProperty (player, "maxhp", sgs.QVariant(player:getMaxHp() * 3))
			room:setPlayerProperty (player, "hp", sgs.QVariant(player:getMaxHp()))
		end
	end
end

baye = sgs.CreateTriggerSkill{
	name = "baye",
	events = {sgs.TargetConfirmed, sgs.EventPhaseStart, sgs.DamageInflicted, sgs.GameStart, sgs.Damage, sgs. DamageCaused, 
		sgs.TurnedOver, sgs.CardEffect, sgs.DrawNCards},
	frequency = sgs.Skill_Compulsory, 
	on_trigger = function(self, event, player, data)
		local room=player:getRoom()
		local msg = sgs.LogMessage()
		local UP = 3
		if event == sgs.TargetConfirmed then 
			local use = data:toCardUse()
			local source=use.from
			if use.card:isKindOf("Indulgence") or use.card:isKindOf ("SupplyShortage") then
				if use.to:contains(player) then
				local p=player
					local move=true
					for _,c in sgs.qlist(source:getJudgingArea()) do
						if c:isKindOf ("Indulgence") then
							move=false
							break
						end
					end
					if use.card:isKindOf ("SupplyShortage") then move=false end
					room:moveCardTo (use.card, source, sgs.Player_PlaceDelayedTrick, true)
					--以上move变量的目的是判断使用者的判定区里是否已经有【乐不思蜀】。若不加该断定，则有可能出现判定区里2张乐的情况 。目前没有更好的办法，只能采用土办法。
					-- if not source:isKongcheng() then
						-- for _, c in sgs.qlist(source:getHandcards()) do
							-- room:obtainCard (p, c)
						-- end
					-- end
					room:detachSkillFromPlayer (source, "fenyong")
					room:detachSkillFromPlayer (source, "xuehen")
					room:detachSkillFromPlayer (source, "zhichi")
					room:detachSkillFromPlayer (source, "kangkai")
					room:detachSkillFromPlayer (source, "manjia")
					room:detachSkillFromPlayer (source, "xiangle")
					room:detachSkillFromPlayer (source, "yiji")
					room:detachSkillFromPlayer (source, "nosyiji")
					local skill_list = source:getVisibleSkillList()
					for _,skill in sgs.qlist(skill_list) do
						local skillName=skill:objectName()
						if not 
						(
						skill:getFrequency() == sgs.Skill_Limited or p:hasSkill(skillName)
							or skill:objectName() == "ruozhi" or skill:objectName() == "jiangfei" or skill:objectName() == "shiyong" or skill:objectName() == "benghuai" or skill:objectName() == "kanpo" or skill:objectName() == "jueqing" or skill:objectName() == "nosrende" or skillName == "jiangchi"
							or skillName == "qixing" or skillName == "dawu" or skillName == "kuangfeng" 
							or skillName== "nosleiji" or skillName == "wangxi" or skillName == "luoyi" or skillName == "hunzi"
							or skillName == "xuanhuo" or skillName == "qiaobian" or skillName == "yongsi" or skillName == "weimu"
							or skillName == "shelie" or skillName == "guose" or skillName == "duanliang" or skillName == "meibu"
							or skillName == "qingjian" or skillName == "feiying" or skillName == "huashen" or skillName == "xinsheng"
							or skillName == "fuhun" or skillName == "xunxun" or skillName == "zongxuan"or skillName == "fangzhu"
							or skillName == "yanxiao" or skillName == "qianxin" or skillName == "jianyan"
							or skillName == "yiji" or skillName == "nosyiji"
							or skillName == "mashu" or skillName == "kangkai" or skillName == "fangquan" 
							or skillName =="zaiqi" or skillName == "longyin" or skillName == "pojun"
							or skillName == "tieji" or skillName == "guicai" or skillName == "guidao"
							or skillName == "lianying" or skillName == "haoshi" or skillName == "zhendu"
							or skillName == "kuimo" or skillName == "$songwei" or skillName == "danshou"
							or skillName == "lieren" or skillName == "shuangxiong" 
							or skillName == "xianzhen" or skillName == "lihuo" or skillName == "xiantu"
						) then
							room:acquireSkill(p, skill:objectName())
						elseif skillName == "lianying" then
							room:acquireSkill(p, "noslianying")
						end
					end
					if source:hasSkill ("kongcheng") then room:detachSkillFromPlayer (source, "kongcheng") end
					if source:hasSkill ("zhenlie") then room:detachSkillFromPlayer (source, "zhenlie") end
					if source:hasSkill ("feiying") then room:detachSkillFromPlayer (source, "feiying") end
					if source:hasSkill ("quanji") then room:detachSkillFromPlayer (source, "quanji") end

					source:throwAllHandCardsAndEquips()
					room:acquireSkill(source,"jiangfei")
					player:gainMark ("@baqi", 1)
					source:gainMark ("@baqiNegative", 4+source:getMark("@baqiNegative")*0.3)
					local count=player:getMark("@baqi")
					if count <= 1 then
						room:acquireSkill(player,"wusheng")
						room:acquireSkill(player,"duanbing")
					end
					if count >= 2 then
						room:acquireSkill(player,"paoxiao")
						room:acquireSkill(player,"zhiheng")
						room:acquireSkill(player,"wushen")
						room:detachSkillFromPlayer (source, "xianzhen")
						room:detachSkillFromPlayer (source, "tianyi")
					end
					if count >= 3 then
						room:acquireSkill(player,"qiangxi")
					end
					if count >= 4 then
						room:acquireSkill(player,"shenji")
					end
					if count >= 5 then
						room:acquireSkill(player,"kurou")
						room:acquireSkill(player,"zhaxiang")
					end
					if count >= 12 then
						room:acquireSkill(player,"kuangbao")
						room:acquireSkill(player,"shenfen")
					end
					local newHp = source:getMaxHp() * 1.2
					room:setPlayerProperty(source, "maxhp", sgs.QVariant(newHp))
					local extra=source:getMark("@baqiNegative")*32
					if source:getRole()=="lord" then
						room:setPlayerProperty(source, "maxhp", sgs.QVariant(source:getMaxHp()+64+extra))
						room:setPlayerProperty(source, "hp", sgs.QVariant(source:getMaxHp()+56+extra))
					else
						room:setPlayerProperty(source, "maxhp", sgs.QVariant(source:getMaxHp()+28+extra))
						room:setPlayerProperty(source, "hp", sgs.QVariant(source:getMaxHp()+56+extra))
					end
					room:detachSkillFromPlayer(player, "qingnang")
					room:detachSkillFromPlayer(player, "nosrende")
					room:detachSkillFromPlayer(player, "nosleiji")
					room:detachSkillFromPlayer(player, "jiangfei")
					room:detachSkillFromPlayer(player, "shiyong")
					room:detachSkillFromPlayer(player, "fenyong")
					room:detachSkillFromPlayer(player, "xuehen")
					room:detachSkillFromPlayer(player, "shensu")
					room:detachSkillFromPlayer(player, "tianyi")
					room:detachSkillFromPlayer(player, "tieji")
					room:detachSkillFromPlayer(player, "xianzhen")
					if player:getMaxHp() > 1 then						
						room:loseMaxHp(player, 1)
					elseif player:getHp() >1 then
						room:loseHp (player, 1)
					elseif not player:isKongcheng() then
						player:throwAllHandCards()
					else
						player:turnOver()
					end
				elseif use.from:objectName() == player:objectName() then 
				--你对其他角色使用乐不思蜀的时候，该牌会交到一名随机角色手中
					math.randomseed(os.time())
					local count = math.random(room:alivePlayerCount()-1)				
					local target=player
					local i=0
					while i<count do
						target=target:getNextAlive()
						if not isFriend(player, target) then
							i=i+1
						end
					end
					room:obtainCard(target, use.card)
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
					if c:isKindOf("Indulgence") or c:isKindOf("SupplyShortage") then
						room:obtainCard(player, c)
					end
				end
			elseif player:getPhase() == sgs.Player_Discard then
				for _, c in sgs.qlist(player:getHandcards()) do
					if c:isKindOf("Peach") or c:isKindOf("Jink") or 
						(player:getMark("@baqi") >= 2 and c:isKindOf("Slash")) then
						room:throwCard(c, player, player)
						if not player:isWounded() then
							room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp()+1))
						else
							healPlayer (player, 1)
						end	
					end
				end	
				-- 2016-10-06:
				-- 弃掉一半“暴怒”标记，全体失去x*x*baqiNegative/64点体力上限
				msg.type = "#baye_loseWrath"
				local nWrath = player:getMark("@wrath")
				if nWrath > 0 then
					player:loseMark("@wrath", player:getMark("@wrath") / 2)
					local playerlist = room:getOtherPlayers(player)
					for _, victim in sgs.qlist(playerlist) do
						local nBaqiNegative = victim:getMark("@baqiNegative")
						room:loseMaxHp(victim, nWrath * nWrath * nBaqiNegative / 64)
					end
				end
			end
		elseif event == sgs.DamageInflicted then
			local damage=data:toDamage()
			local card=damage.card
			if card:isKindOf ("Lightning") then --防止闪电的伤害，然后移动到下家。隐患bug：若下家也有闪电，则下家将判定区里将有两张闪电
				room:moveCardTo (card, player:getNextAlive(), sgs.Player_PlaceDelayedTrick, true)
				return true
			end
		elseif event == sgs.GameStart then
			local playerlist=room:getAlivePlayers()
			msg.type = "#baye_gamestart"
			msg.arg = player:getMaxHp()
			msg.to:append(player)
			room:sendLog(msg)
			if player:getRole() == "renegade" then
				room:setPlayerProperty (player, "role", sgs.QVariant("loyalist"))
			end
			for _,p in sgs.qlist(playerlist) do
				if p:getRole() == "renegade" and p:objectName()~=player:objectName() then
					if player:getRole() == "rebel" then
						room:setPlayerProperty (p, "role", sgs.QVariant("loyalist"))
					elseif player:getRole() == "lord" or player:getRole() == "loyalist" then
						room:setPlayerProperty (p, "role", sgs.QVariant("rebel"))
					end
				end
				--全部角色都失去的技能
				room:detachSkillFromPlayer(p, "jilei")
				room:detachSkillFromPlayer(p, "fangzhu")
				room:detachSkillFromPlayer(p, "danlao")
				room:detachSkillFromPlayer(p, "xuanfeng")
				room:detachSkillFromPlayer(p, "liuli")
				room:detachSkillFromPlayer(p, "shensu")
				if not isFriend (p, player) then
					local MAXHP_MULTIPLIER = 100
					room:acquireSkill (p, "mashu")
					local maxhp=p:getMaxHp()
					-- if maxhp >=3 and maxhp <= 20 then
					if p:getMark("@comm") <= 0 then
						room:setPlayerProperty (p, "maxhp", sgs.QVariant(maxhp * MAXHP_MULTIPLIER))
						room:setPlayerProperty (p, "hp", sgs.QVariant(p:getMaxHp()))
						p:gainMark("@comm")
					end					
				else
                    local role = p:getRole()
                    if role ~= "lord" and p:objectName() ~= player:objectName() then
                        room:killPlayer(p)
                    end

					room:acquireSkill(p, "#jiee")
					room:acquireSkill(p, "#bayeDistance")
					if not p:hasSkill(self:objectName()) then room:acquireSkill(p, self:objectName()) end
					
					room:detachSkillFromPlayer(p, "jueqing")
					room:detachSkillFromPlayer(p, "qiaobian")
					room:detachSkillFromPlayer(p, "nosleiji")
					room:detachSkillFromPlayer(p, "duanliang")
					room:detachSkillFromPlayer(p, "jiangchi")
					room:detachSkillFromPlayer(p, "fuhun")
					room:detachSkillFromPlayer(p, "fangzhu")
					room:detachSkillFromPlayer(p, "junxing")
					room:detachSkillFromPlayer(p, "wangxi")
					room:detachSkillFromPlayer(p, "yiji")
					room:detachSkillFromPlayer(p, "nosyiji")
					room:detachSkillFromPlayer(p, "yanxiao")
					room:detachSkillFromPlayer(p, "quji")
					room:detachSkillFromPlayer(p, "guose")
					room:detachSkillFromPlayer(p, "hunzi")
					room:detachSkillFromPlayer(p, "quanji")
					room:detachSkillFromPlayer(p, "xunxun")
					if not p:hasSkill("nosjianxiong") then
						--room:acquireSkill(p, "nosqianxun")
					end
				end				
				if p:hasSkill ("kuanggu") and not p:hasSkill(self:objectName()) then
					room:setPlayerProperty (p, "maxhp", sgs.QVariant(p:getMaxHp()+4))
					room:setPlayerProperty (p, "hp", sgs.QVariant(p:getMaxHp()))
				end
				if p:hasSkill ("kanpo") then
					room:setPlayerProperty (p, "maxhp", sgs.QVariant(p:getMaxHp()+2))
					room:setPlayerProperty (p, "hp", sgs.QVariant(p:getMaxHp()))
				end
				if p:hasSkill ("nosbuqu") and not p:hasSkill(self:objectName()) then
					room:setPlayerProperty (p, "maxhp", sgs.QVariant(p:getMaxHp()+6))
					room:setPlayerProperty (p, "hp", sgs.QVariant(p:getMaxHp()))
				end
				if p:hasSkill ("jiang") and not p:hasSkill(self:objectName()) then
					room:setPlayerProperty (p, "maxhp", sgs.QVariant(p:getMaxHp()+3))
					room:setPlayerProperty (p, "hp", sgs.QVariant(p:getMaxHp()))
					room:detachSkillFromPlayer(p, "jiang")
				end
				if p:hasSkill ("paoxiao") then
					room:setPlayerProperty (p, "maxhp", sgs.QVariant(p:getMaxHp()+3))
					room:setPlayerProperty (p, "hp", sgs.QVariant(p:getMaxHp()))
				end
				if p:hasSkill ("zishou") then
					room:setPlayerProperty (p, "maxhp", sgs.QVariant(p:getMaxHp()+2))
					room:setPlayerProperty (p, "hp", sgs.QVariant(p:getMaxHp()))
					room:detachSkillFromPlayer(p, "zishou")
				end
				if p:hasSkill ("luanji") then
					room:setPlayerProperty (p, "maxhp", sgs.QVariant(p:getMaxHp()+30))
					room:setPlayerProperty (p, "hp", sgs.QVariant(p:getMaxHp()))
					room:detachSkillFromPlayer(p, "luanji")
					room:acquireSkill(p, "benghuai")
				end
				if p:hasSkill ("kanpo") then
					room:killPlayer (p)
				end	
				if p:hasSkill("quanji") then
					room:detachSkillFromPlayer(p, "quanji")
					room:acquireSkill(p, "benghuai")
				end
				if not isFriend (p, player) then
					room:acquireSkill (p, "jile")
				end
				
			end
		elseif event == sgs.Damage then
			local damage=data:toDamage()
			local to=damage.to

			local D=damage.damage
			local M=player:getMaxHp()
			local H=player:getHp()
			local L=M-H
			if D<=L then
				healPlayer(player, D)
			else
				local dM=(D-L+1)/2
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp()+dM))
				local dH=(L+D)/2
				if dH>=1 then healPlayer(player, dH) end
			end
			
			if isFriend(player, to) and to:objectName() ~= player:objectName() then				
				local recover=sgs.RecoverStruct()
				recover.recover=1
				recover.who=player
				local toDraw=to:getLostHp()
				if toDraw>UP then toDraw=UP end
				room:drawCards(to, toDraw)
				room:recover(to, recover)
			end
		elseif event == sgs.DamageCaused then
			player:loseAllMarks("@nightmare")
			local damage=data:toDamage()
			local to=damage.to		
						
			local card = damage.card
			
			if card ~= nil then 
				if card:getNumber() >= 10 or card:getNumber() == 1 
					or card:getNumber() == 7
				then
					damage.nature = sgs.DamageStruct_Thunder
					data:setValue(damage)
				end
			end
			
			clearCertainSkills(to)

			if damage.nature == sgs.DamageStruct_Fire then
				damage.nature = sgs.DamageStruct_Thunder
				damage.damage = damage.damage - 1
				data:setValue(damage)			
			end
			if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("drank") and not damage.chain then
				damage.damage = damage.damage + 10
				data:setValue(damage)				
			end

			if isFriend(player, to) and to:objectName() ~= player:objectName() and damage.damage >= to:getHp() then
				local recover=sgs.RecoverStruct()
				recover.recover=1
				recover.who=player
				local toDraw=to:getLostHp()
				if toDraw>UP then toDraw=UP end
				room:drawCards(to, toDraw)
				room:recover(to, recover)
				return true
			end
			if not isFriend(player, to) then
				local weapon = player:getWeapon ()
				local plusOne=false
				plusOne = not(weapon and weapon:isKindOf ("GudingBlade"))				
				if damage.card:isKindOf ("Slash") and to:getHandcardNum()<=to:getHp() and not damage.to:hasSkill("jiangfei") and plusOne then
					damage.damage = damage.damage+1
					data:setValue(damage)
				end
				if damage.nature == sgs.DamageStruct_Thunder then
					damage.damage = damage.damage + 8
					data:setValue(damage)
				end
			end
		elseif event == sgs.TurnedOver then
			if not player:faceUp() and player:getHp() > 1 then
				room:loseHp (player, 1)
				player:turnOver()
			end
		elseif event == sgs.CardEffect then
			local effect = data:toCardEffect()
			if effect.card:isKindOf ("Nullification") then
				return true
			end
		elseif event == sgs.DrawNCards then 
			local count = data:toInt() + player:getMark("@baqi")
			data:setValue(count)
		end
	end
}
jiee = sgs.CreateFilterSkill{
	name = "#jiee",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return place == sgs.Player_PlaceHand 
			and (to_select:isKindOf ("Nullification") or to_select:isKindOf("IceSword") or to_select:isKindOf("Vine") or to_select:isKindOf("GudingBlade") or to_select:isKindOf("Collateral")
			or to_select:isKindOf("Fan"))
			or to_select:isKindOf("Slash") and to_select:getSuit() ~= sgs.Card_Heart
				
	end,
	
	view_as = function(self, card)
		local id = card:getId()
		local suit = sgs.Card_Heart
		local point = card:getNumber()
		local chain
		if card:isKindOf("Slash") and card:getSuit() ~= sgs.Card_Heart then
			local new_card = sgs.Sanguosha:getWrappedCard(id)
			new_card:setSkillName(self:objectName())
			new_card:setSuit(sgs.Card_Heart)
			new_card:setModified(true)
			return new_card
		else
			chain = sgs.Sanguosha:cloneCard("peach", suit, point)
			chain:setSkillName(self:objectName())
			local vs_card = sgs.Sanguosha:getWrappedCard(id)
			vs_card:takeOver(chain)
			return vs_card
		end
	end,
}


BTcaocao:addSkill ("nosjianxiong")
BTcaocao:addSkill ("wushuang")
BTcaocao:addSkill ("rende")
BTcaocao:addSkill (jiee)
BTcaocao:addSkill (baye)
BTcaocao:addSkill (bayeDistance)
-- BTcaocao:addSkill (bayeQiangxi)

sgs.LoadTranslationTable{
	["baye"]="霸业",
	["#bayeDistance"]="续命",
	["BTcaocao"]="曹操",
	["#jiee"]="嫉恶",
	["jile"]="极乐",
	[":jiee"]="<b>锁定技，</b>你的【无懈可击】均视为【桃】。",
	["@yeyan"]="夜魇",
	["@baqi"]="霸业",
	["@baqiNegative"]="我兔",
	["@comm"]="领袖",
	["bayeQiangxi"]="强X",
	
-- LogMessage translation
	["#baye_gamestart"] = "Your max hp is %arg"
}