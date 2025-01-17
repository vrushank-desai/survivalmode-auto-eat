Scriptname SMAutoScript extends Quest

; PROPERTIES ------------------------------------------------------------------

Actor Property PlayerRef  Auto
Race Property playerRace Auto hidden

GlobalVariable Property Survival_ModeEnabled  Auto
GlobalVariable Property Survival_HungerNeedValue  Auto

;/
   Index 0 = Survival_HungerRestoreVerySmallAmount
   Index 1 = Survival_HungerRestoreSmallAmount
   Index 2 = Survival_HungerRestoreMediumAmount
   Index 3 = Survival_HungerRestoreLargeAmount
/;
GlobalVariable[] Property hungerRestoreAmounts Auto

SPELL Property Survival_HungerStage0  Auto
SPELL Property Survival_HungerStage1  Auto
SPELL Property Survival_HungerStage2  Auto
SPELL Property Survival_HungerStage3  Auto
SPELL Property Survival_HungerStage4  Auto
SPELL Property Survival_HungerStage5  Auto

;/
   Index 0 = _SurvivalFood_VerySmall
   Index 1 = _SurvivalFood_Small
   Index 2 = _SurvivalFood_Medium
   Index 3 = _SurvivalFood_Large
/;
FormList[] Property eligibleFoodList Auto

FormList Property Survival_FoodRawMeat  Auto
FormList Property Survival_FoodPoisoningImmuneRaces Auto

FormList Property _SurvivalFood_Alcohol Auto

Keyword Property Survival_DiseaseFoodPoisoningKeyword Auto

Message Property _SMNoMoreFoodMessage Auto

String Property foodConsumedText  Auto
Bool Property noFoodMessageShown Auto

FormList Property _SurvivalFood_Whitelist Auto

; VARIABLES -------------------------------------------------------------------
Bool itemFound = False
String[] hungerLevels
SMAutoMCMScript mcmScript

String AUTO_EAT_IGNORE_KEYWORD = "Survival_IgnoreAutoEat"

; EVENT HANDLERS --------------------------------------------------------------

Event OnInit()
   PopulateHungerLevelDesc()
   mcmScript = (self As Form) As SMAutoMCMScript
EndEvent

Event OnUpdate()
   AutoEat()
EndEvent

; STATES ----------------------------------------------------------------------

State Busy
   Function AutoEat()
   EndFunction
EndState

; MAIN FUNCTIONS --------------------------------------------------------------

Function AutoEat()
   GoToState("Busy")
   Eat()
   RegisterForSingleUpdate(mcmScript.GetModSettingFloat("fPollingInterval:Extra"))
   GoToState("")
EndFunction

Function Eat()

   If (!ShouldAutoEat())
      return
   EndIf

   Bool targetWellFed = mcmScript.GetModSettingInt("iTargetLevel:AutoEat") == 0

   If (!IsPlayerHungry(targetWellFed))
      return
   EndIf

   Bool allowAlcohol = mcmScript.GetModSettingBool("bAllowAlcohol:AutoEat")

   itemFound = False

   If (allowAlcohol && CouldConsumeFromList(_SurvivalFood_Alcohol, (hungerRestoreAmounts[0]).GetValue() As Int, targetWellFed))
      noFoodMessageShown = False
      return
   EndIf

   Int index = 0

   While (index < eligibleFoodList.Length)

      If (CouldConsumeFromList(eligibleFoodList[index], (hungerRestoreAmounts[index]).GetValue() As Int, targetWellFed))
         noFoodMessageShown = False
         return
      EndIf

      index += 1

   EndWhile

   If (!itemFound && !noFoodMessageShown)

      Bool disableNotification = mcmScript.GetModSettingBool("bDisableNotification:AutoEat")

      If (!disableNotification)
         _SMNoMoreFoodMessage.Show()
      EndIf

   EndIf

EndFunction

String[] Function GetHighestHungerLevels()
   If (!hungerLevels)
      PopulateHungerLevelDesc()
   EndIf
   return hungerLevels
EndFunction

; HELPER FUNCTIONS ------------------------------------------------------------

