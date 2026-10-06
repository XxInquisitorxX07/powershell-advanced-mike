Configuration CompanyBaseline 
{ 
  Node localhost 
  { 
    File AutomationFolder 
    { 
      DestinationPath = "C:\Automation" 
      Type = "Directory" 
      Ensure = "Present" 
    } 
    File ConfigFile 
    { 
      DestinationPath = "C:\Automation\Config.txt" 
      Contents = "NWTC Standard Configuration" 
      Type = "File" 
      Ensure = "Present" 
      DependsOn = "[File]AutomationFolder" 
    } 
  } 
}
