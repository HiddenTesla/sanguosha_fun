mallory = {}
mallory.hidden = true

mallory.marv = sgs.CreateTriggerSkill {
    name = "marv",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data)
        return false
    end
}

return mallory