Bool Function CouldConsumeFromList(FormList foodItemList, int hungerReductionAmount=0, Bool targetWellFed=False)

   If (PlayerRef.GetItemCount(foodItemList) <= 0)
      return False
   EndIf

   Bool cannotContractFoodPoisoning = PlayerCannotContractFoodPoisoning()

   Int i = 0

   While (i < foodItemList.GetSize())
      Potion consumable = foodItemList.GetAt(i) As Potion

      ; Allow only items flagged as food item and not poison or ignored
      If (consumable && consumable.IsFood() && CanBeConsumed(consumable))

         If ( (cannotContractFoodPoisoning || !Survival_FoodRawMeat.HasForm(consumable)) && PlayerRef.GetItemCount(consumable) > 0)
            itemFound = True
            LogMessage("Current Hunger Level: " + Survival_HungerNeedValue.GetValueInt() + ", hungerReductionAmount: " + hungerReductionAmount)

            If (Survival_HungerNeedValue.GetValueInt() < hungerReductionAmount) && !targetWellFed
               return False
            EndIf

            PlayerRef.EquipItem(consumable, abSilent=true)

            Debug.Notification(consumable.GetName() + foodConsumedText)

            return True
         EndIf

      EndIf

      i += 1

   EndWhile

   return False

EndFunction

Bool Function PlayerCannotContractFoodPoisoning()
   If (!playerRace)
      playerRace  = PlayerRef.GetRace()
   EndIf

   Float diseaseResistMult = PlayerRef.GetActorValue("DiseaseResist") / 100.000

   return diseaseResistMult >= 1.0000 || Survival_FoodPoisoningImmuneRaces.HasForm(playerRace) || PlayerRef.HasEffectKeyword(Survival_DiseaseFoodPoisoningKeyword)
EndFunction

Bool Function IsPlayerHungry(Bool targetWellFed=False)

   If (PlayerRef.HasSpell(Survival_HungerStage0))
      return False
   EndIf

   If (!targetWellFed && PlayerRef.HasSpell(Survival_HungerStage1))
      return False
   EndIf

   return PlayerRef.HasSpell(Survival_HungerStage1) || \
   PlayerRef.HasSpell(Survival_HungerStage2) || \
   PlayerRef.HasSpell(Survival_HungerStage3) || \
   PlayerRef.HasSpell(Survival_HungerStage4) || \
   PlayerRef.HasSpell(Survival_HungerStage5)

EndFunction

Bool Function ShouldAutoEat()

   ; Do nothing if Survival Mode is turned off
   If (Survival_ModeEnabled.GetValue() != 1.0)
      LogMessage("Survival Mode is disabled.")
      return False
   EndIf

   ; Do nothing if auto-eat is disabled
   If (!mcmScript.GetModSettingBool("bEnabled:AutoEat"))
      LogMessage("Auto-eat is disabled.")
      return False
   EndIf

   ; Prevent auto eat during combat
   If (PlayerRef.IsInCombat())
      LogMessage("Player is in combat. Food will not be consumed automatically.")
      return False
   EndIf

   If (PlayerRef.GetSleepState() != 0)
      LogMessage("Player is going to sleep or is waking up. Food will not be consumed automatically.")
      return False
   EndIf

   return True

EndFunction

Bool Function CanBeConsumed(Potion consumable)

   If (consumable.IsPoison()  || consumable.HasKeywordString(AUTO_EAT_IGNORE_KEYWORD))
      LogMessage(consumable.GetName() + " is flagged as a poison or is marked as ignored. Ignoring...")
      return False
   EndIf

   Bool useWhitelistOrFavorite = mcmScript.GetModSettingBool("bUseWhitelistOrFavorite:AutoEat")
   Bool isConsumableWhiteListed = Game.IsObjectFavorited(consumable) || _SurvivalFood_Whitelist.Find(consumable) > 0

   If (useWhitelistOrFavorite && !isConsumableWhiteListed)
      LogMessage("Whitelisting is enabled and " + consumable.GetName() + " is not whitelisted or marked as favorite. Ignoring...")
      return False
   EndIf

   return True

EndFunction

Function PopulateHungerLevelDesc()
   hungerLevels = New String[2]
   hungerLevels[0] = Survival_HungerStage0.GetName()
   hungerLevels[1] = Survival_HungerStage1.GetName()
EndFunction

Function LogMessage(String sMessage)
   Debug.Trace("[SMAE] - " + sMessage)
EndFunction