# Get the download url for the Mac installer from your GravityZone server and put it here
DownloadUrl="https://cloud.gravityzone.bitdefender.com/Packages/MAC/0/yXadvW/setup_downloader.dmg"

### Modify below this line at your own risk!

# Check if BDLDaemon is already running
PROCESS=BDLDaemon
count=$(ps aux | grep -v grep | grep -ci $PROCESS)

if [ $count -gt 0 ]; then
    echo "Bitdefender is already installed..."
    exit 0
fi

# Verify JumpCloud MDM
verify_jc_mdm (){
    # Check the system for the following profileIdentifier
    mdmID="com.jumpcloud.mdm"
    check=$(profiles -Lv | grep "name: $4" -4 | awk -F": " '/attribute: profileIdentifier/{print $NF}')
    if [[ $check == *$mdmID* ]] ; then
        echo "ProfileIdentifier: ${mdmID} found on system. MDM Verified"
        return
    else
        echo "JumpCloud MDM profile not found on system."
        false
    fi
}

if ! verify_jc_mdm "$":; then 
    echo "Device is not yet supervised..."
    exit 0
fi

# Locate DMG Download Link From URL
regex='^https.*.dmg$'
if [[ $DownloadUrl =~ $regex ]]; then
    echo "URL points to direct DMG download"
    validLink="True"
else
    echo "Searching headers for download links"
    urlHead=$(curl -s --head $DownloadUrl)

    locationSearch=$(echo "$urlHead" | grep https:)

    if [ -n "$locationSearch" ]; then

        locationRaw=$(echo "$locationSearch" | cut -d' ' -f2)

        locationFormatted="$(echo "${locationRaw}" | tr -d '[:space:]')"

        regex='^https.*'
        if [[ $locationFormatted =~ $regex ]]; then
            echo "Download link found"
            DownloadUrl=$(echo "$locationFormatted")
        else
            echo "No https location download link found in headers"
            exit 1
        fi

    else

        echo "No location download link found in headers"
        exit 1
    fi

fi

#Create Temp Folder
DATE=$(date '+%Y-%m-%d-%H-%M-%S')

TempFolder="Download-$DATE"

mkdir /tmp/$TempFolder

# Navigate to Temp Folder
cd /tmp/$TempFolder

# Download File into Temp Folder
curl -s -O "$DownloadUrl"

# Capture name of Download File
DownloadFile="$(ls)"

echo "Downloaded $DownloadFile to /tmp/$TempFolder"

# Verifies DMG File
regex='\.dmg$'
if [[ $DownloadFile =~ $regex ]]; then
    DMGFile="$(echo "$DownloadFile")"
    echo "DMG File Found: $DMGFile"
else
    echo "File: $DownloadFile is not a DMG"
    rm -r /tmp/$TempFolder
    echo "Deleted /tmp/$TempFolder"
    exit 1
fi

# Mount DMG File -nobrowse prevents the volume from popping up in Finder

hdiutilAttach=$(hdiutil attach /tmp/$TempFolder/$DMGFile -nobrowse)

echo "Used hdiutil to mount $DMGFile "

err=$?
if [ ${err} -ne 0 ]; then
    echo "Could not mount $DMGFile Error: ${err}"
    rm -r /tmp/$TempFolder
    echo "Deleted /tmp/$TempFolder"
    exit 1
fi

regex='\/Volumes\/.*'
if [[ $hdiutilAttach =~ $regex ]]; then
    DMGVolume="${BASH_REMATCH[@]}"
    echo "Located DMG Volume: $DMGVolume"
else
    echo "DMG Volume not found"
    rm -r /tmp/$TempFolder
    echo "Deleted /tmp/$TempFolder"
    exit 1
fi

# Identify the mount point for the DMG file
DMGMountPoint="$(hdiutil info | grep "$DMGVolume" | awk '{ print $1 }')"

echo "Located DMG Mount Point: $DMGMountPoint"

# Capture name of App file

cd "$DMGVolume/SetupDownloader.app/Contents/MacOS/"

./SetupDownloader
