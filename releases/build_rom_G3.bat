@powershell -NoProfile -ExecutionPolicy Unrestricted "$s=[scriptblock]::create((gc \"%~f0\"|?{$_.readcount -gt 1})-join\"`n\");&$s" %*&goto:eof
#==============================================================
$zip0="gaplus.zip"
$zip1="galaga3.zip"

$ifiles=`
    "gp3-4c.8d","gp3-3c.8c","gp3-2d.8b","gp2-1.4b",`
    "gp3-8b.11d", "gp2-7.11c", "gp3-6b.11b", "gp3-5.8s",`
    "gp2-11.11p","gp2-10.11n","gp2-12.11r","gp2-9.11m",`
    "../bang_24ku8m.snd",`
    "gp3-6.6p","gp3-5.6n",`
    "gp2-7.6s",`
    "gp2-3.1p","gp2-1.1n","gp2-2.2n",`
    "gp2-4.3f"

$ofile="a.galaga3.rom"
$ofileMd5sumValid="6c8c27f573b22b58f20073570423074a"

if (!((Test-Path "./$zip0") -And (Test-Path "./$zip1"))) {
    echo "Error: Cannot find zip files."
	echo ""
	echo "Put $zip0 and $zip1 into the same directory."
}
else {
    Expand-Archive -Path "./$zip0" -Destination ./tmp/ -Force
    Expand-Archive -Path "./$zip1" -Destination ./tmp/ -Force

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

