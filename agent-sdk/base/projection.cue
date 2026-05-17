package base

#Projection: {
	name!: string
	format!: "text" | "json"
	value!: _
	source!: string
}

#DiscoveryRule: {
	kind!: "boot" | "inventory" | "workflow" | "fallback"
	include!: [...string]
	exclude?: [...string]
	search_allowed: bool | *false
}
