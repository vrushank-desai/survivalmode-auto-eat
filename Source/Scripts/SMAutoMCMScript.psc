Scriptname SMAutoMCMScript extends MCM_ConfigBase

GlobalVariable Property Survival_ModeEnabled  Auto

Message Property _SMAutoEatOffMessage Auto
Message Property _SMAutoEatOnMessage Auto

Function toggleAutoEat()

   If (Survival_ModeEnabled.GetValue() != 1.0)
      return
   EndIf

   bool newSetting = !GetModSettingBool("bEnabled:AutoEat")
   SetModSettingBool("bEnabled:AutoEat", newSetting)

   If (newSetting)
      _SMAutoEatOnMessage.Show()
   Else
      _SMAutoEatOffMessage.Show()
   EndIf
EndFunction

; Event raised when the config menu is opened.
Event OnConfigOpen()
   parent.OnConfigOpen()
   SMAutoScript mainScript = (self As Form) As SMAutoScript
   SetMenuOptions("iTargetLevel:AutoEat", mainScript.GetHighestHungerLevels())
   RefreshMenu()
EndEvent