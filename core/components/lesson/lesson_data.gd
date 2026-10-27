class_name LessonData
extends RefCounted

## Short constructors for ModuleFlow page entries so module content files read
## as data. Every function returns a plain Dictionary.



static func _page(kind: String, section: Dictionary, help_title: String, help_body: String) -> Dictionary:
	return {
		"kind": kind,
		"card": "figma",
		"sections": [section],
		"help": {"title": help_title, "body": help_body},
	}


## Big title + body beside an illustration (Figma "hero" frames).
static func hero(title: String, body: String, art: String, opts: Dictionary = {}) -> Dictionary:
	var s := {"layout": "figma_hero", "title": title, "body": body, "art": art}
	s.merge(opts, true)
	return _page("lesson", s, title, str(opts.get("help", body)))


## One step / info card for cards().
static func card(title: String, body: String, art: String = "", opts: Dictionary = {}) -> Dictionary:
	var c := {"title": title, "body": body, "art": art}
	c.merge(opts, true)
	return c


## Title + subtitle + a row of cards (Figma step-card frames).
static func cards(title: String, subtitle: String, list: Array, opts: Dictionary = {}) -> Dictionary:
	var s := {"layout": "figma_cards", "title": title, "subtitle": subtitle, "cards": list}
	s.merge(opts, true)
	var names: PackedStringArray = []
	for c in list:
		names.append(str((c as Dictionary).get("title", "")))
	var help := subtitle if subtitle != "" else "Covers: %s." % ", ".join(names)
	return _page("lesson", s, title if title != "" else names[0], str(opts.get("help", help)))


## `required`: every row must be ticked before ModuleFlow lets the learner
## swipe to the next page.
static func checklist(title: String, subtitle: String, items: Array, required: bool = false) -> Dictionary:
	var help := "Tap each item once it is done."
	help += " Tick every item to continue." if required else " These checks are for real-life work and are not graded."
	var page := _page("lesson", {"layout": "figma_checklist", "title": title, "subtitle": subtitle, "items": items}, title, help)
	page["require_checklist"] = required
	return page


static func wide(title: String, subtitle: String, opts: Dictionary) -> Dictionary:
	var s := {"layout": "figma_wide", "title": title, "subtitle": subtitle}
	s.merge(opts, true)
	return _page("lesson", s, title, subtitle if subtitle != "" else str(opts.get("body", title)))


static func split(title: String, left: Dictionary, opts: Dictionary) -> Dictionary:
	var s := {"layout": "figma_split", "title": title, "left": left}
	s.merge(opts, true)
	return _page("lesson", s, str(left.get("title", title)), str(left.get("body", title)))


## Full-screen Guided Simulation page (3D bench). `sim` holds the step data.
static func simulation(sim: Dictionary) -> Dictionary:
	var page := sim.duplicate(true)
	page["kind"] = "simulation"
	page["immersive"] = true
	page["help"] = {"title": str(sim.get("title", "Guided Simulation")), "body": str(sim.get("description", ""))}
	return page


## Full-screen Assessment Simulation page (no hints).
static func assessment(sim: Dictionary) -> Dictionary:
	var page := simulation(sim)
	page["kind"] = "assessment"
	return page


## `art`: the module's Figma "Cyber-Blue Computer Checklist" sticker.
static func be_ready(art: String) -> Dictionary:
	var page := _page("be_ready", {"layout": "be_ready", "art": art}, "Be Ready for Assessment",
		"The assessment is the same simulation without hints or guides. Swipe left when you are ready.")
	return page


## Hand-off to a simulation hosted by the Android app (Modules 2–4).
static func external_lab(title: String, body: String, art: String, button: String, action: String) -> Dictionary:
	return _page("external_lab", {
		"layout": "external_lab", "title": title, "body": body, "art": art,
		"button": button, "action": action,
	}, title, body)


static func completion(subtitle: String, topics: Array) -> Dictionary:
	return _page("completion", {
		"layout": "completion", "title": "Congratulations!", "subtitle": subtitle, "topics": topics,
	}, "Module complete", "Proceed to Home saves the module as complete. Retake starts it again from the first page.")
