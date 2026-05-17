package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"

	"github.com/fatb4f/bashly.sh/internal/agentgen/cuegraph"
	"github.com/fatb4f/bashly.sh/internal/agentgen/contract"
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
	case "targets":
		return runTargets(args[1:])
	case "vet":
		return runVet(args[1:])
	case "-h", "--help", "help":
		usage()
		return 0
	default:
		fmt.Fprintf(os.Stderr, "agentgen: unknown command: %s\n", args[0])
		usage()
		return 2
	}
}

func runTargets(args []string) int {
	fs := flag.NewFlagSet("targets", flag.ContinueOnError)
	fs.SetOutput(os.Stderr)
	root := fs.String("project-root", ".", "project root")
	if err := fs.Parse(args); err != nil {
		return 2
	}

	graph, err := cuegraph.New(*root)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}

	var targets []contract.GenerationTarget
	if err := graph.Decode("./internal/agent/repo", "surfaces.generation_targets", &targets); err != nil {
		fmt.Fprintf(os.Stderr, "agentgen targets: %v\n", err)
		return 1
	}

	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	if err := enc.Encode(targets); err != nil {
		fmt.Fprintf(os.Stderr, "agentgen targets: %v\n", err)
		return 1
	}

	return 0
}

func runVet(args []string) int {
	fs := flag.NewFlagSet("vet", flag.ContinueOnError)
	fs.SetOutput(os.Stderr)
	root := fs.String("project-root", ".", "project root")
	if err := fs.Parse(args); err != nil {
		return 2
	}

	graph, err := cuegraph.New(*root)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}

	if err := graph.Vet(); err != nil {
		fmt.Fprintf(os.Stderr, "agentgen vet: %v\n", err)
		return 1
	}

	fmt.Println("agentgen vet: ok")
	return 0
}

func usage() {
	fmt.Fprintln(os.Stderr, "Usage: agentgen <targets|vet> [--project-root PATH]")
}
