#!/usr/bin/env python3
"""
raidbots_import.py — ZinaGearCompare
Downloads Raidbots Top Gear results and generates ZinaRaidbotsData.lua
with per-item DPS data for in-game tooltip comparison.

Auto-detects sim type from the report:
  - Patchwerk / LightMovement / HeavyMovement → ST (single target)
  - DungeonSlice / HecticAddCleave            → AoE

Usage:
    py raidbots_import.py <report_url_or_id>
    py raidbots_import.py <report_url_or_id> <st|aoe>   (override auto-detect)

Examples:
    py raidbots_import.py https://www.raidbots.com/simbot/report/abc123
    py raidbots_import.py abc123
"""

import csv
import io
import json
import re
import sys
import urllib.request
from collections import defaultdict
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
ADDON_DIR  = SCRIPT_DIR.parent
LUA_OUT    = ADDON_DIR / "ZinaRaidbotsData.lua"

RAIDBOTS_BASE = "https://www.raidbots.com/reports"

# Fight styles that map to AoE
AOE_FIGHT_STYLES = {"dungeonslice", "hecticaddcleave", "cleaveadd", "dungeonroute"}

SLOT_MAP = {
    "head": "INVTYPE_HEAD", "neck": "INVTYPE_NECK",
    "shoulder": "INVTYPE_SHOULDER", "back": "INVTYPE_CLOAK",
    "chest": "INVTYPE_CHEST", "wrist": "INVTYPE_WRIST",
    "hands": "INVTYPE_HAND", "waist": "INVTYPE_WAIST",
    "legs": "INVTYPE_LEGS", "feet": "INVTYPE_FEET",
    "finger1": "INVTYPE_FINGER", "finger2": "INVTYPE_FINGER",
    "trinket1": "INVTYPE_TRINKET", "trinket2": "INVTYPE_TRINKET",
    "main_hand": "INVTYPE_WEAPONMAINHAND", "off_hand": "INVTYPE_WEAPONOFFHAND",
}


