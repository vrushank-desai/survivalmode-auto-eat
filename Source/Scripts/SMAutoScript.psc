Scriptname SMAutoScript extends Quest

; PROPERTIES ------------------------------------------------------------------

Actor Property PlayerRef  Auto
Race Property playerRace Auto hidden

GlobalVariable Property Survival_ModeEnabled  Auto
GlobalVariable Property Survival_HungerNeedValue  Auto

GlobalVariable Property Survival_HungerRestoreVerySmallAmount  Auto
GlobalVariable Property Survival_HungerRestoreSmallAmount  Auto
GlobalVariable Property Survival_HungerRestoreMediumAmount  Auto
GlobalVariable Property Survival_HungerRestoreLargeAmount  Auto

SPELL Property Survival_HungerStage0  Auto
SPELL Property Survival_HungerStage1  Auto
SPELL Property Survival_HungerStage2  Auto
SPELL Property Survival_HungerStage3  Auto
SPELL Property Survival_HungerStage4  Auto
SPELL Property Survival_HungerStage5  Auto

FormList Property _SurvivalFood_VerySmall  Auto
FormList Property _SurvivalFood_Small  Auto
FormList Property _SurvivalFood_Medium  Auto
FormList Property _SurvivalFood_Large  Auto
FormList Property AutoEatBlackList  Auto

FormList Property Survival_FoodRawMeat  Auto
FormList Property Survival_FoodPoisoningImmuneRaces Auto

Keyword Property Survival_DiseaseFoodPoisoningKeyword Auto

Message Property _SMNoMoreFoodMessage Auto

String Property foodConsumedText  Auto

Bool Property noFoodShown  Auto
