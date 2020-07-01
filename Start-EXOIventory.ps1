Get-Mailbox -ResultSize Unlimited |
  Get-MailboxStatistics |
  Select DisplayName,StorageLimitStatus,TotalItemSize |
  Export-CSV "C:\temp\All Mailboxes.csv" -NoTypeInformation

  #Maybe consider this one: https://devblogs.microsoft.com/scripting/get-exchange-online-mailbox-size-in-gb/