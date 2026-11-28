class_name Design
extends RefCounted
## Cassette Futurism design tokens.
##
## One file, one place to tweak the whole interface. Every UI surface reads
## these values; nothing else in the game hard-codes a palette number.
##
## The language: an old observatory console warmed by tape hiss and phosphor.
## Dark charcoal panels, chunky 2 px bezels, amber for the hand, mint phosphor
## for the machine, cream for the words.


#region Palette

static var BG := Color("12100e")
static var BG_SOFT := Color("1a1815")
static var PANEL := Color(0.145, 0.135, 0.118, 0.96)
static var GOLD := Color("f0a860")
static var GOLD_SOFT := Color("d18d4c")
static var CREAM := Color("f2e6d0")
static var MUTED := Color("a8a29a")
static var TEAL := Color("7ce8d5")
static var ROSE := Color("e8a891")
static var VERMILION := Color("ff5a3c")
static var LINE := Color(0.949, 0.902, 0.816, 0.22)
static var PAPER := Color("e8dcc4")
static var PAPER_DEEP := Color("d6c8ae")
static var INK := Color("15130f")
static var INK_SOFT := Color("6d6155")
static var PAPER_ACCENT := Color("8a5a30")

## The two cassette-futurism accents.
## GOLD is the *hand*: buttons, highlights, things you touch.
## PHOSPHOR is the *machine*: live readouts, selected states, CRT glow.
static var PHOSPHOR := Color("7dffa8")
static var PHOSPHOR_SOFT := Color("5fd98c")
static var BEZEL := Color("2a2723")
static var BEZEL_EDGE := Color("4a4238")

#endregion


#region Shape

static var CORNER_RADIUS := 2
static var BORDER_WIDTH := 2
static var BEZEL_INSET := 10
static var BEZEL_CORNER := 3
static var BUTTON_RADIUS := 4
static var PANEL_RADIUS := 4
static var SHADOW_SIZE := 6
static var SHADOW_OFFSET := Vector2(0, 3)

#endregion


#region CRT

static var SCANLINE_STRENGTH := 0.055
static var SCANLINE_COUNT := 720.0
static var VIGNETTE_STRENGTH := 0.24
static var NOISE_STRENGTH := 0.018
static var CHROMATIC_SPLIT := 0.0007

#endregion


#region Typography

static var FONT_DISPLAY_PATH := "res://assets/fonts/Michroma-Regular.ttf"
static var FONT_TERMINAL_PATH := "res://assets/fonts/SpaceMono-Regular.ttf"
static var FONT_BODY_PATH := "res://assets/fonts/NotoSans-Regular.ttf"
static var FONT_BODY_MED_PATH := "res://assets/fonts/NotoSans-Medium.ttf"
static var FONT_KANNADA_PATH := "res://assets/fonts/NotoSansKannada-Regular.ttf"

static var TYPE_SCALE := {
	"display": 64,
	"heading": 28,
	"body": 17,
	"micro": 11,
	"terminal": 13,
}

#endregion


static func apply_to(target: Node) -> void:
	## Copy the palette onto the global state autoload so every script that
	## still reads G.GOLD, G.CREAM, etc. follows this file.
	if target == null:
		return
	target.set("BG", BG)
	target.set("BG_SOFT", BG_SOFT)
	target.set("PANEL", PANEL)
	target.set("GOLD", GOLD)
	target.set("GOLD_SOFT", GOLD_SOFT)
	target.set("CREAM", CREAM)
	target.set("MUTED", MUTED)
	target.set("TEAL", TEAL)
	target.set("ROSE", ROSE)
	target.set("VERMILION", VERMILION)
	target.set("LINE", LINE)
	target.set("PAPER", PAPER)
	target.set("PAPER_DEEP", PAPER_DEEP)
	target.set("INK", INK)
	target.set("INK_SOFT", INK_SOFT)
	target.set("PAPER_ACCENT", PAPER_ACCENT)
