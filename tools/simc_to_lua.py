#!/usr/bin/env python3
"""
simc_to_lua.py — ZinaGearCompare
Lee los JSON de SimC de tools/simc_output/ y genera ZinaStatWeights.lua
con pesos normalizados (primary = 1.0).

Uso:
    py simc_to_lua.py

Requiere haber corrido run_simc_all.bat primero.
"""

import json
import os
import sys
from pathlib import Path
from datetime import date

# ── Rutas ────────────────────────────────────────────────────────────────────
SCRIPT_DIR   = Path(__file__).parent
OUTPUT_DIR   = SCRIPT_DIR / "simc_output"
ADDON_DIR    = SCRIPT_DIR.parent
LUA_OUT      = ADDON_DIR / "ZinaStatWeights.lua"

# ── Mapeo alias → (specID, primaryStatToken, clase, spec) ────────────────────
# alias = prefijo del fichero JSON (ej. "63_Mage_Fire")
SPEC_MAP = {
    "250_DK_Blood":           (250,  "ITEM_MOD_STRENGTH_SHORT",    "Death Knight",  "Blood (Tank)"),
    "251_DK_Frost":           (251,  "ITEM_MOD_STRENGTH_SHORT",    "Death Knight",  "Frost"),
    "252_DK_Unholy":          (252,  "ITEM_MOD_STRENGTH_SHORT",    "Death Knight",  "Unholy"),
    "577_DH_Havoc":           (577,  "ITEM_MOD_AGILITY_SHORT",     "Demon Hunter",  "Havoc"),
    "581_DH_Vengeance":       (581,  "ITEM_MOD_AGILITY_SHORT",     "Demon Hunter",  "Vengeance (Tank)"),
    "1480_DH_Devourer":       (1480, "ITEM_MOD_INTELLECT_SHORT",   "Demon Hunter",  "Devourer"),
    "103_Druid_Feral":        (103,  "ITEM_MOD_AGILITY_SHORT",     "Druid",         "Feral"),
    "1467_Evoker_Devastation":(1467, "ITEM_MOD_INTELLECT_SHORT",   "Evoker",        "Devastation"),
    "253_Hunter_BM":          (253,  "ITEM_MOD_AGILITY_SHORT",     "Hunter",        "Beast Mastery"),
    "254_Hunter_MM":          (254,  "ITEM_MOD_AGILITY_SHORT",     "Hunter",        "Marksmanship"),
    "255_Hunter_Survival":    (255,  "ITEM_MOD_AGILITY_SHORT",     "Hunter",        "Survival"),
    "62_Mage_Arcane":         (62,   "ITEM_MOD_INTELLECT_SHORT",   "Mage",          "Arcane"),
    "63_Mage_Fire":           (63,   "ITEM_MOD_INTELLECT_SHORT",   "Mage",          "Fire"),
    "64_Mage_Frost":          (64,   "ITEM_MOD_INTELLECT_SHORT",   "Mage",          "Frost"),
    "268_Monk_Brewmaster":    (268,  "ITEM_MOD_AGILITY_SHORT",     "Monk",          "Brewmaster (Tank)"),
    "269_Monk_Windwalker":    (269,  "ITEM_MOD_AGILITY_SHORT",     "Monk",          "Windwalker"),
    "66_Paladin_Protection":  (66,   "ITEM_MOD_STRENGTH_SHORT",    "Paladin",       "Protection (Tank)"),
    "70_Paladin_Retribution": (70,   "ITEM_MOD_STRENGTH_SHORT",    "Paladin",       "Retribution"),
    "258_Priest_Shadow":      (258,  "ITEM_MOD_INTELLECT_SHORT",   "Priest",        "Shadow"),
    "260_Rogue_Outlaw":       (260,  "ITEM_MOD_AGILITY_SHORT",     "Rogue",         "Outlaw"),
    "261_Rogue_Subtlety":     (261,  "ITEM_MOD_AGILITY_SHORT",     "Rogue",         "Subtlety"),
    "262_Shaman_Elemental":   (262,  "ITEM_MOD_INTELLECT_SHORT",   "Shaman",        "Elemental"),
    "263_Shaman_Enhancement": (263,  "ITEM_MOD_AGILITY_SHORT",     "Shaman",        "Enhancement"),
    "265_Warlock_Affliction": (265,  "ITEM_MOD_INTELLECT_SHORT",   "Warlock",       "Affliction"),
    "266_Warlock_Demonology": (266,  "ITEM_MOD_INTELLECT_SHORT",   "Warlock",       "Demonology"),
    "267_Warlock_Destruction":(267,  "ITEM_MOD_INTELLECT_SHORT",   "Warlock",       "Destruction"),
    "71_Warrior_Arms":        (71,   "ITEM_MOD_STRENGTH_SHORT",    "Warrior",       "Arms"),
    "72_Warrior_Fury":        (72,   "ITEM_MOD_STRENGTH_SHORT",    "Warrior",       "Fury"),
    "73_Warrior_Protection":  (73,   "ITEM_MOD_STRENGTH_SHORT",    "Warrior",       "Protection (Tank)"),
}

