module("extensions.fun3", package.seeall)
extension = sgs.Package("fun3")
baolei=sgs.General(extension, "baolei$","god", 4, true, true)
ck=sgs.General(extension, "ck","wei", 6)
mercury=sgs.General(extension, "mercury","wei", 5,true,true)

function sendLog (self, player)
	local room=player:getRoom()
	local message= sgs.LogMessage()
	message.type = "#TriggerSkill"
	message.from = player
	message.arg  = self:objectName()
	room:sendLog(message)
end

nengliangCard = sgs.CreateSkillCard{
	name = "nengliangCard", 
	target_fixed = false,
	will_throw = true, 
	filter = function(self, targets, to_select) 
		return #targets==0
	end,
	on_use = function(self, room, source, targets) --几乎必须
		local dest=targets[1]
		local player=source
		player:loseMark("@power",1)
		if dest:isWounded() then dest:drawCards(2)
		else dest:drawCards(4) end
		local theRecover=sgs.RecoverStruct()
		theRecover.recover=1
		theRecover.who=player
		room:recover(dest,theRecover)
	end,
}
hundunCard = sgs.CreateSkillCard{
	name = "hundunCard", 
	target_fixed = false,
	will_throw = true, 
	filter = function(self, targets, to_select) 
		return #targets==0 and to_select:objectName()~=sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local dest=targets[1]
		local judge=sgs.JudgeStruct()
		--source:turnOver()
		room:loseHp(source,1)
		judge.pattern="."
		judge.good=true
		judge.who=dest
		room:judge(judge)
		local count=judge.card:getNumber()
		if count<5 then count=5
		elseif count>10 then count=10 end
		local suit=judge.card:getSuit()
		if suit==sgs.Card_Club then
			room:loseHp(dest,count)
		else
			local damage=sgs.DamageStruct()
			damage.from=source
			damage.to=dest
			damage.damage=count
			if suit==sgs.Card_Heart then
				damage.nature=sgs.DamageStruct_Fire
				-- damage.chain=true
				-- damage.trigger_chain=true
			elseif suit==sgs.Card_Spade then
				damage.nature=sgs.DamageStruct_Thunder
				-- damage.chain=true
				-- damage.trigger_chain=true
			elseif suit==sgs.Card_Diamond then
				damage.nature=sgs.DamageStruct_Normal
			end
			room:setPlayerProperty(source,"chained",sgs.QVariant(false))
			room:setPlayerProperty(dest,"chained",sgs.QVariant(true))
			room:damage(damage)
			--room:detachSkillFromPlayer(source,"hundun")
		end
	end,
}
hundun = sgs.CreateViewAsSkill{
	name = "hundun",
	n = 4,
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() then return false end
		if #selected==0 then return true
		elseif #selected==1 then return to_select:getSuit()~=selected[1]:getSuit()
		elseif #selected==2 then return to_select:getSuit()~=selected[1]:getSuit() and to_select:getSuit()~=selected[2]:getSuit() 
		elseif #selected==3 then return to_select:getSuit()~=selected[1]:getSuit() and to_select:getSuit()~=selected[2]:getSuit() and to_select:getSuit()~=selected[3]:getSuit() 
		end
	end, 
	view_as = function(self, cards)
		if #cards~=4 then return nil end
		local vs_card=hundunCard:clone()
		for i=1,#cards,1 do
			vs_card:addSubcard(cards[i])
		end
		return vs_card
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#hundunCard")
	end, 
}
nengliang = sgs.CreateViewAsSkill{
	name = "nengliang", --必须
	n = 0, --必须
	view_filter = function(self, selected, to_select)
		return #selected==0
	end, 
	view_as = function(self, cards) 
		if #cards~=0 then return nil end
		local vs_card=nengliangCard:clone()
		return vs_card
	end, 
	enabled_at_play = function(self, player)
		return player:getMark("@power")>0 and not player:hasUsed("#nengliangCard")
	end, 	
}
nengliangGet = sgs.CreateTriggerSkill{
	name = "#nengliang-getMark", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.Damaged,sgs.Damage,sgs.GameStart}, 
	on_trigger = function(self, event, player, data)
		if event==sgs.GameStart then --游戏开始时获得2个能量标记
			player:gainMark("@power",2)
		elseif event==sgs.Damaged or event==sgs.Damage then --每受到或造成1点伤害后获得1个能量标记	
			local room=player:getRoom()
			player:gainMark("@power",data:toDamage().damage)
			if player:getMark("@power") >= 3 then
				if room:askForSkillInvoke(player,"nengliangGet_ask",data) then
					player:loseMark("@power",3)
					local mhp=sgs.QVariant()
					mhp:setValue(player:getMaxHp()+1)
					room:setPlayerProperty(player,"maxhp",mhp)
					local theRecover=sgs.RecoverStruct()
					theRecover.recover=1
					theRecover.who=player
					room:recover(player,theRecover)
				end
			end
		end
	end, 
}
junfu = sgs.CreateTriggerSkill{
	name = "junfu",
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.GameStart, sgs.TurnStart, sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room=player:getRoom()
		if event == sgs.GameStart or event == sgs.TurnStart then			
			local playerlist=room:getOtherPlayers(player)
			for _,dest in sgs.qlist(playerlist) do
				if dest:hasSkill("weimu") then room:detachSkillFromPlayer(dest,"weimu") end
				if dest:hasSkill("yizhong") then room:detachSkillFromPlayer(dest,"yizhong") end
				if dest:hasSkill("yaowu") then room:detachSkillFromPlayer(dest,"yaowu") end
				if dest:hasSkill("shiyong") then 
					room:detachSkillFromPlayer(dest,"shiyong")
					room:loseMaxHp (dest, 1)
				end
			end	
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end
			
			for _, p in sgs.qlist(use.to) do
				local armor=p:getArmor()
				if armor and armor:isKindOf ("RenwangShield") then 
					room:throwCard (armor, p)
					local damage=sgs.DamageStruct()
					room:damage(sgs.DamageStruct(self:objectName(), player, p, 2, sgs.DamageStruct_Thunder))			
				end
			end
			
		end
	end, 
}

