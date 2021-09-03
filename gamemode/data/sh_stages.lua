GAMESTAGE_BASEPLACE = 1
GAMESTAGE_BUILD = 2
GAMESTAGE_PLAY = 3

DAC.DefaultGameStage = GAMESTAGE_BASEPLACE

DAC:RegisterGameStage(GAMESTAGE_BASEPLACE, {
	name = "SETUP",
	showOnHud = true,
	pvp = false,
	nextStage = nil,
	color = Color(0, 130, 255)
})

DAC:RegisterGameStage(GAMESTAGE_BUILD, {
	name = "BUILD",
	showOnHud = true,
	pvp = false,
	allowBuilding = true,
	nextStage = GAMESTAGE_PLAY,
	duration = 0.5, -- Should ideally use a CVar here over a hardcoded value
	color = Color(0, 255, 0)
})

DAC:RegisterGameStage(GAMESTAGE_PLAY, {
	name = "BATTLE",
	showOnHud = true,
	pvp = true,
	nextStage = nil,
	color = Color(255, 0, 0)
})