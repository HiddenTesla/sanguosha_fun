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

anlushan:addSkill(wizard_qinding)
anlushan:addSkill(wizard_lianren)

mayun:addSkill(wizard_guisuo)

sgs.LoadTranslationTable{

	["wizard"] = "真正的粉丝",

	["anlushan"] = "安禄山",
	["#anlushan"] = "连任狂膜",
	["designer:anlushan"] = "Erwin",
	
	["wizard_qinding"] = "钦定",
	[":wizard_qinding"] = "<b>锁定技，</b>当你受到无色【杀】的伤害或流失体力后，你将武将牌翻至正面朝上。",
	
	["wizard_lianren"] = "连任",
	[":wizard_lianren"] = "若你于出牌阶段使用了至少一张红色牌，回合结束开始时，你可以进行一个额外的回合。",
    
    ["mayun"] = "马云",
    ["wizard_guisuo"] = "龟缩",
	[":wizard_qinding"] = "<b>锁定技，你的手牌无上限</b>",
}