qingzhuang = sgs.CreateTriggerSkill{
	name = "qingzhuang", --必须 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data) --必须
		local room=player:getRoom()
		local change=data:toPhaseChange()
		local phase=change.to
		if phase==sgs.Player_Judge and not player:isSkipped(phase) then
			player:skip(phase)
		end
	end, 
}
dunjia = sgs.CreateTriggerSkill{
	name = "dunjia",
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging}, 
	on_trigger = function(self, event, player, data)
		local room=player:getRoom()
		if event==sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Draw then
				if not player:askForSkillInvoke(self:objectName()) then return end
				local judge=sgs.JudgeStruct()
				judge.who=player
				judge.good=true
				judge.pattern="."
				room:judge(judge)
				room:setPlayerFlag(player,"dunjia_used")
				local card=judge.card
				local count=card:getNumber()
				
				if count>10 then count=10
				elseif count==1 then count=10 end
				local toThrow=nil
				
				if not player:isKongcheng() then --如果没有空城，则可以选择弃一张与判定牌花色不同的手牌
					if card:isRed() then toThrow=room:askForCard(player, ".|black|.", "dunjia_discardBlack", data)
					else toThrow=room:askForCard(player, ".|red|.", "dunjia_discardRed", data) end
					if toThrow then room:throwCard(toThrow,player)
					else room:loseHp(player) end
				else
					room:loseHp(player)
				end
				
				player:drawCards(count)
				return true
			end
		else
			local change=data:toPhaseChange()
			local phase=change.to
			if phase==sgs.Player_Discard and not player:isSkipped(phase) and player:hasFlag("dunjia_used") then
				player:skip(phase)
			end
		end --if event==sgs.EventPhaseStart then
	end, 
}

