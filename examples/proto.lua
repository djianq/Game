local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

handshake 1 {
	response {
		msg 0  : string
	}
}

get 2 {
	request {
		what 0 : string
	}
	response {
		result 0 : string
	}
}

set 3 {
	request {
		what 0 : string
		value 1 : string
	}
}

quit 4 {}

login_account 5 {
	request {
		account 0 : string
		password 1 : string
	}
}

add_account 6 {
	request {
		account 1 : string
		password 2 : string
	}
}

add_user 7 {
	request {
		name 0 : string
	}
}

login_user 8 {
	request {
		uid 0 : integer
		name 1 : string
	}
}

]]

proto.s2c = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

heartbeat 1 {}

login_account 2 {
	request {
		result 0 : integer
		desc 1 : string
	}
}

add_account 3 {
	request {
		result 0 : integer
		account 1 : string
		password 2 : string
		desc 3 : string
	}
}

add_user 4 {
	request {
		result 0 : integer
		name 1 : string
		desc 2 : string
		uid 3 : integer
	}
}

login_user 5 {
	request {
		result 0 : integer
		desc 1 : string
		uid 2 : integer
	}
}

]]

return proto
