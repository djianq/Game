ALL_LANGS={"en","tw"}  -- 支持的语言
TARGET_LANG = os.getenv("TARGET_LANG")  -- 环境变量中获取目标语言
AutoConvertCfg = {
	["tw"] = {
		["CharFiles"] = {"STCharacters"},
		["SPhrasesFiles"] = {"STPhrases"},
		["PhrasesFiles"] = {"TWPhrasesIT","TWPhrasesName","TWPhrasesOther","TWVariants"},
	},
}