xuwu = sgs.CreateTriggerSkill{
	name = "xuwu", --必须 
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardEffected},
	on_trigger = function(self, event, player, data) --必须
		local room = player:getRoom()
		local effect = data:toCardEffect()
		if effect.from:hasSkill(self:objectName()) then return false end
		if effect.card:isKindOf("ExNihilo") then
			local list=room:getAlivePlayers()
			for _,p in sgs.qlist(list) do
				if p:hasSkill(self:objectName()) then p:drawCards(3) end
			end
			return true
		end
		if effect.card:isKindOf("AmazingGrace") then
			if effect.to:hasSkill(self:objectName()) 
				then player:drawCards(2)
			else
				return true
			end
		end
		
	end, 
	can_trigger = function(self, target)
		return target
	end,
}

yongsheng = sgs.CreateTriggerSkill{
	name = "yongsheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AskForPeachesDone, sgs.Dying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AskForPeachesDone then
			local dying_data = data:toDying()
			local source = dying_data.who
			if source:hasSkill(self:objectName()) and player:getHp() < 1 then
					source:throwAllCards()
					local maxhp = player:getMaxHp()
					local hp = math.min(3, maxhp)
					room:setPlayerProperty(source, "hp", sgs.QVariant(hp))
					source:drawCards(3)
					if player:isChained() then
						local damage = dying_data.damage
						if (damage == nil) or (damage.nature == sgs.DamageStruct_Normal) then
							room:setPlayerProperty(player, "chained", sgs.QVariant(false))
						end
					end
					if not player:faceUp() then
						player:turnOver()
					end
			end
			return false
		elseif event == sgs.Dying then
			local dying=data:toDying()
			local dyer=dying.who
			if player:getHp()<=0 or not room:askForSkillInvoke(player, self:objectName(), data) then return end
			room:loseHp(player)
			room:setPlayerProperty(dyer, "hp", sgs.QVariant(1))			
		end
	end,
}

zheshe = sgs.CreateTriggerSkill{
	name = "zheshe", --必须 
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged, sgs.EventPhaseStart}, 
	-- events = {sgs.Damaged}, 
	on_trigger = function(self, event, player, data) 
		local trigger = false
		if event == sgs.Damaged or player:getPhase()==sgs.Player_Start then trigger=true end
		-- if event == sgs.Damaged then trigger=true end
		if trigger then
			local room=player:getRoom()
			local ids=room:getNCards(5)
			local t=0
			room:fillAG(ids,player)
			for t=1,5,1 do
				local id=room:askForAG(player, ids, true, self:objectName())
				room:obtainCard(player,id,false)
			end			
			room:clearAG()		
		end
	end, 
}

yinlei = sgs.CreateTriggerSkill{
	name = "yinlei", --必须 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageCaused, sgs.DamageInflicted}, 
	on_trigger = function(self, event, player, data)
		if event == sgs.DamageCaused then
			local damage=data:toDamage()
			if not damage.from:hasSkill(self:objectName()) then return false end
			if damage.nature ~= sgs.DamageStruct_Thunder then
				damage.nature = sgs.DamageStruct_Thunder
			end
			data:setValue(damage)
		elseif event == sgs.DamageInflicted then
			local damage=data:toDamage()
			local room=player:getRoom()
			local source=room:findPlayerBySkillName(self:objectName())
			if  damage.nature == sgs.DamageStruct_Thunder and (damage.from==nil or damage.from:objectName() ~= source:objectName()) then
				damage.from = source
				data:setValue(damage)
			end
			if  damage.nature ~= sgs.DamageStruct_Thunder and damage.to:hasSkill(self:objectName()) then return true end
		end
	end, 
	can_trigger = function(self, target)
		return target
	end, 

}

