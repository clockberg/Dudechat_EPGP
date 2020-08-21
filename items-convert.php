<?php

/**
 * Converts a CSV file to a LUA file usable by the addon.
 *
 * Input: csv file
 * First line has columns. Required columns:
 *
 * ITEM_ID, Z, S, A, E, PROT_WAR, FURY_WAR, ..
 *
 * Other columns will be ignored.
 *
 * Column explaination:
 * ITEM_ID: The item ID from wowhead URL.
 * Z: The GP cost of the item for Z tier.
 * S: The GP cost of the item for S tier.
 * A: The GP cost of the item for A tier.
 * E: The minimum cost of the item.
 * PROT_WAR: A string containing "Z", "S", or "A" representing the tier for this spec.
 * ..
 *
 * Example:
 *

ZONE,BOSS,ITEM,ITEM_ID,Z,S,A,E,PROT_WAR,FURY_WAR,ROGUE,HUNTER,RESTO_SHAM,ELE_SHAM,ENHANCE_SHAM,RESTO_DRUID,BEAR_DRUID,CAT_DRUID,BOOMKIN,MAGE,WARLOCK,HOLY_PRIEST,SHADOW_PRIEST,HOLY_PALADIN,RET_PALADIN,PROT_PALADIN
AQ,Trash,Anubisath Warhammer,21837,14,8,4,3,A,A,,,,,,,,,,,,,,,,
AQ,Trash,Ritssyn's Ring of Chaos,21836,19,11,5,1,,,,,,,,,,,,S,A,,,,,
AQ,Trash,Gloves of the Immortal,21888,1,1,1,1,,,,,,,,,,,,,,,,,,
AQ,Trash,Garb of Royal Ascension,21838,1,1,1,1,,,,,,,,,,,S,,R,,A,,,

 */

if (!isset($argv[1])) {
	die("Usage: " . basename(__FILE__) . " <csv file>\n");
}
$csv_file = trim($argv[1]);
if (!file_exists($csv_file)) {
	die("Input file does not exist.\n");
}

$spec_list = [
	"PROT_WAR",
	"FURY_WAR",
	"ROGUE",
	"HUNTER",
	"RESTO_SHAM",
	"ELE_SHAM",
	"ENHANCE_SHAM",
	"RESTO_DRUID",
	"BEAR_DRUID",
	"CAT_DRUID",
	"BOOMKIN",
	"MAGE",
	"WARLOCK",
	"HOLY_PRIEST",
	"SHADOW_PRIEST",
];

$fh = fopen($csv_file, 'r');
$cols = fgetcsv($fh);
print <<<TEXT
local _, addon = ...

addon.data = addon.data or {}
addon.data.items = {

TEXT;
while ($cells = fgetcsv($fh)) {
	$data = array_combine($cols, $cells);
	$str = "\t[" . $data['ITEM_ID'] . "] = {\n";
	$str .= "\t\t[\"price\"] = " . $data['E'] . ",\n";
	$by_tier = [];
	foreach ($spec_list as $spec) {
		foreach (['Z', 'S', 'A'] as $tier) {
			if (preg_match('/' . $tier . '/i', $data[$spec])) {
				if (!isset($by_tier[$tier])) {
					$by_tier[$tier] = [];
				}
				$by_tier[$tier][] = $spec;
			}
		}
	}
	if (sizeof($by_tier)) {
		$str .= "\t\t[\"by_tier\"] = {\n";
		foreach ($by_tier as $tier => $specs) {
			$str .= "\t\t\t[" . tier_to_num($tier) . "] = {\n";
			$str .= "\t\t\t\t[\"price\"] = " . $data[$tier] . ",\n";
			$str .= "\t\t\t\t[\"specs\"] = {\n";
			foreach ($specs as $spec) {
				$str .= "\t\t\t\t\t\"" . $spec . "\",\n";
			}
			$str .= "\t\t\t\t},\n";
			$str .= "\t\t\t},\n";
		}
		$str .= "\t\t},\n";
	}
	$str .= "\t},\n";
	print $str;
}
print "}\n";

/**
 * @param string $tier
 * @return int
 */
function tier_to_num($tier) {
	switch (strtoupper(trim($tier))) {
		case 'Z': return 1;
		case 'S': return 2;
		case 'A': return 3;
	}
	return 3;
}
