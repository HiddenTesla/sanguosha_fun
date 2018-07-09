module("extensions.bob", package.seeall)
extension = sgs.Package("bob")

local mallory = require("extensions/mallory")

bob=sgs.General(extension, "bob","wei", 4, true)

bob:addSkill(mallory.marv)