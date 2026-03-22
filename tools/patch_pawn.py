#!/usr/bin/env python3
"""
patch_pawn.py — Updates Pawn SavedVariables with ZinaGearCompare stat weights.
Uses dungeon (M+) weights as default.
Run with WoW CLOSED.
"""

import re
import sys
from pathlib import Path

# ZGC dungeon weights: specID -> (primaryStatName, primary, crit, haste, mastery, vers)
# Using base 10.0 for primary, secondaries scaled proportionally
# All DPS specs with SimC MID1 real data (2026-03-22) except Assassination/Balance (estimated)
ZGC_WEIGHTS = {
    # Death Knight — SimC real
    251: ("Strength", 10.00, 5.22, 4.21, 5.28, 4.02),  # Frost
    252: ("Strength", 10.00, 6.10, 6.12, 5.07, 4.01),  # Unholy
    # Demon Hunter — SimC real
    577: ("Agility",  10.00, 5.26, 1.57, 5.31, 3.59),  # Havoc
    1480:("Intellect",10.00, 5.07, 8.07, 6.88, 4.64),  # Devourer
    # Druid
    102: ("Intellect",10.00, 4.40, 5.20, 5.00, 2.60),  # Balance (estimado)
    103: ("Agility",  10.00, 4.82, 4.37, 4.39, 4.97),  # Feral — SimC real
    105: ("Intellect",10.00, 2.00, 9.60, 6.60, 4.80),  # Restoration (estimado)
    # Evoker — SimC real
    1467:("Intellect",10.00, 4.67, 4.10, 3.92, 3.54),  # Devastation
    # Hunter — SimC real
    253: ("Agility",  10.00, 5.01, 4.99, 5.19, 4.90),  # Beast Mastery
    254: ("Agility",  10.00, 4.83, 3.99, 5.01, 5.14),  # Marksmanship
    255: ("Agility",  10.00, 5.36, 5.03, 6.06, 4.94),  # Survival
    # Mage — SimC real
    62:  ("Intellect",10.00, 4.19, 0.10, 5.73, 4.35),  # Arcane
    63:  ("Intellect",10.00, 1.84, 5.31, 4.57, 5.00),  # Fire
    64:  ("Intellect",10.00, 5.25, 4.70, 5.19, 3.74),  # Frost
    # Monk — SimC real
    269: ("Agility",  10.00, 7.00, 6.57, 5.63, 3.80),  # Windwalker
    # Paladin — SimC real
    70:  ("Strength", 10.00, 5.32, 3.04, 5.25, 4.96),  # Retribution
    # Priest — SimC real
    258: ("Intellect",10.00, 5.87, 5.30, 5.43, 5.19),  # Shadow
    # Rogue
    259: ("Agility",  10.00, 5.50, 5.10, 3.00, 2.20),  # Assassination (estimado)
    260: ("Agility",  10.00, 4.85, 3.56, 3.51, 4.58),  # Outlaw — SimC real
    261: ("Agility",  10.00, 4.97, 5.98, 5.50, 4.84),  # Subtlety — SimC real
    # Shaman — SimC real
    262: ("Intellect",10.00, 5.85, 7.22, 4.97, 4.66),  # Elemental
    263: ("Agility",  10.00, 4.46, 4.94, 5.01, 4.65),  # Enhancement
    # Warlock — SimC real
    265: ("Intellect",10.00, 4.77, 4.19, 2.83, 4.58),  # Affliction
    266: ("Intellect",10.00, 5.31, 4.77, 5.09, 5.00),  # Demonology
    267: ("Intellect",10.00, 5.52, 5.95, 5.14, 4.71),  # Destruction
    # Warrior — SimC real
    71:  ("Strength", 10.00, 5.31, 5.46, 5.82, 4.28),  # Arms
    72:  ("Strength", 10.00, 5.62, 8.67, 4.96, 4.51),  # Fury
}

