package cuegraph

import (
	"fmt"
	"io/fs"
	"path/filepath"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"cuelang.org/go/cue/load"
)

type Graph struct {
	root     string
	schemaFS fs.FS
}

func New(root string, schemaFS fs.FS) (*Graph, error) {
	if root == "" {
		root = "."
	}
	return &Graph{
		root:     root,
		schemaFS: schemaFS,
	}, nil
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

func (g *Graph) Vet(pkgPath string) error {
	inst, err := g.load(pkgPath)
	if err != nil {
		return err
	}
	return inst.Validate()
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
	absPath := pkgPath
	if !filepath.IsAbs(pkgPath) {
		absPath = filepath.Join(g.root, pkgPath)
	}

	instances := load.Instances([]string{absPath}, &load.Config{
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
