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

quit 2 {}

login_account 3 {
	request {
		account 0 : string
		password 1 : string
	}
}

add_account 4 {
	request {
		account 1 : string
		password 2 : string
	}
}

add_user 5 {
	request {
		name 0 : string
	}
}

login_user 6 {
	request {
		uid 0 : integer
		name 1 : string
	}
}

login_game 7 {
	request {
		uid 0 : integer
		subid 1 : integer
		account 2 : string
	}
}

logic_data 8 {
	request {
		data 0 : string
		index 1 : integer
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
		subid 3 : integer
		port 4 : integer
	}
}

user_list 6 {
	request {
		amount 0 : integer

		.UserInfo {
        	uid 0 : integer
        	name 1 : string
		}
		
		user 1 : *UserInfo
	}
}

login_game 7 {
	request {
		result 0 : integer
		uid 1 : integer
		desc 2 : string
	}
}

]]

return proto