# Map Pawn scale name → ZGC specID
PAWN_TO_ZGC = {
    "Windwalker":    269,
    "Shadow":        258,
    "Devourer":      1480,
    "Unholy":        252,
    "Retribution":   70,
    "Fury":          72,
    "Enhancement":   263,
    "Elemental":     262,
    "Marksmanship":  254,
    "Havoc":         577,
    "Assasin":       259,   # user's spelling
    "fire":          63,
    "ice":           63,    # duplicate Fire scale (user named it "ice" but SpecID=2=Fire)
    "Frost":         64,    # Mage Frost (ClassID=8, SpecID=3)
    "Survival":      255,
    "Outlaw":        260,
    "Arms":          71,
    "Subtlety":      261,
    "Demonology":    266,
    "Destruction":   267,
    "Affliction":    265,
    "Arcane":        62,
    "Beast":         253,
    "FDH":           251,   # Frost DK (ClassID=6, SpecID=2)
    "feral":         103,
    "healer":        105,   # Resto Druid
}


def update_values_block(content, scale_name, spec_id):
    """Find and replace the Values table for a given scale in the Pawn SavedVariables."""
    w = ZGC_WEIGHTS.get(spec_id)
    if not w:
        print(f"  SKIP {scale_name}: no ZGC weights for specID {spec_id}")
        return content

    primary_name, primary_val, crit, haste, mastery, vers = w

    # Find the scale block - look for ["ScaleName"] = { ... ["Values"] = { ... }, ... }
    # We need to find the Values sub-table and replace only the stat values

    # Escape the scale name for regex
    escaped = re.escape(f'["{scale_name}"]')

    # Find the scale block start
    pattern = escaped + r'\s*=\s*\{'
    match = re.search(pattern, content)
    if not match:
        print(f"  SKIP {scale_name}: scale not found in Pawn.lua")
        return content

    scale_start = match.start()

    # Find the Values block within this scale
    # Look for ["Values"] = { ... } within the next ~500 chars
    values_pattern = r'\["Values"\]\s*=\s*\{([^}]*)\}'
    values_match = re.search(values_pattern, content[scale_start:scale_start+2000])
    if not values_match:
        print(f"  SKIP {scale_name}: no Values table found")
        return content

    old_values_content = values_match.group(1)

    # Build new values, preserving Is* restrictions
    is_restrictions = []
    for line in old_values_content.split('\n'):
        line = line.strip().rstrip(',')
        if line.startswith('["Is') or line.startswith('["Stamina') or \
           line.startswith('["Indestructible') or line.startswith('["Avoidance') or \
           line.startswith('["Leech') or line.startswith('["MovementSpeed') or \
           line.startswith('["MinDamage') or line.startswith('["MaxDamage'):
            is_restrictions.append(line)

    # Build new Values content
    new_parts = [f'\n["{primary_name}"] = {primary_val}']
    new_parts.append(f'["CritRating"] = {crit}')
    new_parts.append(f'["HasteRating"] = {haste}')
    new_parts.append(f'["MasteryRating"] = {mastery}')
    new_parts.append(f'["Versatility"] = {vers}')
    new_parts.extend(is_restrictions)

    new_values_str = ',\n'.join(new_parts) + ',\n'

    # Replace in content
    abs_start = scale_start + values_match.start(1)
    abs_end = scale_start + values_match.end(1)
    content = content[:abs_start] + new_values_str + content[abs_end:]

    print(f"  OK   {scale_name:20s} -> specID {spec_id} ({primary_name}={primary_val}, C={crit}, H={haste}, M={mastery}, V={vers})")
    return content


def main():
    pawn_path = Path(r"C:\Program Files (x86)\World of Warcraft\_retail_\WTF\Account\389813121#2\SavedVariables\Pawn.lua")

    if not pawn_path.exists():
        print(f"ERROR: Pawn.lua not found at {pawn_path}")
        sys.exit(1)

    # Backup
    backup_path = pawn_path.with_suffix('.lua.bak')
    content = pawn_path.read_text(encoding='utf-8')
    backup_path.write_text(content, encoding='utf-8')
    print(f"Backup: {backup_path}")

    print("\nUpdating Pawn scales with ZGC dungeon (M+) weights:\n")

    for scale_name, spec_id in PAWN_TO_ZGC.items():
        content = update_values_block(content, scale_name, spec_id)

    pawn_path.write_text(content, encoding='utf-8')
    print(f"\nDone! Updated {pawn_path}")
    print("Start WoW to see changes in Pawn.")


if __name__ == "__main__":
    main()