nifan = sgs.CreateTriggerSkill{
	name = "nifan", --必须 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.GameStart, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data) --必须
		local room=player:getRoom()
		if event == sgs.GameStart then
			if not player:hasSkill(self:objectName()) then return end
			local originalRole = player:getRole()
			if originalRole ~= "rebel" then			
				room:setPlayerProperty(player, "role", sgs.QVariant("rebel"))
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getRole() == "rebel" then
						room:setPlayerProperty(p, "role", sgs.QVariant(originalRole))
						break
					end
				end			
			end	
		else
			if not (player:getPhase()==sgs.Player_Start or player:getPhase()==sgs.Player_Finish) then return end
			if not (player:getPhase()==sgs.Player_Finish) then return end
			if player:getRole() == "loyalist" or player:getRole() == "lord" then
				player:throwAllHandCardsAndEquips()
				room:loseHp(player)
			elseif player:getRole() == "renegade" then
				room:loseMaxHp(player)
			end
		end
	end, 
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}

-- 以下技能用测试：如果将can_trigger改为“具有技能” 后，“受到伤害后”触发的技能是否能够死亡后发动
-- 实测可以
damageTest = sgs.CreateTriggerSkill{
	name = "damageTest", --必须 
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged}, 
	on_trigger = function(self, event, player, data) --必须
		local room=player:getRoom()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getRole() == "lord" then
				room:killPlayer(p)
			end
		end
	end, 
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end, 
}

skill2 = sgs.CreateTriggerSkill{
	name = "skill2", --必须 
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TurnStart, sgs.GameStart}, 
	on_trigger = function(self, event, player, data) --必须
		local room=player:getRoom()
		room:loseHp(player)
		local plist = sgs.PlayerList()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getHp() <=3 then
				plist:append(p)
				room:drawCards(p,1)
			end
		end
		--local dest = room:askForPlayerChosen(player,room:getAlivePlayers(),self:objectName())		
		local dest = room:askForPlayerChosen(player, plist ,self:objectName())		
	end, 
}

yizhi = sgs.CreateTriggerSkill{
	name = "yizhi$", 
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.GameStart, sgs.AskForPeachesDone},
	on_trigger = function(self, event, player, data)
		local room=player:getRoom()
		if event == sgs.GameStart then
			if player:getRole() ~= "lord" then
				room:detachSkillFromPlayer (player, self:objectName())
			end
		elseif event == sgs.AskForPeachesDone then
			if player:getHp() >=1 then return end
			local loyal = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
			if loyal then
				player:drawCards(1)
				loyal:drawCards(2)
			end			
			if loyal and loyal:getRole()=="loyalist" then
				room:setPlayerProperty(player, "role", sgs.QVariant("loyalist"))
				room:setPlayerProperty(loyal, "role", sgs.QVariant("lord"))
				room:setPlayerProperty(loyal, "maxhp", sgs.QVariant(loyal:getMaxHp()+1))			
				room:setPlayerProperty(loyal, "hp", sgs.QVariant(loyal:getHp()+1))
				for _, skill in sgs.qlist(player:getVisibleSkillList()) do
					if not loyal:hasSkill(skill) then
						room:acquireSkill(loyal, skill) 
					end
				end				
			end
		end
	end, 
	-- can_trigger = function(self, target)
		-- return target and target:hasSkill(self:objectName()) and target:getRole()=="lord"
	-- end, 
}
function isFriend (player1, player2) --判断两名玩家是否属于同一阵营
	local r1=player1:getRole()
	local r2=player2:getRole()
	if r1==r2 then return true end
	if r1=="lord" and r2=="loyalist" then return true end
	if r2=="lord" and r1=="loyalist" then return true end
	return false
end

