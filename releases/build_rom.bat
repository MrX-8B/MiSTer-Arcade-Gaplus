@powershell -NoProfile -ExecutionPolicy Unrestricted "$s=[scriptblock]::create((gc \"%~f0\"|?{$_.readcount -gt 1})-join\"`n\");&$s" %*&goto:eof
#==============================================================
$zip="gaplus.zip"

$ifiles=`
    "gp2-4.8d","gp2-3b.8c","gp2-2b.8b","gp2-1.4b",`
    "gp2-8.11d", "gp2-7.11c", "gp2-6.11b", "gp2-5.8s",`
    "gp2-11.11p","gp2-10.11n","gp2-12.11r","gp2-9.11m",`
    "../bang_24ku8m.snd",`
    "gp2-6.6p","gp2-5.6n",`
    "gp2-7.6s",`
    "gp2-3.1p","gp2-1.1n","gp2-2.2n",`
    "gp2-4.3f"

$ofile="a.gaplus.rom"
$ofileMd5sumValid="e2614b32e75059ceb914800e879f4fad"

if (!(Test-Path "./$zip")) {
    echo "Error: Cannot find $zip file."
	echo ""
	echo "Put $zip into the same directory."
}
else {
    Expand-Archive -Path "./$zip" -Destination ./tmp/ -Force

    cd tmp
    Get-Content $ifiles -Enc Byte -Read 512 | Set-Content "../$ofile" -Enc Byte
    cd ..
    Remove-Item ./tmp -Recurse -Force

    $ofileMD5sumCurrent=(Get-FileHash -Algorithm md5 "./$ofile").Hash.toLower()
    if ($ofileMD5sumCurrent -ne $ofileMd5sumValid) {
        echo "Expected checksum: $ofileMd5sumValid"
        echo "  Actual checksum: $ofileMd5sumCurrent"
        echo ""
        echo "Error: Generated $ofile is invalid."
        echo ""
        echo "This is more likely due to incorrect $zip content."
    }
    else {
        echo "Checksum verification passed."
        echo ""
        echo "Copy $ofile into root of SD card along with the rbf file."
    }
}
echo ""
echo ""
pause

