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

FormList Property Survival_FoodRawMeat  Auto
FormList Property Survival_FoodPoisoningImmuneRaces Auto

Keyword Property Survival_DiseaseFoodPoisoningKeyword Auto

Message Property _SMNoMoreFoodMessage Auto

String Property foodConsumedText  Auto

; EVENT HANDLERS --------------------------------------------------------------

Event OnInit()
	GetPlayerRace()
EndEvent

Event OnUpdate()
	AutoEat()
EndEvent

; STATES ----------------------------------------------------------------------

State Busy
   Function AutoEat()
      RegisterForSingleUpdate(1.0)
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

   If (!IsPlayerHungry())
      LogMessage("Player is not hungry.")
      return
   EndIf

   Int consumedItemCount = GetConsumedItemCount(_SurvivalFood_VerySmall, Survival_HungerRestoreVerySmallAmount.GetValue() As Int)

   If (consumedItemCount == -1)
      _SMNoMoreFoodMessage.Show()
   EndIf

EndFunction

; HELPER FUNCTIONS ------------------------------------------------------------

Int Function GetConsumedItemCount(FormList foodItemList, int hungerReductionAmount=0)

   If (PlayerRef.GetItemCount(foodItemList) <= 0)
      LogMessage("Player does not have any consumable food items")
      return -1 ; NOT_FOUND
   EndIf

   Bool cannotContractFoodPoisoning = PlayerCannotContractFoodPoisoning()

   If (cannotContractFoodPoisoning)
      LogMessage("Player is immune to food poisoning.")
   Else
      LogMessage("Player is susceptible to food poisoning.")
   EndIf

   Int i = 0

   While (i < foodItemList.GetSize())
      Potion consumable = foodItemList.GetAt(i) As Potion

      If (consumable && consumable.IsFood())

         If ( (cannotContractFoodPoisoning || !Survival_FoodRawMeat.HasForm(consumable)) && PlayerRef.GetItemCount(consumable) > 0)

            If (Survival_HungerNeedValue.GetValueInt() < hungerReductionAmount)
               LogMessage("Player's hunger level is at acceptable level. Skipping consumption...")
               return 0 ; FOUND_NOT_CONSUMED
            EndIf

            PlayerRef.EquipItem(consumable, abSilent=true)
            Debug.Notification(consumable.GetName() + foodConsumedText)
            return 1 ; FOUND_AND_CONSUMED
         EndIf

         i += 1

      EndIf

   EndWhile

   return -1 ; NOT_FOUND

EndFunction

Function GetPlayerRace()
   playerRace  = PlayerRef.GetRace()
EndFunction

Bool Function PlayerCannotContractFoodPoisoning()
   If (!playerRace)
      GetPlayerRace()
   EndIf

   Float diseaseResistMult = PlayerRef.GetActorValue("DiseaseResist") / 100.000

   return diseaseResistMult >= 1.0000 || Survival_FoodPoisoningImmuneRaces.HasForm(playerRace) || PlayerRef.HasEffectKeyword(Survival_DiseaseFoodPoisoningKeyword)
EndFunction

Bool Function PlayerIsCurrentlyInCombat()
   ;/
      https://www.creationkit.com/index.php?title=GetCombatState_-_Actor

      This function is unreliable the first time it is called after a certain amount of time has passed.
      You should call it on an empty line first before calling it for real.
   /;

   PlayerRef.GetCombatState()

   ; 0 = Not in combat | 1 = In combat | 2 = Searching
   return PlayerRef.GetCombatState() == 1

EndFunction

Bool Function IsPlayerHungry()

   If (PlayerRef.HasSpell(Survival_HungerStage0))
      return false
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
      return false
   EndIf

   SMAutoMCMScript mcmScript = (self As Form) As SMAutoMCMScript

   ; Do nothing if auto-eat is disabled
   If (!mcmScript.GetModSettingBool("bEnabled:AutoEat"))
      LogMessage("Auto-eat is disabled.")
      return false
   EndIf

   ; Prevent auto eat during combat
   If (PlayerIsCurrentlyInCombat())
      LogMessage("Player is in combat.")
      return false
   EndIf

   If (PlayerRef.GetSleepState() != 0)
      LogMessage("Player is going to sleep or is waking up.")
      return false
   EndIf

   return true

EndFunction

Function LogMessage(String sMessage)
   Debug.Notification("[SMAE] - [State : " + GetState() + "] - " + sMessage)
EndFunction