toutao = sgs.CreateTriggerSkill{
	name = "toutao",
	events = {sgs.CardEffected, sgs.EventPhaseStart, },
	frequency = sgs.Skill_Compulsory, 
	on_trigger = function(self, event, player, data)
		local room=player:getRoom()
		if event == sgs.CardEffected then 
			local use = data:toCardEffect()
			local monkey = room:findPlayerBySkillName(self:objectName())
			local dest=use.to
			local card=use.card
			if (card:isKindOf("Peach") or card:isKindOf("Analeptic")) and not isFriend(use.from, monkey) then
				room:obtainCard (monkey, card)
				-- sendLog (self, monekey) 不知道为什么加了这一句之后，桃就从无效变成有效了
				return true
			elseif (use.card:isKindOf("GodSalvation") or use.card:isKindOf("AmazingGrace"))and not isFriend(dest, monkey) then
				room:loseHp(dest)
				if not use.from:hasSkill (self:objectName()) then room:obtainCard(monkey, use.card) end
				sendLog (self, monkey)
				return true
			elseif (use.card:isKindOf("SavageAssault") or use.card:isKindOf("ArcheryAttack"))and isFriend(dest, monkey) then
				local recover=sgs.RecoverStruct()
				recover.recover=1
				recover.card=card
				recover.who=monkey
				room:recover(dest, recover)
				if not use.from:hasSkill (self:objectName()) then room:obtainCard(monkey, use.card) end
				sendLog (self, monkey)
				return true
			end
		elseif event == sgs.EventPhaseStart then
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

mili = sgs.CreateProhibitSkill{
	name = "mili",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("Slash") or card:isKindOf("Indulgence") or card:isKindOf("ArcheryAttack"))
	end
}

baolei:addSkill(xuwu)
baolei:addSkill(junfu)
baolei:addSkill(yizhi)

-- ck:addSkill(hundun)
ck:addSkill("nosyiji")
-- ck:addSkill("nosrende")
-- ck:addSkill(yongsheng)
mercury:addSkill(mili)
mercury:addSkill("luanwu")


sgs.LoadTranslationTable{
	["fun3"]="娱乐3",
	["baolei"]="堡垒",
	["@power"]="能量",
	["ck"]="混沌骑士",
	["mercury"]="幽鬼",
	["nengliangGet_ask"]="你想增吗？",
	["dunjia"]="遁甲",
	[":dunjia"]="摸牌阶段，你可以放弃摸牌并进行一次判定：你弃一张与此判定牌颜色不同的手牌或失去1点体力，然后摸X张牌，X为此判定牌的点数且A，J，Q，K均视为10。若如此做，你跳过此回合的弃牌阶段。",
	["dunjia_discardBlack"]="请弃一张黑色手牌，否则失去1点体力。",
	["dunjia_discardRed"]="请弃一张红色手牌，否则失去1点体力。",
	["xuwu"]="虚无",
	[":xuwu"]="<b>锁定技，</b>任意角色使用【无中生有】时，此【无中生有】无效，然后你摸2张牌。",
	["yongsheng"]="永生",
	[":yongsheng"]="<b>锁定技，</b>当你处于濒死状态时，你弃置你区域里所有的牌，然后将你的武将牌翻至正面朝上并重置之，再摸三张牌且体力回复至3点。",
	["junfu"]="均富",
	[":junfu"]="<b>锁定技，</b>游戏开始时，所有角色均失去【毅重】和【帷幕】技能。当你指定一名角色为【杀】的目标时，若其装备有【仁王盾】，须将【仁王盾】弃置，然后你对其造成2点伤害。",
	["yinlei"]="引雷",
	[":yinlei"]="<b>锁定技，</b>你造成的伤害均视为雷电伤害。你是所有雷电伤害的伤害来源。",
	["nifan"]="逆反",
	[":nifan"]="<b>锁定技，</b>游戏开始时，若你的身份为忠臣，你将身份改为反贼，场上另一名反贼变为忠臣。主公和忠臣的回合准备阶段和结束阶段开始时，须弃掉所有牌。",
	["yizhi"]="遗志",
	[":yizhi"]="<b>主公技，</b>当你死亡时，你可以指定一名角色，若该角色为忠臣，则其将身份改为主公，增加1点体力上限并回复1点体力，获得你的全部技能，游戏继续。",
	["toutao"]="偷桃",
	[":toutao"]="<b>锁定技，</b>当有一名角色使用【桃】时，若其与你不同阵营，则此【桃】无效且你获得之。",
	["mili"]="迷离",
	
}