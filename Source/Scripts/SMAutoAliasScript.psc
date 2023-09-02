Scriptname SMAutoAliasScript extends ReferenceAlias

Event OnInit()
   resumeAutoEat()
EndEvent

Event OnPlayerLoadGame()
   resumeAutoEat()
EndEvent

Function resumeAutoEat()
   SMAutoScript questScript = GetOwningQuest() as SMAutoScript
   questScript.noFoodMessageShown = False
   questScript.AutoEat()
EndFunction