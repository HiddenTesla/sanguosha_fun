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

sgs.LoadTranslationTable {
    ["shared_fuyin"] = "福音",
    [":shared_fuyin"] = "<b>反贼技，锁定技，</b>每当你或另一名反贼死亡时，若此时存活的忠臣数不少于反贼数，则内奸立即死亡。",
}

return shared