# Clave SimC → clave interna del addon
SIMC_KEY_MAP = {
    "Int":     "primary",
    "Str":     "primary",
    "Agi":     "primary",
    "Crit":    "crit",
    "Haste":   "haste",
    "Mastery": "mastery",
    "Vers":    "versatility",
}

# ── Specs que NO tienen perfil MID1 — se mantienen estimadas ─────────────────
# (specID, primaryToken, clase, spec, dungeon_weights, raid_weights,
#  tier2pc, tier4pc, nota)
MANUAL_SPECS = [
    # Balance Druid — haste +12% dungeon (AoE), mastery +8% raid (ST)
    (102,  "ITEM_MOD_INTELLECT_SHORT", "Druid", "Balance",
     dict(primary=1.0, crit=0.44, haste=0.52, mastery=0.50, versatility=0.26),
     dict(primary=1.0, crit=0.44, haste=0.42, mastery=0.58, versatility=0.26),
     1.05, 1.12, "estimado — sin perfil MID1"),
    # Guardian Druid — haste +10% dungeon, mastery +8% raid
    (104,  "ITEM_MOD_AGILITY_SHORT",   "Druid", "Guardian (Tank)",
     dict(primary=1.0, crit=0.40, haste=0.52, mastery=0.30, versatility=0.44),
     dict(primary=1.0, crit=0.40, haste=0.43, mastery=0.38, versatility=0.44),
     1.05, 1.12, "estimado — sin perfil MID1"),
    # Restoration Druid — haste +10% dungeon, mastery +5% raid
    (105,  "ITEM_MOD_INTELLECT_SHORT", "Druid", "Restoration (Healer)",
     dict(primary=1.0, crit=0.20, haste=0.96, mastery=0.66, versatility=0.48),
     dict(primary=1.0, crit=0.20, haste=0.82, mastery=0.74, versatility=0.48),
     1.05, 1.10, "estimado — sin perfil MID1"),
    # Preservation Evoker — haste +12% dungeon, mastery +6% raid
    (1468, "ITEM_MOD_INTELLECT_SHORT", "Evoker", "Preservation (Healer)",
     dict(primary=1.0, crit=0.38, haste=0.60, mastery=0.74, versatility=0.28),
     dict(primary=1.0, crit=0.38, haste=0.48, mastery=0.82, versatility=0.28),
     1.05, 1.10, "estimado — sin perfil MID1"),
    # Augmentation Evoker
    (1473, "ITEM_MOD_INTELLECT_SHORT", "Evoker", "Augmentation (Support)",
     dict(primary=1.0, crit=0.38, haste=0.56, mastery=0.42, versatility=0.32),
     dict(primary=1.0, crit=0.36, haste=0.46, mastery=0.50, versatility=0.30),
     1.05, 1.12, "estimado — sin perfil MID1"),
    # Mistweaver Monk — haste +10% dungeon, mastery +8% raid
    (270,  "ITEM_MOD_INTELLECT_SHORT", "Monk", "Mistweaver (Healer)",
     dict(primary=1.0, crit=0.44, haste=0.64, mastery=0.22, versatility=0.48),
     dict(primary=1.0, crit=0.48, haste=0.52, mastery=0.30, versatility=0.40),
     1.05, 1.10, "estimado — sin perfil MID1"),
    # Holy Paladin — haste +12% dungeon, mastery +8% raid
    (65,   "ITEM_MOD_INTELLECT_SHORT", "Paladin", "Holy (Healer)",
     dict(primary=1.0, crit=0.45, haste=0.50, mastery=0.50, versatility=0.30),
     dict(primary=1.0, crit=0.45, haste=0.40, mastery=0.58, versatility=0.30),
     1.05, 1.10, "estimado — sin perfil MID1"),
    # Discipline Priest — haste +10% dungeon, mastery +8% raid
    (256,  "ITEM_MOD_INTELLECT_SHORT", "Priest", "Discipline (Healer)",
     dict(primary=1.0, crit=0.48, haste=0.62, mastery=0.24, versatility=0.36),
     dict(primary=1.0, crit=0.48, haste=0.50, mastery=0.36, versatility=0.28),
     1.05, 1.10, "estimado — sin perfil MID1"),
    # Holy Priest — haste +12% dungeon, mastery +10% raid
    (257,  "ITEM_MOD_INTELLECT_SHORT", "Priest", "Holy (Healer)",
     dict(primary=1.0, crit=0.50, haste=0.40, mastery=0.22, versatility=0.56),
     dict(primary=1.0, crit=0.56, haste=0.30, mastery=0.36, versatility=0.46),
     1.05, 1.10, "estimado — sin perfil MID1"),
    # Assassination Rogue — haste +10% dungeon, mastery +6% raid
    (259,  "ITEM_MOD_AGILITY_SHORT",   "Rogue", "Assassination",
     dict(primary=1.0, crit=0.55, haste=0.51, mastery=0.30, versatility=0.22),
     dict(primary=1.0, crit=0.55, haste=0.42, mastery=0.38, versatility=0.22),
     1.05, 1.12, "estimado — sin perfil MID1"),
    # Restoration Shaman — haste +10% dungeon, mastery +5% raid
    (264,  "ITEM_MOD_INTELLECT_SHORT", "Shaman", "Restoration (Healer)",
     dict(primary=1.0, crit=0.62, haste=0.42, mastery=0.34, versatility=0.38),
     dict(primary=1.0, crit=0.62, haste=0.34, mastery=0.42, versatility=0.38),
     1.05, 1.10, "estimado — sin perfil MID1"),
]

