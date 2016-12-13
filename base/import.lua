--代替Lua本身的module, require机制
_G._ImportModule = _G._ImportModule or {}
local _ImportModule = _G._ImportModule

ALL_CLASS = ALL_CLASS or {}	-- 全局变量，记录所有 Class 与 Class:GetType() 对应关系
ALL_CLASS_PATH = ALL_CLASS_PATH or {}
setmetatable(ALL_CLASS, {__mode = "kv"})


local function SafeImport(PathFile, Reload)
	if PathFile[0] == '.' or PathFile[0] == '/' then
		return nil, "forbidden import"
	end

	local Old = _ImportModule[PathFile]
	if Old and not Reload then
		return Old
	end

	--****先loadfile再clear环境
	local func, err = loadfile(PathFile)
	if not func then
		return func, err
	end

	local function CallInit(Module)

		-- 注册所有的 Class 到 ALL_CLASS 里去，依赖 Class:GetType() 属性，注意：只遍历 1 层
		for _, v in pairs(Module) do
			if type(v) == "table" and rawget(v, "__ClassType") then
				local ClassType = v:GetType()
				local OldPath = ALL_CLASS_PATH[ClassType]
				if OldPath then
					print("class type repeat regiest:" .. ClassType .. OldPath .. " " .. PathFile)
				else
					ALL_CLASS_PATH[ClassType] = PathFile
				end
				local oldClass = ALL_CLASS[ClassType]
				if oldClass then
					assert(oldClass == v, "class repeat:" .. ClassType)
				end
				ALL_CLASS[ClassType] = v
			end
		end
		
		-- 载入模块时调用其构造函数
		if Module.__init__ then
			Module:__init__()
		end
	end

	local function CallDestroy(Module)
		if Module.__destroy__ then
			Module:__destroy__()
		end	

		local metatable = getmetatable(Old)
		if metatable["__newindex"] then
			metatable["__newindex"] = nil
		end
	end

	local function CallUpdate(Module)
		if Module.__update__ then
			Module:__update__()
		end
	end

	--第一次载入，不存在更新的问题
	if not Old then
		_ImportModule[PathFile] = {}
		local New = _ImportModule[PathFile]
		--设置原始环境
		setmetatable(New, {__index = _G})
		setfenv(func, New)()
		CallInit(New)
		return New
	end
end

function Import(PathFile)
	local Module, Err = SafeImport(PathFile, false)
	assert(Module, Err)
	return Module
end

--系统启动时执行此函数，调用_ImportModule中所有预载入模块的Startup函数
function ExeModuleStartup()
	--注意:**先复制一份Module表，因为调用SystemStartup的时候有可能改变这个table。
	local _copy = {}
	for k, v in pairs(_ImportModule) do
		_copy[k] = v
	end

	for File, ModuleObj in pairs(_copy) do
		if ModuleObj.SystemStartup then
			ModuleObj:SystemStartup()
		end
	end
end
