shared = {}
shared.hidden = true

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

function shared:isFriend(p1, p2)
    return getHouse(p1) == getHouse(p2) 
end

function shared:killAllRenegades(room)
    for _, alive in sgs.qlist(room:getAlivePlayers()) do
        local role = alive:getRole() 
        if role == "renegade" then
            room:killPlayer(alive)
        end
    end
end

shared.fuyin = sgs.CreateTriggerSkill {
    name = "shared_fuyin",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Death},
    on_trigger = function(self, event, player, data)
        if player:getRole() ~= "rebel" then
            return false
        end
        local room = player:getRoom()
        local death = data:toDeath()
        local deadman = death.who

        if deadman:getRole() ~= "rebel" then
            return false
        end

        local nLoyalist = 0
        local nRebel = 0
        for _, alive in sgs.qlist(room:getAlivePlayers()) do
            local role = alive:getRole() 
            if role == "loyalist" then
                    nLoyalist = nLoyalist + 1
            elseif role == "rebel" then
                    nRebel = nRebel + 1
            end
        end
        if (nLoyalist >= nRebel or deadman:objectName() == player:objectName()) and nLoyalist > 0 then
            shared:killAllRenegades(room)
        end
    end,

    can_trigger = function(self, target)
        return target:hasSkill(self:objectName())
    end
}

shared.dutao = sgs.CreateTriggerSkill {
    name = "shared_dutao",
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

sgs.LoadTranslationTable {
    ["shared_fuyin"] = "福音",
    [":shared_fuyin"] = "<b>反贼技，锁定技，</b>每当你或另一名反贼死亡时，若此时存活的忠臣数不少于反贼数，则内奸立即死亡。",
    ["shared_dutao"] = "毒桃",
    [":shared_dutao"] = "<b>反贼技，锁定技，</b>每当内奸对一名角色使用【桃】时，该【桃】无效，该角色失去1点体力上限且该内奸立即死亡。",
}

return shared