# ── Funciones ─────────────────────────────────────────────────────────────────

def load_json(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)

def extract_scale_factors(data):
    """Extrae el dict scale_factors del primer player del JSON de SimC."""
    try:
        return data["sim"]["players"][0]["scale_factors"]
    except (KeyError, IndexError):
        return None

def normalize(sf):
    """
    Normaliza scale_factors de SimC a primary=1.0.
    primary = máximo entre Int, Str, Agi.
    Devuelve dict {primary, crit, haste, mastery, versatility} o None.
    """
    primary_raw = max(
        sf.get("Int", 0),
        sf.get("Str", 0),
        sf.get("Agi", 0),
    )
    if primary_raw <= 0:
        return None

    return {
        "primary":      1.0,
        "crit":         round(sf.get("Crit",    0) / primary_raw, 3),
        "haste":        round(sf.get("Haste",   0) / primary_raw, 3),
        "mastery":      round(sf.get("Mastery", 0) / primary_raw, 3),
        "versatility":  round(sf.get("Vers",    0) / primary_raw, 3),
    }

def weights_line(w):
    return (
        f"{{ primary={w['primary']:.2f}, "
        f"crit={w['crit']:.3f}, "
        f"haste={w['haste']:.3f}, "
        f"mastery={w['mastery']:.3f}, "
        f"versatility={w['versatility']:.3f} }}"
    )

def stat_order(w):
    """Devuelve string legible del orden de stats, ej. Haste > Mastery > Vers > Crit"""
    stats = [("Crit", w["crit"]), ("Haste", w["haste"]),
             ("Mastery", w["mastery"]), ("Vers", w["versatility"])]
    stats.sort(key=lambda x: -x[1])
    return " > ".join(s[0] for s in stats)

# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    if not OUTPUT_DIR.exists():
        print(f"ERROR: No se encuentra {OUTPUT_DIR}")
        print("Ejecuta run_simc_all.bat primero.")
        sys.exit(1)

    today = date.today().isoformat()
    results = {}   # alias → {raid: weights, dungeon: weights}
    errors  = []

    print(f"\nLeyendo JSONs de {OUTPUT_DIR} ...\n")

    for alias, (spec_id, primary_token, clase, spec_name) in SPEC_MAP.items():
        raid_path    = OUTPUT_DIR / f"{alias}_raid.json"
        dungeon_path = OUTPUT_DIR / f"{alias}_dungeon.json"

        w_raid = w_dungeon = None

        for path, label in [(raid_path, "raid"), (dungeon_path, "dungeon")]:
            if not path.exists():
                errors.append(f"[FALTA]  {path.name}")
                continue
            data = load_json(path)
            sf   = extract_scale_factors(data)
            if not sf:
                errors.append(f"[SIN SF] {path.name}")
                continue
            w = normalize(sf)
            if not w:
                errors.append(f"[ERROR normalize] {path.name}")
                continue
            if label == "raid":
                w_raid = w
            else:
                w_dungeon = w
            print(f"  OK  {alias:35s} {label:8s}  {stat_order(w)}")

        results[alias] = {
            "spec_id":       spec_id,
            "primary_token": primary_token,
            "clase":         clase,
            "spec_name":     spec_name,
            "raid":          w_raid,
            "dungeon":       w_dungeon,
        }

    if errors:
        print("\nAvisos:")
        for e in errors:
            print(f"  {e}")

    # ── Generar Lua ───────────────────────────────────────────────────────────
    lines = []
    lines.append("-- ZinaStatWeights.lua — ZinaGearCompare")
    lines.append("-- Pesos de stats por spec (specID global) y tipo de contenido.")
    lines.append("-- primary=1.0 es la referencia; los secondaries son fracciones relativas.")
    lines.append("--")
    lines.append(f"-- Generado automáticamente por tools/simc_to_lua.py — {today}")
    lines.append("-- Fuente: SimulationCraft nightly, perfiles MID1 (Midnight 12.0.1)")
    lines.append("-- Fight styles: Patchwerk (raid) · DungeonSlice (dungeon/M+)")
    lines.append("-- Specs sin perfil MID1 marcadas como 'estimado'.")
    lines.append("--")
    lines.append("-- Para actualizar: corre tools/run_simc_all.bat y luego tools/simc_to_lua.py")
    lines.append("")
    lines.append("ZGC_StatWeights = {")
    lines.append("")

    # Agrupa por clase para el output
    from collections import defaultdict
    by_class = defaultdict(list)

    # Specs con datos SimC
    for alias, info in results.items():
        by_class[info["clase"]].append(("simc", info))

    # Specs manuales
    for row in MANUAL_SPECS:
        spec_id, primary_token, clase, spec_name, w_dun, w_raid, t2, t4, nota = row
        by_class[clase].append(("manual", {
            "spec_id": spec_id, "primary_token": primary_token,
            "clase": clase, "spec_name": spec_name,
            "raid": w_raid, "dungeon": w_dun,
            "tier2pc": t2, "tier4pc": t4, "nota": nota,
        }))

    CLASS_ORDER = [
        "Death Knight", "Demon Hunter", "Druid", "Evoker",
        "Hunter", "Mage", "Monk", "Paladin", "Priest",
        "Rogue", "Shaman", "Warlock", "Warrior",
    ]

    for clase in CLASS_ORDER:
        if clase not in by_class:
            continue
        lines.append(f"    -- ── {clase} {'─' * max(0, 60 - len(clase))}")

        # Ordenar specs de la clase por specID
        entries = sorted(by_class[clase], key=lambda x: x[1]["spec_id"])

        for source, info in entries:
            spec_id       = info["spec_id"]
            primary_token = info["primary_token"]
            spec_name     = info["spec_name"]
            w_raid        = info.get("raid")
            w_dungeon     = info.get("dungeon")
            tier2pc       = info.get("tier2pc", 1.05)
            tier4pc       = info.get("tier4pc", 1.12)

            if source == "simc":
                # Determinar tier4pc: healers/tanks tienen 1.10, resto 1.12
                tier4pc = 1.10 if any(x in spec_name for x in ["Healer", "Tank"]) else 1.12
                nota = f"SimC MID1 · {today}"
                # Orden de stats para el comentario
                order_str = stat_order(w_dungeon or w_raid) if (w_dungeon or w_raid) else "?"
            else:
                nota = info.get("nota", "estimado")
                order_str = stat_order(w_dungeon or w_raid) if (w_dungeon or w_raid) else "?"

            # Fallback: si falta uno de los dos, usar el otro
            if w_raid    is None: w_raid    = w_dungeon
            if w_dungeon is None: w_dungeon = w_raid
            if w_raid    is None:
                lines.append(f"    -- [{spec_id}] {spec_name}: SIN DATOS — se omite")
                continue

            lines.append(f"    [{spec_id}] = {{ -- {spec_name} — {order_str} | {nota}")
            lines.append(f"        primaryStat  = \"{primary_token}\",")
            lines.append(f"        dungeon      = {weights_line(w_dungeon)},")
            lines.append(f"        raid         = {weights_line(w_raid)},")
            lines.append(f"        tierBonus2pc = {tier2pc},")
            lines.append(f"        tierBonus4pc = {tier4pc},")
            lines.append(f"    }},")

        lines.append("")

    lines.append("}")
    lines.append("")

    lua_content = "\n".join(lines)
    LUA_OUT.write_text(lua_content, encoding="utf-8")
    print(f"\nOK Generado: {LUA_OUT}")
    print(f"  Specs con SimC: {len(results)}")
    print(f"  Specs estimadas: {len(MANUAL_SPECS)}")

if __name__ == "__main__":
    main()
