Scriptname SMAutoScript extends Quest

; PROPERTIES ------------------------------------------------------------------

Actor Property PlayerRef  Auto
Race Property playerRace Auto hidden

GlobalVariable Property Survival_ModeEnabled  Auto
GlobalVariable Property Survival_HungerNeedValue  Auto

GlobalVariable[] Property hungerRestoreAmounts Auto

SPELL Property Survival_HungerStage0  Auto
SPELL Property Survival_HungerStage1  Auto
SPELL Property Survival_HungerStage2  Auto
SPELL Property Survival_HungerStage3  Auto
SPELL Property Survival_HungerStage4  Auto
SPELL Property Survival_HungerStage5  Auto

FormList[] Property eligibleFoodList Auto

FormList Property Survival_FoodRawMeat  Auto
FormList Property Survival_FoodPoisoningImmuneRaces Auto

Keyword Property Survival_DiseaseFoodPoisoningKeyword Auto

Message Property _SMNoMoreFoodMessage Auto

String Property foodConsumedText  Auto
Bool Property noFoodMessageShown Auto

; VARIABLES -------------------------------------------------------------------
Bool itemFound = False
String[] hungerLevels
SMAutoMCMScript mcmScript

; EVENT HANDLERS --------------------------------------------------------------

Event OnInit()
   hungerLevels = New String[2]
   hungerLevels[0] = Survival_HungerStage0.GetName()
   hungerLevels[1] = Survival_HungerStage1.GetName()

   mcmScript = (self As Form) As SMAutoMCMScript
EndEvent

Event OnUpdate()
   AutoEat()
EndEvent

; STATES ----------------------------------------------------------------------

State Busy
   Function AutoEat()
      RegisterForSingleUpdate(2.0)
   EndFunction
EndState

; MAIN FUNCTIONS --------------------------------------------------------------

Function AutoEat()
   GoToState("Busy")
   Eat()
   RegisterForSingleUpdate(1.0)
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

   Int index = 0
   itemFound = False


   While (index < eligibleFoodList.Length)

      If (CouldConsumeFromList(eligibleFoodList[index], (hungerRestoreAmounts[index]).GetValue() As Int, targetWellFed))
         noFoodMessageShown = False
         return
      EndIf

      index += 1

   EndWhile

   If (!itemFound && !noFoodMessageShown)
      _SMNoMoreFoodMessage.Show()
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

      If (consumable && consumable.IsFood())

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

         i += 1

      EndIf

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

Function PopulateHungerLevelDesc()
   hungerLevels = New String[2]
   hungerLevels[0] = Survival_HungerStage0.GetName()
   hungerLevels[1] = Survival_HungerStage1.GetName()
EndFunction

Function LogMessage(String sMessage)
   Debug.Trace("[SMAE] - " + sMessage)
EndFunction