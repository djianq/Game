--基础类库

--获取一个class的父类
function Super(TmpClass)
	return getmetatable(TmpClass).__index
end

--判断一个class或者对象是否
function IsSub(clsOrObj, Ancestor)
	local Temp = clsOrObj
	while 1 do
		local mt = getmetatable(Temp)
		if mt then
			Temp = mt.__index
			if Temp == Ancestor then
				return true
			end
		else
			return false
		end
	end
end

--暂时没有一个比较好的方法来防止将Class的table当成一个实例来使用
--大家命名一个Class的时候一定要和其产生的实例区别开来。
clsObject = 
{
	--用于区别是否是一个对象 or Class or 普通table
	__ClassType = "<base class>"
}
		
function clsObject:Inherit(clsName, o)	
	o = o or {}
	o.mt = {__index = o}
	assert(clsName, "must have clsTypeName")
	o.__ClassType = clsName
	o.__InheritMap = {[self:GetType()] = true}  -- 记录继承类型
	o.__InheritSelf = false
	if self.__InheritMap then
		for UpType, _ in pairs(self.__InheritMap) do
			o.__InheritMap[UpType] = true
		end
	end
	--没有对table属性做深拷贝，如果这个类有table属性应该在init函数中初始化
	--不应该把一个table属性放到class的定义中

	setmetatable(o, {__index = self})
	return o
end

function clsObject:IsSubObj(ObjType)
	return self:GetTypeMap()[ObjType]
end

function clsObject:GetTypeMap()
	local clsSelf = getmetatable(self)
	if clsSelf then
		local Temp = clsSelf.__index
		if not Temp.__InheritSelf then
			Temp.__InheritMap[Temp:GetType()] = true
			Temp.__InheritSelf = true
		end
		return Temp.__InheritMap
	end
	return {}
end

function clsObject:New(...)
	local o = {}

	--没有初始化对象的属性，对象属性应该在init函数中显示初始化
	--如果是子类，应该在自己的init函数中先调用父类的init函数
	setmetatable(o, self.mt)

	if o.__init__ then
		o:__init__(...)
	end
	return o
end

function clsObject:__init__()
	--nothing
end

function clsObject:IsClass()
	return true
end

function clsObject:Destroy()
	--所有对象释放的时候删除相关变量
end

function clsObject:GetType()
	return self.__ClassType
end
