--module("extensions.shared", package.seeall)
-- extension = sgs.Package("shared")

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

shared.fuyin_renegade = sgs.CreateTriggerSkill {
    name = "shared_fuyin_renegade",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Death},
    on_trigger = function(self, event, player, data)
        print(player:objectName())
        if player:getRole() ~= "renegade" then
            return false
        end
        local room = player:getRoom()
        local nLoyalist = 0
        local nRebel = 0
        for _, alive in sgs.qlist(room:getAlivePlayers()) do
           local role = alive:getRole() 
           if role == "loyalist" then
                nLoyalist = nLoyalist + 1
           elseif role == "rebel" then
                nReble = nRebel + 1
           end
           print(nLoyalist, nRebel)
           if nLoyalist >= nRebel then
               room:killPlayer(player)
           end
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}

shared.fuyin = sgs.CreateTriggerSkill {
    name = "shared_fuyin",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        for _, target in sgs.qlist(room:getOtherPlayers(player)) do
            if target:getRole() == "renegade" then
                print("dss")
                room:acquireSkill(target, "shared_fuyin_renegade", true)
                print(target:objectName() .. " acquires")
            end
        end
    end
}

sgs.LoadTranslationTable {
    ["shared_fuyin"] = "福音",
    [":shared_fuyin"] = "<b>锁定技，</b>每当一名角色死亡时，若此时存活的忠臣数不少于反贼数，则内奸立即死亡。即使你已死亡，该触发依然生效。",
    ["shared_fuyin_renegade"] = "hidden",
}

return shared
