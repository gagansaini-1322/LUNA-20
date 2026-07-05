echo -off
for loadoption in Shell*.*; do
  if exist "$loadoption" then
    load "$loadoption"
    exit
  endif
endfor
for loadoption in EFI\BOOT\*.efi; do
  if exist "$loadoption" then
    load "$loadoption"
    exit
  endif
endfor
echo "No bootable option or path found."
