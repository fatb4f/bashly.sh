package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"

	"github.com/fatb4f/agent-sdk/internal/contract"
	"github.com/fatb4f/agent-sdk/internal/cuegraph"
	sdkcue "github.com/fatb4f/agent-sdk/cue"
)

func main() {
	os.Exit(run(os.Args[1:]))
}

func run(args []string) int {
	if len(args) == 0 {
		usage()
		return 2
	}

	switch args[0] {
	case "generate":
		return runGenerate(args[1:])
	case "check-generated":
		return runCheckGenerated(args[1:])
	case "vet":
		return runVet(args[1:])
	case "doctor":
		return runDoctor(args[1:])
	case "targets":
		return runTargets(args[1:])
	case "-h", "--help", "help":
		usage()
		return 0
	default:
		fmt.Fprintf(os.Stderr, "agentctl: unknown command: %s\n", args[0])
		usage()
		return 2
	}
}

func runGenerate(args []string) int {
	fs := flag.NewFlagSet("generate", flag.ContinueOnError)
	fs.SetOutput(os.Stderr)
	root := fs.String("project-root", ".", "project root")
	if err := fs.Parse(args); err != nil {
		return 2
	}

	graph, err := cuegraph.New(*root, sdkcue.FS)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}

	var project contract.ProjectGraph
	if err := graph.Decode("agent.cue", "project", &project); err != nil {
		fmt.Fprintf(os.Stderr, "agentctl generate: %v\n", err)
		return 1
	}

	// Phase 3: Write project-graph.json before rendering
	outputRoot := filepath.Join(*root, project.Output.Root)
	if err := os.MkdirAll(filepath.Join(outputRoot, "generated"), 0755); err != nil {
		fmt.Fprintf(os.Stderr, "agentctl generate: %v\n", err)
		return 1
	}

	graphPath := filepath.Join(outputRoot, "generated", "project-graph.json")
	f, err := os.Create(graphPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "agentctl generate: %v\n", err)
		return 1
	}
	defer f.Close()

	enc := json.NewEncoder(f)
	enc.SetIndent("", "  ")
	if err := enc.Encode(project); err != nil {
		fmt.Fprintf(os.Stderr, "agentctl generate: %v\n", err)
		return 1
	}

	fmt.Printf("agentctl generate: wrote %s\n", graphPath)
	// TODO: Implement rendering of frames based on ProjectGraph and embedded templates.

	return 0
}

func runCheckGenerated(args []string) int {
	fmt.Println("agentctl check-generated: not fully implemented yet")
	return 0
}

func runVet(args []string) int {
	fs := flag.NewFlagSet("vet", flag.ContinueOnError)
	fs.SetOutput(os.Stderr)
	root := fs.String("project-root", ".", "project root")
	if err := fs.Parse(args); err != nil {
		return 2
	}

	graph, err := cuegraph.New(*root, sdkcue.FS)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}

	if err := graph.Vet("agent.cue"); err != nil {
		fmt.Fprintf(os.Stderr, "agentctl vet: %v\n", err)
		return 1
	}

	fmt.Println("agentctl vet: ok")
	return 0
}

func runDoctor(args []string) int {
	fmt.Println("agentctl doctor: ok")
	return 0
}

func runTargets(args []string) int {
	fs := flag.NewFlagSet("targets", flag.ContinueOnError)
	fs.SetOutput(os.Stderr)
	root := fs.String("project-root", ".", "project root")
	pkg := fs.String("package", "agent.cue", "CUE package to evaluate")
	expr := fs.String("expr", "surfaces.generation_targets", "CUE expression to decode")
	if err := fs.Parse(args); err != nil {
		return 2
	}

	graph, err := cuegraph.New(*root, sdkcue.FS)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}

	var targets []contract.GenerationTarget
	if err := graph.Decode(*pkg, *expr, &targets); err != nil {
		fmt.Fprintf(os.Stderr, "agentctl targets: %v\n", err)
		return 1
	}

	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	if err := enc.Encode(targets); err != nil {
		fmt.Fprintf(os.Stderr, "agentctl targets: %v\n", err)
		return 1
	}

	return 0
}

func usage() {
	fmt.Fprintln(os.Stderr, "Usage: agentctl <generate|check-generated|vet|doctor|targets> [--project-root PATH]")
}
