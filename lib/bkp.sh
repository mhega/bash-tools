suffix=$(date +%s)
BACKUPPATH="/Users/mhega/bkp.d"
echo $PWD
mkdir -p $BACKUPPATH
ls -ld $BACKUPPATH
BKP_TARGET_PATH=$(echo $BACKUPPATH"$PWD"/"$(basename $PWD)"_$suffix | sed "s/\(\/\s*\"*\s*\)\./\1/g")
mkdir -p $(dirname $BKP_TARGET_PATH)
set -x
zip "$BKP_TARGET_PATH".zip ./*  | tee "$BKP_TARGET_PATH".log
{ set +x; } 2>/dev/null; echo "Command output directed to:"
echo "$BKP_TARGET_PATH".log