def fetch_url(url):
    req = urllib.request.Request(url, headers={"User-Agent": "ZinaGearCompare/1.0"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return resp.read().decode("utf-8")


def extract_report_id(url_or_id):
    m = re.search(r"report/([a-zA-Z0-9]+)", url_or_id)
    if m:
        return m.group(1)
    if re.match(r"^[a-zA-Z0-9]+$", url_or_id):
        return url_or_id
    print(f"ERROR: Cannot extract report ID from: {url_or_id}")
    sys.exit(1)


SPEC_NAME_TO_ID = {
    "blood death knight": 250, "frost death knight": 251, "unholy death knight": 252,
    "havoc demon hunter": 577, "vengeance demon hunter": 581, "devourer demon hunter": 1480,
    "balance druid": 102, "feral druid": 103, "guardian druid": 104, "restoration druid": 105,
    "devastation evoker": 1467, "preservation evoker": 1468, "augmentation evoker": 1473,
    "beast mastery hunter": 253, "marksmanship hunter": 254, "survival hunter": 255,
    "arcane mage": 62, "fire mage": 63, "frost mage": 64,
    "brewmaster monk": 268, "mistweaver monk": 270, "windwalker monk": 269,
    "holy paladin": 65, "protection paladin": 66, "retribution paladin": 70,
    "discipline priest": 256, "holy priest": 257, "shadow priest": 258,
    "assassination rogue": 259, "outlaw rogue": 260, "subtlety rogue": 261,
    "elemental shaman": 262, "enhancement shaman": 263, "restoration shaman": 264,
    "affliction warlock": 265, "demonology warlock": 266, "destruction warlock": 267,
    "arms warrior": 71, "fury warrior": 72, "protection warrior": 73,
}

def detect_sim_info(json_text):
    """
    Detect sim type and spec from data.json.
    Returns (sim_type, fight_style, spec_name, spec_id).
    """
    try:
        data = json.loads(json_text)
        options = data.get("sim", {}).get("options", {})
        fight_style = options.get("fight_style", "")

        sim_type = "st"
        if fight_style.lower().replace("_", "") in AOE_FIGHT_STYLES:
            sim_type = "aoe"

        # Extract spec from first player
        players = data.get("sim", {}).get("players", [])
        spec_name = ""
        spec_id = 0
        if players:
            spec_name = players[0].get("specialization", "")
            spec_id = SPEC_NAME_TO_ID.get(spec_name.lower(), 0)

        return sim_type, fight_style, spec_name, spec_id
    except (json.JSONDecodeError, KeyError, AttributeError):
        return None, None, "", 0


def parse_csv(csv_text):
    reader = csv.DictReader(io.StringIO(csv_text))
    results = {}
    for row in reader:
        name = row["name"].strip()
        dps  = float(row["dps_mean"])
        results[name] = dps
    return results


def parse_input(input_text):
    lines = input_text.strip().split("\n")
    char_info = {}
    combos = {}
    pending_comment = None

    re_combo_header = re.compile(r"^###\s+Combo\s+(\d+)")
    re_comment_item = re.compile(r"^#\s+(.+?)\s+(\d+)\s*$")
    re_base_slot    = re.compile(r"^(\w+)=,id=(\d+),bonus_id=([\d/]+)")
    re_profile_slot = re.compile(
        r'^profileset\."Combo\s+(\d+)"\+=(\w+)=,id=(\d+),bonus_id=([\d/]+)'
    )
    re_field = re.compile(r"^(race|level|spec|role)=(.+)")
    re_name  = re.compile(r"^name=(.+)")

    CLASS_KEYWORDS = {
        "deathknight", "demonhunter", "druid", "evoker", "hunter",
        "mage", "monk", "paladin", "priest", "rogue", "shaman",
        "warlock", "warrior",
    }

    for line in lines:
        line = line.strip()
        if not line:
            continue

        if "=" in line and not line.startswith("#") and not line.startswith("profileset"):
            parts = line.split("=", 1)
            key = parts[0].lower()
            if key in CLASS_KEYWORDS:
                char_info["class"] = key
                char_info["name"] = parts[1]
                continue
            m = re_field.match(line)
            if m:
                char_info[m.group(1)] = m.group(2)
                continue
            m = re_name.match(line)
            if m:
                char_info["name"] = m.group(1)
                continue

        m = re_combo_header.match(line)
        if m:
            combo_name = f"Combo {m.group(1)}"
            if combo_name not in combos:
                combos[combo_name] = {}
            pending_comment = None
            continue

        m = re_comment_item.match(line)
        if m:
            pending_comment = {"name": m.group(1), "ilvl": int(m.group(2))}
            continue

        m = re_base_slot.match(line)
        if m:
            slot = m.group(1)
            if slot in SLOT_MAP:
                if "Combo 1" not in combos:
                    combos["Combo 1"] = {}
                item = {"id": int(m.group(2)), "bonus_ids": m.group(3), "slot": slot}
                if pending_comment:
                    item["name"] = pending_comment["name"]
                    item["ilvl"] = pending_comment["ilvl"]
                combos["Combo 1"][slot] = item
            pending_comment = None
            continue

        m = re_profile_slot.match(line)
        if m:
            combo_name = f"Combo {m.group(1)}"
            slot = m.group(2)
            if slot in SLOT_MAP:
                if combo_name not in combos:
                    combos[combo_name] = {}
                item = {"id": int(m.group(3)), "bonus_ids": m.group(4), "slot": slot}
                if pending_comment:
                    item["name"] = pending_comment["name"]
                    item["ilvl"] = pending_comment["ilvl"]
                combos[combo_name][slot] = item
            pending_comment = None
            continue

    return char_info, combos


def compute_item_dps(combos, dps_results):
    base_name = None
    current_gear_dps = None
    for name, dps in dps_results.items():
        if not name.startswith("Combo "):
            base_name = name
            current_gear_dps = dps
            break

    if "Combo 1" not in dps_results and base_name:
        dps_results["Combo 1"] = current_gear_dps

    best_combo_dps = max(dps_results.values())

    # Find which combo is the best, to identify BIS items
    best_combo_name = max(dps_results, key=dps_results.get)

    slot_items = defaultdict(lambda: defaultdict(list))
    item_meta = {}

    for combo_name, slots in combos.items():
        combo_dps = dps_results.get(combo_name)
        if combo_dps is None:
            continue
        for slot, item in slots.items():
            item_id = item["id"]
            if item_id == 0:
                continue
            slot_items[slot][item_id].append(combo_dps)
            if item_id not in item_meta:
                item_meta[item_id] = {
                    "name": item.get("name", f"Item {item_id}"),
                    "ilvl": item.get("ilvl", 0),
                    "slot": slot,
                }

    # Identify which items are in the best combo → those are BIS
    best_combo_items = {}  # slot → item_id
    if best_combo_name in combos:
        for slot, item in combos[best_combo_name].items():
            if item["id"] != 0:
                best_combo_items[slot] = item["id"]

    items = {}
    best_by_slot = {}

    for slot, id_map in slot_items.items():
        if len(id_map) <= 1:
            # Single item in slot — it's the only option, so it's BIS by default
            for item_id, dps_list in id_map.items():
                best = max(dps_list)
                items[item_id] = {**item_meta[item_id], "bestDPS": best,
                                  "appearances": len(dps_list), "fixed": False,
                                  "delta": 0}
                best_by_slot[slot] = (item_id, best)
            continue

        # Use max DPS (best combo containing this item), not average
        slot_best_id = None
        slot_best_dps = -1

        for item_id, dps_list in id_map.items():
            best = max(dps_list)
            items[item_id] = {**item_meta[item_id], "bestDPS": best,
                              "appearances": len(dps_list), "fixed": False}
            if best > slot_best_dps:
                slot_best_dps = best
                slot_best_id = item_id

        # If we know which item is in the best combo, use that as BIS
        if slot in best_combo_items and best_combo_items[slot] in id_map:
            slot_best_id = best_combo_items[slot]
            slot_best_dps = items[slot_best_id]["bestDPS"]

        best_by_slot[slot] = (slot_best_id, slot_best_dps)

        for item_id in id_map:
            items[item_id]["delta"] = items[item_id]["bestDPS"] - slot_best_dps

    return items, best_by_slot, best_combo_dps, current_gear_dps


def lua_escape(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def parse_existing_lua(lua_text, sim_type):
    """Parse existing items and bestBySlot from the Lua file for a given sim type."""
    pattern = rf'ZGC_RaidbotsData\["{sim_type}"\]\s*=\s*\{{(.*?)\n\}}'
    m = re.search(pattern, lua_text, re.DOTALL)
    if not m:
        return {}, {}

    block = m.group(1)
    existing_items = {}
    existing_best = {}

    # Parse items: [12345] = { name="...", ilvl=250, slot="...", bestDPS=1234.5, delta=-10.0, n=24 },
    for im in re.finditer(
        r'\[(\d+)\]\s*=\s*\{\s*'
        r'name="([^"]*)",\s*'
        r'ilvl=(\d+),\s*'
        r'slot="([^"]*)",\s*'
        r'bestDPS=([\d.]+),\s*'
        r'delta=([-\d.]+),\s*'
        r'n=(\d+)\s*\}', block
    ):
        item_id = int(im.group(1))
        existing_items[item_id] = {
            "name": im.group(2),
            "ilvl": int(im.group(3)),
            "slot": im.group(4),
            "bestDPS": float(im.group(5)),
            "delta": float(im.group(6)),
            "appearances": int(im.group(7)),
        }

    # Parse bestBySlot: ["slot"] = { id=12345, name="...", bestDPS=1234.5 },
    for bm in re.finditer(
        r'\["([^"]+)"\]\s*=\s*\{\s*'
        r'id=(\d+),\s*'
        r'name="([^"]*)",\s*'
        r'bestDPS=([\d.]+)\s*\}', block
    ):
        existing_best[bm.group(1)] = (int(bm.group(2)), float(bm.group(4)))

    return existing_items, existing_best


def generate_lua(items, best_by_slot, char_info, best_combo_dps, current_gear_dps,
                 sim_type, fight_style, spec_id, spec_name, report_id):
    now = datetime.now().strftime("%Y-%m-%d %H:%M")

    existing_text = None
    other_type = "aoe" if sim_type == "st" else "st"
    if LUA_OUT.exists():
        existing_text = LUA_OUT.read_text(encoding="utf-8")

    # --- Merge with existing data for the SAME sim type ---
    # Determine which slots the new sim touches
    new_slots = set()
    for item_id, info in items.items():
        if not info.get("fixed"):
            new_slots.add(info["slot"])

    merged_count = 0
    if existing_text:
        old_items, old_best = parse_existing_lua(existing_text, sim_type)
        if old_items:
            # Keep old items whose slot is NOT touched by the new sim
            for old_id, old_info in old_items.items():
                if old_info["slot"] not in new_slots and old_id not in items:
                    items[old_id] = old_info
                    merged_count += 1
            # Keep old bestBySlot for untouched slots
            for old_slot, old_val in old_best.items():
                if old_slot not in new_slots and old_slot not in best_by_slot:
                    best_by_slot[old_slot] = old_val

    if merged_count:
        print(f"  Merged {merged_count} existing items from untouched slots")

    lines = []
    lines.append("-- ZinaRaidbotsData.lua — ZinaGearCompare")
    lines.append("-- Per-item DPS data from Raidbots Top Gear simulations.")
    lines.append(f"-- Generated by tools/raidbots_import.py — {now}")
    lines.append("-- DO NOT EDIT MANUALLY — re-run the script to update.")
    lines.append("")
    lines.append("ZGC_RaidbotsData = ZGC_RaidbotsData or {}")
    lines.append("")

    key = sim_type
    lines.append(f'ZGC_RaidbotsData["{key}"] = {{')
    lines.append(f'    character = "{lua_escape(char_info.get("name", "Unknown"))}",')
    lines.append(f'    class     = "{lua_escape(char_info.get("class", "unknown"))}",')
    lines.append(f'    spec      = "{lua_escape(char_info.get("spec", "unknown"))}",')
    lines.append(f'    reportID  = "{report_id}",')
    lines.append(f'    specID    = {spec_id},')
    lines.append(f'    specName  = "{lua_escape(spec_name)}",')
    lines.append(f'    fightStyle = "{lua_escape(fight_style or "unknown")}",')
    lines.append(f'    imported  = "{now}",')
    lines.append(f'    bestComboDPS   = {best_combo_dps:.1f},')
    lines.append(f'    currentGearDPS = {current_gear_dps:.1f},')
    lines.append(f'    baselineDPS    = {best_combo_dps:.1f},')
    lines.append("")

    lines.append("    items = {")
    for item_id in sorted(items.keys()):
        info = items[item_id]
        delta = info.get("delta", 0)
        lines.append(
            f'        [{item_id}] = {{ '
            f'name="{lua_escape(info["name"])}", '
            f'ilvl={info["ilvl"]}, '
            f'slot="{info["slot"]}", '
            f'bestDPS={info["bestDPS"]:.1f}, '
            f'delta={delta:.1f}, '
            f'n={info["appearances"]} '
            f'}},'
        )
    lines.append("    },")
    lines.append("")

    lines.append("    bestBySlot = {")
    for slot in sorted(best_by_slot.keys()):
        best_id, best_dps = best_by_slot[slot]
        best_name = items[best_id]["name"] if best_id in items else "Unknown"
        lines.append(
            f'        ["{slot}"] = {{ id={best_id}, '
            f'name="{lua_escape(best_name)}", '
            f'bestDPS={best_dps:.1f} }},'
        )
    lines.append("    },")
    lines.append("}")
    lines.append("")

    if existing_text:
        pattern = rf'ZGC_RaidbotsData\["{other_type}"\]\s*=\s*\{{.*?\n\}}'
        m = re.search(pattern, existing_text, re.DOTALL)
        if m:
            lines.append(m.group(0))
            lines.append("")

    lua_content = "\n".join(lines)
    LUA_OUT.write_text(lua_content, encoding="utf-8")
    return lua_content


def main():
    if len(sys.argv) < 2:
        print("Usage: py raidbots_import.py <report_url_or_id> [st|aoe]")
        print("")
        print("The sim type (ST or AoE) is auto-detected from the report:")
        print("  Patchwerk / LightMovement  →  ST")
        print("  DungeonSlice / HecticAddCleave  →  AoE")
        print("")
        print("Examples:")
        print("  py raidbots_import.py https://www.raidbots.com/simbot/report/abc123")
        print("  py raidbots_import.py abc123")
        print("  py raidbots_import.py abc123 st   (force ST)")
        sys.exit(1)

    report_id = extract_report_id(sys.argv[1])
    manual_type = sys.argv[2].lower() if len(sys.argv) >= 3 else None

    if manual_type and manual_type not in ("st", "aoe"):
        print("ERROR: sim type must be 'st' or 'aoe'")
        sys.exit(1)

    print(f"Report ID: {report_id}")
    print()

    # Download all data
    csv_url   = f"{RAIDBOTS_BASE}/{report_id}/data.csv"
    json_url  = f"{RAIDBOTS_BASE}/{report_id}/data.json"
    input_url = f"{RAIDBOTS_BASE}/{report_id}/input.txt"

    print(f"Downloading data.json ...")
    json_text = fetch_url(json_url)

    print(f"Downloading data.csv ...")
    csv_text = fetch_url(csv_url)

    print(f"Downloading input.txt ...")
    input_text = fetch_url(input_url)

    # Auto-detect sim type and spec
    detected_type, fight_style, spec_name, spec_id = detect_sim_info(json_text)
    if manual_type:
        sim_type = manual_type
        print(f"\nFight style:  {fight_style}  (auto-detect: {detected_type})")
        print(f"Sim type:     {sim_type.upper()}  (manual override)")
    elif detected_type:
        sim_type = detected_type
        print(f"\nFight style:  {fight_style}")
        print(f"Sim type:     {sim_type.upper()}  (auto-detected)")
    else:
        print("\nWARNING: Could not detect fight style, defaulting to ST")
        sim_type = "st"
        fight_style = "unknown"

    if spec_name:
        print(f"Spec:         {spec_name} (specID={spec_id})")
    else:
        print("WARNING: Could not detect specialization from report")

    print()

    # Parse
    print("Parsing DPS results ...")
    dps_results = parse_csv(csv_text)
    print(f"  Found {len(dps_results)} combos in CSV")

    print("Parsing item data ...")
    char_info, combos = parse_input(input_text)
    print(f"  Character: {char_info.get('name', '?')} ({char_info.get('class', '?')} {char_info.get('spec', '?')})")
    print(f"  Combos with items: {len(combos)}")

    print("Computing per-item DPS ...")
    items, best_by_slot, best_combo_dps, current_gear_dps = compute_item_dps(combos, dps_results)
    compared = {k: v for k, v in items.items() if v.get("appearances", 0) > 0}
    solo_slots = sum(1 for s, ids in {i["slot"]: True for i in items.values()}.items()
                     if sum(1 for it in items.values() if it["slot"] == s) == 1)
    print(f"  Total items: {len(compared)} across {len(best_by_slot)} slots ({solo_slots} slots with single item)")
    print()
    print(f"  Best combo DPS:    {best_combo_dps:,.0f}  (shown on Raidbots page)")
    print(f"  Current gear DPS:  {current_gear_dps:,.0f}  (your equipped gear)")
    print(f"  Difference:        {best_combo_dps - current_gear_dps:+,.0f}")

    # Results summary
    print()
    print("=" * 65)
    print(f"  {'SLOT':<12} {'ITEM':<30} {'iLvl':>5} {'DELTA':>10}")
    print("-" * 65)
    for slot in sorted(best_by_slot.keys()):
        slot_items_list = [(iid, info) for iid, info in items.items() if info["slot"] == slot and not info.get("fixed")]
        slot_items_list.sort(key=lambda x: x[1].get("delta", 0), reverse=True)
        for iid, info in slot_items_list:
            delta = info.get("delta", 0)
            pct = (delta / best_combo_dps) * 100 if best_combo_dps else 0
            marker = " <-- BEST" if delta == 0 else ""
            print(f"  {slot:<12} {info['name']:<30} {info['ilvl']:>5} {delta:>+8.0f} ({pct:+.2f}%){marker}")
        print()

    print("Generating ZinaRaidbotsData.lua ...")
    generate_lua(items, best_by_slot, char_info, best_combo_dps, current_gear_dps,
                 sim_type, fight_style, spec_id, spec_name, report_id)
    print(f"OK: {LUA_OUT}")
    print()
    print("Now /reload in WoW to load the new data.")


if __name__ == "__main__":
    main()
