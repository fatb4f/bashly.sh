package cuegraph

import (
	"fmt"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"cuelang.org/go/cue/load"

	"github.com/fatb4f/agent-sdk/tools/internal/contract"
)

type Graph struct {
	root string
}

func New(root string) (*Graph, error) {
	if root == "" {
		root = "."
	}
	return &Graph{root: root}, nil
}

func (g *Graph) Decode(pkgPath, expr string, dst any) error {
	v, err := g.lookup(pkgPath, expr)
	if err != nil {
		return err
	}
	if err := v.Decode(dst); err != nil {
		return fmt.Errorf("decode %s:%s: %w", pkgPath, expr, err)
	}
	return nil
}

func (g *Graph) Vet() error {
	var targets []contract.GenerationTarget
	if err := g.Decode("./internal/agent/repo", "surfaces.generation_targets", &targets); err != nil {
		return err
	}

	var generationData map[string]any
	if err := g.Decode("./internal/agent/codex", "generationData", &generationData); err != nil {
		return err
	}

	var skillIndex []any
	if err := g.Decode("./internal/agent/codex", "skillIndex", &skillIndex); err != nil {
		return err
	}

	var surfaceIndex []any
	if err := g.Decode("./internal/agent/codex", "surfaceIndex", &surfaceIndex); err != nil {
		return err
	}

	var defaultRules string
	if err := g.Decode("./internal/agent/codex", "defaultRules", &defaultRules); err != nil {
		return err
	}

	_ = generationData
	_ = skillIndex
	_ = surfaceIndex
	_ = defaultRules
	return nil
}

func (g *Graph) lookup(pkgPath, expr string) (cue.Value, error) {
	inst, err := g.load(pkgPath)
	if err != nil {
		return cue.Value{}, err
	}

	path := cue.ParsePath(expr)
	v := inst.LookupPath(path)
	if err := v.Err(); err != nil {
		return cue.Value{}, fmt.Errorf("lookup %s:%s: %w", pkgPath, expr, err)
	}

	return v, nil
}

func (g *Graph) load(pkgPath string) (cue.Value, error) {
	instances := load.Instances([]string{pkgPath}, &load.Config{
		Dir:        g.root,
		ModuleRoot: g.root,
	})
	if len(instances) != 1 {
		return cue.Value{}, fmt.Errorf("load %s: expected one instance, got %d", pkgPath, len(instances))
	}

	if err := instances[0].Err; err != nil {
		return cue.Value{}, fmt.Errorf("load %s: %w", pkgPath, err)
	}

	ctx := cuecontext.New()
	v := ctx.BuildInstance(instances[0])
	if err := v.Err(); err != nil {
		return cue.Value{}, fmt.Errorf("build %s: %w", pkgPath, err)
	}

	return v, nil
}
