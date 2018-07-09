module("extensions.alice", package.seeall)
extension = sgs.Package("alice")

local mallory = require("extensions/mallory")

alice=sgs.General(extension, "alice","wei", 4, false)
