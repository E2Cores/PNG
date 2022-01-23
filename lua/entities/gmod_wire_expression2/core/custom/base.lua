E2Lib.RegisterExtension("base", true, "Base E2 Core")

registerCallback("construct", function(self)
	self.data.x = {}
end)

__e2setcost(5)
e2function number foo(number n)
	return n
end