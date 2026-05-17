package contract

type ProjectGraph struct {
	SchemaVersion string         `json:"schema_version"`
	Repo          RepoConfig     `json:"repo"`
	Output        OutputConfig   `json:"output"`
	Profile       ProfileConfig  `json:"profile"`
	Skills        []SkillConfig  `json:"skills"`
	Adapters      AdaptersConfig `json:"adapters"`
}

type RepoConfig struct {
	Name   string `json:"name"`
	Module string `json:"module"`
	Root   string `json:"root"`
}

type OutputConfig struct {
	Root string `json:"root"`
}

type ProfileConfig struct {
	ID     string `json:"id"`
	Source string `json:"source"`
}

type SkillConfig struct {
	ID       string `json:"id"`
	Required bool   `json:"required,omitempty"`
}

type AdaptersConfig struct {
	Codex  AdapterConfig `json:"codex"`
	Claude AdapterConfig `json:"claude"`
}

type AdapterConfig struct {
	Enabled bool `json:"enabled"`
}
