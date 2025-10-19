#!/usr/bin/env nix-shell
#!nix-shell -i bash -p xmlstarlet
# shellcheck disable=SC2016

set -eou pipefail
set -x

echo '<?xml version="1.0" encoding="UTF-8"?><Run></Run>' >splits.lss
xmlstarlet edit -L \
  --append '/Run' -t attr -n 'version' -v '1.7.0' \
  --subnode '/Run' -t elem -n 'GameIcon' \
  --subnode '/Run' -t elem -n 'GameName' -v 'Hollow Knight: Silksong' \
  --subnode '/Run' -t elem -n 'CategoryName' -v '100%' \
  --subnode '/Run' -t elem -n 'Offset' -v '00:00:00' \
  --subnode '/Run' -t elem -n 'AttemptCount' -v '0' \
  --subnode '/Run' -t elem -n 'AttemptHistory' \
  splits.lss

xmlstarlet edit -L \
  --subnode '/Run' -t elem -n 'Metadata' \
  --subnode '/Run/Metadata' -t elem -n 'Run' -v '' \
  --subnode '/Run/Metadata' -t elem -n 'Variables' -v '' \
  --subnode '/Run/Metadata' -t elem -n 'Platform' -v '' \
  --append '/Run/Metadata' -t attr -n 'usesEmulator' -v 'False' \
  splits.lss

xmlstarlet edit -L --subnode '/Run' -t elem -n 'Segments' -v '' splits.lss

spoolCount=1
maskCount=1

while IFS= read -r match; do

  split_name=$match

  if [[ "$match" =~ -MaskShard|-SpoolFragment ]]; then
    if [[ "$match" == "-MaskShard" ]]; then
      if ((maskCount % 4 == 0)); then
        split_name="-Mask"
        count=$((maskCount / 4))
      else
        split_name="-MaskShard"
        count="$maskCount"
      fi
      ((maskCount++))
    elif [[ "$match" == "-SpoolFragment" ]]; then
      if ((spoolCount % 2 == 0)); then
        split_name="-Spool"
        count=$((spoolCount / 2))
      else
        split_name="-SpoolFragment"
        count="$spoolCount"
      fi
      ((spoolCount++))
    fi

    xmlstarlet edit -L \
      --subnode '/Run/Segments' -t elem -n 'Segment' -v '' \
      --var newSegment '$prev' \
      --subnode '$newSegment' -t elem -n 'Name' -v "$split_name$count" \
      --subnode '$newSegment' -t elem -n 'SplitTimes' -v '' \
      --subnode '$newSegment/SplitTimes' -t elem -n 'SplitTime' -v 'Personal Best' \
      splits.lss

  else
    xmlstarlet edit -L \
      --subnode '/Run/Segments' -t elem -n 'Segment' -v '' \
      --var newSegment '$prev' \
      --subnode '$newSegment' -t elem -n 'Name' -v "$split_name" \
      --subnode '$newSegment' -t elem -n 'SplitTimes' -v '' \
      --subnode '$newSegment/SplitTimes' -t elem -n 'SplitTime' -v 'Personal Best' \
      splits.lss
  fi

done <splits.txt

xmlstarlet edit -L --subnode '/Run' -t elem -n 'AutoSplitterSettings' -v '' splits.lss
xmlstarlet edit -L --subnode '/Run/AutoSplitterSettings' -t elem -n 'Version' -v '1.0' splits.lss
xmlstarlet edit -L \
  --subnode '/Run/AutoSplitterSettings' -t elem -n 'CustomSettings' -v '' \
  --subnode '/Run/AutoSplitterSettings/CustomSettings' -t elem -n 'Setting' -v '' \
  --var setting '$prev' \
  --append '$setting' -t attr -n 'id' -v 'script_name' \
  --append '$setting' -t attr -n 'type' -v 'string' \
  --append '$setting' -t attr -n 'value' -v 'silksong_autosplit_wasm' \
  splits.lss
xmlstarlet edit -L \
  --subnode '/Run/AutoSplitterSettings/CustomSettings' -t elem -n 'Setting' -v '' \
  --var setting '$prev' \
  --append '$setting' -t attr -n 'id' -v 'splits' \
  --append '$setting' -t attr -n 'type' -v 'list' \
  splits.lss

spoolCount=1
maskCount=1

while IFS= read -r match; do

  split_name=$match

  if [[ "$match" =~ -MaskShard|-SpoolFragment ]]; then
    if [[ "$match" == "-MaskShard" ]]; then
      if ((maskCount % 4 == 0)); then
        split_name="-Mask"
        count=$((maskCount / 4))
      else
        split_name="-MaskShard"
        count="$maskCount"
      fi
      ((maskCount++))
    elif [[ "$match" == "-SpoolFragment" ]]; then
      if ((spoolCount % 2 == 0)); then
        split_name="-Spool"
        count=$((spoolCount / 2))
      else
        split_name="-SpoolFragment"
        count="$spoolCount"
      fi
      ((spoolCount++))
    fi

    xmlstarlet edit -L \
      --subnode '/Run/AutoSplitterSettings/CustomSettings/Setting[@id="splits"]' -t elem -n Setting -v '' \
      --var setting '$prev' \
      --append '$setting' -t attr -n 'type' -v 'string' \
      --append '$setting' -t attr -n 'value' -v "$split_name$count" \
      splits.lss

  else
    xmlstarlet edit -L \
      --subnode '/Run/AutoSplitterSettings/CustomSettings/Setting[@id="splits"]' -t elem -n Setting -v '' \
      --var setting '$prev' \
      --append '$setting' -t attr -n 'type' -v 'string' \
      --append '$setting' -t attr -n 'value' -v "$split_name" \
      splits.lss
  fi

done <splits.txt

cat splits.lss
