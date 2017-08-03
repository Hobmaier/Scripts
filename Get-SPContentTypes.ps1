# Description
#   Output all available Content Type GUIDs and their respective fields
#
# Syntax
#   ./listCtFields
#
# Parameters
#   none
#
# Settings
#   Only change the -value parameter!
#
set-variable -option constant -name url -value "http://localhost"  # Site collection
set-variable -option constant -name out -value "ContentTypes.csv"  # Site collection
# End of settings

$site = new-object Microsoft.SharePoint.SPSite($url)
$cts = $site.rootweb.ContentTypes
echo "Processing..."

'"CT Name"' + `
',"CT ID"' + `
',"CT Description"' + `
',"CT Group"' +
',"Field Title"' + `
',"Field Internal Name"' + `
',"Field ID"' + `
',"Field Group"' + `
',"Field Max Length"' + `
',"Field Description"' | Out-File $out

ForEach ($id in $cts)
{
  ForEach ($field in $id.Fields)
  {
    '"' + $id.Name + `
    '","' + $id.Id + `
    '","' + $id.Description + `
    '","' + $id.Group + `
    '","' + $field.Title + `
    '","' + $field.InternalName + `
    '","' + $field.Id + `
    '","' + $field.Group + `
    '","' + $field.MaxLength + `
    '","' + $field.Description + `
    '"' | Out-File $out -append
  }
}

$site.Dispose()

echo "Finished!"

# Changelog
#
#   v1.0 - February 28, 2011
#       First release